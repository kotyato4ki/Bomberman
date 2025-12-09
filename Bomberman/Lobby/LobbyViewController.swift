//
//  LobbyViewController.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import UIKit

final class LobbyViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Lobby"
        label.textColor = .white
        label.font = Fonts.pixelHeading
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    private let readyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ready", for: .normal)
        button.backgroundColor = UIColor(red: 0.1803, green: 0.1019, blue: 0.176, alpha: 1)
        button.tintColor = .systemGreen
        button.layer.cornerRadius = 12
        button.titleLabel?.font = Fonts.pixel27
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        let image = UIImage(named: "back_button")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.configuration = nil
        button.imageView?.contentMode = .scaleAspectFit
        
        return button
    }()

    
    private var players: [PlayerModel] = [] {
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
    
    private let service = GameWebSocketService.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)
        readyButton.addTarget(self, action: #selector(readyButtonTapped), for: .touchUpInside)
        view.backgroundColor = Colors.background
        setupUI()
        setupTableView()
        setupCallbacks()
    }
    
    deinit {
        service.onGameState = nil
    }


    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(readyButton)
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: readyButton.topAnchor, constant: -16),
            
            readyButton.widthAnchor.constraint(equalToConstant: 300),
            readyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            readyButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        readyButton.pinCenterX(to: view)
    }

    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PlayerCell.self, forCellReuseIdentifier: PlayerCell.reuseIdentifier)
    }
    
    private func setupCallbacks() {
        service.onGameState = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch state.state {
                case "WAITING":
                    self.players = state.players
                    
                case "IN_PROGRESS":
                    self.startGame(with: state)
                    
                case "GAME_OVER":
                    print("GAME_OVER, winner: \(state.winner ?? "nil")")
                    
                default:
                    break
                }
            }
        }
    }
    
    private func startGame(with state: GameStateModel) {
        // TODO: тут переход на экран игры.
        print("Игра началась! Переходим на поле…")
    }


    
    private func updateReadyState() {
        guard let myId = service.currentPlayerId else {
            isMyReady = false
            return
        }
        
        if let me = players.first(where: { $0.id == myId }) {
            isMyReady = me.ready
        } else {
            isMyReady = false
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
        service.sendReady()
        isMyReady.toggle()
        updateReadyButtonAppearance()
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

