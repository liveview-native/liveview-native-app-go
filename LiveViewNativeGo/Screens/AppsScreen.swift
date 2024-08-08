//
//  AppsScreen.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI
import VisionKit
import LiveViewNative
import LiveViewNativeLiveForm
import LiveViewNativeAVKit
import LiveViewNativeCharts
import LiveViewNativeMapKit
import TipKit

/// The current app to display, with a unique ID for each instance of this app launched.
struct SelectedApp: Identifiable, Equatable {
    let url: URL
    let id: UUID
}

/// A tip on accessing quick actions.
struct QuickActionsTip: Tip {
    var title: Text {
        Text("Quick Actions")
    }

    var message: Text? {
        Text("Shake your device to access quick actions.")
    }

    var image: Image? {
        Image(systemName: "iphone.gen2.radiowaves.left.and.right")
    }
}

/// A tip on scanning LiveBook QR codes.
struct QRConnectTip: Tip {
    var title: Text {
        Text("Connect to LiveBook")
    }

    var message: Text? {
        Text("Scan the QR code in a LiveView smart cell to connect.")
    }

    var image: Image? {
        Image(systemName: "qrcode.viewfinder")
    }
}

/// The app scanning and rendering screen.
struct AppsScreen: View {
    @State private var selection: SelectedApp?
    
    @State private var selectCustomURL: Bool = false
    
    @AppStorage("customURL") private var inputURL: String = ""
    
    @State private var items: [RecognizedItem] = []
    
    @Environment(Settings.self) private var settings
    
    @Environment(\.dynamicTypeSize) private var dynamicType
    
    var body: some View {
        DataScannerView(
            isActive: selection == nil,
            items: $items.animation(.default),
            recognizedDataTypes: [.barcode(symbologies: [.qr, .microQR])],
            isHighlightingEnabled: true
        ) { item in
            switch item {
            case let .barcode(code):
                selection = code.payloadStringValue
                    .flatMap({ URL(string: $0) })
                    .flatMap({ .init(url: $0, id: UUID()) })
            default:
                print(item)
            }
        }
            .ignoresSafeArea()
            .safeAreaInset(edge: .top) {
                TipView(QRConnectTip())
                    .tipBackground(.ultraThinMaterial)
                    .shadow(radius: 16)
                    .padding()
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Spacer()
                        .frame(maxWidth: .infinity)
                    currentScanOverlay
                        .frame(maxWidth: .infinity)
                    customURLButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("LVN Go")
            // custom URL form
            .alert("Enter URL", isPresented: $selectCustomURL) {
                TextField("URL", text: $inputURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    selection = URL(string: inputURL.starts(with: "http://") || inputURL.starts(with: "https://") ? inputURL : "http://\(inputURL)")
                        .flatMap { .init(url: $0, id: UUID()) }
                }
            }
            // display the selected app
            .fullScreenCover(item: $selection) { app in
                #LiveView(
                    app.url,
                    addons: [.liveForm, .avKit, .charts, .mapKit],
                    reconnecting: { _, _ in fatalError() }
                )
                .preferredColorScheme(settings.colorScheme)
                .dynamicTypeSize(settings.dynamicTypeEnabled ? settings.dynamicType : dynamicType)
                .environment(settings)
                .modifier(QuickActionsModifier(app: app, selection: $selection))
            }
    }
    
    @ViewBuilder
    var currentScanOverlay: some View {
        if case let .barcode(code) = items.last,
           let payloadStringValue = code.payloadStringValue,
           let url = URL(string: payloadStringValue)
        {
            Button {
                selection = .init(url: url, id: UUID())
            } label: {
                Label {
                    Text(url.host() ?? url.absoluteString)
                        .font(.caption.monospaced())
                } icon: {
                    Image(systemName: "arrow.up.right.square.fill")
                }
                .foregroundStyle(.black)
                .padding(2)
                .fixedSize(horizontal: true, vertical: false)
            }
            .compositingGroup()
            .shadow(radius: 5)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.mini)
            .tint(.yellow)
        }
    }
    
    @ViewBuilder
    var customURLButton: some View {
        Button {
            selectCustomURL = true
        } label: {
            Image(systemName: "link.badge.plus")
                .foregroundStyle(.white)
                .imageScale(.large)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(.black)
    }
}

struct QuickActionsModifier: ViewModifier {
    let app: SelectedApp
    @Binding var selection: SelectedApp?
    
    @State private var isPresented = false
    @State private var isSettingsOpen = false
    
    @Environment(Settings.self) private var settings
    
    let tip = QuickActionsTip()
    
    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .onShakeGesture {
                isPresented = true
                tip.invalidate(reason: .actionPerformed)
            }
            #endif
            .confirmationDialog("Quick Actions", isPresented: $isPresented, titleVisibility: .visible) {
                Button("Settings") {
                    isSettingsOpen = true
                }
                Button("Reset LiveView") {
                    selection = .init(url: app.url, id: UUID())
                }
                Button("Disconnect", role: .destructive) {
                    selection = nil
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $isSettingsOpen) {
                SettingsScreen()
            }
            .safeAreaInset(edge: .bottom) {
                TipView(tip)
                    .tipBackground(.ultraThinMaterial)
                    .shadow(radius: 16)
                    .padding()
            }
    }
}

#Preview {
    AppsScreen()
}
