//
//  SettingsView.swift
//  TouchPane
//
//  Created by Sebastian Hueber on 03.02.23.
//

import SwiftUI
import TouchUpCore

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case gestures
    case tuning
    case diagnostics

    var id: String { rawValue }

    func title(_ model: TouchPane) -> String {
        switch self {
        case .general: return model.text("General", "通用")
        case .gestures: return model.text("Gestures", "手势")
        case .tuning: return model.text("Tuning", "调校")
        case .diagnostics: return model.text("Diagnostics", "诊断")
        }
    }

    func subtitle(_ model: TouchPane) -> String {
        switch self {
        case .general: return model.text("Input, display and app preferences", "输入、显示器与应用偏好")
        case .gestures: return model.text("Gesture actions and mappings", "手势操作与映射")
        case .tuning: return model.text("Thresholds and scrolling", "阈值与滚动")
        case .diagnostics: return model.text("Debug and live status", "调试与实时状态")
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .gestures: return "hand.tap"
        case .tuning: return "slider.horizontal.3"
        case .diagnostics: return "stethoscope"
        }
    }
}

struct SettingsView: View {

    @ObservedObject var model: TouchPane
    @State private var selectedPane: SettingsPane = .general

    static let diagnosticsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    private var connectedScreenSelection: Binding<UInt> {
        Binding {
            model.connectedTouchscreen?.id ?? 0
        } set: { value in
            model.connectedTouchscreen = model.connectedScreens.first(where: { $0.id == value })
            model.rememeberCues()
        }
    }

    private var scrollSpeedBinding: Binding<Double> {
        Binding {
            Double(model.scrollSpeedMultiplier)
        } set: { value in
            model.scrollSpeedMultiplier = CGFloat(value)
        }
    }

    private var inertiaAmountBinding: Binding<Double> {
        Binding {
            Double(model.scrollInertiaVelocityMultiplier)
        } set: { value in
            model.scrollInertiaVelocityMultiplier = CGFloat(value)
        }
    }

    private var inertiaDecayBinding: Binding<Double> {
        Binding {
            Double(model.scrollInertiaDecelerationPerFrame)
        } set: { value in
            model.scrollInertiaDecelerationPerFrame = CGFloat(value)
        }
    }

    private var errorResistanceBinding: Binding<Double> {
        Binding {
            Double(model.errorResistance)
        } set: { value in
            model.errorResistance = NSInteger(Int(value))
        }
    }

    private var doubleClickDistanceBinding: Binding<Double> {
        Binding {
            Double(model.doubleClickDistance)
        } set: { value in
            model.doubleClickDistance = CGFloat(Int(value))
        }
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(get: { model.appLanguage }, set: { model.appLanguage = $0 })
    }

    private var appearanceSelection: Binding<AppAppearance> {
        Binding(get: { model.appAppearance }, set: { model.appAppearance = $0 })
    }

    private var connectionStateText: String {
        switch model.connectionState {
        case .uncertain: return model.text("Checking", "检查中")
        case .disconnected: return model.text("Disconnected", "未连接")
        case .connectedHotPlug: return model.text("Connected", "已连接")
        case .connectedPreferred: return model.text("Connected (preferred)", "已连接（首选）")
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailPane
        }
        .frame(minWidth: 780, maxWidth: .infinity, minHeight: 560, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TouchPane")
                    .font(.title3.weight(.semibold))
                Text(model.text("Preferences", "偏好设置"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 14)

            VStack(spacing: 4) {
                ForEach(SettingsPane.allCases) { pane in
                    paneButton(pane)
                }
            }
            .padding(.horizontal, 10)

            Spacer()
        }
        .frame(width: 210)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
    }

    private func paneButton(_ pane: SettingsPane) -> some View {
        let isSelected = selectedPane == pane

        return Button {
            selectedPane = pane
        } label: {
            HStack(spacing: 10) {
                Image(systemName: pane.symbol)
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pane.title(model))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(pane.subtitle(model))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageHeader

                switch selectedPane {
                case .general:
                    generalPane
                case .gestures:
                    gesturesPane
                case .tuning:
                    tuningPane
                case .diagnostics:
                    diagnosticsPane
                }
            }
            .padding(24)
            .frame(maxWidth: 860, alignment: .leading)
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedPane.title(model))
                .font(.system(size: 29, weight: .bold))
            Text(selectedPane.subtitle(model))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var generalPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !model.isAccessibilityAccessGranted {
                accessBanner
            }

            SettingsGroup(title: model.text("Appearance & Language", "外观与语言")) {
                VStack(alignment: .leading, spacing: 8) {
                    SettingText(labels: (
                        model.text("Appearance", "外观"),
                        model.text("Follow macOS or choose a fixed light or dark appearance.", "跟随 macOS，或固定使用浅色或深色外观。")
                    ))
                    Picker("", selection: appearanceSelection) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(model.appearanceName(appearance)).tag(appearance)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 8)

                sectionDivider

                VStack(alignment: .leading, spacing: 8) {
                    SettingText(labels: (
                        model.text("Language", "语言"),
                        model.text("Follow the system language or choose English, Simplified Chinese, or Traditional Chinese.", "跟随系统语言，或选择 English / 简体中文 / 繁體中文；无法识别时使用英文。")
                    ))
                    Picker("", selection: languageSelection) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(model.languageName(language)).tag(language)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 8)
            }

            SettingsGroup(title: model.text("Input", "输入")) {
                settingToggleRow(
                    labels: model.uiLabels(for: \.isPublishingMouseEventsEnabled),
                    isOn: $model.isPublishingMouseEventsEnabled
                )

                sectionDivider

                VStack(alignment: .leading, spacing: 8) {
                    SettingText(labels: model.uiLabels(for: \.connectedTouchscreen))

                    if model.connectedScreens.isEmpty {
                        Text(model.text("No connected touchscreen detected yet.", "尚未检测到已连接的触摸屏。"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("", selection: connectedScreenSelection) {
                            ForEach(model.connectedScreens) { screen in
                                Text(screen.name).tag(screen.id)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 320, alignment: .leading)
                    }
                }
                .padding(.vertical, 8)
            }

            SettingsGroup(title: model.text("Status", "状态")) {
                settingValueRow(model.text("Accessibility", "辅助功能"), value: model.accessibilityTrustedNow ? model.text("Granted", "已授权") : model.text("Missing", "未授权"))
                sectionDivider
                settingValueRow(model.text("Input Publishing", "输入输出"), value: model.isPublishingMouseEventsEnabled ? model.text("Enabled", "已启用") : model.text("Disabled", "已停用"))
                sectionDivider
                settingValueRow(model.text("Connection", "连接"), value: connectionStateText)
                sectionDivider
                settingValueRow(model.text("Assigned Screen", "指定显示器"), value: model.connectedTouchscreen?.name ?? model.text("(Auto)", "（自动）"))
            }

            SettingsGroup(title: model.text("About", "关于")) {
                footer
            }
        }
    }

    private var gesturesPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsGroup(title: model.text("Gesture Toggles", "手势开关")) {
                settingToggleRow(labels: model.uiLabels(for: \.isSecondaryClickEnabled), isOn: $model.isSecondaryClickEnabled)
                sectionDivider
                settingToggleRow(labels: model.uiLabels(for: \.isMagnificationEnabled), isOn: $model.isMagnificationEnabled)
                sectionDivider
                settingToggleRow(labels: model.uiLabels(for: \.isThreeFingerSwipeEnabled), isOn: $model.isThreeFingerSwipeEnabled)
                sectionDivider
                settingToggleRow(labels: model.uiLabels(for: \.isFourFingerSwipeUpKeyboardEnabled), isOn: $model.isFourFingerSwipeUpKeyboardEnabled)
            }

            SettingsGroup(title: model.text("Shortcut Mapping", "快捷键映射")) {
                shortcutFieldRow(
                    labels: model.uiLabels(for: \.fiveFingerHoldShortcutSpec),
                    placeholder: "fn",
                    text: $model.fiveFingerHoldShortcutSpec,
                    hint: model.text("Example: fn or cmd+shift", "示例：fn 或 cmd+shift")
                )
                sectionDivider
                shortcutFieldRow(
                    labels: model.uiLabels(for: \.fourFingerSwipeLeftSequenceSpec),
                    placeholder: "cmd+a, delete",
                    text: $model.fourFingerSwipeLeftSequenceSpec,
                    hint: model.text("Example: cmd+a, delete", "示例：cmd+a, delete")
                )
            }
        }
    }

    private var tuningPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsGroup(title: model.text("Touch Timing", "触摸时间")) {
                sliderRow(
                    labels: model.uiLabels(for: \.holdDuration),
                    value: $model.holdDuration,
                    range: 0.0...0.16,
                    step: 0.02,
                    currentText: { String(format: model.text("Current %.2f s", "当前 %.2f 秒"), $0) },
                    minText: "0.00 s",
                    maxText: "0.16 s"
                )
                sectionDivider
                sliderRow(
                    labels: model.uiLabels(for: \.doubleClickDistance),
                    value: doubleClickDistanceBinding,
                    range: 0...8,
                    step: 1,
                    currentText: { model.text("Current \(Int($0)) mm", "当前 \(Int($0)) 毫米") },
                    minText: "0 mm",
                    maxText: "8 mm"
                )
            }

            SettingsGroup(title: model.text("Scroll", "滚动")) {
                settingToggleRow(labels: model.uiLabels(for: \.isScrollInertiaEnabled), isOn: $model.isScrollInertiaEnabled)
                sectionDivider
                sliderRow(
                    labels: model.uiLabels(for: \.scrollSpeedMultiplier),
                    value: scrollSpeedBinding,
                    range: 0.5...3.0,
                    step: 0.1,
                    currentText: { String(format: model.text("Current %.1fx", "当前 %.1fx"), $0) },
                    minText: "0.5x",
                    maxText: "3.0x"
                )
                sectionDivider
                sliderRow(
                    labels: model.uiLabels(for: \.scrollInertiaVelocityMultiplier),
                    value: inertiaAmountBinding,
                    range: 0.5...2.0,
                    step: 0.05,
                    currentText: { String(format: model.text("Current %.2fx", "当前 %.2fx"), $0) },
                    minText: "0.5x",
                    maxText: "2.0x",
                    disabled: !model.isScrollInertiaEnabled
                )
                sectionDivider
                sliderRow(
                    labels: model.uiLabels(for: \.scrollInertiaDecelerationPerFrame),
                    value: inertiaDecayBinding,
                    range: 0.85...0.99,
                    step: 0.005,
                    currentText: { String(format: model.text("Current %.3f", "当前 %.3f"), $0) },
                    minText: "0.850",
                    maxText: "0.990",
                    disabled: !model.isScrollInertiaEnabled
                )
            }

            SettingsGroup(title: model.text("Reliability", "可靠性")) {
                sliderRow(
                    labels: model.uiLabels(for: \.errorResistance),
                    value: errorResistanceBinding,
                    range: 0...10,
                    step: 1,
                    currentText: { model.text("Current \(Int($0))", "当前 \(Int($0))") },
                    minText: "0",
                    maxText: "10"
                )
                sectionDivider
                settingToggleRow(labels: model.uiLabels(for: \.ignoreOriginTouches), isOn: $model.ignoreOriginTouches)
            }
        }
    }

    private var diagnosticsPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsGroup(title: model.text("Actions", "操作")) {
                actionRow(title: model.text("Grant Accessibility Access", "授予辅助功能权限"), action: model.grantAccessibilityAccess)
                sectionDivider
                actionRow(title: model.text("Restart Input Pipeline", "重启输入通道"), action: model.restartInputPipeline)
                sectionDivider
                actionRow(title: model.text("Refresh Touch Connection", "刷新触摸连接"), action: model.refreshTouchConnection)
                sectionDivider
                actionRow(title: model.text("Reset Diagnostics", "重置诊断信息"), action: model.resetDiagnostics)
                sectionDivider
                actionRow(title: model.text("Open Fullscreen Test Environment", "打开全屏测试环境")) {
                    (NSApp.delegate as? AppDelegate)?.showDebugOverlay()
                }
            }

            SettingsGroup(title: model.text("Live Diagnostics", "实时诊断")) {
                diagnosticsTextLine(model.text("Status", "状态"), model.suggestedBlocker())
                diagnosticsTextLine(model.text("Accessibility (Cached)", "辅助功能（缓存）"), model.isAccessibilityAccessGranted ? model.text("Granted", "已授权") : model.text("Missing", "未授权"))
                diagnosticsTextLine(model.text("Accessibility (Live)", "辅助功能（实时）"), model.accessibilityTrustedNow ? model.text("Granted", "已授权") : model.text("Missing", "未授权"))
                diagnosticsTextLine(model.text("Input Enabled", "输入已启用"), model.isPublishingMouseEventsEnabled ? model.text("Yes", "是") : model.text("No", "否"))
                diagnosticsTextLine(model.text("Connection", "连接"), connectionStateText)
                diagnosticsTextLine(model.text("Connected Screens", "已连接显示器"), "\(model.connectedScreens.count)")
                diagnosticsTextLine(model.text("Assigned Screen", "指定显示器"), model.connectedTouchscreen?.name ?? model.text("(Auto)", "（自动）"))
                diagnosticsTextLine(model.text("Touch Reports", "触摸报告"), "\(model.touchUpdateCount)")
                diagnosticsTextLine(model.text("Last Active Touches", "最近活动触点"), "\(model.lastActiveTouchCount)")
                diagnosticsTextLine(model.text("Gesture Decisions", "手势判定"), "\(model.gestureDecisionCount)")
                diagnosticsTextLine(model.text("Current Gesture", "当前手势"), model.currentGestureName)
                diagnosticsTextLine(model.text("Current Action", "当前操作"), model.currentActionName)
                diagnosticsTextLine(model.text("Last Gesture -> Action", "最近手势 → 操作"), "\(model.lastGestureName) -> \(model.lastActionName)")
                diagnosticsTextLine(model.text("Input Frame", "输入帧"), "\(model.inputProcessFrameID)")
                diagnosticsTextLine(model.text("Input Active Touches", "活动输入触点"), "\(model.inputActiveTouchCount)")
                diagnosticsTextLine(model.text("3F Session", "三指会话"), model.threeFingerTracking ? model.text("Active", "活动") : model.text("Idle", "空闲"))
                diagnosticsTextLine(model.text("3F Triggered", "三指已触发"), model.threeFingerTriggered ? model.text("Yes", "是") : model.text("No", "否"))
                diagnosticsTextLine(model.text("3F Touches / Upward", "三指触点 / 上滑"), "\(model.threeFingerTouchCount) / \(model.threeFingerUpwardTouchCount)")
                diagnosticsTextLine(model.text("3F Travel V / H", "三指位移 纵 / 横"), String(format: "%.1f / %.1f mm", model.threeFingerVerticalTravelMM, model.threeFingerHorizontalTravelMM))
                diagnosticsTextLine(model.text("HID Connect / Disconnect", "HID 连接 / 断开"), "\(model.hidConnectCount) / \(model.hidDisconnectCount)")
                diagnosticsTextLine(model.text("Last Touch Update", "最近触摸更新"), formatDate(model.lastTouchUpdateAt))

                if !model.diagnosticsEvents.isEmpty {
                    sectionDivider
                    eventBlock(title: model.text("Recent Diagnostics", "最近诊断"), events: Array(model.diagnosticsEvents.prefix(8)))
                }

                if !model.recentGestureEvents.isEmpty {
                    sectionDivider
                    eventBlock(title: model.text("Recent Gesture Stream", "最近手势流"), events: Array(model.recentGestureEvents.prefix(10)))
                }
            }

        }
    }

    private var accessBanner: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.text("Accessibility Access Required", "需要辅助功能权限"))
                    .font(.headline)
                Text(model.text("TouchPane needs Accessibility access before macOS will accept the injected mouse and keyboard events.", "TouchPane 需要辅助功能权限，macOS 才会接受它发送的鼠标和键盘事件。"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(model.text("Grant Access", "授予权限")) {
                model.grantAccessibilityAccess()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private func settingToggleRow(labels: (title: String, description: String), isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 14) {
            SettingText(labels: labels)
            Spacer(minLength: 12)
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }

    private func shortcutFieldRow(labels: (title: String, description: String), placeholder: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingText(labels: labels)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func sliderRow(labels: (title: String, description: String), value: Binding<Double>, range: ClosedRange<Double>, step: Double, currentText: @escaping (Double) -> String, minText: String, maxText: String, disabled: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingText(labels: labels)

            Slider(value: value, in: range, step: step)
                .disabled(disabled)

            HStack {
                Text(minText)
                Spacer()
                Text(currentText(value.wrappedValue))
                Spacer()
                Text(maxText)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if disabled {
                Text(model.text("Enable Scroll Inertia to adjust this.", "启用滚动惯性后才能调整此项。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .opacity(disabled ? 0.55 : 1)
    }

    private func settingValueRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func actionRow(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private func diagnosticsTextLine(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(title):")
                .foregroundStyle(.primary)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 11, weight: .regular, design: .monospaced))
        .padding(.vertical, 2)
    }

    private func eventBlock(title: String, events: [DiagnosticsEvent]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(events) { event in
                Text("[\(formatDate(event.time))] \(event.message)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color(nsColor: .separatorColor))
    }

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("TouchPane v\(versionString)")
                        .font(.headline)
                }

                Text(model.text("Touch input for macOS", "macOS 触摸输入"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Link(destination: URL(string: "https://github.com/XLARIC/TouchPane")!) {
                Label("GitHub", systemImage: "link")
            }
        }
        .padding(.vertical, 8)
    }

    func formatDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        return Self.diagnosticsDateFormatter.string(from: date)
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
    }
}

private struct SettingText: View {
    let labels: (title: String, description: String)

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(labels.title)
                .font(.body.weight(.medium))
            Text(labels.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
