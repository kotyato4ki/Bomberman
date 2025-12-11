import SpriteKit
import UIKit

public class GameScene: SKScene {
    private var map: [[String]] = []
    private var tileSize: CGSize = .zero
    private var mapNode = SKNode()
    private var player = SKSpriteNode()
    private var playerGridPosition = CGPoint(x: 1, y: 1)
    private var idleAction: SKAction?

    private let wallCategory: UInt32 = 0x1 << 1
    private let bombCategory: UInt32 = 0x1 << 2
    private let playerCategory: UInt32 = 0x1 << 3

    public override func didMove(to view: SKView) {
        backgroundColor = .clear
        addChild(mapNode)
        setupPlayerIfNeeded()
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutMap()
    }

    public func updateMap(_ newMap: [[String]]) {
        map = newMap

        // Find a walkable cell from top-left to bottom-right
        var foundPosition: CGPoint? = nil
        outer: for y in 0..<map.count {
            for x in 0..<map[y].count {
                if map[y][x] != "#" {
                    foundPosition = CGPoint(x: x, y: y)
                    break outer
                }
            }
        }
        playerGridPosition = foundPosition ?? CGPoint(x: 1, y: 1)
        layoutMap()
    }

    private func layoutMap() {
        mapNode.removeAllChildren()

        guard !map.isEmpty, let scene = scene else { return }
        guard let firstRow = map.first else { return }

        let rows = map.count
        let columns = firstRow.count

        let tileWidth = floor(scene.size.width / CGFloat(columns))
        let tileHeight = floor(scene.size.height / CGFloat(rows))
        let size = min(tileWidth, tileHeight)
        tileSize = CGSize(width: size, height: size)

        let totalWidth = size * CGFloat(columns)
        let totalHeight = size * CGFloat(rows)
        let originX = (scene.size.width - totalWidth) / 2.0
        let originY = (scene.size.height - totalHeight) / 2.0
        let origin = CGPoint(x: originX, y: originY)

        for y in 0..<rows {
            for x in 0..<columns {
                let cell = map[y][x]
                // Walls: "#" is wall, "." is destroyable wall
                guard cell == "#" || cell == "." else { continue }

                let isHorizontal = isHorizontalWall(x: x, y: y)
                var texture: SKTexture?

                if isHorizontal {
                    texture = SKTexture(imageNamed: "horizontal_wall")
                } else {
                    texture = SKTexture(imageNamed: "vertical_wall")
                }

                let node: SKSpriteNode
                if let tex = texture {
                    node = SKSpriteNode(texture: tex)
                } else {
                    node = SKSpriteNode(color: .brown, size: tileSize)
                }

                if cell == "." {
                    node.alpha = 0.5
                } else {
                    node.alpha = 1.0
                }

                node.size = tileSize
                node.position = positionForCell(x: x, y: y, tileSize: tileSize, origin: origin)
                node.zPosition = 1
                mapNode.addChild(node)
            }
        }

        // Place or reposition player
        if player.parent == nil {
            setupPlayerIfNeeded()
            addChild(player)
        }
        player.size = tileSize
        player.position = positionForCell(x: Int(playerGridPosition.x), y: Int(playerGridPosition.y), tileSize: tileSize, origin: origin)
    }

    private func isHorizontalWall(x: Int, y: Int) -> Bool {
        // Returns true if the wall at (x,y) should be drawn as horizontal
        // Only '#' count as walls here

        guard y >= 0, y < map.count, x >= 0, x < map[y].count else { return false }
        guard map[y][x] == "#" || map[y][x] == "." else { return false }

        let isWall: (Int, Int) -> Bool = { xx, yy in
            guard yy >= 0, yy < self.map.count, xx >= 0, xx < self.map[yy].count else { return false }
            return self.map[yy][xx] == "#"
        }

        let left = isWall(x - 1, y)
        let right = isWall(x + 1, y)
        let up = isWall(x, y - 1)
        let down = isWall(x, y + 1)

        // If left or right is wall and (up and down are not both walls) -> horizontal
        if (left || right) && !(up && down) {
            return true
        }
        return false
    }

    private func positionForCell(x: Int, y: Int, tileSize: CGSize, origin: CGPoint) -> CGPoint {
        // SpriteKit's coordinate system: (0,0) bottom-left
        // We want the center of the cell
        let posX = origin.x + (CGFloat(x) * tileSize.width) + tileSize.width / 2
        let posY = origin.y + (CGFloat(map.count - 1 - y) * tileSize.height) + tileSize.height / 2
        return CGPoint(x: posX, y: posY)
    }

    private func setupPlayerIfNeeded() {
        if player.parent == nil {
            if let texture = SKTexture(imageNamed: "priest2_v1_1").cgImage() != nil ? SKTexture(imageNamed: "priest2_v1_1") : nil {
                player = SKSpriteNode(texture: texture)
            } else {
                player = SKSpriteNode(color: .white, size: tileSize)
            }
            player.zPosition = 10
            player.size = tileSize
            player.physicsBody = SKPhysicsBody(rectangleOf: tileSize)
            player.physicsBody?.categoryBitMask = playerCategory
            player.physicsBody?.collisionBitMask = 0
            player.physicsBody?.contactTestBitMask = 0
            addChild(player)
            buildAndRunIdleAnimation()
        }
    }

    private func buildAndRunIdleAnimation() {
        var frames: [SKTexture] = []
        let baseName = "priest2_v1_"
        for i in 1...4 {
            let name = "\(baseName)\(i)"
            if let img = UIImage(named: name) {
                frames.append(SKTexture(image: img))
            } else if let tex = SKTexture(imageNamed: name), tex.size() != .zero {
                frames.append(tex)
            }
        }
        guard !frames.isEmpty else { return }

        // Forward frames
        let forward = SKAction.animate(with: frames, timePerFrame: 0.15)
        // Reverse frames excluding first and last to prevent duplicate frames in ping-pong
        let reverseFrames = frames.dropFirst().dropLast().reversed()
        let reverse = SKAction.animate(with: Array(reverseFrames), timePerFrame: 0.15)
        let sequence = SKAction.sequence([forward, reverse])
        let repeatForever = SKAction.repeatForever(sequence)

        idleAction = repeatForever
        player.run(repeatForever, withKey: "idleAnimation")
    }

    public func move(dx: Int, dy: Int) {
        guard !map.isEmpty else { return }
        let rows = map.count
        let columns = map[0].count
        let newX = Int(playerGridPosition.x) + dx
        let newY = Int(playerGridPosition.y) + dy

        if newX < 0 || newX >= columns || newY < 0 || newY >= rows {
            return
        }
        let cell = map[newY][newX]
        if cell == "#" || cell == "." {
            return
        }

        playerGridPosition = CGPoint(x: newX, y: newY)

        // Compute new position with current tileSize and origin
        guard let scene = scene else { return }
        let totalWidth = tileSize.width * CGFloat(columns)
        let totalHeight = tileSize.height * CGFloat(rows)
        let originX = (scene.size.width - totalWidth) / 2.0
        let originY = (scene.size.height - totalHeight) / 2.0
        let origin = CGPoint(x: originX, y: originY)

        let newPos = positionForCell(x: newX, y: newY, tileSize: tileSize, origin: origin)

        let moveAction = SKAction.move(to: newPos, duration: 0.12)
        moveAction.timingMode = .easeInEaseOut
        player.run(moveAction)
    }

    public func placeBomb() {
        guard let scene = scene else { return }
        let columns = map.first?.count ?? 0
        let rows = map.count
        guard columns > 0, rows > 0 else { return }

        // Position bomb at player's cell
        let bombNode: SKSpriteNode
        if let bombTexture = SKTexture(imageNamed: "bomb").cgImage() != nil ? SKTexture(imageNamed: "bomb") : nil {
            bombNode = SKSpriteNode(texture: bombTexture)
        } else {
            bombNode = SKSpriteNode(color: .gray, size: CGSize(width: tileSize.width * 0.8, height: tileSize.height * 0.8))
            bombNode.name = "bomb"
        }
        bombNode.size = CGSize(width: tileSize.width * 0.8, height: tileSize.height * 0.8)

        let totalWidth = tileSize.width * CGFloat(columns)
        let totalHeight = tileSize.height * CGFloat(rows)
        let originX = (scene.size.width - totalWidth) / 2.0
        let originY = (scene.size.height - totalHeight) / 2.0
        let origin = CGPoint(x: originX, y: originY)

        let bombPos = positionForCell(x: Int(playerGridPosition.x), y: Int(playerGridPosition.y), tileSize: tileSize, origin: origin)
        bombNode.position = bombPos
        bombNode.zPosition = 5
        mapNode.addChild(bombNode)

        // After 1.5 seconds explode and update map
        let wait = SKAction.wait(forDuration: 1.5)
        let explode = SKAction.run { [weak self, weak bombNode] in
            guard let self = self, let bomb = bombNode else { return }

            if let explosionTexture = SKTexture(imageNamed: "explosion").cgImage() != nil ? SKTexture(imageNamed: "explosion") : nil {
                bomb.texture = explosionTexture
            } else {
                bomb.color = .yellow
                bomb.colorBlendFactor = 1.0
            }
            let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let group = SKAction.group([scaleUp, fadeOut])
            let remove = SKAction.removeFromParent()
            bomb.run(SKAction.sequence([group, remove]))
            self.clearDestroyableWalls(from: Int(self.playerGridPosition.x), y: Int(self.playerGridPosition.y))
            self.layoutMap()
        }
        bombNode.run(SKAction.sequence([wait, explode]))
    }

    private func clearDestroyableWalls(from x: Int, y: Int) {
        guard y >= 0, y < map.count, x >= 0, x < map[y].count else { return }

        // Clear center
        if map[y][x] == "." {
            map[y][x] = " "
        }

        let directions = [(0,-1), (0,1), (-1,0), (1,0)]

        for (dx, dy) in directions {
            var nx = x + dx
            var ny = y + dy
            while ny >= 0 && ny < map.count && nx >= 0 && nx < map[ny].count {
                if map[ny][nx] == "." {
                    map[ny][nx] = " "
                    nx += dx
                    ny += dy
                } else {
                    break
                }
            }
        }
    }
}
