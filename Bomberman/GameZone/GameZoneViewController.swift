//
//  GameZoneViewController.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import UIKit
import SpriteKit

final class GameZoneViewController: UIViewController {
    
    private let interactor: GameZoneInteractionLogic
    private let backButton = UIButton(type: .system)
    private let gameMapView = UIView()
    private let spriteKitView = SKView()
    
    // Кнопки управления
    private let upButton = UIButton(type: .system)
    private let downButton = UIButton(type: .system)
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    
    private var gameState: GameStateModel?
    private var localMap: [[String]]? // Локальная копия карты для отслеживания изменений
    private var wallViews: [String: UIView] = [:] // Храним view стен для удаления
    private var autoExplosionTimer: Timer?
    private var tileSize: CGFloat = 0
    private var offsetX: CGFloat = 0
    private var offsetY: CGFloat = 0
    
    init(interactor: GameZoneInteractionLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Создаем паттерн из картинки gamezone, увеличенной в 2.5 раза
        if let originalImage = UIImage(named: "gamezone") {
            let scaledImage = scaleImage(originalImage, by: 2.5)
            let patternColor = UIColor(patternImage: scaledImage)
            view.backgroundColor = patternColor
        } else {
            view.backgroundColor = Colors.background
        }
        
        configureUI()
        configureCallbacks()
        setupAutoExplosionTimer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Перерисовываем карту при изменении размеров view
        if let state = gameState {
            renderMap(state.map)
        }
    }
    
    deinit {
        interactor.updateGameStateDeinit()
        autoExplosionTimer?.invalidate()
    }
    
    @objc
    private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func configureUI() {
        configureBackButton()
        configureGameMapView()
        configureControlButtons()
    }
    
    private func configureGameMapView() {
        gameMapView.backgroundColor = .clear
        view.addSubview(gameMapView)
        gameMapView.pinTop(to: view.topAnchor)
        gameMapView.pinLeft(to: view.leadingAnchor)
        gameMapView.pinRight(to: view.trailingAnchor)
        gameMapView.pinBottom(to: view.bottomAnchor)
        
        // Настраиваем SpriteKit view для анимаций
        spriteKitView.backgroundColor = .clear
        spriteKitView.allowsTransparency = true
        spriteKitView.isUserInteractionEnabled = false
        view.addSubview(spriteKitView)
        spriteKitView.pinTop(to: view.topAnchor)
        spriteKitView.pinLeft(to: view.leadingAnchor)
        spriteKitView.pinRight(to: view.trailingAnchor)
        spriteKitView.pinBottom(to: view.bottomAnchor)
        
        let scene = SKScene(size: view.bounds.size)
        scene.backgroundColor = .clear
        spriteKitView.presentScene(scene)
    }
    
    private func setupAutoExplosionTimer() {
        autoExplosionTimer?.invalidate()
        autoExplosionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let state = self.gameState else {
                print("Timer tick: no game state")
                return
            }
            // Запускаем взрывы для любых состояний, где есть карта
            print("Timer tick: attempting to explode wall, state: \(state.state)")
            self.explodeRandomWall()
        }
        // Запускаем первый взрыв сразу для теста
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self,
                  self.gameState != nil else { return }
            print("First explosion test")
            self.explodeRandomWall()
        }
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
        // Добавляем кнопку назад поверх игрового поля
        view.bringSubviewToFront(backButton)
    }
    
    private func configureControlButtons() {
        let spacing: CGFloat = 5 // Уменьшено расстояние между кнопками
        let buttonMargin: CGFloat = 5 // Сдвинуто левее
        
        // Получаем размер изображения после масштабирования (увеличение в 10 раз: 2.0 * 5)
        guard let arrowImage = UIImage(named: "arrow") else { return }
        let scaledImage = scaleImage(arrowImage, by: 10.0)
        let buttonSize = max(scaledImage.size.width, scaledImage.size.height)
        
        // Настраиваем кнопки со стрелками
        // Базовая картинка показывает стрелку вниз
        setupArrowButton(upButton, rotation: 0) // вверх (поворот на 180°)
        setupArrowButton(downButton, rotation: .pi) // вниз (без поворота)
        setupArrowButton(leftButton, rotation: -.pi / 2) // влево (поворот на -90°)
        setupArrowButton(rightButton, rotation: .pi / 2) // вправо (поворот на 90°)
        
        // Добавляем на view с размером изображения
        [upButton, downButton, leftButton, rightButton].forEach {
            view.addSubview($0)
            $0.setWidth(buttonSize)
            $0.setHeight(buttonSize)
            // Делаем contentMode fit, чтобы изображение не обрезалось
            $0.imageView?.contentMode = .scaleAspectFit
            // Делаем кнопки более прозрачными
            $0.alpha = 0.2
        }
        
        // Располагаем кнопки в форме креста в правом нижнем углу
        // Центральная позиция по горизонтали (отступ от правого края)
        let centerOffset = buttonMargin + buttonSize / 2
        
        // Вниз (центральная кнопка внизу)
        downButton.pinRight(to: view.safeAreaLayoutGuide.trailingAnchor, buttonMargin + 50)
        downButton.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, buttonMargin)
        
        // Вверх (над кнопкой вниз) - привязываем низ upButton к верху downButton
        upButton.pinRight(to: view.safeAreaLayoutGuide.trailingAnchor, buttonMargin + 50)
        upButton.pinBottom(to: downButton.topAnchor, -spacing)
        
        // Влево (слева от центральных кнопок)
        leftButton.pinRight(to: upButton.leadingAnchor, -spacing - 25)
        leftButton.pinCenterY(to: upButton.centerYAnchor, 35)
        
        // Вправо (справа от центральных кнопок)
        rightButton.pinLeft(to: upButton.trailingAnchor, spacing - 35)
        rightButton.pinCenterY(to: upButton.centerYAnchor, 35)
        
        // Подключаем обработчики
        upButton.addTarget(self, action: #selector(upButtonTapped), for: .touchUpInside)
        downButton.addTarget(self, action: #selector(downButtonTapped), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        
        // Добавляем кнопки поверх игрового поля
        [upButton, downButton, leftButton, rightButton].forEach {
            view.bringSubviewToFront($0)
        }
    }
    
    private func setupArrowButton(_ button: UIButton, rotation: CGFloat) {
        guard let arrowImage = UIImage(named: "arrow") else { return }
        
        // Увеличиваем изображение в 10 раз (2.0 * 5)
        let scale: CGFloat = 10.0
        let scaledImage = scaleImage(arrowImage, by: scale)
        
        // Поворачиваем изображение стрелки
        let rotatedImage = rotateImage(scaledImage, by: rotation)
        button.setImage(rotatedImage, for: .normal)
        button.tintColor = .white
        // Убираем фон и рамку - только картинка
        button.backgroundColor = .clear
    }
    
    private func rotateImage(_ image: UIImage, by radians: CGFloat) -> UIImage {
        // Для поворотов на 90° или 270° меняем размеры местами
        let isQuarterTurn = abs(radians - .pi / 2) < 0.01 || abs(radians + .pi / 2) < 0.01
        let rotatedSize = isQuarterTurn 
            ? CGSize(width: image.size.height, height: image.size.width)
            : image.size
        
        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            cgContext.rotate(by: radians)
            cgContext.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
            
            if let cgImage = image.cgImage {
                cgContext.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
            }
        }.withRenderingMode(.alwaysTemplate)
    }
    
    @objc private func upButtonTapped() {
        interactor.sendMove(dx: 0, dy: -1)
    }
    
    @objc private func downButtonTapped() {
        interactor.sendMove(dx: 0, dy: 1)
    }
    
    @objc private func leftButtonTapped() {
        interactor.sendMove(dx: -1, dy: 0)
    }
    
    @objc private func rightButtonTapped() {
        interactor.sendMove(dx: 1, dy: 0)
    }
    
    
    private func configureCallbacks() {
        interactor.configureCallbacks()
    }
    
    private func scaleImage(_ image: UIImage, by scale: CGFloat) -> UIImage {
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func updateGameState(_ state: GameStateModel) {
        let isFirstUpdate = gameState == nil
        
        gameState = state
        
        // Инициализируем локальную карту при первом обновлении
        if localMap == nil {
            localMap = state.map.map { $0.map { String($0) } } // Глубокая копия
        }
        
        renderMap(state.map)
        
        // Запускаем таймер при первом обновлении или если он еще не запущен
        if isFirstUpdate || autoExplosionTimer == nil {
            print("Setting up auto explosion timer, state: \(state.state)")
            setupAutoExplosionTimer()
        }
        
        print("Game state updated: \(state.state), walls count: \(wallViews.count)")
    }
    
    private func renderMap(_ map: [[String]]) {
        // Используем локальную карту, если она есть, иначе серверную
        let mapToRender = localMap ?? map
        
        // Удаляем все предыдущие view стен только если карта изменилась
        if localMap == nil || mapToRender != map {
            gameMapView.subviews.forEach { $0.removeFromSuperview() }
            wallViews.removeAll()
        }
        
        guard !mapToRender.isEmpty else { return }
        
        let mapHeight = mapToRender.count
        let mapWidth = mapToRender[0].count
        
        // Вычисляем размер одной клетки на основе доступного пространства
        let availableWidth = gameMapView.bounds.width
        let availableHeight = gameMapView.bounds.height
        let calculatedTileWidth = availableWidth / CGFloat(mapWidth)
        let calculatedTileHeight = availableHeight / CGFloat(mapHeight)
        tileSize = min(calculatedTileWidth, calculatedTileHeight)
        
        // Центрируем карту на экране
        let totalMapWidth = CGFloat(mapWidth) * tileSize
        let totalMapHeight = CGFloat(mapHeight) * tileSize
        offsetX = (availableWidth - totalMapWidth) / 2
        offsetY = (availableHeight - totalMapHeight) / 2
        
        // Рисуем стены только если их еще нет
        for y in 0..<mapHeight {
            for x in 0..<mapWidth {
                let tile = mapToRender[y][x]
                let key = "\(x),\(y)"
                
                // Проверяем, существует ли уже view для этой стены
                if wallViews[key] != nil {
                    continue // Пропускаем, если уже нарисована
                }
                
                if tile == "#" {
                    // Неразрушаемая стена
                    renderWall(at: x, y: y, in: mapToRender, isDestroyable: false, offsetX: offsetX, offsetY: offsetY, tileSize: tileSize)
                } else if tile == "." {
                    // Разрушаемая стена (тусклая)
                    if let wallView = renderWall(at: x, y: y, in: mapToRender, isDestroyable: true, offsetX: offsetX, offsetY: offsetY, tileSize: tileSize) {
                        wallViews[key] = wallView
                    }
                }
            }
        }
    }
    
    @discardableResult
    private func renderWall(at x: Int, y: Int, in map: [[String]], isDestroyable: Bool, offsetX: CGFloat, offsetY: CGFloat, tileSize: CGFloat) -> UIView? {
        // Определяем, горизонтальная или вертикальная стена
        let isHorizontal = isHorizontalWall(at: x, y: y, in: map)
        let imageName = isHorizontal ? "horizontal_wall" : "vertical_wall"
        
        guard let wallImage = UIImage(named: imageName) else { return nil }
        
        let imageView = UIImageView(image: wallImage)
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        
        // Если стена разрушаемая, делаем её тусклее (применяем альфа-канал)
        if isDestroyable {
            imageView.alpha = 0.5 // Делаем тусклее с помощью прозрачности
        }
        
        imageView.frame = CGRect(
            x: offsetX + CGFloat(x) * tileSize,
            y: offsetY + CGFloat(y) * tileSize,
            width: tileSize,
            height: tileSize
        )
        gameMapView.addSubview(imageView)
        return imageView
    }
    
    private func isHorizontalWall(at x: Int, y: Int, in map: [[String]]) -> Bool {
        let mapHeight = map.count
        let mapWidth = map[0].count
        
        // Проверяем соседние клетки
        let hasLeftWall = x > 0 && map[y][x - 1] == "#"
        let hasRightWall = x < mapWidth - 1 && map[y][x + 1] == "#"
        let hasTopWall = y > 0 && map[y - 1][x] == "#"
        let hasBottomWall = y < mapHeight - 1 && map[y + 1][x] == "#"
        
        // Если стена имеет соседей слева/справа, это горизонтальная стена
        // Если стена имеет соседей сверху/снизу, это вертикальная стена
        // Если имеет соседей в обоих направлениях, проверяем преобладающее направление
        let horizontalNeighbors = (hasLeftWall ? 1 : 0) + (hasRightWall ? 1 : 0)
        let verticalNeighbors = (hasTopWall ? 1 : 0) + (hasBottomWall ? 1 : 0)
        
        // Если горизонтальных соседей больше или равно, считаем горизонтальной
        return horizontalNeighbors >= verticalNeighbors
    }
    
    private func explodeRandomWall() {
        guard let map = gameState?.map, !map.isEmpty else {
            print("explodeRandomWall: no map")
            return
        }
        
        // Находим все разрушаемые стены в текущей карте
        var destroyableWalls: [(x: Int, y: Int)] = []
        for y in 0..<map.count {
            for x in 0..<map[0].count {
                if map[y][x] == "." {
                    destroyableWalls.append((x: x, y: y))
                }
            }
        }
        
        print("explodeRandomWall: found \(destroyableWalls.count) destroyable walls, wallViews count = \(wallViews.count)")
        
        guard !destroyableWalls.isEmpty else {
            print("explodeRandomWall: no destroyable walls found")
            return
        }
        
        // Выбираем случайную стену
        let randomWall = destroyableWalls.randomElement()!
        print("explodeRandomWall: selected wall at (\(randomWall.x), \(randomWall.y))")
        
        // Воспроизводим анимацию взрыва
        playExplosionAnimation(at: randomWall.x, y: randomWall.y) { [weak self] in
            // После анимации удаляем стену
            self?.removeWall(at: randomWall.x, y: randomWall.y)
        }
    }
    
    private func playExplosionAnimation(at x: Int, y: Int, completion: @escaping () -> Void) {
        guard let scene = spriteKitView.scene else {
            print("playExplosionAnimation: no scene")
            return
        }
        
        print("playExplosionAnimation: at (\(x), \(y))")
        
        // Создаем текстуры для анимации
        var textures: [SKTexture] = []
        for i in 1...8 {
            let textureName = "exp\(i)"
            // Проверяем, существует ли изображение в bundle
            if UIImage(named: textureName) != nil {
                let texture = SKTexture(imageNamed: textureName)
                textures.append(texture)
            } else {
                print("playExplosionAnimation: texture \(textureName) not found")
            }
        }
        
        print("playExplosionAnimation: loaded \(textures.count) textures")
        
        guard !textures.isEmpty else {
            print("playExplosionAnimation: no textures loaded")
            completion()
            return
        }
        
        // Создаем спрайт (увеличен в 1.5 раза)
        let sprite = SKSpriteNode(texture: textures[0])
        sprite.size = CGSize(width: tileSize * 1.5, height: tileSize * 1.5)
        
        // Позиция в координатах экрана (SpriteKit использует систему координат с началом внизу слева)
        let screenX = offsetX + CGFloat(x) * tileSize + tileSize / 2
        let screenY = view.bounds.height - (offsetY + CGFloat(y) * tileSize + tileSize / 2)
        sprite.position = CGPoint(x: screenX, y: screenY)
        sprite.zPosition = 100 // Поверх других элементов
        
        print("playExplosionAnimation: sprite position = (\(screenX), \(screenY)), tileSize = \(tileSize)")
        
        scene.addChild(sprite)
        
        // Анимация
        let animateAction = SKAction.animate(with: textures, timePerFrame: 0.1)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([animateAction, removeAction])
        
        sprite.run(sequence) {
            print("playExplosionAnimation: animation completed")
            completion()
        }
    }
    
    private func removeWall(at x: Int, y: Int) {
        print("removeWall: attempting to remove wall at (\(x), \(y))")
        
        // Обновляем локальную карту
        if var local = localMap, x < local[0].count, y < local.count, local[y][x] == "." {
            local[y][x] = " "
            localMap = local
            print("removeWall: updated local map at (\(x), \(y))")
        }
        
        // Удаляем view стены
        let key = "\(x),\(y)"
        if let wallView = wallViews[key] {
            print("removeWall: found wall view, removing")
            UIView.animate(withDuration: 0.2, animations: {
                wallView.alpha = 0
            }) { _ in
                wallView.removeFromSuperview()
                print("removeWall: wall view removed from superview")
            }
            wallViews.removeValue(forKey: key)
        } else {
            print("removeWall: wall view not found for key \(key), trying to find by frame")
            // Попробуем найти и удалить view стены напрямую через координаты
            let wallFrame = CGRect(
                x: offsetX + CGFloat(x) * tileSize,
                y: offsetY + CGFloat(y) * tileSize,
                width: tileSize,
                height: tileSize
            )
            
            // Ищем все subviews в этой области
            for subview in gameMapView.subviews {
                if abs(subview.frame.midX - wallFrame.midX) < 5 && 
                   abs(subview.frame.midY - wallFrame.midY) < 5 && 
                   abs(subview.alpha - 0.5) < 0.1 {
                    print("removeWall: found wall by frame, removing")
                    UIView.animate(withDuration: 0.2, animations: {
                        subview.alpha = 0
                    }) { _ in
                        subview.removeFromSuperview()
                    }
                    break
                }
            }
        }
    }
}

