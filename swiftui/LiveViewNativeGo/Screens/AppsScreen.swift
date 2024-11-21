//
//  AppsScreen.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI
import Foundation
import VisionKit
import LiveViewNative
import LiveViewNativeLiveForm
import LiveViewNativeAVKit
import LiveViewNativeCharts
import LiveViewNativeMapKit
import TipKit

/// The current app to display, with a unique ID for each instance of this app launched.
struct SelectedApp: Identifiable, Hashable, Codable {
    let url: URL
    let id: UUID
    
    @ViewBuilder
    func makeLiveView(settings: Settings, dynamicType: DynamicTypeSize) -> some View {
        #LiveView(
            url,
            addons: [.liveForm, .avKit, .charts, .mapKit]
        ) {
            ConnectingView(url: url)
        } disconnected: {
            DisconnectedView()
        } reconnecting: { content, isReconnecting in
            ReconnectingView(isReconnecting: isReconnecting) {
                content
            }
        } error: { error in
            ErrorView(error: error)
        }
        .preferredColorScheme(settings.colorScheme)
        .dynamicTypeSize(settings.dynamicTypeEnabled ? settings.dynamicType : dynamicType)
        .environment(settings)
    }
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

/// The app scanning and rendering screen.
struct AppsScreen: View {
    @State private var selection: SelectedApp?
    
    @State private var showCodeScanner: Bool = false
    
    @AppStorage("customURL") private var inputURL: String = ""
    
    @Environment(Settings.self) private var settings
    
    @Environment(\.dynamicTypeSize) private var dynamicType
    
    #if os(macOS) || os(visionOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    var body: some View {
        #if os(iOS)
        List {
            Section {
                if settings.recentURLs.isEmpty {
                    Text("No recent apps connected.")
                }
                ForEach(settings.recentURLs.reversed(), id: \.self) { url in
                    Button {
                        selection = .init(url: url, id: UUID())
                        settings.recentURLs += [url]
                    } label: {
                        Label {
                            Text((url as NSURL).resourceSpecifier.flatMap({ String($0.dropFirst(2)) }) ?? url.absoluteString)
                        } icon: {
                            AsyncImage(url: url.replacing(path: "/apple-touch-icon.png")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                case .failure:
                                    AsyncImage(url: url.replacing(path: "/favicon.ico")) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                        default:
                                            Rectangle()
                                                .fill(.quaternary)
                                        }
                                    }
                                default:
                                    Rectangle()
                                        .fill(.quaternary)
                                }
                            }
                            .frame(width: 30, height: 30)
                            .clipShape(.rect(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Recents")
                    Spacer()
                    Button("Clear") {
                        settings.recentURLs = []
                    }
                    .controlSize(.mini)
                }
            }
        }
            .safeAreaInset(edge: .bottom) {
                VStack {
                    Divider()
                    VStack {
                        Button {
                            showCodeScanner = true
                        } label: {
                            Label("Scan QR Code", systemImage: "qrcode")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.extraLarge)
                        .sheet(isPresented: $showCodeScanner) {
                            NavigationStack {
                                LiveViewCodeScanner { url in
                                    showCodeScanner = false
                                    selection = .init(url: url, id: UUID())
                                    settings.recentURLs += [url]
                                }
                            }
                        }
                        
                        HStack {
                            VStack { Divider() }
                            Text("OR")
                                .font(.caption)
                                .foregroundStyle(.separator)
                            VStack { Divider() }
                        }
                        .padding(.vertical)
                        
                        HStack {
                            TextField("Enter URL", text: $inputURL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                guard let url = URL(string: appendingScheme(to: inputURL))
                                else { return }
                                selection = .init(url: url, id: UUID())
                                settings.recentURLs += [url]
                            } label: {
                                Label("Launch", systemImage: "arrow.up.right.square.fill")
                            }
                            .tint(Color.accentColor)
                            .disabled(inputURL.isEmpty)
                        }
                    }
                    .padding()
                    .buttonStyle(.bordered)
                }
                .background(ignoresSafeAreaEdges: .bottom)
            }
            .navigationTitle("LVN Go")
            .navigationBarTitleDisplayMode(.inline)
            // display the selected app
            .fullScreenCover(item: $selection) { app in
                app.makeLiveView(settings: settings, dynamicType: dynamicType)
                    .modifier(QuickActionsModifier(app: app, selection: $selection))
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                guard selection == nil,
                      let webpageURL = activity.webpageURL,
                      let components = URLComponents(url: webpageURL, resolvingAgainstBaseURL: true),
                      let liveViewURL = components.queryItems?
                        .first(where: { $0.name == "liveview" })
                        .flatMap(\.value)
                        .flatMap(URL.init)
                else { return }
                self.selection = .init(url: liveViewURL, id: .init())
                settings.recentURLs += [liveViewURL]
            }
        #elseif os(macOS)
        VStack {
            VStack {
                TextField("URL", text: $inputURL)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                Button {
                    guard let url = URL(string: appendingScheme(to: inputURL))
                    else { return }
                    openWindow(value: SelectedApp(url: url, id: .init()))
                    settings.recentURLs += [url]
                } label: {
                    Label("Launch", systemImage: "arrow.up.right.square.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            Divider()
            Button {
                let url = URL(string: "http://localhost:4000")!
                openWindow(value: SelectedApp(url: url, id: .init()))
                settings.recentURLs += [url]
            } label: {
                Label("Launch Local Host", systemImage: "network")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.extraLarge)
        .buttonStyle(.borderedProminent)
        .padding()
        .navigationTitle("LiveView Native Go")
        #else
        List {
            Section {
                if settings.recentURLs.isEmpty {
                    Text("No recent apps connected.")
                }
                ForEach(settings.recentURLs.reversed(), id: \.self) { url in
                    Button {
                        openWindow(value: SelectedApp(url: url, id: .init()))
                        settings.recentURLs += [url]
                    } label: {
                        Label {
                            Text((url as NSURL).resourceSpecifier.flatMap({ String($0.dropFirst(2)) }) ?? url.absoluteString)
                        } icon: {
                            AsyncImage(url: url.replacing(path: "/apple-touch-icon.png")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                case .failure:
                                    AsyncImage(url: url.replacing(path: "/favicon.ico")) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                        default:
                                            Rectangle()
                                                .fill(.quaternary)
                                        }
                                    }
                                default:
                                    Rectangle()
                                        .fill(.quaternary)
                                }
                            }
                            .frame(width: 30, height: 30)
                            .clipShape(.rect(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Recents")
                    Spacer()
                    Button("Clear") {
                        settings.recentURLs = []
                    }
                    .controlSize(.mini)
                }
            }
        }
        .ornament(attachmentAnchor: .scene(.bottom)) {
            HStack {
                TextField("URL", text: $inputURL)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 300, maxWidth: .infinity)
                Button {
                    guard let url = URL(string: appendingScheme(to: inputURL))
                    else { return }
                    openWindow(value: SelectedApp(url: url, id: .init()))
                    settings.recentURLs += [url]
                } label: {
                    Label("Launch", systemImage: "arrow.up.right.square.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonBorderShape(.roundedRectangle(radius: 10))
            }
            .padding(8)
            .glassBackgroundEffect(in: .rect(cornerRadius: 16, style: .continuous))
        }
        .navigationTitle("LiveView Native Go")
        #endif
    }
    
    func appendingScheme(to inputURL: String) -> String {
        inputURL.starts(with: "http://") || inputURL.starts(with: "https://") ? inputURL : "http://\(inputURL)"
    }
}

#Preview {
    NavigationStack {
        AppsScreen()
    }
        .environment(Settings())
}
