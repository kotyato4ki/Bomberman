//
//  ConnectionViewController.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import UIKit

final class ConnectionViewController: UIViewController {

    private let interactor: ConnectionInteractionLogic
    private let nameField = UITextField()
    private let roleLabel = UILabel()
    private let connectButton = UIButton()
    private let gameNameLabel = UILabel()
    private let stack = UIStackView()
    
    init(interactor: ConnectionInteractionLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "background")
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)
        
        configureNameTextField()
        configureRoleLabel()
        configureConnectButton()
        configureGameNameLabel()
        configureStack()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        interactor.updateLobbyFlag()
    }
    
    private func configureNameTextField() {
        let placeholderText = "name"
        let placeholderColor = UIColor.lightGray

        let attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )
        nameField.attributedPlaceholder = attributedPlaceholder
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: nameField.frame.height))
        nameField.leftView = leftPaddingView
        nameField.leftViewMode = .always

        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: nameField.frame.height))
        nameField.rightView = rightPaddingView
        nameField.rightViewMode = .always
        
        nameField.borderStyle = .line
        nameField.backgroundColor = UIColor(red: 0.255, green: 0.1608, blue: 0.192, alpha: 1)
        nameField.textColor = .white
        nameField.font = Fonts.pixel27
        nameField.autocapitalizationType = .none
        nameField.autocorrectionType = .no
    }
    
    private func configureRoleLabel() {
        roleLabel.textColor = .white
        roleLabel.textAlignment = .center
        roleLabel.font = Fonts.pixel27
        roleLabel.text = "Enter a name or leave the field blank to follow"
    }
    
    private func configureConnectButton() {
        connectButton.setTitle("connect", for: .normal)
        connectButton.titleLabel?.font = Fonts.pixel27
        connectButton.backgroundColor = .none
        connectButton.tintColor = .white
        connectButton.backgroundColor = UIColor(red: 0.1803, green: 0.1019, blue: 0.176, alpha: 1)
        connectButton.layer.cornerRadius = 10
        connectButton.addTarget(nil, action: #selector(connectTapped), for: .touchUpInside)
    }
    
    private func configureGameNameLabel() {
        gameNameLabel.textColor = .white
        gameNameLabel.textAlignment = .center
        gameNameLabel.font = Fonts.pixelHeading
        gameNameLabel.text = "bomberman"
    }

    private func configureStack() {
        stack.axis = .vertical
        stack.spacing = 16
        [gameNameLabel, roleLabel, nameField, connectButton].forEach { stack.addArrangedSubview($0) }
        
        view.addSubview(stack)
        stack.pinCenterY(to: view)
        stack.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 32)
        stack.pinRight(to: view.safeAreaLayoutGuide.trailingAnchor, 32)
        connectButton.setHeight(50)
    }
    
    @objc
    private func connectTapped() {
        let name = nameField.text ?? ""

        if name.isEmpty {
            showAlert("Enter your name to start the game")
            return
        }

        interactor.connectToGame(name: name)
    }
    
    private func showAlert(_ text: String) {
        let alert = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
