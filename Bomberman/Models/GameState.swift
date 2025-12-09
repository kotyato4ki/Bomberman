// Models/GameState.swift

import Foundation

struct PlayerModel: Codable, Identifiable {
    let id: String
    let name: String
    let x: Int
    let y: Int
    let alive: Bool
    let ready: Bool
}

struct BombModel: Codable {
    let x: Int
    let y: Int
}

struct ExplosionModel: Codable {
    let x: Int
    let y: Int
}

struct GameStateModel: Codable {
    let state: String                 // "WAITING" | "IN_PROGRESS" | "GAME_OVER"
    let map: [[String]]
    let players: [PlayerModel]
    let bombs: [BombModel]
    let explosions: [ExplosionModel]
    let timeRemaining: Double?        
    let winner: String?
    
    enum CodingKeys: String, CodingKey {
        case state
        case map
        case players
        case bombs
        case explosions
        case timeRemaining = "time_remaining"
        case winner
    }
}
