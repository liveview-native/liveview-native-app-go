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
    @Environment(\.openWindow) private var openWindow
    
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
                .onChange(of: settings.recentURLs, initial: true) { _, newRecentURLs in
                    delegate.updateDockMenu(newRecentURLs)
                }
                #endif
        }
        .environment(settings)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
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
        WindowGroup(for: SelectedApp.self) { $app in
            if let app {
                app.makeLiveView(settings: settings, dynamicType: dynamicType)
                    .environment(settings)
                    .focusedSceneValue(\.focusedApp, app)
            }
        }
        .defaultWindowPlacement { content, context in
            WindowPlacement(.leading(context.windows.first!))
        }
        
        WindowGroup(id: "logs") {
            NavigationStack {
                LogsScreen()
                    .navigationTitle("Logs")
            }
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
    
    func updateDockMenu(_ recentURLs: [URL]) {
        dockMenu.removeAllItems()
        dockMenu.addItem(.sectionHeader(title: "Recents"))
        for url in recentURLs.reversed() {
            let item = NSMenuItem(
                title: (url as NSURL).resourceSpecifier.flatMap({ String($0.dropFirst(2)) }) ?? url.absoluteString,
                action: #selector(openRecentApp(_:)),
                keyEquivalent: ""
            )
            item.representedObject = url as NSURL
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
        openWindow(value: SelectedApp(url: url as URL, id: UUID()))
        settings?.recentURLs += [url as URL]
    }
    
    @objc func clearRecentApps(_ sender: NSMenuItem) {
        settings?.recentURLs = []
    }
}
#endif
