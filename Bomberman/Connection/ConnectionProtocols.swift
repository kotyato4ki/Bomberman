//
//  ConnectionProtocols.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import Foundation

protocol ConnectionInteractionLogic {
    func connectToGame(name: String)
    func updateLobbyFlag()
}

protocol ConnectionPresentationLogic {
    func routingToLobby()
}
