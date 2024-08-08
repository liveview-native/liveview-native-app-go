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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
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
}
