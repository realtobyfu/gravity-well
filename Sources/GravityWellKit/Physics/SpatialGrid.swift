import Foundation
import Collections

internal final class SpatialGrid {
    private let bounds: PhysicsBounds
    private let cellSize: Float
    private let gridWidth: Int
    private let gridHeight: Int

    private var grid: [[PhysicsBody]]

    init(bounds: PhysicsBounds, cellSize: Float) {
        self.bounds = bounds
        self.cellSize = cellSize
        self.gridWidth = Int(ceil((bounds.maxX - bounds.minX) / cellSize))
        self.gridHeight = Int(ceil((bounds.maxY - bounds.minY) / cellSize))

        self.grid = Array(
            repeating: Array(repeating: [], count: gridHeight),
            count: gridWidth
        )
    }

    func clear() {
        for x in 0..<gridWidth {
            for y in 0..<gridHeight {
                grid[x][y].removeAll(keepingCapacity: true)
            }
        }
    }

    func insert(_ body: PhysicsBody) {
        let cells = getCells(for: body)
        for (x, y) in cells {
            if isValidCell(x: x, y: y) {
                grid[x][y].append(body)
            }
        }
    }

    func remove(_ body: PhysicsBody) {
        let cells = getCells(for: body)
        for (x, y) in cells {
            if isValidCell(x: x, y: y) {
                grid[x][y].removeAll { $0.id == body.id }
            }
        }
    }

    func getPotentialCollisions() -> [(PhysicsBody, PhysicsBody)] {
        var collisions: [(PhysicsBody, PhysicsBody)] = []
        var checkedPairs: Set<String> = []

        for x in 0..<gridWidth {
            for y in 0..<gridHeight {
                let bodies = grid[x][y]

                for i in 0..<bodies.count {
                    for j in (i + 1)..<bodies.count {
                        let bodyA = bodies[i]
                        let bodyB = bodies[j]
                        let pairKey = generatePairKey(bodyA.id, bodyB.id)

                        if !checkedPairs.contains(pairKey) {
                            checkedPairs.insert(pairKey)
                            collisions.append((bodyA, bodyB))
                        }
                    }
                }
            }
        }

        return collisions
    }

    func query(in area: PhysicsBounds) -> [PhysicsBody] {
        var bodySet: Set<ObjectIdentifier> = []
        var bodies: [PhysicsBody] = []

        let startX = max(0, Int((area.minX - bounds.minX) / cellSize))
        let endX = min(gridWidth - 1, Int((area.maxX - bounds.minX) / cellSize))
        let startY = max(0, Int((area.minY - bounds.minY) / cellSize))
        let endY = min(gridHeight - 1, Int((area.maxY - bounds.minY) / cellSize))

        for x in startX...endX {
            for y in startY...endY {
                for body in grid[x][y] {
                    let identifier = ObjectIdentifier(body)
                    if !bodySet.contains(identifier) && body.bounds.intersects(area) {
                        bodySet.insert(identifier)
                        bodies.append(body)
                    }
                }
            }
        }

        return bodies
    }

    private func getCells(for body: PhysicsBody) -> [(Int, Int)] {
        let bodyBounds = body.bounds
        let startX = Int((bodyBounds.minX - bounds.minX) / cellSize)
        let endX = Int((bodyBounds.maxX - bounds.minX) / cellSize)
        let startY = Int((bodyBounds.minY - bounds.minY) / cellSize)
        let endY = Int((bodyBounds.maxY - bounds.minY) / cellSize)

        var cells: [(Int, Int)] = []
        for x in startX...endX {
            for y in startY...endY {
                cells.append((x, y))
            }
        }
        return cells
    }

    private func isValidCell(x: Int, y: Int) -> Bool {
        return x >= 0 && x < gridWidth && y >= 0 && y < gridHeight
    }

    private func generatePairKey(_ idA: UUID, _ idB: UUID) -> String {
        let sortedIds = [idA.uuidString, idB.uuidString].sorted()
        return "\(sortedIds[0])_\(sortedIds[1])"
    }
}

