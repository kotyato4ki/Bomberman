//
//  CharacterPresenter.swift
//  Bomberman
//
//  Created by Nick on 11.12.2025.
//

import Foundation
    
final class CharacterSelectionPresenter: CharacterSelectionPresentationLogic {
    weak var view: CharacterSelectionViewController?
    
    func presentCharacters(_ characters: [CharacterModel]) {
        view?.displayCharacters(characters)
    }
    
    func presentSelectedCharacter(_ character: CharacterModel) {
        view?.highlightSelectedCharacter(character)
        view?.updateConfirmButton(enabled: true)
    }
}
