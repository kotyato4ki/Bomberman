//
//  GameZoneProtocols.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation

protocol GameZoneInteractionLogic {
    func configureCallbacks()
    func sendMove(dx: Int, dy: Int)
    func sendPlaceBomb()
    func updateGameStateDeinit()
}

protocol GameZonePresentationLogic {
    func updateGameState(_ state: GameStateModel)
}

