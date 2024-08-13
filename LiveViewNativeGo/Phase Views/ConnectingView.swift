//
//  ConnectingView.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 8/8/24.
//

import SwiftUI

struct ConnectingView: View {
    let url: URL
    
    var body: some View {
        ProgressView(url.absoluteString)
    }
}

#Preview {
    ConnectingView(url: URL(string: "http://localhost:4000")!)
}
