//
//  CharacterSelectionViewController.swift
//  Bomberman
//
//  Created by Nick on 11.12.2025.
//

import UIKit

final class CharacterSelectionViewController: UIViewController {
    
    private let interactor: CharacterSelectionInteractionLogic
    
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let confirmButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    private var characters: [CharacterModel] = []
    private var selectedCharacter: CharacterModel?
    
    init(interactor: CharacterSelectionInteractionLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        setupUI()
        interactor.loadCharacters()
    }
    
    private func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Background
        let bg = UIImageView(image: UIImage(named: "background"))
        bg.contentMode = .scaleAspectFill
        view.addSubview(bg)
        bg.pin(to: view)
        
        configureBackButton()
        
        // Title
        titleLabel.text = "Choose your bomber"
        titleLabel.font = Fonts.pixelHeading.withSize(35)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)
        titleLabel.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 30)
        titleLabel.pinCenterX(to: view)
        
        // ScrollView + StackView
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.pinTop(to: titleLabel.bottomAnchor, 20)
        scrollView.pinHorizontal(to: view, 20)
        scrollView.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, 20)

        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.alignment = .center
        scrollView.addSubview(stackView)

        // Ограничения для центрирования стека
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        
        // Confirm Button
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.titleLabel?.font = Fonts.pixel27
        confirmButton.backgroundColor = UIColor(red: 0.18, green: 0.10, blue: 0.18, alpha: 1)
        confirmButton.tintColor = .systemGreen
        confirmButton.layer.cornerRadius = 12
        confirmButton.isEnabled = false
        confirmButton.alpha = 0.5
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        view.addSubview(confirmButton)
        confirmButton.setHeight(60)
        confirmButton.setWidth(300)
        confirmButton.pinBottom(to: view.bottomAnchor, 15)
        confirmButton.pinCenterX(to: view)
    }
    
    private func configureBackButton() {
        let image = UIImage(named: "back_button")?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(image, for: .normal)
        backButton.tintColor = .white
        backButton.configuration = nil
        backButton.imageView?.contentMode = .scaleAspectFit
        view.bringSubviewToFront(backButton)
        
        view.addSubview(backButton)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 8)
        backButton.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 16)
    }
    
    @objc
    private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    func displayCharacters(_ characters: [CharacterModel]) {
        self.characters = characters
        
        // Очистим стек
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for character in characters {
            let cell = CharacterCell()
            cell.configure(with: character)
            cell.widthAnchor.constraint(equalToConstant: 120).isActive = true
            cell.heightAnchor.constraint(equalToConstant: 160).isActive = true
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(characterTapped(_:)))
            cell.addGestureRecognizer(tapGesture)
            cell.isUserInteractionEnabled = true
            
            stackView.addArrangedSubview(cell)
        }
    }
    
    @objc private func characterTapped(_ sender: UITapGestureRecognizer) {
        guard let cell = sender.view as? CharacterCell,
              let index = stackView.arrangedSubviews.firstIndex(of: cell) else { return }
        let character = characters[index]
        interactor.selectCharacter(character)
    }
    
    func highlightSelectedCharacter(_ character: CharacterModel) {
        selectedCharacter = character
        stackView.arrangedSubviews.forEach { ($0 as? CharacterCell)?.setSelected(false) }
        if let index = characters.firstIndex(of: character),
           let cell = stackView.arrangedSubviews[index] as? CharacterCell {
            cell.setSelected(true)
        }
    }
    
    func updateConfirmButton(enabled: Bool) {
        confirmButton.isEnabled = enabled
        confirmButton.alpha = enabled ? 1.0 : 0.5
    }
    
    @objc private func confirmTapped() {
        guard let selected = selectedCharacter else { return }
        interactor.selectCharacter(selected)
        navigationController?.pushViewController(LobbyAssembly.build(), animated: true)
    }
}
