//
//  LobbyViewController.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import UIKit

final class LobbyViewController: UIViewController {
    
    private let interactor: LobbyInteractionLogic
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private let readyButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    var players: [PlayerModel] = [] {
        didSet {
            tableView.reloadData()
            updateReadyState()
        }
    }
    
    private var isMyReady: Bool = false {
        didSet {
            updateReadyButtonAppearance()
        }
    }
    
    init(interactor: LobbyInteractionLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)
        readyButton.addTarget(self, action: #selector(readyButtonTapped), for: .touchUpInside)
        view.backgroundColor = Colors.background
        
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "background")
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)
        
        configureUI()
    }
    
    deinit {
        interactor.updateGameStateDeinit()
    }
    
    @objc
    private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func configureUI() {
        configureBackButton()
        configureTitleLabel()
        configureReadyButton()
        configureTableView()
        configureCallbacks()
    }
    
    private func configureBackButton() {
        let image = UIImage(named: "back_button")?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(image, for: .normal)
        backButton.tintColor = .white
        backButton.configuration = nil
        backButton.imageView?.contentMode = .scaleAspectFit
        
        view.addSubview(backButton)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 8)
        backButton.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 16)
    }
    
    private func configureTitleLabel() {
        titleLabel.text = "Lobby"
        titleLabel.textColor = .white
        titleLabel.font = Fonts.pixelHeading
        
        view.addSubview(titleLabel)
        titleLabel.pinCenterX(to: view.centerXAnchor)
        titleLabel.pinCenterY(to: backButton.centerYAnchor)
    }
    
    private func configureReadyButton() {
        readyButton.setTitle("ready", for: .normal)
        readyButton.backgroundColor = UIColor(red: 0.1803, green: 0.1019, blue: 0.176, alpha: 1)
        readyButton.tintColor = .systemGreen
        readyButton.layer.cornerRadius = 12
        readyButton.titleLabel?.font = Fonts.pixel27
        
        view.addSubview(readyButton)
        readyButton.setWidth(300)
        readyButton.setHeight(50)
        readyButton.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, 16)
        readyButton.pinCenterX(to: view)
    }
    
    private func configureTableView() {
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PlayerCell.self, forCellReuseIdentifier: PlayerCell.reuseIdentifier)
        
        view.addSubview(tableView)
        tableView.pinTop(to: titleLabel.bottomAnchor, 16)
        tableView.pinLeft(to: view.leadingAnchor, 16)
        tableView.pinRight(to: view.trailingAnchor, 16)
        tableView.pinBottom(to: readyButton.topAnchor, 16)
    }
    
    private func configureCallbacks() {
        interactor.configureCallbacks()
    }

    private func updateReadyState() {
        interactor.getMyPlayerId { [weak self] myId in
            guard let self = self else { return }
            
            guard let myId = myId else {
                self.isMyReady = false
                return
            }
            
            if let me = self.players.first(where: { $0.id == myId }) {
                self.isMyReady = me.ready
            } else {
                self.isMyReady = false
            }
        }
    }

    private func updateReadyButtonAppearance() {
        let title = isMyReady ? "not ready" : "ready"
        let color: UIColor = isMyReady ? .systemYellow : .systemGreen
        
        UIView.performWithoutAnimation {
            readyButton.setTitle(title, for: .normal)
            readyButton.tintColor = color
            readyButton.layoutIfNeeded()
        }
    }
    
    @objc private func readyButtonTapped() {
        interactor.sendReady()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension LobbyViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        players.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PlayerCell.reuseIdentifier,
            for: indexPath
        ) as? PlayerCell else {
            return UITableViewCell()
        }
        
        let player = players[indexPath.row]
        cell.configure(with: player)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}

