//
//  DebugView.swift
//  TouchPane
//
//  Created by Sebastian Hueber on 11.02.23.
//

import SwiftUI
import AppKit
import TouchUpCore

struct DebugView: View {
    
    @ObservedObject var model: TouchPane
    
    let closeAction: ()->Void
    
    var pixelsPerMM: CGFloat
    
    init(model: TouchPane, closeAction: @escaping ()->Void) {
        self.model = model
        self.pixelsPerMM = model.touchscreen()?.pixelsPerMM() ?? 30
        self.closeAction = closeAction
    }
    
    func colorForPhase(_ phase: NSTouch.Phase) -> Color {
        switch phase {
        case .stationary:
            return Color.yellow
            
        case .began:
            return Color.blue
            
        case .ended:
            return Color.red
    
        case .cancelled:
            return Color.orange
            
        default:
            return Color.green
        }
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { context in
        ZStack(alignment: .bottom) {
            
            Rectangle()
                .foregroundColor(Color(white: 0.1))
                .frame(maxWidth:.infinity, maxHeight: .infinity)
                .overlay(GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        
                        
                        ForEach(model.touches, id:\.uuid) { point in
                            let ageMs = Int(context.date.timeIntervalSince(point.lastUpdatedAt) * 1000)

                            Circle()
                                .foregroundColor(colorForPhase(point.phase))
                                .border(Color.gray, width: point.confidenceFlag ? 5 : 0)
                                .opacity(point.isActive() ? 1 : 0.5)
                                .frame(width: 16 * pixelsPerMM, height: 16 * pixelsPerMM)
                                .position(x: geo.size.width * point.location.x,
                                          y: geo.size.height * point.location.y)

                            Text("\(point.contactID)\nS:\(point.isOnSurface ? 1 : 0)  V:\(point.confidenceFlag ? 1 : 0)\nA:\(ageMs)ms")
                                .multilineTextAlignment(.center)
                                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 6)
                                .background(Color.black.opacity(0.45))
                                .cornerRadius(6)
                            .position(x: geo.size.width * point.location.x,
                                      y: geo.size.height * point.location.y)
                            
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(model.text("Input Frame", "输入帧")): \(model.inputProcessFrameID)")
                            Text("\(model.text("Input Active Touches", "活动输入触点")): \(model.inputActiveTouchCount)")
                            Text("\(model.text("3F Session", "三指会话")): \(model.threeFingerTracking ? model.text("Active", "活动") : model.text("Idle", "空闲"))")
                            Text("\(model.text("3F Triggered", "三指已触发")): \(model.threeFingerTriggered ? model.text("Yes", "是") : model.text("No", "否"))")
                            Text("\(model.text("3F Touches/Upward", "三指触点/上滑")): \(model.threeFingerTouchCount)/\(model.threeFingerUpwardTouchCount)")
                            Text(String(format: "3F Travel V/H: %.1f / %.1f mm", model.threeFingerVerticalTravelMM, model.threeFingerHorizontalTravelMM))
                        }
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(24)
                        
                        
                    }
                })
            
            
            Button(action: {
                closeAction()
            }, label: {
                HStack {
                    Text(model.text("Close overlay with ", "关闭调试层："))
                    Label("W", systemImage: "command.square.fill")
                    Text(model.text("or by mouse-clicking here", "，或用鼠标点击这里"))
                }
                .font(.largeTitle)
                .modify {
                    if #available(macOS 13.0, *) {
                        $0.fontDesign(.rounded)
                    } else { $0 }
                }
            })
            .foregroundColor(.gray)
            .buttonStyle(.borderless)
            .keyboardShortcut(KeyEquivalent("w"), modifiers: [.command])
            .padding(.bottom, 140)
        }
        .id(model.inputProcessFrameID)
        }
        
            
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView(model: TouchPane(), closeAction: {})
    }
}


extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
    }
}
