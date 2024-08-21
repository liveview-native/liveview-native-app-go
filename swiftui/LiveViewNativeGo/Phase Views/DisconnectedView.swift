//
//  DisconnectedView.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 8/8/24.
//

import SwiftUI

struct DisconnectedView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Connection", systemImage: "network.slash")
        } description: {
            Text("The app will reconnect when network connection is regained.")
        }
    }
}

#Preview {
    DisconnectedView()
}
