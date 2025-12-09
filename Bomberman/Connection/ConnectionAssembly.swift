//
//  ConnectionAssembly.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import Foundation

final class ConnectionAssembly {
    static func build() -> ConnectionViewController {
        let presenter = ConnectionPresenter()
        let interactor = ConnectionInteractor(presenter: presenter)
        let view = ConnectionViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
