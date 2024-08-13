//
//  ContentView.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isSettingsOpen = false
    
    var body: some View {
        NavigationStack {
            AppsScreen()
                #if os(iOS)
                .toolbarTitleMenu {
                    toolbarItems
                }
                .sheet(isPresented: $isSettingsOpen) {
                    SettingsScreen()
                }
                #else
                .toolbar {
                    toolbarItems
                }
                #endif
        }
    }
    
    @ViewBuilder
    var toolbarItems: some View {
        #if os(macOS)
        SettingsLink()
        Button {
            NSWorkspace.shared.open(.documentation)
        } label: {
            Label("Documentation", systemImage: "book.closed.fill")
        }
        #else
        Button {
            isSettingsOpen = true
        } label: {
            Label("Settings", systemImage: "gear")
        }
        Link(destination: .documentation) {
            Label("Documentation", systemImage: "book.closed.fill")
        }
        #endif
    }
}

#Preview {
    ContentView()
}
