//
//  CharacterCell.swift
//  Bomberman
//
//  Created by Nick on 11.12.2025.
//

import Foundation
import UIKit

final class CharacterCell: UICollectionViewCell {
    static let reuseId = "CharacterCell"
    
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 1, alpha: 0.1)
        layer.cornerRadius = 16
        layer.borderWidth = 4
        layer.borderColor = UIColor.clear.cgColor
        
        imageView.contentMode = .scaleAspectFit
        nameLabel.textColor = .white
        nameLabel.font = Fonts.pixel27
        nameLabel.textAlignment = .center
        
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        
        imageView.pinTop(to: contentView.topAnchor, 10)
        imageView.pinHorizontal(to: contentView, 10)
        imageView.setHeight(100)
        
        nameLabel.pinTop(to: imageView.bottomAnchor, 8)
        nameLabel.pinHorizontal(to: contentView)
        nameLabel.pinBottom(to: contentView.bottomAnchor, 10)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with character: CharacterModel) {
        imageView.image = UIImage(named: character.previewImageName)
        nameLabel.text = character.name
    }
    
    func setSelected(_ selected: Bool) {
        layer.borderColor = selected ? UIColor.systemGreen.cgColor : UIColor.clear.cgColor
    }
}
