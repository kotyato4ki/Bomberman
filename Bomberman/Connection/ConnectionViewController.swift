//
//  ConnectionViewController.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import UIKit

final class ConnectionViewController: UIViewController {
    
    private var didOpenLobby = false
    
    private let nameField: UITextField = {
        let field = UITextField()
        let placeholderText = "name"
        let placeholderColor = UIColor.lightGray

        let attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )
        field.attributedPlaceholder = attributedPlaceholder
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: field.frame.height))
        field.leftView = leftPaddingView
        field.leftViewMode = .always

        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: field.frame.height))
        field.rightView = rightPaddingView
        field.rightViewMode = .always
        
        field.borderStyle = .line
        field.backgroundColor = UIColor(red: 0.255, green: 0.1608, blue: 0.192, alpha: 1)
        field.textColor = .white
        field.font = Fonts.pixelText
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        return field
    }()
    
    private let roleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = Fonts.pixelText
        label.text = "Enter a name or leave the field blank to follow"
        return label
    }()
    
    private let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("connect", for: .normal)
        button.titleLabel?.font = Fonts.pixelText
        button.backgroundColor = .none
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 0.1803, green: 0.1019, blue: 0.176, alpha: 1)
        button.layer.cornerRadius = 10
        button.addTarget(nil, action: #selector(connectTapped), for: .touchUpInside)
        return button
    }()
    
    private let gameNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = Fonts.pixelHeading
        label.text = "bomberman"
        return label
    }()
    
    private let stack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .init(red: 0.149, green: 0.0745, blue: 0.101, alpha: 1)
        configureStack()
    }

    private func configureStack() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        [gameNameLabel, roleLabel, nameField, connectButton].forEach { stack.addArrangedSubview($0) }
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            connectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func connectTapped() {
        let name = nameField.text ?? ""

        if name.isEmpty {
            showAlert("Введите имя для игры")
            return
        }

        GameWebSocketService.shared.onAssignPlayerId = { id in
            print("Назначен id: \(id)")
        }

        GameWebSocketService.shared.onGameState = { [weak self] state in
            guard let self = self else { return }
            print("Получено состояние: \(state.state)")
            
            guard state.state == "WAITING" else { return }
            
            guard !self.didOpenLobby else { return }
            self.didOpenLobby = true
            
            DispatchQueue.main.async {
                self.openLobby()
            }
        }

        GameWebSocketService.shared.onDisconnected = { error in
            print("Отключено от сервера: \(String(describing: error))")
        }

        GameWebSocketService.shared.connect()
        let role: ClientRole = .player   // пока без spectator, раз ты имя требуешь
        GameWebSocketService.shared.sendJoin(name: name, role: role)

        print("Подключение к серверу...")
    }

    
    private func openLobby() {
        let vc = LobbyViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showAlert(_ text: String) {
        let alert = UIAlertController(title: "Ошибка", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
