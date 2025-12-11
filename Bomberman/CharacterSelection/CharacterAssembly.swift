import UIKit

final class CharacterSelectionAssembly {
    static func build() -> CharacterSelectionViewController {
        let presenter = CharacterSelectionPresenter()
        let interactor = CharacterSelectionInteractor(presenter: presenter)
        let viewController = CharacterSelectionViewController(interactor: interactor)
        presenter.view = viewController
        return viewController
    }
}
