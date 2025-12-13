import UIKit
import SpriteKit

final class GameZoneViewController: UIViewController {

    private let interactor: GameZoneInteractionLogic

    private let backButton = UIButton(type: .system)

    // Общий контейнер
    private let gameMapView = UIView()

    // Контейнер для UIKit-тайлов (его чистим в renderMap)
    private let mapTilesView = UIView()

    // SpriteKit поверх
    private let skView = SKView()
    private var gameScene: GameScene?

    // Кнопки управления
    private let upButton = UIButton(type: .system)
    private let downButton = UIButton(type: .system)
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    private let bombButton = UIButton(type: .system)

    private var gameState: GameStateModel?

    private var didShowGameOverOverlay = false
    private var overlayView: UIView?
    
    private var lastMapTilesBounds: CGRect = .zero
    private var needsMapRerenderAfterLayout = false

    // Таймер раунда (правый верхний угол)
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = Fonts.pixel27
        label.textAlignment = .right
        label.numberOfLines = 1
        label.isHidden = true
        return label
    }()

    // Чтобы реже пересобирать карту
    private var lastRenderedMapSignature: Int?
    
    private lazy var horizontalWallImage = UIImage(named: "horizontal_wall")
    private lazy var verticalWallImage = UIImage(named: "vertical_wall")

    init(interactor: GameZoneInteractionLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)

        if let originalImage = UIImage(named: "gamezone") {
            let scaledImage = scaleImage(originalImage, by: 2.5)
            view.backgroundColor = UIColor(patternImage: scaledImage)
        } else {
            view.backgroundColor = Colors.background
        }

        configureUI()
        configureSpriteKit()
        configureCallbacks()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // если размеров ещё нет — нечего рисовать
        guard mapTilesView.bounds.width > 0, mapTilesView.bounds.height > 0 else { return }

        // если bounds не поменялись и мы не просили перерендер — выходим
        let boundsChanged = (mapTilesView.bounds != lastMapTilesBounds)
        guard boundsChanged || needsMapRerenderAfterLayout else { return }

        lastMapTilesBounds = mapTilesView.bounds
        needsMapRerenderAfterLayout = false

        if let state = gameState {
            // layout сначала
            syncSceneLayoutIfPossible(with: state.map)
            // потом карта (старая стабильная)
            renderMap(state.map)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        interactor.configureCallbacks()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        interactor.updateGameStateDeinit() // sets onGameState = nil
    }

    deinit { interactor.updateGameStateDeinit() }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - UI

    private func configureUI() {
        configureGameMapView()
        configureBackButton()
        configureControlButtons()
        configureTimerLabel()
    }

    private func configureGameMapView() {
        gameMapView.backgroundColor = .clear
        view.addSubview(gameMapView)
        gameMapView.pinTop(to: view.topAnchor)
        gameMapView.pinLeft(to: view.leadingAnchor)
        gameMapView.pinRight(to: view.trailingAnchor)
        gameMapView.pinBottom(to: view.bottomAnchor)

        // UIKit тайлы рисуем СЮДА
        mapTilesView.backgroundColor = .clear
        gameMapView.addSubview(mapTilesView)
        mapTilesView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapTilesView.topAnchor.constraint(equalTo: gameMapView.topAnchor),
            mapTilesView.leadingAnchor.constraint(equalTo: gameMapView.leadingAnchor),
            mapTilesView.trailingAnchor.constraint(equalTo: gameMapView.trailingAnchor),
            mapTilesView.bottomAnchor.constraint(equalTo: gameMapView.bottomAnchor)
        ])

        // SKView поверх тайлов
        skView.backgroundColor = .clear
        skView.allowsTransparency = true
        skView.isOpaque = false
        gameMapView.addSubview(skView)

        skView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: gameMapView.topAnchor),
            skView.leadingAnchor.constraint(equalTo: gameMapView.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: gameMapView.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: gameMapView.bottomAnchor)
        ])
    }

    private func configureBackButton() {
        let image = UIImage(named: "back_button")?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(image, for: .normal)
        backButton.tintColor = .white
        backButton.configuration = nil
        backButton.imageView?.contentMode = .scaleAspectFit

        view.addSubview(backButton)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 4)
        backButton.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 16)

        view.bringSubviewToFront(backButton)
    }

    private func configureControlButtons() {
        let spacing: CGFloat = 5
        let buttonMargin: CGFloat = 5

        guard let arrowImage = UIImage(named: "arrow") else { return }
        let scaledImage = scaleImage(arrowImage, by: 10.0)
        let buttonSize = max(scaledImage.size.width, scaledImage.size.height)

        setupArrowButton(upButton, rotation: 0)
        setupArrowButton(downButton, rotation: .pi)
        setupArrowButton(leftButton, rotation: -.pi / 2)
        setupArrowButton(rightButton, rotation: .pi / 2)

        [upButton, downButton, leftButton, rightButton].forEach {
            view.addSubview($0)
            $0.setWidth(buttonSize)
            $0.setHeight(buttonSize)
            $0.imageView?.contentMode = .scaleAspectFit
            $0.alpha = 0.2
        }

        // Бомба
        if (UIImage(named: "bomb") ?? UIImage(systemName: "flame.fill")) != nil {
            view.addSubview(bombButton)
            bombButton.backgroundColor = .clear
            bombButton.alpha = 0.25 // на время дебага, потом вернёшь 0.25

            if let bombImage = UIImage(named: "bomb") ?? UIImage(systemName: "flame.fill") {
                let scaledBomb = scaleImage(bombImage, by: 3.0)
                bombButton.setImage(scaledBomb.withRenderingMode(.alwaysTemplate), for: .normal)
                bombButton.tintColor = .white
                let s = max(scaledBomb.size.width, scaledBomb.size.height)
                bombButton.setWidth(s)
                bombButton.setHeight(s)
            } else {
                // дебаг-заглушка
                bombButton.setTitle("B", for: .normal)
                bombButton.setTitleColor(.red, for: .normal)
                bombButton.setWidth(60)
                bombButton.setHeight(60)
            }
        }

        // Позиционирование
        downButton.pinRight(to: view.safeAreaLayoutGuide.trailingAnchor, buttonMargin + 50)
        downButton.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, buttonMargin)

        upButton.pinRight(to: view.safeAreaLayoutGuide.trailingAnchor, buttonMargin + 50)
        upButton.pinBottom(to: downButton.topAnchor, -spacing)

        leftButton.pinRight(to: upButton.leadingAnchor, -spacing - 25)
        leftButton.pinCenterY(to: upButton.centerYAnchor, 35)

        rightButton.pinLeft(to: upButton.trailingAnchor, spacing - 35)
        rightButton.pinCenterY(to: upButton.centerYAnchor, 35)

        bombButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bombButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            bombButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])

        // Обработчики: двигаем и сцену (для ощущения мгновенности), и интерактор
        upButton.addTarget(self, action: #selector(upButtonTapped), for: .touchUpInside)
        downButton.addTarget(self, action: #selector(downButtonTapped), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        bombButton.addTarget(self, action: #selector(bombButtonTapped), for: .touchUpInside)

        [upButton, downButton, leftButton, rightButton, bombButton].forEach {
            view.bringSubviewToFront($0)
        }
    }

    private func configureTimerLabel() {
        gameMapView.addSubview(timerLabel)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: gameMapView.topAnchor, constant: 0),
            timerLabel.trailingAnchor.constraint(equalTo: gameMapView.trailingAnchor, constant: -90)
        ])
        view.bringSubviewToFront(timerLabel)
    }

    private func setupArrowButton(_ button: UIButton, rotation: CGFloat) {
        guard let arrowImage = UIImage(named: "arrow") else { return }
        let scaledImage = scaleImage(arrowImage, by: 10.0)
        let rotatedImage = rotateImage(scaledImage, by: rotation)
        button.setImage(rotatedImage, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .clear
    }

    private func rotateImage(_ image: UIImage, by radians: CGFloat) -> UIImage {
        let isQuarterTurn = abs(radians - .pi / 2) < 0.01 || abs(radians + .pi / 2) < 0.01
        let rotatedSize = isQuarterTurn
            ? CGSize(width: image.size.height, height: image.size.width)
            : image.size

        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        return renderer.image { context in
            let cg = context.cgContext
            cg.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            cg.rotate(by: radians)
            cg.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
            if let cgImage = image.cgImage {
                cg.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
            }
        }.withRenderingMode(.alwaysTemplate)
    }

    // MARK: - SpriteKit

    private func configureSpriteKit() {
        skView.ignoresSiblingOrder = true

        let scene = GameScene()
        scene.scaleMode = .resizeFill
        let selectedId = GameWebSocketService.shared.selectedCharacterId
        print("GameScene character id:", selectedId)
        scene.setCharacter(id: selectedId)
        gameScene = scene
        skView.presentScene(scene)
    }

    private func syncSceneLayoutIfPossible(with map: [[String]]) {
        guard let scene = gameScene else { return }
        guard !map.isEmpty else { return }
        guard mapTilesView.bounds.width > 0, mapTilesView.bounds.height > 0 else { return }

        // 1-в-1 с renderMap: считаем от mapTilesView
        let rows = map.count
        let cols = map[0].count

        let availableWidth = mapTilesView.bounds.width
        let availableHeight = mapTilesView.bounds.height

        let calculatedTileWidth = availableWidth / CGFloat(cols)
        let calculatedTileHeight = availableHeight / CGFloat(rows)
        let finalTile = min(calculatedTileWidth, calculatedTileHeight)

        let totalMapWidth = CGFloat(cols) * finalTile
        let totalMapHeight = CGFloat(rows) * finalTile
        let offsetX = (availableWidth - totalMapWidth) / 2
        let offsetY = (availableHeight - totalMapHeight) / 2

        scene.setGridLayout(
            rows: rows,
            cols: cols,
            tileSize: CGSize(width: finalTile, height: finalTile),
            originInViewCoords: CGPoint(x: offsetX, y: offsetY),
            viewSize: skView.bounds.size
        )
    }

    private func configureCallbacks() {
        interactor.configureCallbacks()
    }

    // MARK: - Inputs

    @objc private func upButtonTapped() {
        gameScene?.move(dx: 0, dy: -1)
        interactor.sendMove(dx: 0, dy: -1)
    }

    @objc private func downButtonTapped() {
        gameScene?.move(dx: 0, dy: 1)
        interactor.sendMove(dx: 0, dy: 1)
    }

    @objc private func leftButtonTapped() {
        gameScene?.move(dx: -1, dy: 0)
        interactor.sendMove(dx: -1, dy: 0)
    }

    @objc private func rightButtonTapped() {
        gameScene?.move(dx: 1, dy: 0)
        interactor.sendMove(dx: 1, dy: 0)
    }

    @objc private func bombButtonTapped() {
        interactor.sendPlaceBomb()
    }

    // MARK: - State

    func updateGameState(_ state: GameStateModel) {
        gameState = state

        // 1) layout
        syncSceneLayoutIfPossible(with: state.map)

        // 2) UIKit карта
        if mapTilesView.bounds.width > 0, mapTilesView.bounds.height > 0 {
            renderMap(state.map)

            // ✅ важно: чтобы viewDidLayoutSubviews не делал "второй лишний рендер"
            lastMapTilesBounds = mapTilesView.bounds
            needsMapRerenderAfterLayout = false
        } else {
            needsMapRerenderAfterLayout = true
        }

        // 3) collision
        gameScene?.updateCollisionMap(state.map)

        // 4) игроки
        gameScene?.syncPlayers(state.players, myId: GameWebSocketService.shared.currentPlayerId)

        // 5) бомбы/взрывы
        gameScene?.syncBombs(state.bombs)
        gameScene?.syncExplosions(state.explosions)

        // 6) таймер
        if state.state == "IN_PROGRESS", let time = state.timeRemaining {
            let clamped = max(0, time)
            let minutes = Int(clamped) / 60
            let seconds = Int(clamped) % 60
            timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
            timerLabel.isHidden = false
        } else {
            timerLabel.isHidden = true
        }

        if state.state == "GAME_OVER", !didShowGameOverOverlay {
            didShowGameOverOverlay = true
            showGameOverOverlay(winner: state.winner ?? "Unknown")
        }
    }

    // MARK: - Your UIKit renderer (почти без изменений)

    private func renderMap(_ map: [[String]]) {
        // Ничего не чистим в gameMapView — иначе ты снесёшь SKView.
        // Чистим ТОЛЬКО контейнер для тайлов.
        mapTilesView.subviews.forEach { $0.removeFromSuperview() }

        guard !map.isEmpty else { return }

        let mapHeight = map.count
        let mapWidth = map[0].count

        let availableWidth = mapTilesView.bounds.width
        let availableHeight = mapTilesView.bounds.height
        let calculatedTileWidth = availableWidth / CGFloat(mapWidth)
        let calculatedTileHeight = availableHeight / CGFloat(mapHeight)
        let finalTileSize = min(calculatedTileWidth, calculatedTileHeight)

        let totalMapWidth = CGFloat(mapWidth) * finalTileSize
        let totalMapHeight = CGFloat(mapHeight) * finalTileSize
        let offsetX = (availableWidth - totalMapWidth) / 2
        let offsetY = (availableHeight - totalMapHeight) / 2

        for y in 0..<mapHeight {
            for x in 0..<mapWidth {
                let tile = map[y][x]
                if tile == "#" {
                    renderWall(at: x, y: y, in: map, isDestroyable: false,
                               offsetX: offsetX, offsetY: offsetY, tileSize: finalTileSize)
                } else if tile == "." {
                    renderWall(at: x, y: y, in: map, isDestroyable: true,
                               offsetX: offsetX, offsetY: offsetY, tileSize: finalTileSize)
                }
            }
        }
    }

    private func renderWall(at x: Int, y: Int, in map: [[String]],
                            isDestroyable: Bool, offsetX: CGFloat, offsetY: CGFloat, tileSize: CGFloat) {
        let isHorizontal = isHorizontalWall(at: x, y: y, in: map)
        let wallImage = isHorizontal ? horizontalWallImage : verticalWallImage
        guard let wallImage else { return }

        let imageView = UIImageView(image: wallImage)
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        if isDestroyable { imageView.alpha = 0.5 }

        imageView.frame = CGRect(
            x: offsetX + CGFloat(x) * tileSize,
            y: offsetY + CGFloat(y) * tileSize,
            width: tileSize,
            height: tileSize
        )
        mapTilesView.addSubview(imageView)
    }

    private func isHorizontalWall(at x: Int, y: Int, in map: [[String]]) -> Bool {
        let mapHeight = map.count
        let mapWidth = map[0].count

        let hasLeftWall = x > 0 && map[y][x - 1] == "#"
        let hasRightWall = x < mapWidth - 1 && map[y][x + 1] == "#"
        let hasTopWall = y > 0 && map[y - 1][x] == "#"
        let hasBottomWall = y < mapHeight - 1 && map[y + 1][x] == "#"

        let horizontalNeighbors = (hasLeftWall ? 1 : 0) + (hasRightWall ? 1 : 0)
        let verticalNeighbors = (hasTopWall ? 1 : 0) + (hasBottomWall ? 1 : 0)
        return horizontalNeighbors >= verticalNeighbors
    }

    // MARK: - Utils

    private func scaleImage(_ image: UIImage, by scale: CGFloat) -> UIImage {
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func showGameOverOverlay(winner: String) {
        // Create dimming overlay
        let overlay = UIView()
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.65)
        overlay.alpha = 0
        overlay.isUserInteractionEnabled = true // block touches underneath
        view.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.overlayView = overlay

        // Winner label
        let label = UILabel()
        label.textColor = .white
        label.font = Fonts.pixelHeading
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = "Winner: \(winner)"
        overlay.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -16)
        ])

        // Animate in
        UIView.animate(withDuration: 0.25) {
            overlay.alpha = 1
        }

        // Dismiss after 3 seconds and return to lobby
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0
            }, completion: { _ in
                overlay.removeFromSuperview()
                self.overlayView = nil
                // Return to LobbyViewController
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
}
