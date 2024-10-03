//
//  URL+replacing.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 10/3/24.
//

import Foundation

extension URL {
    func replacing(path: String) -> Self {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        components.path = path
        return components.url!
    }
}
