//
//  GameZoneAssembly.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import Foundation

final class GameZoneAssembly {
    static func build() -> GameZoneViewController {
        let presenter = GameZonePresenter()
        let interactor = GameZoneInteractor(presenter: presenter)
        let view = GameZoneViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}

