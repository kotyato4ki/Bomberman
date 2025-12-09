//
//  NetworkConfig.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import Foundation

enum NetworkConfig {
    static let host = "localhost"
    static let port: Int = 8765

    static var webSocketURL: URL? {
        var components = URLComponents()
        components.scheme = "ws"
        components.host = host
        components.port = port
        return components.url
    }
}
