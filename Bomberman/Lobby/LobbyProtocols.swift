//
//  LobbyProtocols.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation

protocol LobbyInteractionLogic {
    func updateGameStateDeinit()
    func configureCallbacks()
    func getMyPlayerId(completion: @escaping (String?) -> Void)
    func sendReady()
}

protocol LobbyPresentationLogic {
    func updatePlayers(_ players: [PlayerModel])
    func startGame(with: GameStateModel)
}
