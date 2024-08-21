//
//  LiveViewNativeGoApp.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI
import TipKit

@main
struct LiveViewNativeGoApp: App {
    @State private var settings = Settings()
    @Environment(\.dynamicTypeSize) private var dynamicType
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif
    
    init() {
        do {
            #if DEBUG
            try Tips.resetDatastore()
            #endif
            try Tips.configure()
        } catch {
            print("Error configuring tips: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environment(settings)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        #if os(macOS)
        WindowGroup(for: SelectedApp.self) { $app in
            if let app {
                app.makeLiveView(settings: settings, dynamicType: dynamicType)
                    .environment(settings)
                    .focusedSceneValue(\.focusedApp, app)
            }
        }
        .commands {
            QuickActionsCommands()
        }
        SwiftUI.Settings {
            SettingsScreen()
        }
        .environment(settings)
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif
