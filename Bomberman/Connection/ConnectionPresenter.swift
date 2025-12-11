//
//  ConnectionPresenter.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import Foundation
import UIKit

final class ConnectionPresenter: ConnectionPresentationLogic {
    var view: ConnectionViewController?
    
    func routingToLobby() {
        let vc = LobbyAssembly.build()
        view?.navigationController?.pushViewController(vc, animated: true)
    }
}
