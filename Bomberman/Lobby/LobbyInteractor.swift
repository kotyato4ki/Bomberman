//
//  LobbyInteractor.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation

final class LobbyInteractor: LobbyInteractionLogic {
    private let presenter: LobbyPresentationLogic
    private let service = GameWebSocketService.shared
    
    init(presenter: LobbyPresentationLogic) {
        self.presenter = presenter
    }
    
    func updateGameStateDeinit() {
        service.onGameState = nil
    }
    
    func configureCallbacks() {
        service.onGameState = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch state.state {
                case "WAITING":
                    self.presenter.updatePlayers(state.players)
                    
                case "IN_PROGRESS":
                    self.presenter.startGame(with: state)
                    
                case "GAME_OVER":
                    print("GAME_OVER, winner: \(state.winner ?? "nil")")
                    
                default:
                    break
                }
            }
        }
    }
    
    func getMyPlayerId(completion: @escaping (String?) -> Void) {
        completion(service.currentPlayerId)
    }
    
    func sendReady() {
        service.sendReady()
        // Для теста: сразу переходим на GameZone
        presenter.routeToGameZone()
    }
}
