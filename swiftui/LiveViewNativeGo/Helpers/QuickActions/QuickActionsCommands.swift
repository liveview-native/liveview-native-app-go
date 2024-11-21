//
//  QuickActionsCommands.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 8/13/24.
//

#if !os(tvOS) && !os(visionOS)
import SwiftUI

struct QuickActionsCommands: Commands {
    @FocusedValue(\.focusedApp) var focusedApp
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        if let focusedApp {
            CommandMenu("LiveView") {
                Button("Reset...") {
                    dismissWindow(value: focusedApp)
                    openWindow(value: SelectedApp(url: focusedApp.url, id: UUID()))
                }
                .keyboardShortcut("r")
                Button("Logs") {
                    openWindow(id: "logs")
                }
            }
        }
    }
}

extension FocusedValues {
    var focusedApp: SelectedApp? {
        get { self[FocusedAppKey.self] }
        set { self[FocusedAppKey.self] = newValue }
    }
    
    private enum FocusedAppKey: FocusedValueKey {
        typealias Value = SelectedApp
    }
}
#endif
