//
//  LiveViewCodeScanner.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 10/3/24.
//

#if os(iOS)
import SwiftUI
import VisionKit
import TipKit

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

struct LiveViewCodeScanner: View {
    @State private var items: [RecognizedItem] = []
    let onScan: (URL) -> ()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        DataScannerView(
            items: $items.animation(.default),
            recognizedDataTypes: [.barcode(symbologies: [.qr, .microQR])],
            isHighlightingEnabled: true
        ) { item in
            switch item {
            case let .barcode(code):
                guard let url = code.payloadStringValue.flatMap({ URL(string: $0) })
                else { return }
                onScan(url)
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
                currentScanOverlay
                    .padding()
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
    }
    
    @ViewBuilder
    var currentScanOverlay: some View {
        if case let .barcode(code) = items.last,
           let payloadStringValue = code.payloadStringValue,
           let url = URL(string: payloadStringValue)
        {
            Button {
                onScan(url)
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
}
#endif
