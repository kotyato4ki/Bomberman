//
//  ServerMessage.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import Foundation

struct AssignIdMessage: Codable {
    let type: String       // "assign_id"
    let payload: String    // id игрока
}

struct GameStateMessage: Codable {
    let type: String       // "game_state"
    let payload: GameStateModel
}
