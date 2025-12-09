//
//  ConnectionPresenter.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import Foundation

final class ConnectionPresenter: ConnectionPresentationLogic {
    public var view: ConnectionViewController?
    
    func routingToLobby() {
        let vc = LobbyViewController()
        view?.navigationController?.pushViewController(vc, animated: true)
    }
}
