//
//  LobbyViewController.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import UIKit

final class LobbyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        
        let label = UILabel()
        label.text = "Лобби"
        label.textColor = .white
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
