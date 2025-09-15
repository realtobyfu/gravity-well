//
//  PhysicsManager.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit
import CoreMotion

// MARK: - Physics Manager
class PhysicsManager: NSObject {
    private var animator: UIDynamicAnimator!
    private var gravity: UIGravityBehavior!
    private var collision: UICollisionBehavior!
    private var portalField: UIFieldBehavior!
    private let motionManager = CMMotionManager()

    weak var referenceView: UIView?
    weak var delegate: PhysicsManagerDelegate?

    init(referenceView: UIView) {
        super.init()
        self.referenceView = referenceView
        setupPhysics()
        setupMotion()
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }

    private func setupPhysics() {
        guard let referenceView = referenceView else { return }

        animator = UIDynamicAnimator(referenceView: referenceView)

        // Gravity behavior
        gravity = UIGravityBehavior()
        gravity.magnitude = GameConfig.Physics.baseGravityMagnitude
        animator.addBehavior(gravity)

        // Collision behavior
        collision = UICollisionBehavior()
        collision.translatesReferenceBoundsIntoBoundary = true
        collision.collisionDelegate = self
        animator.addBehavior(collision)
    }

    func setupPortalField(at center: CGPoint, with portalBarrier: UIView) {
        // Add portal as a boundary
        let portalPath = UIBezierPath(ovalIn: portalBarrier.bounds)
        collision.addBoundary(withIdentifier: "portal" as NSString, for: portalPath)

        // Add radial gravity field around portal
        portalField = UIFieldBehavior.radialGravityField(position: center)
        portalField.strength = GameConfig.Physics.portalFieldStrength
        portalField.falloff = GameConfig.Physics.portalFieldFalloff
        portalField.minimumRadius = GameConfig.Physics.portalMinimumRadius
        portalField.region = UIRegion(radius: GameConfig.Physics.portalFieldRadius)
        animator.addBehavior(portalField)
    }

    private func setupMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = GameConfig.Timing.motionUpdateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }

            // Update gravity based on device tilt
            let rotation = atan2(motion.gravity.x, motion.gravity.y) - .pi
            self.gravity.angle = CGFloat(rotation)

            // Make portal pulse when tilted strongly
            let tiltMagnitude = sqrt(pow(motion.gravity.x, 2) + pow(motion.gravity.z, 2))
            if tiltMagnitude > GameConfig.Balance.portalPulseThreshold {
                self.delegate?.physicsManagerDetectedStrongTilt()
            }
        }
    }

    func addShape(_ shape: ShapeView) {
        gravity.addItem(shape)
        collision.addItem(shape)
        portalField?.addItem(shape)

        // Item behavior
        let itemBehavior = UIDynamicItemBehavior(items: [shape])
        itemBehavior.elasticity = GameConfig.Physics.elasticity
        itemBehavior.friction = GameConfig.Physics.friction
        itemBehavior.density = GameConfig.Physics.density
        itemBehavior.allowsRotation = true

        // Add initial velocity toward center
        guard let referenceView = referenceView else { return }
        let vectorToCenter = CGVector(
            dx: (referenceView.bounds.midX - shape.center.x) * GameConfig.Physics.velocityMultiplier,
            dy: (referenceView.bounds.midY - shape.center.y) * GameConfig.Physics.velocityMultiplier
        )
        itemBehavior.addLinearVelocity(CGPoint(x: vectorToCenter.dx, y: vectorToCenter.dy), for: shape)

        animator.addBehavior(itemBehavior)
    }

    func removeShape(_ shape: ShapeView) {
        gravity.removeItem(shape)
        collision.removeItem(shape)
        portalField?.removeItem(shape)

        // Remove associated behaviors
        for behavior in animator.behaviors {
            if let itemBehavior = behavior as? UIDynamicItemBehavior,
               itemBehavior.items.contains(where: { $0 === shape }) {
                animator.removeBehavior(itemBehavior)
                break
            }
        }
    }

    func updateGravityMagnitude(_ magnitude: CGFloat) {
        gravity.magnitude = magnitude
    }
}

// MARK: - Physics Manager Delegate
protocol PhysicsManagerDelegate: AnyObject {
    func physicsManagerDetectedStrongTilt()
    func physicsManagerDetectedPortalCollision()
}

// MARK: - Collision Delegate
extension PhysicsManager: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        if let id = identifier as? String, id == "portal" {
            delegate?.physicsManagerDetectedPortalCollision()
        }
    }
}