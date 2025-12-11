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
        // В реальной игре — запрос с сервера. Пока хардкод:
        let characters = [
            CharacterModel(name: "White", previewImageName: "char_white"),
            CharacterModel(name: "Black", previewImageName: "char_black"),
            CharacterModel(name: "Red",   previewImageName: "char_red"),
            CharacterModel(name: "Blue",  previewImageName: "char_blue")
        ]
        presenter.presentCharacters(characters)
    }
    
    func selectCharacter(_ character: CharacterModel) {
        service.sendCharacterSelection(character.name)
        presenter.presentSelectedCharacter(character)
    }
}
