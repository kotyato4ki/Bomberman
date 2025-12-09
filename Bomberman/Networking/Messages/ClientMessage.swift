//
//  ClientMessage.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import Foundation

enum ClientRole: String {
    case player
    case spectator
}

struct ClientMessage: Codable {
    let type: String
    let role: String?
    let name: String?
    let dx: Int?
    let dy: Int?
    
    
    static func join(name: String?, role: ClientRole) -> ClientMessage {
        ClientMessage(
            type: "join",
            role: role.rawValue,
            name: role == .player ? name : nil,
            dx: nil,
            dy: nil
        )
    }
    
    static func ready() -> ClientMessage {
        ClientMessage(
            type: "ready",
            role: nil,
            name: nil,
            dx: nil,
            dy: nil
        )
    }
    
    static func move(dx: Int, dy: Int) -> ClientMessage {
        ClientMessage(
            type: "move",
            role: nil,
            name: nil,
            dx: dx,
            dy: dy
        )
    }
    
    static func placeBomb() -> ClientMessage {
        ClientMessage(
            type: "place_bomb",
            role: nil,
            name: nil,
            dx: nil,
            dy: nil
        )
    }
}

