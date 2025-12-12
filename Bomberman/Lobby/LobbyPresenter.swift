//
//  LobbyPresenter.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation
import UIKit

final class LobbyPresenter: LobbyPresentationLogic {
    var view: LobbyViewController?
    
    func updatePlayers(_ players: [PlayerModel]) {
        view?.players = players
    }
    
    func startGame(with gameState: GameStateModel) {
        routeToGameZone()
    }
    
    func routeToGameZone() {
        let gameZoneVC = GameZoneAssembly.build()
        view?.navigationController?.pushViewController(gameZoneVC, animated: true)
    }
}
