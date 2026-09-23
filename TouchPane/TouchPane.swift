//
//  Model.swift
//  TouchPane
//
//  Created by Sebastian Hueber on 03.02.23.
//

import AppKit
import Combine
import TouchUpCore

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case simplifiedChinese
    case traditionalChinese

    var id: String { rawValue }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

struct DiagnosticsEvent: Identifiable {
    let id = UUID()
    let time = Date()
    let message: String
}

struct TouchManagerDiagnosticsSnapshot {
    let inputProcessFrameID: Int
    let inputActiveTouchCount: Int
    let threeFingerTracking: Bool
    let threeFingerTriggered: Bool
    let threeFingerTouchCount: Int
    let threeFingerUpwardTouchCount: Int
    let threeFingerVerticalTravelMM: CGFloat
    let threeFingerHorizontalTravelMM: CGFloat
}

class TouchPane: NSObject, ObservableObject {
    
    let touchManager: TUCTouchInputManager
    @Published var touches = [TUCTouch]()
    @Published var appLanguage: AppLanguage = .system {
        didSet { UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage") }
    }
    @Published var appAppearance: AppAppearance = .system {
        didSet { UserDefaults.standard.set(appAppearance.rawValue, forKey: "appAppearance") }
    }
    
    
    var observers = [AnyCancellable]()
    
    
    @Published var isPublishingMouseEventsEnabled = true
    
    @Published var connectionState: ConnectionState = .disconnected
    
    
    
    @Published var holdDuration: TimeInterval = 0.1
    @Published var doubleClickDistance: CGFloat = 3 //mm
    @Published var errorResistance: NSInteger = 0 // num of Reports to wait before cancelling a touch
    @Published var ignoreOriginTouches: Bool = false
    
    
    
    @Published var isSecondaryClickEnabled = false
    @Published var isMagnificationEnabled = false
    @Published var isThreeFingerSwipeEnabled = true
    @Published var isFourFingerSwipeUpKeyboardEnabled = true
    @Published var fiveFingerHoldShortcutSpec: String = "fn"
    @Published var fourFingerSwipeLeftSequenceSpec: String = "cmd+a, delete"

    @Published var isScrollInertiaEnabled = true
    @Published var scrollSpeedMultiplier: CGFloat = 1.4
    @Published var scrollInertiaDecelerationPerFrame: CGFloat = 0.95
    @Published var scrollInertiaVelocityMultiplier: CGFloat = 1.0
    
    
    
    @Published var connectedScreens = [TUCScreen]()
    var connectedTouchscreen: TUCScreen?
    
    var lastDateUSBAdded: Date?
    var lastDateScreenAdded: Date?
    var idOfLastAddedScreen: UInt?
    
    let hotPlugTimeInterval: TimeInterval = 10
    
    
    @Published var isAccessibilityAccessGranted = false
    @Published var touchUpdateCount: Int = 0
    @Published var lastTouchUpdateAt: Date?
    @Published var lastActiveTouchCount: Int = 0
    @Published var gestureDecisionCount: Int = 0
    @Published var lastGestureName: String = "-"
    @Published var lastActionName: String = "-"
    @Published var lastGestureDecisionAt: Date?
    @Published var currentGestureName: String = "-"
    @Published var currentActionName: String = "-"
    @Published var recentGestureEvents: [DiagnosticsEvent] = []
    @Published var hidConnectCount: Int = 0
    @Published var hidDisconnectCount: Int = 0
    @Published var diagnosticsEvents: [DiagnosticsEvent] = []
    @Published var inputProcessFrameID: Int = 0
    @Published var inputActiveTouchCount: Int = 0
    @Published var threeFingerTracking: Bool = false
    @Published var threeFingerTriggered: Bool = false
    @Published var threeFingerTouchCount: Int = 0
    @Published var threeFingerUpwardTouchCount: Int = 0
    @Published var threeFingerVerticalTravelMM: CGFloat = 0
    @Published var threeFingerHorizontalTravelMM: CGFloat = 0
    
    private var lastGestureLogAt: Date?
    private var lastGestureSignature: String = ""
    private var traditionalChineseCache: [String: String] = [:]

    func text(_ english: String, _ chinese: String) -> String {
        switch effectiveLanguage {
        case .simplifiedChinese:
            return chinese
        case .traditionalChinese:
            return traditionalChineseText(chinese)
        case .system, .english:
            return english
        }
    }

    var effectiveLanguage: AppLanguage {
        guard appLanguage == .system else { return appLanguage }
        let languageCode = Locale.preferredLanguages.first?
            .replacingOccurrences(of: "_", with: "-")
            .lowercased() ?? "en"

        if languageCode.hasPrefix("zh-hant") ||
            languageCode.hasPrefix("zh-tw") ||
            languageCode.hasPrefix("zh-hk") ||
            languageCode.hasPrefix("zh-mo") {
            return .traditionalChinese
        }
        if languageCode == "zh" || languageCode.hasPrefix("zh-") {
            return .simplifiedChinese
        }
        return .english
    }

    func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .system: return text("System", "跟随系统")
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        }
    }

    private func traditionalChineseText(_ simplified: String) -> String {
        if let cached = traditionalChineseCache[simplified] {
            return cached
        }

        let convertedText = NSMutableString(string: simplified)
        guard CFStringTransform(convertedText, nil, "Hans-Hant" as CFString, false) else {
            return simplified
        }

        var result = convertedText as String
        let macTerminology = [
            ("設置", "設定"),
            ("觸摸", "觸控"),
            ("鼠標", "滑鼠"),
            ("屏幕", "螢幕"),
            ("滾動", "捲動"),
            ("調度中心", "指揮中心"),
            ("調試", "除錯"),
            ("實時", "即時"),
            ("數據", "資料"),
            ("默認", "預設"),
            ("信息", "資訊"),
            ("文件", "檔案"),
            ("啓", "啟")
        ]
        for (source, replacement) in macTerminology {
            result = result.replacingOccurrences(of: source, with: replacement)
        }

        traditionalChineseCache[simplified] = result
        return result
    }

    func appearanceName(_ appearance: AppAppearance) -> String {
        switch appearance {
        case .system: return text("System", "跟随系统")
        case .light: return text("Light", "浅色")
        case .dark: return text("Dark", "深色")
        }
    }
    
    // MARK: - Attempt to automatically determine touch screen
    
    
    
    var identificationCues: (name:String, id:UInt) {
        get {
            let name = UserDefaults.standard.string(forKey: "touchscreenNameCue") ?? "Digital"
            let id   = UserDefaults.standard.integer(forKey: "touchscreenIDCue")
            return (name, UInt(id))
        }
    }
    
    func rememeberCues() {
        if let connectedTouchscreen = self.touchscreen() {
            UserDefaults.standard.set(connectedTouchscreen.name, forKey: "touchscreenNameCue")
            UserDefaults.standard.set(connectedTouchscreen.id,   forKey: "touchscreenIDCue")
        }
    }
    
    
    /**
     returns true, if the screen list contained the preferred screen which is now assigned the touch screen.
     if screen list empty, it removes the assigned touch screen.
     */
    @discardableResult func identifyPreferredOrNoScreen() -> Bool {
        let cues = identificationCues
        
        
        if connectedScreens.count == 0 {
            self.connectedTouchscreen = nil
            self.connectionState = .uncertain
            print("OH NO SCREEN")
            return true
        }
        
       
        
        if let perfectMatch = connectedScreens.first(where: { $0.matching(name: cues.name, id: cues.id) == 1}) {
            self.connectedTouchscreen = perfectMatch
            self.connectionState = lastDateUSBAdded == nil ? .connectedPreferred : .connectedHotPlug
            print("PREFERRED SCREEN FOUND")
            return true
        }
        
        return false
    }
    
    
    @discardableResult func identifyHotPlug() -> Bool {
        // if the USB cable of a touch screen was plugged in within last 10 seconds, assign this to the touchscreen
        
        // no need to hot plug during existing connection
        if self.connectionState.isConnected {
            print("HOTPLUG SKIPPED")
            return false
        }
        
        if let lastDateUSBAdded, let lastDateScreenAdded, let idOfLastAddedScreen {
            if Date().timeIntervalSince(lastDateUSBAdded) < hotPlugTimeInterval
                && Date().timeIntervalSince(lastDateScreenAdded) < hotPlugTimeInterval {
                
                
                if let screen = self.connectedScreens.first(where: {$0.id == idOfLastAddedScreen}) {
                    self.connectedTouchscreen = screen
                    let cues = identificationCues
                    let match = screen.matching(name: cues.name, id: cues.id)
                    self.connectionState = match == 1 ? .connectedPreferred : .connectedHotPlug
                    print("HOTPLUG SUCCESS")
                    return true
                }
                
                print("HOTPLUG FAIL")
            }
        }
        
        return false
    }
    
    
    @objc func screenParametersDidChange() {
        // identify which screen is newly added.
        let oldScreenList = self.connectedScreens
        self.connectedScreens = TUCScreen.allScreens() as! [TUCScreen]
        
        // a new screen appeared!
        if connectedScreens.count > oldScreenList.count {
            self.lastDateScreenAdded = Date()
            
            let new = connectedScreens.first { s in
                !(oldScreenList.contains(where: {$0.id == s.id}))
            }
            if let new {
                self.idOfLastAddedScreen = new.id
                identifyHotPlug()
            }
        }
        
        // search for the preferred screen, also important if user rearranged screens (and screen numbers)
        if !self.identifyPreferredOrNoScreen() {
            self.connectedTouchscreen = self.connectedScreens.last
        }
    }
    
    
    func checkAccessibilityAccessGranted() {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        self.isAccessibilityAccessGranted = AXIsProcessTrustedWithOptions([checkOptPrompt: true] as CFDictionary?)
    }
    
    var accessibilityTrustedNow: Bool {
        AXIsProcessTrusted()
    }
    
    func grantAccessibilityAccess() {
        self.touchManager.triggerSystemAccessibilityAccessAlert()
        (NSApp.delegate as? AppDelegate)?.settingsWindow.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.checkAccessibilityAccessGranted()
        }
        addDiagnosticsEvent("Requested Accessibility access prompt")
    }

    func sendVirtualKeyboardKey(token: String, shifted: Bool = false) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let shortcutSpec: String
        if let mappedShortcut = virtualKeyboardShortcutSpec(for: trimmed, shifted: shifted) {
            shortcutSpec = mappedShortcut
        } else if shifted && trimmed.range(of: #"^[a-z]$"#, options: .regularExpression) != nil {
            shortcutSpec = "shift+\(trimmed)"
        } else {
            shortcutSpec = trimmed
        }

        touchManager.performShortcutChordSpec(shortcutSpec)
        addDiagnosticsEvent("Virtual key: \(shortcutSpec)")
    }

    private func virtualKeyboardShortcutSpec(for token: String, shifted: Bool) -> String? {
        if shifted && token.range(of: #"^[a-z]$"#, options: .regularExpression) != nil {
            return "shift+\(token)"
        }

        let symbolShortcutMap: [String: String] = [
            "-": "hyphen",
            "/": "slash",
            ":": "shift+semicolon",
            ";": "semicolon",
            "(": "shift+9",
            ")": "shift+0",
            "$": "shift+4",
            "&": "shift+7",
            "@": "shift+2",
            "\"": "shift+quote",
            ".": "period",
            ",": "comma",
            "?": "shift+slash",
            "!": "shift+1",
            "'": "quote",
            "#": "shift+3",
            "%": "shift+5",
            "^": "shift+6",
            "*": "shift+8",
            "+": "shift+equal",
            "=": "equal",
            "_": "shift+hyphen",
            "\\": "backslash",
            "|": "shift+backslash",
            "~": "shift+grave",
            "<": "shift+comma"
        ]

        return symbolShortcutMap[token]
    }
    
    
    override init() {
        self.touchManager = TUCTouchInputManager()
        
        super.init()
        
        self.screenParametersDidChange()
        
        self.touchManager.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(TouchPane.screenParametersDidChange), name: NSApplication.didChangeScreenParametersNotification, object: nil)

        initPreferences()
        
        checkAccessibilityAccessGranted()
        addDiagnosticsEvent("Initialized model")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func resetDiagnostics() {
        touchUpdateCount = 0
        lastTouchUpdateAt = nil
        lastActiveTouchCount = 0
        gestureDecisionCount = 0
        lastGestureName = "-"
        lastActionName = "-"
        lastGestureDecisionAt = nil
        currentGestureName = "-"
        currentActionName = "-"
        recentGestureEvents = []
        lastGestureLogAt = nil
        lastGestureSignature = ""
        hidConnectCount = 0
        hidDisconnectCount = 0
        diagnosticsEvents = []
        inputProcessFrameID = 0
        inputActiveTouchCount = 0
        threeFingerTracking = false
        threeFingerTriggered = false
        threeFingerTouchCount = 0
        threeFingerUpwardTouchCount = 0
        threeFingerVerticalTravelMM = 0
        threeFingerHorizontalTravelMM = 0
        addDiagnosticsEvent("Diagnostics reset")
    }
    
    func restartInputPipeline() {
        touchManager.stop()
        touchManager.start()
        addDiagnosticsEvent("Restarted HID input pipeline")
    }
    
    func refreshTouchConnection() {
        addDiagnosticsEvent("Refreshing touch connection...")
        connectionState = .uncertain
        
        // Rebuild HID connection and then refresh screen mapping to avoid stale assignment.
        touchManager.stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.touchManager.start()
            self.screenParametersDidChange()
            self.checkAccessibilityAccessGranted()
            self.addDiagnosticsEvent("Touch connection refresh requested")
        }
    }
    
    func addDiagnosticsEvent(_ message: String) {
        let applyEvent = {
            self.diagnosticsEvents.insert(DiagnosticsEvent(message: message), at: 0)
            if self.diagnosticsEvents.count > 40 {
                self.diagnosticsEvents.removeLast(self.diagnosticsEvents.count - 40)
            }
        }

        if Thread.isMainThread {
            applyEvent()
        } else {
            DispatchQueue.main.async(execute: applyEvent)
        }
    }
    
    func gestureDisplayName(_ gesture: TUCCursorGesture) -> String {
        switch gesture {
        case .TUCCursorGestureTouchDown: return text("Touch Down", "触摸按下")
        case .TUCCursorGestureTap: return text("Tap", "点按")
        case .TUCCursorGestureLongPress: return text("Long Press", "长按")
        case .TUCCursorGestureDrag: return text("Drag (1 Finger)", "单指拖动")
        case .TUCCursorGestureHoldAndDrag: return text("Hold + Drag", "长按拖动")
        case .TUCCursorGestureTapSecondFinger: return text("Second-Finger Tap", "第二指点按")
        case .TUCCursorGestureTwoFingerDrag: return text("Two-Finger Drag", "双指拖动")
        case .TUCCursorGesturePinch: return text("Pinch", "捏合")
        case .TUCCursorGestureThreeFingerSwipeUp: return text("Three-Finger Swipe Up", "三指上滑")
        case .TUCCursorGestureFourFingerSwipeLeft: return text("Four-Finger Swipe Left", "四指左滑")
        case .TUCCursorGestureFiveFingerHold: return text("Five-Finger Hold", "五指长按")
        case .TUCCursorGestureFourFingerSwipeUp: return text("Four-Finger Swipe Up", "四指上滑")
        case .TUCCursorGestureFourFingerSwipeDown: return text("Four-Finger Swipe Down", "四指下滑")
        default: return text("Unknown", "未知") + " (\(gesture.rawValue))"
        }
    }
    
    func actionDisplayName(_ action: TUCCursorAction) -> String {
        switch action {
        case .none: return text("None", "无")
        case .move: return text("Move Cursor", "移动光标")
        case .pointAndClick: return text("Point and Click", "指向并点按")
        case .drag: return text("Drag", "拖动")
        case .click: return text("Click", "点按")
        case .secondaryClick: return text("Secondary Click", "辅助点按")
        case .scroll: return text("Scroll", "滚动")
        case .magnify: return text("Magnify", "缩放")
        case .missionControl: return "Mission Control"
        case .keyboardShortcutHold: return text("Hold Shortcut", "按住快捷键")
        case .keyboardShortcutSequence: return text("Shortcut Sequence", "快捷键序列")
        case .floatingKeyboard: return text("Floating Keyboard", "悬浮键盘")
        case .hideFloatingKeyboard: return text("Hide Floating Keyboard", "隐藏悬浮键盘")
        @unknown default: return text("Unknown", "未知")
        }
    }
    
    func addGestureEventIfNeeded(gestureName: String, actionName: String) {
        let signature = "\(gestureName)->\(actionName)"
        let now = Date()
        let shouldLog: Bool
        if signature != lastGestureSignature {
            shouldLog = true
        } else if let lastGestureLogAt {
            shouldLog = now.timeIntervalSince(lastGestureLogAt) >= 0.25
        } else {
            shouldLog = true
        }
        
        if shouldLog {
            recentGestureEvents.insert(DiagnosticsEvent(message: "\(gestureName) -> \(actionName)"), at: 0)
            if recentGestureEvents.count > 24 {
                recentGestureEvents.removeLast(recentGestureEvents.count - 24)
            }
            lastGestureSignature = signature
            lastGestureLogAt = now
        }
    }
    
    func suggestedBlocker() -> String {
        if !accessibilityTrustedNow {
            return text("Accessibility permission is not active.", "辅助功能权限未启用。")
        }
        if !isPublishingMouseEventsEnabled {
            return text("Mouse event publishing is OFF.", "鼠标事件输出已关闭。")
        }
        if !connectionState.isConnected {
            return text("No touchscreen HID connection detected.", "未检测到触摸屏 HID 连接。")
        }
        if touchUpdateCount == 0 {
            return text("No touch reports received yet.", "尚未收到触摸报告。")
        }
        return text("Touch reports are flowing. If output still fails, inspect diagnostics and restart input pipeline.", "触摸报告接收正常；如仍无输出，请查看诊断并重启输入通道。")
    }
    
    func sendTestClickAtCursor() {
        let loc = NSEvent.mouseLocation
        guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: loc, mouseButton: .left),
              let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: loc, mouseButton: .left) else {
            addDiagnosticsEvent("Failed to build test click events")
            return
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        addDiagnosticsEvent("Posted test click at cursor")
    }
    
    func sendTestScroll() {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: -80, wheel2: 0, wheel3: 0) else {
            addDiagnosticsEvent("Failed to build test scroll event")
            return
        }
        event.post(tap: .cghidEventTap)
        addDiagnosticsEvent("Posted test scroll event")
    }
    
}


// MARK: - Loading, Saving and Syncing Settings with Framework
extension TouchPane {
    
    func initPreferences() {
        let defaults = UserDefaults.standard
        
        defaults.register(defaults: [
            "appLanguage" : AppLanguage.system.rawValue,
            "appAppearance" : AppAppearance.system.rawValue,
            "holdDuration" : 0.1,
            "doubleClickDistance" : 8,
            "errorResistance" : 4,
            "ignoreOriginTouches" : true,
            "isSecondaryClickEnabled" : true,
            "isMagnificationEnabled" : true,
            "isThreeFingerSwipeEnabled" : true,
            "isFourFingerSwipeUpKeyboardEnabled" : true,
            "fiveFingerHoldShortcutSpec" : "fn",
            "fourFingerSwipeLeftSequenceSpec" : "cmd+a, delete",
            "isScrollInertiaEnabled" : true,
            "scrollSpeedMultiplier" : 1.4,
            "scrollInertiaDecelerationPerFrame" : 0.95,
            "scrollInertiaVelocityMultiplier" : 1.0
        ])

        appLanguage = AppLanguage(rawValue: defaults.string(forKey: "appLanguage") ?? "") ?? .system
        appAppearance = AppAppearance(rawValue: defaults.string(forKey: "appAppearance") ?? "") ?? .system
        
        holdDuration = defaults.double(forKey: "holdDuration")
        doubleClickDistance = defaults.double(forKey: "doubleClickDistance")
        errorResistance = defaults.integer(forKey: "errorResistance")
        ignoreOriginTouches = defaults.bool(forKey: "ignoreOriginTouches")
        defaults.removeObject(forKey: "primaryInteractionMode")
        defaults.removeObject(forKey: "isClickWindowToFrontEnabled")
        
        
        self.observers = [
            $isPublishingMouseEventsEnabled.assign(to: \.postMouseEvents, on: touchManager),
            $holdDuration.assign(to: \.holdDuration, on: touchManager),
            $doubleClickDistance.assign(to: \.doubleClickTolerance, on: touchManager),
            $errorResistance.assign(to: \.errorResistance, on: touchManager),
            $ignoreOriginTouches.assign(to: \.ignoreOriginTouches, on: touchManager),
            $isThreeFingerSwipeEnabled.assign(to: \.threeFingerSwipeEnabled, on: touchManager),
            $isFourFingerSwipeUpKeyboardEnabled.assign(to: \.fourFingerSwipeUpKeyboardEnabled, on: touchManager),
            $fiveFingerHoldShortcutSpec.assign(to: \.fiveFingerHoldShortcutSpec, on: touchManager),
            $fourFingerSwipeLeftSequenceSpec.assign(to: \.fourFingerSwipeLeftSequenceSpec, on: touchManager),
            $isScrollInertiaEnabled.assign(to: \.scrollInertiaEnabled, on: touchManager),
            $scrollSpeedMultiplier.assign(to: \.scrollSpeedMultiplier, on: touchManager),
            $scrollInertiaDecelerationPerFrame.assign(to: \.scrollInertiaDecelerationPerFrame, on: touchManager),
            $scrollInertiaVelocityMultiplier.assign(to: \.scrollInertiaVelocityMultiplier, on: touchManager)
        ]
        
        
        
        isSecondaryClickEnabled = defaults.bool(forKey: "isSecondaryClickEnabled")
        isMagnificationEnabled = defaults.bool(forKey: "isMagnificationEnabled")
        isThreeFingerSwipeEnabled = defaults.bool(forKey: "isThreeFingerSwipeEnabled")
        isFourFingerSwipeUpKeyboardEnabled = defaults.object(forKey: "isFourFingerSwipeUpKeyboardEnabled") as? Bool ?? true
        fiveFingerHoldShortcutSpec = defaults.string(forKey: "fiveFingerHoldShortcutSpec") ?? "fn"
        let savedFourFingerSequence = defaults.string(forKey: "fourFingerSwipeLeftSequenceSpec")
        if let savedFourFingerSequence, !savedFourFingerSequence.isEmpty {
            fourFingerSwipeLeftSequenceSpec = (savedFourFingerSequence == "ctrl+a, delete") ? "cmd+a, delete" : savedFourFingerSequence
        } else {
            fourFingerSwipeLeftSequenceSpec = "cmd+a, delete"
        }
        touchManager.threeFingerSwipeEnabled = isThreeFingerSwipeEnabled
        touchManager.fourFingerSwipeUpKeyboardEnabled = isFourFingerSwipeUpKeyboardEnabled
        touchManager.fiveFingerHoldShortcutSpec = fiveFingerHoldShortcutSpec
        touchManager.fourFingerSwipeLeftSequenceSpec = fourFingerSwipeLeftSequenceSpec

        isScrollInertiaEnabled = defaults.bool(forKey: "isScrollInertiaEnabled")
        scrollSpeedMultiplier = CGFloat(defaults.double(forKey: "scrollSpeedMultiplier"))
        scrollInertiaDecelerationPerFrame = CGFloat(defaults.double(forKey: "scrollInertiaDecelerationPerFrame"))
        scrollInertiaVelocityMultiplier = CGFloat(defaults.double(forKey: "scrollInertiaVelocityMultiplier"))
        touchManager.scrollInertiaEnabled = isScrollInertiaEnabled
        touchManager.scrollSpeedMultiplier = scrollSpeedMultiplier
        touchManager.scrollInertiaDecelerationPerFrame = scrollInertiaDecelerationPerFrame
        touchManager.scrollInertiaVelocityMultiplier = scrollInertiaVelocityMultiplier
    }
    
    
    func savePreferences() {
        let defaults = UserDefaults.standard

        defaults.set(appLanguage.rawValue, forKey: "appLanguage")
        defaults.set(appAppearance.rawValue, forKey: "appAppearance")
        
        defaults.set(holdDuration, forKey: "holdDuration")
        defaults.set(doubleClickDistance, forKey: "doubleClickDistance")
        defaults.set(errorResistance, forKey: "errorResistance")
        defaults.set(ignoreOriginTouches, forKey: "ignoreOriginTouches")
        
        defaults.set(isSecondaryClickEnabled, forKey: "isSecondaryClickEnabled")
        defaults.set(isMagnificationEnabled, forKey: "isMagnificationEnabled")
        defaults.set(isThreeFingerSwipeEnabled, forKey: "isThreeFingerSwipeEnabled")
        defaults.set(isFourFingerSwipeUpKeyboardEnabled, forKey: "isFourFingerSwipeUpKeyboardEnabled")
        defaults.set(fiveFingerHoldShortcutSpec, forKey: "fiveFingerHoldShortcutSpec")
        defaults.set(fourFingerSwipeLeftSequenceSpec, forKey: "fourFingerSwipeLeftSequenceSpec")

        defaults.set(isScrollInertiaEnabled, forKey: "isScrollInertiaEnabled")
        defaults.set(Double(scrollSpeedMultiplier), forKey: "scrollSpeedMultiplier")
        defaults.set(Double(scrollInertiaDecelerationPerFrame), forKey: "scrollInertiaDecelerationPerFrame")
        defaults.set(Double(scrollInertiaVelocityMultiplier), forKey: "scrollInertiaVelocityMultiplier")
    }
    
}



extension TouchPane: TUCTouchDelegate {
    func performUIUpdate(_ updates: @escaping () -> Void) {
        if Thread.isMainThread {
            updates()
        } else {
            DispatchQueue.main.async(execute: updates)
        }
    }

    func captureTouchManagerDiagnostics() -> TouchManagerDiagnosticsSnapshot {
        TouchManagerDiagnosticsSnapshot(
            inputProcessFrameID: Int(touchManager.debugProcessFrameID),
            inputActiveTouchCount: Int(touchManager.debugActiveTouchCount),
            threeFingerTracking: touchManager.debugThreeFingerTracking,
            threeFingerTriggered: touchManager.debugThreeFingerTriggered,
            threeFingerTouchCount: Int(touchManager.debugThreeFingerTouchCount),
            threeFingerUpwardTouchCount: Int(touchManager.debugThreeFingerUpwardTouchCount),
            threeFingerVerticalTravelMM: touchManager.debugThreeFingerVerticalTravelMM,
            threeFingerHorizontalTravelMM: touchManager.debugThreeFingerHorizontalTravelMM
        )
    }

    func applyTouchManagerDiagnostics(_ snapshot: TouchManagerDiagnosticsSnapshot) {
        inputProcessFrameID = snapshot.inputProcessFrameID
        inputActiveTouchCount = snapshot.inputActiveTouchCount
        threeFingerTracking = snapshot.threeFingerTracking
        threeFingerTriggered = snapshot.threeFingerTriggered
        threeFingerTouchCount = snapshot.threeFingerTouchCount
        threeFingerUpwardTouchCount = snapshot.threeFingerUpwardTouchCount
        threeFingerVerticalTravelMM = snapshot.threeFingerVerticalTravelMM
        threeFingerHorizontalTravelMM = snapshot.threeFingerHorizontalTravelMM
    }

    func touchesDidChange() {
        let touchSnapshot = (self.touchManager.touchSet.allObjects as? [TUCTouch]) ?? []
        let lastTouchUpdateAt = Date()
        let activeTouchCount = touchSnapshot.filter { $0.isActive() }.count
        let diagnosticsSnapshot = captureTouchManagerDiagnostics()

        performUIUpdate {
            self.touches = touchSnapshot
            self.touchUpdateCount += 1
            self.lastTouchUpdateAt = lastTouchUpdateAt
            self.lastActiveTouchCount = activeTouchCount
            self.applyTouchManagerDiagnostics(diagnosticsSnapshot)
        }
    }

    func inputDiagnosticsDidChange() {
        let diagnosticsSnapshot = captureTouchManagerDiagnostics()
        performUIUpdate {
            self.applyTouchManagerDiagnostics(diagnosticsSnapshot)
        }
    }
    
    
    func touchscreen() -> TUCScreen? {
        self.connectedTouchscreen ?? self.connectedScreens.last
    }

    
    func action(for gesture: TUCCursorGesture) -> TUCCursorAction {
        let action: TUCCursorAction
        switch gesture {
        case .TUCCursorGestureTouchDown:
            action = .move
            
        case .TUCCursorGestureTap:
            action = .click
            
        case .TUCCursorGestureLongPress:
            action = .click
            
        case .TUCCursorGestureDrag:
            action = .scroll
            
        case .TUCCursorGestureHoldAndDrag:
            action = .drag
            
        case .TUCCursorGestureTapSecondFinger:
            action = isSecondaryClickEnabled ? .secondaryClick : .none
            
        case .TUCCursorGestureTwoFingerDrag:
            action = .scroll
            
        case .TUCCursorGesturePinch:
            action = isMagnificationEnabled ? .magnify : .none

        case .TUCCursorGestureThreeFingerSwipeUp:
            action = .missionControl

        case .TUCCursorGestureFourFingerSwipeLeft:
            action = .keyboardShortcutSequence

        case .TUCCursorGestureFiveFingerHold:
            action = .keyboardShortcutHold

        case .TUCCursorGestureFourFingerSwipeUp:
            action = isFourFingerSwipeUpKeyboardEnabled ? .floatingKeyboard : .none

        case .TUCCursorGestureFourFingerSwipeDown:
            action = isFourFingerSwipeUpKeyboardEnabled ? .hideFloatingKeyboard : .none
            
        default:
            action = .none
        }
        
        let gestureName = gestureDisplayName(gesture)
        let actionName = actionDisplayName(action)
        performUIUpdate {
            self.gestureDecisionCount += 1
            self.lastGestureDecisionAt = Date()
            self.lastGestureName = gestureName
            self.lastActionName = actionName
            self.currentGestureName = gestureName
            self.currentActionName = actionName
            self.addGestureEventIfNeeded(gestureName: gestureName, actionName: actionName)
        }
        
        return action
    }
    
    
    
    func touchscreenDidConnect() {
        performUIUpdate {
            self.hidConnectCount += 1
            self.addDiagnosticsEvent("Touchscreen HID connected")
            self.lastDateScreenAdded = Date()
            
            if !self.identifyHotPlug() {
                if self.connectionState.isConnected {
                    self.connectionState = .uncertain
                }
            }
            
            self.identifyPreferredOrNoScreen()
        }
    }
    
    func touchscreenDidDisconnect() {
        performUIUpdate {
            self.hidDisconnectCount += 1
            self.addDiagnosticsEvent("Touchscreen HID disconnected")
            self.connectionState = .disconnected
        }
    }

    func performCustomAction(_ action: TUCCursorAction) {
        performUIUpdate {
            switch action {
            case .floatingKeyboard:
                (NSApp.delegate as? AppDelegate)?.showFloatingKeyboard()
            case .hideFloatingKeyboard:
                (NSApp.delegate as? AppDelegate)?.hideFloatingKeyboard()
            default:
                break
            }
        }
    }
}


extension TouchPane {
    func uiLabels<T>(for keyPath: KeyPath<TouchPane, T>) -> (title:String, description:String) {
        switch keyPath {
        case \.isPublishingMouseEventsEnabled:
            return(text("Control Mouse with Touch", "启用触摸控制鼠标"),
                   text("Turns the driver on or off.", "开启或关闭触摸输入驱动。"))
            
        case \.connectedTouchscreen:
            return(text("Assign Mouse Events to", "触摸事件发送到"),
                   text("Specifies which screen should receive the touch events.", "指定接收触摸事件的显示器。"))
            
        case \.isSecondaryClickEnabled:
            return(text("Secondary Click", "辅助点按"),
                   text("While your pointing finger is resting on the screen, tap another finger in proximity to it to generate a secondary click event at the location of the first finger.", "一根手指停在屏幕上时，用另一根手指在附近点按，可在第一根手指的位置触发辅助点按。"))
            
        case \.isMagnificationEnabled:
            return(text("Magnification", "缩放"),
                   text("Pinch two fingers to increase or decrease the size of the content. (EXPERIMENTAL)", "双指捏合以放大或缩小内容。（实验功能）"))

        case \.isThreeFingerSwipeEnabled:
            return(text("Three-Finger Swipe Up", "三指上滑"),
                   text("Swipe up with three fingers to open Mission Control.", "三指上滑打开调度中心。"))

        case \.isFourFingerSwipeUpKeyboardEnabled:
            return(text("Four-Finger Swipe Up Keyboard", "四指上滑键盘"),
                   text("Swipe up with four fingers to show the floating keyboard, and swipe down with four fingers to hide it.", "四指上滑显示悬浮键盘，四指下滑隐藏。"))

        case \.fiveFingerHoldShortcutSpec:
            return(text("Five-Finger Hold Shortcut", "五指长按快捷键"),
                   text("Hold five fingers still to keep a shortcut chord pressed. Example: fn or cmd+shift.", "五指保持不动时持续按住快捷键组合，例如 fn 或 cmd+shift。"))

        case \.fourFingerSwipeLeftSequenceSpec:
            return(text("Four-Finger Left Swipe Sequence", "四指左滑快捷键序列"),
                   text("Swipe left with four fingers to fire a shortcut sequence. Example: cmd+a, delete.", "四指左滑触发快捷键序列，例如 cmd+a, delete。"))
            
        case \.holdDuration:
            return(text("Hold Duration", "长按时间"),
                   text("How long do you have to hold finger to initiate hold&drag", "手指按住多久后开始长按拖动。"))
            
        case \.doubleClickDistance:
            return(text("Double Click Zone", "双击范围"),
                   text("How many mm can two taps be apart from each other to qualify double click", "两次点按相距多少毫米以内时判定为双击。"))
            
        case \.ignoreOriginTouches:
            return(text("Ignore Origin Touches", "忽略原点触摸"),
                   text("If your touchscreen randomly sends coordinate (0,0) in its datastream, toggle this option to make input more stable.", "如果触摸屏偶尔错误发送坐标 (0,0)，开启此项可提高稳定性。"))
            
        case \.errorResistance:
            return(text("Error Resistance", "容错等级"),
                   text("If your touchscreen is really unreliable at reporting touches, increase this slider to make inputs more stable at the cost of higher latency in detecting liftoffs.", "触摸报告不稳定时可提高此值；数值越高越稳定，但检测手指离开会稍有延迟。"))

        case \.isScrollInertiaEnabled:
            return(text("Scroll Inertia", "滚动惯性"),
                   text("Keeps scrolling for a short time after you lift your finger (iPad-like).", "手指离开后继续滚动一小段距离，效果类似 iPad。"))

        case \.scrollSpeedMultiplier:
            return(text("Scroll Speed", "滚动速度"),
                   text("Scales regular one-finger drag scrolling. Higher values scroll faster for the same finger travel.", "调整单指拖动滚动速度；数值越高，同样手指位移滚动越快。"))

        case \.scrollInertiaDecelerationPerFrame:
            return(text("Decay Speed", "衰减速度"),
                   text("Higher values decay slower; lower values decay faster.", "数值越高减速越慢，数值越低减速越快。"))

        case \.scrollInertiaVelocityMultiplier:
            return(text("Inertia Amount", "惯性强度"),
                   text("Scales the starting speed of inertial scrolling.", "调整惯性滚动的初始速度。"))
            
        default:
            return("\(keyPath)", "")
        }
    }
}


enum ConnectionState: Int {
    case uncertain
    case disconnected
    case connectedHotPlug // connected as result from hot plugging within a few seconds
    case connectedPreferred // connected with stored cues matching perfectly
    
    var image: NSImage? {
        let image: NSImage?
        
        switch self {
        case .uncertain:
            image = NSImage(systemSymbolName: "rectangle.dashed", accessibilityDescription: nil)
        case .disconnected:
            image = NSImage(systemSymbolName: "rectangle.badge.xmark", accessibilityDescription: nil)
        default:
            image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: nil)
        }

        image?.isTemplate = true
        
        return image
    }
    
    var isConnected: Bool {
        return self == .connectedPreferred || self == .connectedHotPlug
    }
}
                 
                 
extension TUCScreen: Identifiable {
    func matching(name:String, id:UInt) -> Float {
        let sameName = self.name == name
        let sameID = self.id == id
        
        if sameName && sameID { return 1 }
        else if sameName { return 0.5 }
        else if sameID { return 0.2 }
        else { return 0}
    }
}
