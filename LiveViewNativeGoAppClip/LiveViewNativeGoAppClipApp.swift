//
//  LiveViewNativeGoAppClipApp.swift
//  LiveViewNativeGoAppClip
//
//  Created by Carson Katri on 8/15/24.
//

import SwiftUI
import TipKit

@main
struct LiveViewNativeGoAppClipApp: App {
    @State private var settings = Settings()
    
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
    }
}
