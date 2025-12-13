//
//  CharacterInteractor.swift
//  Bomberman
//
//  Created by Nick on 11.12.2025.
//

import Foundation

final class CharacterSelectionInteractor: CharacterSelectionInteractionLogic {
    private let presenter: CharacterSelectionPresentationLogic
    private let service = GameWebSocketService.shared
    
    init(presenter: CharacterSelectionPresentationLogic) {
        self.presenter = presenter
    }
    
    func loadCharacters() {
        let characters = [
            CharacterModel(name: "1", previewImageName: "character1"),
            CharacterModel(name: "2",   previewImageName: "character2"),
            CharacterModel(name: "3",  previewImageName: "character3")
        ]
        presenter.presentCharacters(characters)
    }
    
    func selectCharacter(_ character: CharacterModel) {
        guard let selectedId = Int(character.name) else {
            service.selectedCharacterId = 2
            presenter.presentSelectedCharacter(CharacterModel(name: "2", previewImageName: "character2"))
            return
        }

        service.selectedCharacterId = selectedId
        presenter.presentSelectedCharacter(character)
    }
}
