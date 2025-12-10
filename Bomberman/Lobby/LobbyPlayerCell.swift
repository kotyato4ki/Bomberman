//
//  LobbyPlayerCell.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import UIKit

final class PlayerCell: UITableViewCell {
    
    static let reuseIdentifier = "PlayerCell"
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = Fonts.pixel27
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemYellow
        label.font = Fonts.pixel27
        label.textAlignment = .right
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        view.layer.cornerRadius = 12
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        configureContainerView()
        configureNameLabel()
        configureStatusLabel()
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    func configure(with player: PlayerModel) {
        nameLabel.text = player.name
        
        if player.ready {
            statusLabel.text = "ready"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "not ready"
            statusLabel.textColor = .systemYellow
        }
    }
    
    private func configureContainerView() {
        contentView.addSubview(containerView)
        containerView.pinTop(to: contentView.topAnchor, 4)
        containerView.pinBottom(to: contentView.bottomAnchor, 4)
        containerView.pinLeft(to: contentView.leadingAnchor)
        containerView.pinRight(to: contentView.trailingAnchor)
    }
    
    private func configureNameLabel() {
        containerView.addSubview(nameLabel)
        nameLabel.pinLeft(to: containerView.leadingAnchor, 16)
        nameLabel.pinCenterY(to: containerView.centerYAnchor)
    }
    
    private func configureStatusLabel() {
        containerView.addSubview(statusLabel)
        statusLabel.pinRight(to: containerView.trailingAnchor, 12)
        statusLabel.pinCenterY(to: containerView.centerYAnchor)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8)
        ])
    }
}
