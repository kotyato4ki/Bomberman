//
//  LobbyPresenter.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation

final class LobbyPresenter: LobbyPresentationLogic {
    var view: LobbyViewController?
    
    func updatePlayers(_ players: [PlayerModel]) {
        view?.players = players
    }
    
    func startGame(with: GameStateModel) {
        // TODO: тут переход на экран игры.
        print("Game started")
    }
}
