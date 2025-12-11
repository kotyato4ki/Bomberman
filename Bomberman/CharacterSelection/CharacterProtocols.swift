//
//  CharacterProtocols.swift
//  Bomberman
//
//  Created by Nick on 11.12.2025.
//

import Foundation

protocol CharacterSelectionPresentationLogic: AnyObject {
    func presentCharacters(_ characters: [CharacterModel])
    func presentSelectedCharacter(_ character: CharacterModel)
}

protocol CharacterSelectionInteractionLogic: AnyObject {
    func loadCharacters()
    func selectCharacter(_ character: CharacterModel)
}
