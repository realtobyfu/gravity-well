//
//  GravityWellGameViewController.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit
import AVFoundation

// MARK: - Game View Controller
class GravityWellGameViewController: UIViewController {

    // MARK: - Game Components
    private var gameState: GameState!
    private var physicsManager: PhysicsManager!
    private var visualEffects: VisualEffects!
    private var gameHUD: GameHUD!

    // MARK: - Game Objects
    private var centralPortal: PortalView!
    private var portalBarrier: UIView!
    private var collectionZones: [CollectionZone] = []

    // MARK: - Game Timer
    private var spawnTimer: Timer?

    // MARK: - Audio
    private var audioPlayer: AVAudioPlayer?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
    }

    deinit {
        spawnTimer?.invalidate()
    }

    // MARK: - Game Setup
    private func setupGame() {
        // Initialize game state
        gameState = GameState()

        // Setup view
        view.backgroundColor = GameConfig.Colors.background

        // Initialize managers
        physicsManager = PhysicsManager(referenceView: view)
        physicsManager.delegate = self
        visualEffects = VisualEffects(containerView: view)
        gameHUD = GameHUD(containerView: view)

        // Setup visual elements
        visualEffects.addStarField()
        visualEffects.addScanlines()
        setupPortal()
        setupCollectionZones()

        // Start game
        startGame()
    }

    private func setupPortal() {
        // Setup Central Portal
        let portalSize = GameConfig.UI.portalSize
        centralPortal = PortalView(frame: CGRect(
            x: view.bounds.midX - portalSize/2,
            y: view.bounds.midY - portalSize/2,
            width: portalSize,
            height: portalSize
        ))
        view.addSubview(centralPortal)

        // Invisible barrier for collision
        portalBarrier = UIView(frame: centralPortal.frame.insetBy(dx: GameConfig.UI.portalBarrierInset, dy: GameConfig.UI.portalBarrierInset))
        portalBarrier.backgroundColor = .clear
        portalBarrier.layer.cornerRadius = (portalSize - GameConfig.UI.portalBarrierInset * 2) / 2
        view.addSubview(portalBarrier)

        // Setup physics for portal
        physicsManager.setupPortalField(at: centralPortal.center, with: portalBarrier)
    }

    private func setupCollectionZones() {
        let zoneSize = GameConfig.UI.collectionZoneSize
        let margin = GameConfig.UI.collectionZoneMargin

        // Define positions for each corner
        let positions: [CGPoint] = [
            CGPoint(x: margin, y: view.bounds.height - zoneSize - margin), // Bottom left
            CGPoint(x: view.bounds.width - zoneSize - margin, y: view.bounds.height - zoneSize - margin), // Bottom right
            CGPoint(x: margin, y: 100), // Top left
            CGPoint(x: view.bounds.width - zoneSize - margin, y: 100) // Top right
        ]

        for (index, config) in GameConfig.zoneConfigs.enumerated() {
            let zone = CollectionZone(
                frame: CGRect(x: positions[index].x, y: positions[index].y, width: zoneSize, height: zoneSize),
                color: config.color,
                acceptedShape: config.shapeType
            )
            view.addSubview(zone)
            collectionZones.append(zone)
        }
    }

    // MARK: - Game Logic
    private func startGame() {
        gameState.startGame()
        gameHUD.showMessage("LEVEL \(gameState.currentLevel)\nREADY?", duration: 2.0, color: .systemCyan)
        startSpawning()
    }

    private func startSpawning() {
        spawnTimer?.invalidate()
        spawnTimer = Timer.scheduledTimer(withTimeInterval: gameState.spawnInterval, repeats: true) { [weak self] _ in
            self?.spawnShape()
        }
    }

    private func spawnShape() {
        let randomType = ShapeType.allCases.randomElement()!

        // Spawn from edges
        let edge = Int.random(in: 0...3)
        var position: CGPoint

        switch edge {
        case 0: // Top
            position = CGPoint(x: CGFloat.random(in: 50...(view.bounds.width - 50)), y: -30)
        case 1: // Right
            position = CGPoint(x: view.bounds.width + 30, y: CGFloat.random(in: 100...(view.bounds.height - 100)))
        case 2: // Bottom
            position = CGPoint(x: CGFloat.random(in: 50...(view.bounds.width - 50)), y: view.bounds.height + 30)
        default: // Left
            position = CGPoint(x: -30, y: CGFloat.random(in: 100...(view.bounds.height - 100)))
        }

        let shape = ShapeView(type: randomType, position: position)
        view.addSubview(shape)
        gameState.addActiveShape(shape)

        // Add to physics
        physicsManager.addShape(shape)

        // Check collection after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + GameConfig.Timing.collectionCheckDelay) { [weak self] in
            self?.checkShapeCollection(shape)
        }
    }

    private func checkShapeCollection(_ shape: ShapeView) {
        Timer.scheduledTimer(withTimeInterval: GameConfig.Timing.collectionCheckInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            // Check if shape is in any collection zone
            for zone in self.collectionZones {
                if zone.frame.intersects(shape.frame) {
                    if zone.acceptedShape == shape.shapeType {
                        self.collectShape(shape, in: zone)
                        timer.invalidate()
                        return
                    }
                }
            }

            // Check if shape hit the portal
            if self.centralPortal.frame.intersects(shape.frame) {
                self.shapeHitPortal(shape)
                timer.invalidate()
                return
            }

            // Remove if out of bounds for too long
            if !self.view.bounds.insetBy(dx: -100, dy: -100).intersects(shape.frame) {
                self.removeShape(shape)
                timer.invalidate()
                return
            }
        }
    }

    private func collectShape(_ shape: ShapeView, in zone: CollectionZone) {
        // Visual feedback
        zone.flash()
        visualEffects.createParticleEffect(at: shape.center, color: zone.color)

        // Update score
        gameState.addScore(gameState.pointsPerCollection)
        gameHUD.updateScore(gameState.score)

        // Remove shape
        removeShape(shape)

        // Check for level up
        if gameState.score >= gameState.pointsForLevelUp {
            levelUp()
        }

        gameHUD.showMessage("+\(gameState.pointsPerCollection) POINTS!", duration: 1.0, color: .systemGreen)
    }

    private func shapeHitPortal(_ shape: ShapeView) {
        // Portal takes damage
        centralPortal.takeDamage()

        // Lose life
        gameState.loseLife()
        gameHUD.updateLives(gameState.lives)

        // Screen shake
        visualEffects.shakeScreen()

        // Remove shape with explosion
        visualEffects.createExplosion(at: shape.center)
        removeShape(shape)

        if gameState.isGameOver {
            gameOver()
        } else {
            gameHUD.showMessage("PORTAL DAMAGED!", duration: 1.5, color: .systemRed)
        }
    }

    private func removeShape(_ shape: ShapeView) {
        gameState.removeActiveShape(shape)
        physicsManager.removeShape(shape)

        UIView.animate(withDuration: 0.3, animations: {
            shape.alpha = 0
            shape.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { _ in
            shape.removeFromSuperview()
        }
    }

    private func levelUp() {
        gameState.levelUp()
        gameHUD.updateLevel(gameState.currentLevel)
        gameHUD.showMessage("LEVEL UP!\nSPEED INCREASE!", duration: 2.0, color: .systemYellow)

        // Make game harder
        physicsManager.updateGravityMagnitude(gameState.gravityMagnitude)

        // Restart spawning with new parameters
        startSpawning()
    }

    private func gameOver() {
        spawnTimer?.invalidate()

        gameHUD.showMessage("GAME OVER\nFINAL SCORE: \(String(format: "%08d", gameState.score))", duration: 5.0, color: .systemRed)

        // Clear all shapes
        for shape in gameState.activeShapes {
            removeShape(shape)
        }

        // Show restart button
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.gameHUD.showRestartButton(target: self, action: #selector(self?.restartGame))
        }
    }

    @objc private func restartGame() {
        // Reset game state
        gameState.reset()
        gameHUD.updateScore(gameState.score)
        gameHUD.updateLives(gameState.lives)
        gameHUD.updateLevel(gameState.currentLevel)

        // Remove restart button
        gameHUD.removeRestartButton()

        // Reset physics
        physicsManager.updateGravityMagnitude(GameConfig.Physics.baseGravityMagnitude)

        // Start new game
        startGame()
    }
}

// MARK: - Physics Manager Delegate
extension GravityWellGameViewController: PhysicsManagerDelegate {
    func physicsManagerDetectedStrongTilt() {
        centralPortal.pulse()
    }

    func physicsManagerDetectedPortalCollision() {
        centralPortal.pulse()
    }
}