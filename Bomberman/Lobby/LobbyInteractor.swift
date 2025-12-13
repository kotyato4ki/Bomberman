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
    
    // Добавляем флаг для отслеживания текущего статуса
    private var currentGameState: String = "WAITING"
    
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
                
                // Сохраняем текущий статус игры
                self.currentGameState = state.state
                
                switch state.state {
                case "WAITING":
                    self.presenter.updatePlayers(state.players)
                    
                case "IN_PROGRESS":
                    self.presenter.startGame(with: state)
                    
                case "GAME_OVER":
                    print("GAME_OVER, winner: \(state.winner ?? "nil")")
                    // После окончания игры можно перейти в WAITING,
                    // но это уже обрабатывается на сервере
                    
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
        // Проверяем текущий статус игры
        if currentGameState == "IN_PROGRESS" {
            // Если игра уже началась, сразу переходим на игровое поле
            print("Игра уже началась. Переход на GameZone...")
            DispatchQueue.main.async { [weak self] in
                self?.presenter.routeToGameZone()
            }
            return
        }
        
        // Если игра еще не началась, отправляем готовность
        service.sendReady()
    }
}
