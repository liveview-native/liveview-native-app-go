//
//  ContentView.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isSettingsOpen = false
    
    #if os(visionOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    
    var body: some View {
        NavigationStack {
            AppsScreen()
                #if os(iOS)
                .toolbarTitleMenu {
                    toolbarItems
                }
                #else
                .toolbar {
                    toolbarItems
                }
                #endif
                #if os(iOS) || os(visionOS)
                .sheet(isPresented: $isSettingsOpen) {
                    SettingsScreen()
                }
                #endif
        }
    }
    
    @ViewBuilder
    var toolbarItems: some View {
        #if os(macOS)
        SettingsLink()
        #else
        Button {
            isSettingsOpen = true
        } label: {
            Label("Settings", systemImage: "gear")
        }
        #endif
        #if os(macOS)
        Button {
            NSWorkspace.shared.open(.documentation)
        } label: {
            Label("Documentation", systemImage: "book.closed.fill")
        }
        #elseif os(visionOS)
        Button {
            UIApplication.shared.open(.documentation)
        } label: {
            Label("Documentation", systemImage: "book.closed.fill")
        }
        #else
        Link(destination: .documentation) {
            Label("Documentation", systemImage: "book.closed.fill")
        }
        #endif
        #if os(visionOS)
        Button {
            dismissWindow(id: "logs")
            openWindow(id: "logs")
        } label: {
            Label("Logs", systemImage: "scroll")
        }
        #endif
    }
}

#Preview {
    ContentView()
        .environment(Settings())
}
