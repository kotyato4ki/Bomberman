//
//  GameZonePresenter.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation

final class GameZonePresenter: GameZonePresentationLogic {
    var view: GameZoneViewController?
    
    func updateGameState(_ state: GameStateModel) {
        view?.updateGameState(state)
    }
}

