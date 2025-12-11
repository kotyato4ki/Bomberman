//
//  CharacterSelectionViewController.swift
//  Bomberman
//
//  Created by Nick on 11.12.2025.
//

import Foundation
import UIKit

final class CharacterSelectionViewController: UIViewController {
    
    private let interactor: CharacterSelectionInteractionLogic
    
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    private let confirmButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    private var characters: [CharacterModel] = []
    private var selectedCharacter: CharacterModel?
    
    init(interactor: CharacterSelectionInteractionLogic) {
        self.interactor = interactor
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 120, height: 160)
        layout.minimumInteritemSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
        
        // CollectionView
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CharacterCell.self, forCellWithReuseIdentifier: CharacterCell.reuseId)
        view.addSubview(collectionView)
        collectionView.pinTop(to: titleLabel.bottomAnchor, 10)
        collectionView.pinHorizontal(to: view, 20)
        collectionView.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, -100)
        
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
        collectionView.reloadData()
    }
    
    func highlightSelectedCharacter(_ character: CharacterModel) {
        selectedCharacter = character
        collectionView.visibleCells.forEach { ($0 as? CharacterCell)?.setSelected(false) }
        if let index = characters.firstIndex(of: character),
           let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterCell {
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
        // Здесь будет переход в лобби или сразу в игру
        navigationController?.pushViewController(LobbyAssembly.build(), animated: true)
    }
}

// MARK: - CollectionView DataSource & Delegate
extension CharacterSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        characters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CharacterCell.reuseId, for: indexPath) as! CharacterCell
        cell.configure(with: characters[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let character = characters[indexPath.item]
        interactor.selectCharacter(character)
    }
}
