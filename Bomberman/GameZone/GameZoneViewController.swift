//
//  GameZoneViewController.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 10.12.2025.
//

import UIKit

final class GameZoneViewController: UIViewController {
    
    private let interactor: GameZoneInteractionLogic
    private let backButton = UIButton(type: .system)
    private let gameMapView = UIView()
    
    // Кнопки управления
    private let upButton = UIButton(type: .system)
    private let downButton = UIButton(type: .system)
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    
    private var gameState: GameStateModel?
    
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
        gameState = state
        renderMap(state.map)
        print("Game state updated: \(state.state)")
    }
    
    private func renderMap(_ map: [[String]]) {
        // Удаляем все предыдущие view стен
        gameMapView.subviews.forEach { $0.removeFromSuperview() }
        
        guard !map.isEmpty else { return }
        
        let mapHeight = map.count
        let mapWidth = map[0].count
        
        // Вычисляем размер одной клетки на основе доступного пространства
        let availableWidth = gameMapView.bounds.width
        let availableHeight = gameMapView.bounds.height
        let calculatedTileWidth = availableWidth / CGFloat(mapWidth)
        let calculatedTileHeight = availableHeight / CGFloat(mapHeight)
        let finalTileSize = min(calculatedTileWidth, calculatedTileHeight)
        
        // Центрируем карту на экране
        let totalMapWidth = CGFloat(mapWidth) * finalTileSize
        let totalMapHeight = CGFloat(mapHeight) * finalTileSize
        let offsetX = (availableWidth - totalMapWidth) / 2
        let offsetY = (availableHeight - totalMapHeight) / 2
        
        for y in 0..<mapHeight {
            for x in 0..<mapWidth {
                let tile = map[y][x]
                
                if tile == "#" {
                    // Неразрушаемая стена
                    renderWall(at: x, y: y, in: map, isDestroyable: false, offsetX: offsetX, offsetY: offsetY, tileSize: finalTileSize)
                } else if tile == "." {
                    // Разрушаемая стена (тусклая)
                    renderWall(at: x, y: y, in: map, isDestroyable: true, offsetX: offsetX, offsetY: offsetY, tileSize: finalTileSize)
                }
            }
        }
    }
    
    private func renderWall(at x: Int, y: Int, in map: [[String]], isDestroyable: Bool, offsetX: CGFloat, offsetY: CGFloat, tileSize: CGFloat) {
        // Определяем, горизонтальная или вертикальная стена
        let isHorizontal = isHorizontalWall(at: x, y: y, in: map)
        let imageName = isHorizontal ? "horizontal_wall" : "vertical_wall"
        
        guard let wallImage = UIImage(named: imageName) else { return }
        
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
}

