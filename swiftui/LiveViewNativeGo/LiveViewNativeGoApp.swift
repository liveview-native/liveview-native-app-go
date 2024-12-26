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
    
    #if os(macOS) || os(visionOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
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
        // Shared Windows
        WindowGroup {
            ContentView()
                #if os(macOS)
                .task {
                    delegate.openWindow = openWindow
                    delegate.settings = settings
                }
                .onChange(of: settings.recentApps, initial: true) { _, newRecentApps in
                    delegate.updateDockMenu(newRecentApps)
                }
                #endif
        }
        .environment(settings)
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        #endif
        #if os(visionOS)
        .defaultSize(width: 600, height: 400)
        #endif
        
        // macOS Windows
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
        
        SwiftUI.Window(Text("Logs"), id: "logs") {
            LogsScreen()
        }
        #endif
        
        // visionOS Windows
        #if os(visionOS)
        WindowGroup(id: SelectedApp.LaunchStyle.plain.rawValue, for: SelectedApp.self) { $app in
            if let app {
                app.makeLiveView(settings: settings, dynamicType: dynamicType)
                    .environment(settings)
                    .handlesExternalEvents(preferring: [], allowing: [])
            }
        }
        .defaultWindowPlacement { content, context in
            WindowPlacement(.leading(context.windows.first!))
        }
        
        WindowGroup(id: SelectedApp.LaunchStyle.volumetric.rawValue, for: SelectedApp.self) { $app in
            if let app {
                app.makeLiveView(settings: settings, dynamicType: dynamicType)
                    .environment(settings)
                    .handlesExternalEvents(preferring: [], allowing: [])
            }
        }
        .windowStyle(.volumetric)
        .defaultWindowPlacement { content, context in
            WindowPlacement(.leading(context.windows.first!))
        }
        
        ImmersiveSpace(id: SelectedApp.LaunchStyle.immersiveSpace.rawValue, for: SelectedApp.self) { $app in
            if let app {
                app.makeLiveView(settings: settings, dynamicType: dynamicType)
                    .environment(settings)
            }
        }
        
        WindowGroup(id: "logs") {
            NavigationStack {
                LogsScreen()
                    .navigationTitle("Logs")
            }
            .handlesExternalEvents(preferring: [], allowing: [])
        }
        .defaultSize(width: 600, height: 800)
        .defaultWindowPlacement { content, context in
            WindowPlacement(.trailing(context.windows.first!))
        }
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    var openWindow: OpenWindowAction!
    weak var settings: Settings?
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    let dockMenu = NSMenu()
    
    func updateDockMenu(_ recentApps: [SelectedApp]) {
        dockMenu.removeAllItems()
        dockMenu.addItem(.sectionHeader(title: "Recents"))
        for app in recentApps.reversed() {
            let item = NSMenuItem(
                title: (app.url as NSURL).resourceSpecifier.flatMap({ String($0.dropFirst(2)) }) ?? app.url.absoluteString,
                action: #selector(openRecentApp(_:)),
                keyEquivalent: ""
            )
            item.representedObject = app.url as NSURL
            dockMenu.addItem(item)
        }
        dockMenu.addItem(.separator())
        dockMenu.addItem(
            withTitle: "Clear Recents",
            action: #selector(clearRecentApps(_:)),
            keyEquivalent: ""
        )
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return dockMenu
    }
    
    @objc func openRecentApp(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? NSURL
        else { return }
        let app = SelectedApp(url: url as URL, id: UUID())
        openWindow(value: app)
        settings?.recentApps += [app]
    }
    
    @objc func clearRecentApps(_ sender: NSMenuItem) {
        settings?.recentApps = []
    }
}
#endif
