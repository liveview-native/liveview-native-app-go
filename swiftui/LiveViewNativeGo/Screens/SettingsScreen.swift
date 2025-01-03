//
//  SettingsScreen.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI

struct SettingsScreen: View {
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
        
    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            List {
                Section("Device Settings") {
                    Picker("Appearance", selection: $settings.colorScheme) {
                        Text("System").tag(ColorScheme?.none)
                        Text("Light").tag(ColorScheme?.some(.light))
                        Text("Dark").tag(ColorScheme?.some(.dark))
                    }
                }
                Section {
                    Toggle("Use Dynamic Type", isOn: $settings.dynamicTypeEnabled)
                    #if os(tvOS)
                    LabeledContent("Dynamic Type Size") {
                        Picker(selection: $settings.dynamicType) {
                            ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                                Text(String(describing: size))
                                    .tag(size)
                            }
                        } label: {
                            Text("Dynamic Type")
                        }
                        .pickerStyle(.menu)
                        .disabled(!settings.dynamicTypeEnabled)
                    }
                    #else
                    Slider(
                        value: Binding {
                            Double(DynamicTypeSize.allCases.firstIndex(of: settings.dynamicType)!)
                        } set: {
                            settings.dynamicType = DynamicTypeSize.allCases[Int($0)]
                        },
                        in: Double(DynamicTypeSize.allCases.startIndex)...Double(DynamicTypeSize.allCases.index(before: DynamicTypeSize.allCases.endIndex)),
                        step: 1
                    ) {
                        Text("Dynamic Type")
                    }
                    .disabled(!settings.dynamicTypeEnabled)
                    #endif
                } header: {
                    Text("Dynamic Type")
                } footer: {
                    #if !os(tvOS)
                    Text(String(describing: settings.dynamicType))
                    #endif
                }
                Section {
                    Link("Live Form", destination: .liveForm)
                    Link("AVKit", destination: .avKit)
                    Link("Swift Charts", destination: .charts)
                    Link("MapKit", destination: .mapKit)
                    Link("RealityKit", destination: .realityKit)
                } header: {
                    Text("Included Addons")
                } footer: {
                    Text("Use Xcode to include additional addons")
                }
                
                Section("About") {
                    LabeledContent("Client Version") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                            #if !os(tvOS)
                            .textSelection(.enabled)
                            #endif
                    }
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
                    Link("Release Notes", destination: URL(string: "https://github.com/liveview-native/liveview-client-swiftui/releases/tag/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")!)
                }
            }
                #if os(iOS) || os(visionOS)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                #endif
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var settings = Settings()
        @Environment(\.dynamicTypeSize) private var dynamicType
        
        var body: some View {
            SettingsScreen()
                .environment(settings)
                .preferredColorScheme(settings.colorScheme)
                .dynamicTypeSize(settings.dynamicTypeEnabled ? settings.dynamicType : dynamicType)
        }
    }
    return PreviewView()
}
