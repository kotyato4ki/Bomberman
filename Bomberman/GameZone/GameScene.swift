import SpriteKit
import UIKit

public final class GameScene: SKScene {

    // VC сюда подкидывает карту для проверки проходимости/разрушения
    private var collisionMap: [[String]] = []

    // Геометрия грида приходит из VC (чтобы совпадало 1-в-1 с UIKit)
    private var rows: Int = 0
    private var cols: Int = 0
    private var tileSize: CGSize = .zero

    // origin в координатах UIKit view (top-left), а SpriteKit — bottom-left
    private var originInView: CGPoint = .zero
    private var viewSize: CGSize = .zero

    // Игрок в координатах грида (x,y как в map[y][x])
    private var playerGrid = CGPoint(x: 1, y: 1)

    private var player = SKSpriteNode()
    private var hasPlayer = false

    // Прочие игроки (по id)
    private var otherPlayerNodes: [String: SKSpriteNode] = [:]

    public var onMapChanged: (([[String]]) -> Void)?
    
    // Бомба и взрыв
    private var bombNodes: [String: SKSpriteNode] = [:]
    private var animatedExplosions = Set<String>()  // чтобы не переигрывать одно и то же

    public override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupPlayerIfNeeded()
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // VC всё равно дернёт setGridLayout на layoutSubviews, тут можно не дергаться
        syncPlayerPosition(animated: false)
    }

    // MARK: - VC -> Scene

    func setGridLayout(rows: Int,
                              cols: Int,
                              tileSize: CGSize,
                              originInViewCoords: CGPoint,
                              viewSize: CGSize) {
        self.rows = rows
        self.cols = cols
        self.tileSize = tileSize
        self.originInView = originInViewCoords
        self.viewSize = viewSize

        setupPlayerIfNeeded()
        syncPlayerPosition(animated: false)
    }

     func updateCollisionMap(_ map: [[String]]) {
        collisionMap = map
        if !hasPlayer {
            playerGrid = findFirstWalkable(in: map)
            hasPlayer = true
        } else if !isWalkable(x: Int(playerGrid.x), y: Int(playerGrid.y)) {
            playerGrid = findFirstWalkable(in: map)
        }
        syncPlayerPosition(animated: false)
    }

    func setPlayerGridPosition(x: Int, y: Int) {
        playerGrid = CGPoint(x: x, y: y)
        syncPlayerPosition(animated: false)
    }

    // MARK: - Movement

    func move(dx: Int, dy: Int) {
        guard rows > 0, cols > 0 else { return }

        let newX = Int(playerGrid.x) + dx
        let newY = Int(playerGrid.y) + dy

        guard isWalkable(x: newX, y: newY) else { return }

        playerGrid = CGPoint(x: newX, y: newY)
        syncPlayerPosition(animated: true)
    }

    // MARK: - Bombs / Explosions

    func placeBomb() {
        guard tileSize != .zero else { return }

        let bomb = SKSpriteNode(imageNamed: "bomb")
        bomb.size = CGSize(width: tileSize.width * 0.8, height: tileSize.height * 0.8)
        bomb.position = pointForCell(x: Int(playerGrid.x), y: Int(playerGrid.y))
        bomb.zPosition = 20
        addChild(bomb)

        let wait = SKAction.wait(forDuration: 1.2)

        let explode = SKAction.run { [weak self, weak bomb] in
            guard let self, let bomb else { return }
            self.runExplosion(at: bomb.position)
            bomb.removeFromParent()

            // Ломаем разрушаемые стены в collisionMap и сообщаем VC
            self.clearDestroyableWalls(fromX: Int(self.playerGrid.x), y: Int(self.playerGrid.y))
        }

        bomb.run(.sequence([wait, explode]))
    }
    
    func syncBombs(_ bombs: [BombModel]) {
        guard tileSize != .zero else { return }

        var alive = Set<String>()

        for b in bombs {
            let key = cellKey(x: b.x, y: b.y)
            alive.insert(key)

            let node = bombNodes[key] ?? {
                let n = SKSpriteNode(imageNamed: "bomb")
                n.size = CGSize(width: tileSize.width * 0.8, height: tileSize.height * 0.8)
                n.zPosition = 20
                addChild(n)
                bombNodes[key] = n
                return n
            }()

            node.position = pointForCell(x: b.x, y: b.y)
            node.isHidden = false
            node.alpha = 1
            node.setScale(1)
        }

        // удалить бомбы, которых больше нет в состоянии
        for (key, node) in bombNodes where !alive.contains(key) {
            node.removeFromParent()
            bombNodes.removeValue(forKey: key)
        }
    }
    
    func syncExplosions(_ explosions: [ExplosionModel]) {
        guard tileSize != .zero else { return }

        // Взрыв без id = ключ по клетке. Криво, но живём.
        // Анимация запускается только когда ключ впервые появляется.
        for e in explosions {
            let key = cellKey(x: e.x, y: e.y)
            guard !animatedExplosions.contains(key) else { continue }
            animatedExplosions.insert(key)

            // если на этой клетке есть бомба — можно убрать сразу (чисто визуально)
            if let bomb = bombNodes[key] {
                bomb.removeFromParent()
                bombNodes.removeValue(forKey: key)
            }

            runExplosion(atCellX: e.x, y: e.y)
        }

        // ЧИСТКА: если взрывов больше нет в состоянии, разрешаем анимировать клетку снова.
        // Иначе повторный взрыв на той же клетке никогда не покажется.
        let current = Set(explosions.map { cellKey(x: $0.x, y: $0.y) })
        animatedExplosions = animatedExplosions.intersection(current)
    }
    
    // MARK: - Name labels helpers

    private func nameFontSize() -> CGFloat {
        guard tileSize != .zero else { return 20 }
        return max(16, min(tileSize.height * 0.75, 52))
    }

    private func makeNameLabel() -> SKLabelNode {
        let label = SKLabelNode()
        label.name = "nameLabel"
        label.zPosition = 999            // чтобы всегда поверх
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .bottom
        label.alpha = 1                  // на всякий
        label.isUserInteractionEnabled = false
        return label
    }

    private func updateNameLabelLayout(for node: SKSpriteNode) {
        guard let label = node.childNode(withName: "nameLabel") as? SKLabelNode else { return }
        label.fontSize = nameFontSize()
        // позиция над спрайтом
        let offsetY = node.size.height / 2 + 6
        label.position = CGPoint(x: 0, y: offsetY)
    }

    private func setName(_ name: String, for node: SKSpriteNode) {
        let label: SKLabelNode
        if let existing = node.childNode(withName: "nameLabel") as? SKLabelNode {
            label = existing
        } else {
            let created = makeNameLabel()
            node.addChild(created)
            label = created
        }

        let size = nameFontSize()
        let font = Fonts.pixelify(size)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -5   // было -3, сделаем “пожирнее”
        ]

        label.attributedText = NSAttributedString(string: name, attributes: attrs)
        updateNameLabelLayout(for: node)
    }
    
    // MARK: - Players sync (multi-player rendering)

    func syncPlayers(_ players: [PlayerModel], myId: String?) {
        guard tileSize != .zero else { return }

        // 1) Мой игрок (если id известен) — обновляем основного `player`
        if let myId, let me = players.first(where: { $0.id == myId }) {
            setPlayerGridPosition(x: me.x, y: me.y)
            player.isHidden = !me.alive
            setName(me.name, for: player)
            updateNameLabelLayout(for: player)
        } else if let first = players.first { // fallback: первый в списке
            setPlayerGridPosition(x: first.x, y: first.y)
            player.isHidden = !first.alive
            setName(first.name, for: player)
            updateNameLabelLayout(for: player)
        }

        // 2) Остальные игроки — отдельные спрайты
        var stillPresent = Set<String>()
        for p in players {
            if p.id == myId { continue }
            stillPresent.insert(p.id)

            let node: SKSpriteNode = otherPlayerNodes[p.id] ?? {
                let n = makeOtherPlayerNode()
                addChild(n)
                otherPlayerNodes[p.id] = n
                return n
            }()

            node.size = tileSize
            setName(p.name, for: node)
            updateNameLabelLayout(for: node)
            node.position = pointForCell(x: p.x, y: p.y)
            node.zPosition = 45
            node.isHidden = !p.alive

            // Запустить анимацию, если не запущена
            if node.action(forKey: "idle") == nil {
                runIdleAnimation(on: node)
            }
        }

        // 3) Удалить те, кого больше нет
        for (id, node) in otherPlayerNodes where !stillPresent.contains(id) {
            node.removeFromParent()
            otherPlayerNodes.removeValue(forKey: id)
        }
    }
    
    private func runExplosion(atCellX x: Int, y: Int) {
        let boom = SKSpriteNode(imageNamed: "explosion")
        boom.position = pointForCell(x: x, y: y)
        boom.size = tileSize
        boom.zPosition = 30
        addChild(boom)

        let scale = SKAction.scale(to: 1.6, duration: 0.12)
        let fade = SKAction.fadeOut(withDuration: 0.18)
        let group = SKAction.group([scale, fade])
        boom.run(.sequence([group, .removeFromParent()]))
    }

    private func runExplosion(at position: CGPoint) {
        // Самый простой вариант: один спрайт + масштаб + исчезновение
        let boom = SKSpriteNode(imageNamed: "explosion")
        boom.position = position
        boom.size = tileSize
        boom.zPosition = 30
        addChild(boom)

        let scale = SKAction.scale(to: 1.6, duration: 0.12)
        let fade = SKAction.fadeOut(withDuration: 0.18)
        let group = SKAction.group([scale, fade])
        boom.run(.sequence([group, .removeFromParent()]))
    }

    // MARK: - Player setup / animation
    
    private func cellKey(x: Int, y: Int) -> String { "\(x):\(y)" }

    private func setupPlayerIfNeeded() {
        guard !hasPlayer else { return }

        player = SKSpriteNode(imageNamed: "priest2_v1_1")
        player.zPosition = 50
        player.size = tileSize == .zero ? CGSize(width: 32, height: 32) : tileSize
        addChild(player)
        // Имя моего игрока добавим при syncPlayers, но сразу подготовим лейбл
        let nameLabel = makeNameLabel()
        player.addChild(nameLabel)
        updateNameLabelLayout(for: player)

        hasPlayer = true
        runIdleAnimation()
    }

    private func makeOtherPlayerNode() -> SKSpriteNode {
        let n = SKSpriteNode(imageNamed: "priest2_v1_1")
        n.color = .orange
        n.colorBlendFactor = 0.45 // легкий оттенок, чтобы отличать соперников
        n.zPosition = 45
        n.size = tileSize == .zero ? CGSize(width: 32, height: 32) : tileSize
        let label = makeNameLabel()
        n.addChild(label)
        updateNameLabelLayout(for: n)
        return n
    }

    private func runIdleAnimation() {
        runIdleAnimation(on: player)
    }

    private func runIdleAnimation(on node: SKSpriteNode) {
        var frames: [SKTexture] = []
        let base = "priest2_v1_"
        for i in 1...4 {
            let tex = SKTexture(imageNamed: "\(base)\(i)")
            if tex.size() != .zero { frames.append(tex) }
        }
        guard !frames.isEmpty else { return }

        let forward = SKAction.animate(with: frames, timePerFrame: 0.12)
        let reverse = SKAction.animate(with: Array(frames.dropFirst().dropLast().reversed()), timePerFrame: 0.20)
        node.run(.repeatForever(.sequence([forward, reverse])), withKey: "idle")
    }

    // MARK: - Positioning (важно: совпадение с UIKit)

    private func syncPlayerPosition(animated: Bool) {
        guard tileSize != .zero else { return }
        let p = pointForCell(x: Int(playerGrid.x), y: Int(playerGrid.y))

        player.size = tileSize
        updateNameLabelLayout(for: player)

        if animated {
            let a = SKAction.move(to: p, duration: 0.10)
            a.timingMode = .easeInEaseOut
            player.run(a)
        } else {
            player.position = p
        }
    }

    private func pointForCell(x: Int, y: Int) -> CGPoint {
        // UIKit: originInView — сверху-слева, y растет вниз.
        // SpriteKit: (0,0) снизу-слева, y растет вверх.
        // Поэтому переворачиваем Y.

        let centerXInView = originInView.x + CGFloat(x) * tileSize.width + tileSize.width / 2
        let centerYInView = originInView.y + CGFloat(y) * tileSize.height + tileSize.height / 2

        let spriteKitY = viewSize.height - centerYInView
        return CGPoint(x: centerXInView, y: spriteKitY)
    }

    // MARK: - Walkability & destruction

    private func isWalkable(x: Int, y: Int) -> Bool {
        guard y >= 0, y < collisionMap.count else { return false }
        guard x >= 0, x < collisionMap[y].count else { return false }
        let cell = collisionMap[y][x]
        return cell != "#" && cell != "."
    }

    private func findFirstWalkable(in map: [[String]]) -> CGPoint {
        let r = map.count
        let c = map.first?.count ?? 0
        for y in 0..<r {
            for x in 0..<c {
                let cell = map[y][x]
                if cell != "#" && cell != "." {
                    return CGPoint(x: x, y: y)
                }
            }
        }
        return CGPoint(x: 0, y: 0)
    }

    private func clearDestroyableWalls(fromX x: Int, y: Int) {
        guard !collisionMap.isEmpty else { return }

        func clearIfDestroyable(_ xx: Int, _ yy: Int) {
            guard yy >= 0, yy < collisionMap.count else { return }
            guard xx >= 0, xx < collisionMap[yy].count else { return }
            if collisionMap[yy][xx] == "." { collisionMap[yy][xx] = " " }
        }

        // центр + крест (можешь расширять дальность как хочешь)
        clearIfDestroyable(x, y)
        clearIfDestroyable(x, y - 1)
        clearIfDestroyable(x, y + 1)
        clearIfDestroyable(x - 1, y)
        clearIfDestroyable(x + 1, y)

        onMapChanged?(collisionMap)
    }
}

