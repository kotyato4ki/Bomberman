//
//  LobbyAssembly.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation

final class LobbyAssembly {
    static func build() -> LobbyViewController {
        let presenter = LobbyPresenter()
        let interactor = LobbyInteractor(presenter: presenter)
        let view = LobbyViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
