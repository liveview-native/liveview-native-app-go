//
//  ContentView.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI

struct ContentView: View {
    @State private var settings = Settings()
    @State private var isSettingsOpen = false
    
    var body: some View {
        NavigationStack {
            AppsScreen()
                .toolbarTitleMenu {
                    Button {
                        isSettingsOpen = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    Link(destination: .documentation) {
                        Label("Documentation", systemImage: "book.closed.fill")
                    }
                }
                .sheet(isPresented: $isSettingsOpen) {
                    SettingsScreen()
                }
        }
        .environment(settings)
    }
}

#Preview {
    ContentView()
}
