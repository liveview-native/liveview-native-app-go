//
//  QuickActionsModifier.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 8/13/24.
//

import SwiftUI
import TipKit

struct QuickActionsModifier: ViewModifier {
    let app: SelectedApp
    @Binding var selection: SelectedApp?
    
    @State private var isPresented = false
    @State private var isSettingsOpen = false
    
    @Environment(Settings.self) private var settings
    
    let tip = QuickActionsTip()
    
    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .onShakeGesture {
                isPresented = true
                tip.invalidate(reason: .actionPerformed)
            }
            #endif
            .confirmationDialog("Quick Actions", isPresented: $isPresented, titleVisibility: .visible) {
                Button("Settings") {
                    isSettingsOpen = true
                }
                Button("Reset LiveView") {
                    selection = .init(url: app.url, id: UUID())
                }
                Button("Disconnect", role: .destructive) {
                    selection = nil
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $isSettingsOpen) {
                SettingsScreen()
            }
            .safeAreaInset(edge: .bottom) {
                TipView(tip)
                    .tipBackground(.ultraThinMaterial)
                    .shadow(radius: 16)
                    .padding()
            }
    }
}
