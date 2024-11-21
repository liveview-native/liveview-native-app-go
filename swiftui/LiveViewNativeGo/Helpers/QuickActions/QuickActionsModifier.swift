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
    @State private var isLogsOpen = false
    
    @Environment(Settings.self) private var settings
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let tip = QuickActionsTip()
    
    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .onShakeGesture {
                isPresented = true
                tip.invalidate(reason: .actionPerformed)
            }
            .inspector(isPresented: $isLogsOpen) {
                LogsScreen()
                    .navigationTitle("Logs")
            }
            .safeAreaInset(edge: .bottom) {
                TipView(tip)
                    .tipBackground(.ultraThinMaterial)
                    .shadow(radius: 16)
                    .padding()
            }
            #endif
            .quickActionsDialog(sizeClass: horizontalSizeClass ?? .regular, isPresented: $isPresented) {
                actions
            }
            .sheet(isPresented: $isSettingsOpen) {
                SettingsScreen()
            }
    }
    
    @ViewBuilder
    var actions: some View {
        Button("Settings") {
            isSettingsOpen = true
        }
        Button("Logs") {
            isLogsOpen = true
        }
        Button("Reset LiveView") {
            selection = .init(url: app.url, id: UUID())
        }
        Button("Disconnect", role: .destructive) {
            selection = nil
        }
        Button("Cancel", role: .cancel) {}
    }
}

fileprivate extension View {
    @ViewBuilder
    func quickActionsDialog(sizeClass: UserInterfaceSizeClass, isPresented: Binding<Bool>, @ViewBuilder actions: () -> some View) -> some View {
        switch sizeClass {
        case .compact:
            self.confirmationDialog("Quick Actions", isPresented: isPresented, titleVisibility: .visible) {
                actions()
            }
        default:
            self.alert("Quick Actions", isPresented: isPresented) {
                actions()
            }
        }
    }
}
