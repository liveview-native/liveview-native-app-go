//
//  Settings.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 3/26/24.
//

import SwiftUI

@Observable final class Settings {
    var colorScheme: ColorScheme? {
        get {
            access(keyPath: \.colorScheme)
            return (_ColorScheme(rawValue: UserDefaults.standard.integer(forKey: "colorScheme")) ?? .light).value
        }
        set {
            withMutation(keyPath: \.colorScheme) {
                UserDefaults.standard.setValue(_ColorScheme(from: newValue).rawValue, forKey: "colorScheme")
            }
        }
    }
    
    var dynamicTypeEnabled: Bool {
        get {
            access(keyPath: \.dynamicTypeEnabled)
            return UserDefaults.standard.bool(forKey: "dynamicTypeEnabled")
        }
        set {
            withMutation(keyPath: \.dynamicTypeEnabled) {
                UserDefaults.standard.setValue(newValue, forKey: "dynamicTypeEnabled")
            }
        }
    }
    
    var dynamicType: DynamicTypeSize {
        get {
            access(keyPath: \.dynamicType)
            return DynamicTypeSize.allCases[UserDefaults.standard.integer(forKey: "dynamicType")]
        }
        set {
            guard let index = DynamicTypeSize.allCases.firstIndex(of: newValue)
            else { return }
            withMutation(keyPath: \.dynamicType) {
                UserDefaults.standard.setValue(index, forKey: "dynamicType")
            }
        }
    }
    
    var recentURLs: [URL] {
        get {
            access(keyPath: \.recentURLs)
            return (UserDefaults.standard.array(forKey: "recentURLs") as? [String] ?? [])
                .compactMap(URL.init)
        }
        set {
            withMutation(keyPath: \.recentURLs) {
                UserDefaults.standard.setValue(
                    // remove duplicates
                    newValue.reduce(into: [String]()) { partialResult, url in
                        partialResult.removeAll(where: { $0 == url.absoluteString })
                        partialResult.append(url.absoluteString)
                    },
                    forKey: "recentURLs"
                )
            }
        }
    }
    
    enum _ColorScheme: Int {
        case system
        case light
        case dark
        
        init(from value: ColorScheme?) {
            switch value {
            case .none:
                self = .system
            case .light:
                self = .light
            case .dark:
                self = .dark
            @unknown default:
                self = .light
            }
        }
        
        var value: ColorScheme? {
            switch self {
            case .system:
                return nil
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }
}
