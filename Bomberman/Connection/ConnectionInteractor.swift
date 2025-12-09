//
//  ConnectionInteractor.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import UIKit

final class ConnectionInteractor: ConnectionInteractionLogic {
    private let presenter: ConnectionPresentationLogic
    private var didOpenLobby = false
    
    init(presenter: ConnectionPresentationLogic) {
        self.presenter = presenter
    }
    
    func connectToGame(name: String) {
        GameWebSocketService.shared.onAssignPlayerId = { id in
            print("Set id: \(id)")
        }

        GameWebSocketService.shared.onGameState = { [weak self] state in
            guard let self = self else { return }
            print("Get state: \(state.state)")
            
            guard state.state == "WAITING" else { return }
            
            guard !self.didOpenLobby else { return }
            self.didOpenLobby = true
            
            DispatchQueue.main.async {
                self.presenter.routingToLobby()
            }
        }

        GameWebSocketService.shared.onDisconnected = { error in
            print("Disconnected from the server: \(String(describing: error))")
        }

        GameWebSocketService.shared.connect()
        let role: ClientRole = .player
        GameWebSocketService.shared.sendJoin(name: name, role: role)

        print("Connection to the server...")
    }
    
    func updateLobbyFlag() {
        didOpenLobby = false
    }
}
