//
//  AppsScreen.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI
import Foundation
#if os(iOS)
import VisionKit
#endif
import LiveViewNative
import LiveViewNativeLiveForm
import LiveViewNativeAVKit
import LiveViewNativeCharts
#if !os(tvOS)
import LiveViewNativeMapKit
#endif
#if os(visionOS)
import LiveViewNativeRealityKit
#endif
import TipKit

/// The current app to display, with a unique ID for each instance of this app launched.
struct SelectedApp: Identifiable, Hashable, Codable {
    let url: URL
    let id: UUID
    
    #if os(visionOS)
    let launchStyle: LaunchStyle
    
    enum LaunchStyle: String, Hashable, Codable, CustomStringConvertible {
        case plain
        case volumetric
        case immersiveSpace
        
        var description: String {
            switch self {
            case .plain:
                "Plain"
            case .volumetric:
                "Volumetric"
            case .immersiveSpace:
                "Immersive Space"
            }
        }
    }
    #endif
    
    @ViewBuilder
    func makeLiveView(settings: Settings, dynamicType: DynamicTypeSize) -> some View {
        #if os(tvOS)
        let view: AnyView = #LiveView(
            url,
            addons: [.liveForm, .avKit, .charts]
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
        #elseif os(visionOS)
        let view: AnyView = #LiveView(
            url,
            addons: [.liveForm, .avKit, .charts, .mapKit, .realityKit]
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
        #else
        let view: AnyView = #LiveView(
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
        #endif
        
        view
        .preferredColorScheme(settings.colorScheme)
        .dynamicTypeSize(settings.dynamicTypeEnabled ? settings.dynamicType : dynamicType)
        .environment(settings)
    }
    
    func withUniqueID() -> Self {
        #if os(visionOS)
        Self(url: url, id: UUID(), launchStyle: launchStyle)
        #else
        Self(url: url, id: UUID())
        #endif
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
    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    #endif
    
    var body: some View {
        #if os(iOS)
        List {
            Section {
                if settings.recentApps.isEmpty {
                    Text("No recent apps connected.")
                }
                ForEach(settings.recentApps.reversed(), id: \.self) { app in
                    Button {
                        let app = app.withUniqueID()
                        selection = app
                        settings.recentApps += [app]
                    } label: {
                        Label {
                            Text((app.url as NSURL).resourceSpecifier.flatMap({ String($0.dropFirst(2)) }) ?? app.url.absoluteString)
                        } icon: {
                            AsyncImage(url: app.url.replacing(path: "/apple-touch-icon.png")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                case .failure:
                                    AsyncImage(url: app.url.replacing(path: "/favicon.ico")) { phase in
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
                        settings.recentApps = []
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
                                    let app = SelectedApp(url: url, id: UUID())
                                    selection = app
                                    settings.recentApps += [app]
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
                                let app = SelectedApp(url: url, id: UUID())
                                selection = app
                                settings.recentApps += [app]
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
                let app = SelectedApp(url: liveViewURL, id: .init())
                selection = app
                settings.recentApps += [app]
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
                    let app = SelectedApp(url: url, id: .init())
                    openWindow(value: app)
                    settings.recentApps += [app]
                } label: {
                    Label("Launch", systemImage: "arrow.up.right.square.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            Divider()
            Button {
                let url = URL(string: "http://localhost:4000")!
                let app = SelectedApp(url: url, id: .init())
                openWindow(value: app)
                settings.recentApps += [app]
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
        #elseif os(visionOS)
        List {
            Section {
                if settings.recentApps.isEmpty {
                    Text("No recent apps connected.")
                }
                ForEach(settings.recentApps.reversed(), id: \.self) { app in
                    Button {
                        let app = app.withUniqueID()
                        if app.launchStyle == .immersiveSpace {
                            Task {
                                await openImmersiveSpace(id: app.launchStyle.rawValue, value: app)
                            }
                        } else {
                            openWindow(id: app.launchStyle.rawValue, value: app)
                        }
                        settings.recentApps += [app]
                    } label: {
                        Label {
                            HStack {
                                Text((app.url as NSURL).resourceSpecifier.flatMap({ String($0.dropFirst(2)) }) ?? app.url.absoluteString)
                                Spacer()
                                if app.launchStyle != .plain {
                                    Text(app.launchStyle.description)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            AsyncImage(url: app.url.replacing(path: "/apple-touch-icon.png")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                case .failure:
                                    AsyncImage(url: app.url.replacing(path: "/favicon.ico")) { phase in
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
                        settings.recentApps = []
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
                Menu {
                    Section("Style") {
                        ForEach([SelectedApp.LaunchStyle.plain, .volumetric, .immersiveSpace], id: \.self) { launchStyle in
                            Button(launchStyle.description) {
                                guard let url = URL(string: appendingScheme(to: inputURL))
                                else { return }
                                let app = SelectedApp(url: url, id: .init(), launchStyle: launchStyle)
                                if launchStyle == .immersiveSpace {
                                    Task {
                                        await openImmersiveSpace(id: launchStyle.rawValue, value: app)
                                    }
                                } else {
                                    openWindow(id: launchStyle.rawValue, value: app)
                                }
                                settings.recentApps += [app]
                            }
                        }
                    }
                } label: {
                    Label("Launch", systemImage: "arrow.up.right.square.fill")
                        .frame(maxWidth: .infinity)
                } primaryAction: {
                    guard let url = URL(string: appendingScheme(to: inputURL))
                    else { return }
                    let app = SelectedApp(url: url, id: .init(), launchStyle: .plain)
                    openWindow(id: SelectedApp.LaunchStyle.plain.rawValue, value: app)
                    settings.recentApps += [app]
                }
                .buttonBorderShape(.roundedRectangle(radius: 10))
            }
            .padding(8)
            .glassBackgroundEffect(in: .rect(cornerRadius: 16, style: .continuous))
        }
        .navigationTitle("LiveView Native Go")
        #else
        Group {
            if let app = selection {
                app.makeLiveView(settings: settings, dynamicType: dynamicType)
                    .modifier(QuickActionsModifier(app: app, selection: $selection))
                    .onExitCommand {
                        selection = nil
                    }
            } else {
                VStack(alignment: .leading) {
                    Text("") // this makes sure the URL field is not covered by the sidebar.
                    List {
                        Section {
                            if settings.recentApps.isEmpty {
                                Text("No recent apps connected.")
                            }
                            ForEach(settings.recentApps.reversed(), id: \.self) { app in
                                Button {
                                    let app = app.withUniqueID()
                                    selection = app
                                    settings.recentApps += [app]
                                } label: {
                                    Label {
                                        Text((app.url as NSURL).resourceSpecifier.flatMap({ String($0.dropFirst(2)) }) ?? app.url.absoluteString)
                                    } icon: {
                                        AsyncImage(url: app.url.replacing(path: "/apple-touch-icon.png")) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                            case .failure:
                                                AsyncImage(url: app.url.replacing(path: "/favicon.ico")) { phase in
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
                                    settings.recentApps = []
                                }
                            }
                        }
                    }
                    .searchable(text: $inputURL, prompt: "URL")
                    .onSubmit(of: .search) {
                        guard let url = URL(string: appendingScheme(to: inputURL))
                        else { return }
                        let app = SelectedApp(url: url, id: .init())
                        selection = app
                        settings.recentApps += [app]
                    }
                }
            }
        }
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
