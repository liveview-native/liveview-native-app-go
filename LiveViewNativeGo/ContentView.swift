//
//  ContentView.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI

struct ContentView: View {
    @State private var settings = Settings()
    @Environment(\.dynamicTypeSize) private var dynamicType
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
                }
                .sheet(isPresented: $isSettingsOpen) {
                    SettingsScreen()
                }
        }
        .environment(settings)
        .preferredColorScheme(settings.colorScheme)
        .dynamicTypeSize(settings.dynamicTypeEnabled ? settings.dynamicType : dynamicType)
    }
}

#Preview {
    ContentView()
}
