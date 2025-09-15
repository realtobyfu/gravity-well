//
//  GameState.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import Foundation

// MARK: - Game State
class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var currentLevel: Int = 1
    @Published var isGameActive: Bool = false
    @Published var isGameOver: Bool = false

    private(set) var activeShapes: [ShapeView] = []

    func addActiveShape(_ shape: ShapeView) {
        activeShapes.append(shape)
    }

    func removeActiveShape(_ shape: ShapeView) {
        if let index = activeShapes.firstIndex(of: shape) {
            activeShapes.remove(at: index)
        }
    }

    func clearActiveShapes() {
        activeShapes.removeAll()
    }

    func addScore(_ points: Int) {
        score += points
    }

    func loseLife() {
        lives -= 1
        if lives <= 0 {
            isGameOver = true
            isGameActive = false
        }
    }

    func levelUp() {
        currentLevel += 1
    }

    func reset() {
        score = 0
        lives = 3
        currentLevel = 1
        isGameActive = false
        isGameOver = false
        activeShapes.removeAll()
    }

    func startGame() {
        isGameActive = true
        isGameOver = false
    }

    // Game difficulty scaling
    var spawnInterval: Double {
        return max(1.0, 3.0 - Double(currentLevel) * 0.2)
    }

    var gravityMagnitude: CGFloat {
        return min(1.5, 0.5 + CGFloat(currentLevel) * 0.1)
    }

    var pointsPerCollection: Int {
        return 10 * currentLevel
    }

    var pointsForLevelUp: Int {
        return currentLevel * 100
    }
}