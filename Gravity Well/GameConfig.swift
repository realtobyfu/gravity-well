//
//  GameConfig.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit

// MARK: - Game Configuration
struct GameConfig {

    // MARK: - Physics Constants
    struct Physics {
        static let baseGravityMagnitude: CGFloat = 0.5
        static let maxGravityMagnitude: CGFloat = 1.5
        static let elasticity: CGFloat = 0.6
        static let friction: CGFloat = 0.2
        static let density: CGFloat = 1.0
        static let portalFieldStrength: CGFloat = -0.5
        static let portalFieldFalloff: CGFloat = 2.0
        static let portalFieldRadius: CGFloat = 150
        static let portalMinimumRadius: CGFloat = 50
        static let velocityMultiplier: CGFloat = 0.3
    }

    // MARK: - UI Constants
    struct UI {
        static let portalSize: CGFloat = 100
        static let portalBarrierInset: CGFloat = -10
        static let collectionZoneSize: CGFloat = 80
        static let collectionZoneMargin: CGFloat = 20
        static let shapeSize: CGSize = CGSize(width: 40, height: 40)
        static let labelHeight: CGFloat = 30
        static let messageHeight: CGFloat = 40
    }

    // MARK: - Timing Constants
    struct Timing {
        static let baseSpawnInterval: Double = 3.0
        static let minSpawnInterval: Double = 1.0
        static let spawnSpeedIncrease: Double = 0.2
        static let collectionCheckInterval: Double = 0.1
        static let collectionCheckDelay: Double = 0.5
        static let motionUpdateInterval: Double = 1.0 / 60.0
    }

    // MARK: - Visual Effects
    struct Effects {
        static let scanlineSpacing: Int = 4
        static let scanlineOpacity: Float = 0.05
        static let particleCount: Int = 12
        static let explosionParticleCount: Int = 12
        static let particleMinDistance: CGFloat = 30
        static let particleMaxDistance: CGFloat = 80
        static let explosionMinDistance: CGFloat = 40
        static let explosionMaxDistance: CGFloat = 120
        static let particleDuration: Double = 0.8
        static let explosionDuration: Double = 0.8
    }

    // MARK: - Game Balance
    struct Balance {
        static let basePointsPerShape: Int = 10
        static let pointsMultiplierPerLevel: Int = 100
        static let initialLives: Int = 3
        static let portalPulseThreshold: Double = 0.6
    }

    // MARK: - Arcade Colors
    struct Colors {
        static let background = UIColor.black
        static let scanline = UIColor.white.withAlphaComponent(0.05)
        static let hudText = UIColor.cyan
        static let portalRing = UIColor.magenta
        static let portalGlow1 = UIColor.magenta.withAlphaComponent(0.3)
        static let portalGlow2 = UIColor.cyan.withAlphaComponent(0.5)
        static let portalCore = UIColor.magenta
        static let explosionColors: [UIColor] = [.red, .orange, .yellow, .white]
    }

    // MARK: - Collection Zone Configuration
    static let zoneConfigs: [(color: UIColor, shapeType: ShapeType)] = [
        (.magenta, .triangle),
        (.cyan, .star),
        (.green, .hexagon),
        (.yellow, .circle)
    ]
}