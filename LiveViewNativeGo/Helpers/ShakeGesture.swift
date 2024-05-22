//
//  ShakeGesture.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 5/9/24.
//

#if os(iOS)
import SwiftUI

extension Notification.Name {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
        }
     }
}

struct OnShakeGestureModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension View {
    func onShakeGesture(perform action: @escaping () -> Void) -> some View {
        self.modifier(OnShakeGestureModifier(action: action))
    }
}
#endif
