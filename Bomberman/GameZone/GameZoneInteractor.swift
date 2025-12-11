//
//  GameZoneInteractor.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation

final class GameZoneInteractor: GameZoneInteractionLogic {
    private let presenter: GameZonePresentationLogic
    private let service = GameWebSocketService.shared
    
    init(presenter: GameZonePresentationLogic) {
        self.presenter = presenter
    }
    
    func updateGameStateDeinit() {
        service.onGameState = nil
    }
    
    func configureCallbacks() {
        service.onGameState = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.presenter.updateGameState(state)
            }
        }
    }
    
    func sendMove(dx: Int, dy: Int) {
        service.sendMove(dx: dx, dy: dy)
    }
    
    func sendPlaceBomb() {
        service.sendPlaceBomb()
    }
}

