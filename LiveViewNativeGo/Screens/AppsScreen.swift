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

struct AppsScreen: View {
    @State private var selection: SelectedApp?
    
    @State private var selectCustomURL: Bool = false
    @State private var confirmDisconnect: Bool = false
    
    @State private var inputURL: String = ""
    
    @State private var items: [RecognizedItem] = []
    
    var body: some View {
        Group {
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
        }
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                HStack {
                    Spacer()
                        .frame(maxWidth: .infinity)
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
                        .frame(maxWidth: .infinity)
                    }
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
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("LVN Go")
            .alert("Enter URL", isPresented: $selectCustomURL) {
                TextField("URL", text: $inputURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    selection = URL(string: inputURL).flatMap({ .init(url: $0, id: UUID()) })
                }
            }
            .fullScreenCover(item: $selection) { app in
                #LiveView(
                    app.url,
                    addons: [.liveForm],
                    reconnecting: { _, _ in fatalError() }
                )
                    #if os(iOS)
                    .onShakeGesture {
                        confirmDisconnect = true
                    }
                    #endif
                    .confirmationDialog("Quick Actions", isPresented: $confirmDisconnect, titleVisibility: .visible) {
                        Button("Disconnect") {
                            selection = nil
                        }
                        Button("Reset LiveView") {
                            selection = .init(url: app.url, id: UUID())
                        }
                        Button("Cancel", role: .cancel) {}
                    }
            }
    }
    
    struct SelectedApp: Identifiable, Equatable {
        let url: URL
        let id: UUID
    }
}

#Preview {
    AppsScreen()
}
