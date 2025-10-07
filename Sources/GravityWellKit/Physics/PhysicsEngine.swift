import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Dispatch
import simd

@available(iOS 17.0, macOS 14.0, *)
public final class PhysicsEngine {
    public static let shared = PhysicsEngine()

    private var isInitialized = false

    private let updateQueue = DispatchQueue(
        label: "com.gravitywell.physics-update",
        qos: .userInteractive
    )

    #if canImport(UIKit)
    private var displayLink: CADisplayLink?
    #else
    private var timer: Timer?
    #endif
    private var lastUpdateTime: CFTimeInterval = 0

    private init() {}

    public func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        setupUpdateLoop()
    }

    private func setupUpdateLoop() {
        #if canImport(UIKit)
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
        #else
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.update()
        }
        #endif
    }

    #if canImport(UIKit)
    @objc private func update(displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard deltaTime > 0 && deltaTime < 0.1 else { return }

        updateQueue.async { [weak self] in
            self?.updatePhysics(deltaTime: deltaTime)
        }
    }
    #else
    @objc private func update() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard deltaTime > 0 && deltaTime < 0.1 else { return }

        updateQueue.async { [weak self] in
            self?.updatePhysics(deltaTime: deltaTime)
        }
    }
    #endif

    private func updatePhysics(deltaTime: TimeInterval) {
        PhysicsWorld.activeWorlds.forEach { world in
            world.update(deltaTime: deltaTime)
        }
    }

    public func pause() {
        #if canImport(UIKit)
        displayLink?.isPaused = true
        #else
        timer?.invalidate()
        #endif
    }

    public func resume() {
        #if canImport(UIKit)
        displayLink?.isPaused = false
        #else
        if timer == nil || !timer!.isValid {
            setupUpdateLoop()
        }
        #endif
        lastUpdateTime = 0
    }

    public func shutdown() {
        #if canImport(UIKit)
        displayLink?.invalidate()
        displayLink = nil
        #else
        timer?.invalidate()
        timer = nil
        #endif
        isInitialized = false
    }

    deinit {
        shutdown()
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class PhysicsWorld {
    public static var activeWorlds: Set<PhysicsWorld> = []

    public let id = UUID()
    public weak var delegate: PhysicsWorldDelegate?
    public weak var collisionDelegate: CollisionDelegate?

    private var bodies: [UUID: PhysicsBody] = [:]
    private var forceFields: [UUID: ForceField] = [:]
    private var spatialGrid: SpatialGrid

    public var gravity = Vector2(0, 98)
    public var damping: Float = 0.999
    public var bounds: PhysicsBounds

    private let physicsQueue = DispatchQueue(
        label: "com.gravitywell.physics-world",
        qos: .userInteractive,
        attributes: .concurrent
    )

    public init(bounds: PhysicsBounds = PhysicsBounds(
        minX: 0, maxX: 1000, minY: 0, maxY: 1000
    )) {
        self.bounds = bounds
        self.spatialGrid = SpatialGrid(bounds: bounds, cellSize: 100)
        Self.activeWorlds.insert(self)
    }

    deinit {
        Self.activeWorlds.remove(self)
    }

    public func addBody(_ body: PhysicsBody) {
        physicsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.bodies[body.id] = body
            self.spatialGrid.insert(body)

            DispatchQueue.main.async {
                self.delegate?.physicsWorld(self, didAdd: body)
            }
        }
    }

    public func removeBody(_ body: PhysicsBody) {
        physicsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.bodies.removeValue(forKey: body.id)
            self.spatialGrid.remove(body)

            DispatchQueue.main.async {
                self.delegate?.physicsWorld(self, didRemove: body)
            }
        }
    }

    public func addForceField(_ field: ForceField) {
        physicsQueue.async(flags: .barrier) { [weak self] in
            self?.forceFields[field.id] = field
        }
    }

    public func removeForceField(_ field: ForceField) {
        physicsQueue.async(flags: .barrier) { [weak self] in
            self?.forceFields.removeValue(forKey: field.id)
        }
    }

    internal func update(deltaTime: TimeInterval) {
        physicsQueue.async { [weak self] in
            self?.performPhysicsUpdate(deltaTime: deltaTime)
        }
    }

    private func performPhysicsUpdate(deltaTime: TimeInterval) {
        let dt = Float(deltaTime)

        spatialGrid.clear()
        for body in bodies.values {
            spatialGrid.insert(body)
        }

        DispatchQueue.concurrentPerform(iterations: bodies.count) { index in
            let body = Array(bodies.values)[index]
            guard body.isDynamic else { return }

            updateBodyForces(body, deltaTime: dt)
            body.update(deltaTime: deltaTime)
            body.velocity *= damping

            enforceBounds(body)
        }

        detectCollisions()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.physicsWorldDidUpdate(self)
        }
    }

    private func updateBodyForces(_ body: PhysicsBody, deltaTime: Float) {
        body.acceleration = gravity

        for field in forceFields.values where field.isActive {
            if field.isInRange(of: body) {
                let force = field.calculateForce(on: body)
                body.applyForce(force)
            }
        }
    }

    private func enforceBounds(_ body: PhysicsBody) {
        let radius = body.radius
        let bounds = self.bounds

        if body.position.x - radius < bounds.minX {
            body.position.x = bounds.minX + radius
            body.velocity.x = abs(body.velocity.x) * 0.8
        } else if body.position.x + radius > bounds.maxX {
            body.position.x = bounds.maxX - radius
            body.velocity.x = -abs(body.velocity.x) * 0.8
        }

        if body.position.y - radius < bounds.minY {
            body.position.y = bounds.minY + radius
            body.velocity.y = abs(body.velocity.y) * 0.8
        } else if body.position.y + radius > bounds.maxY {
            body.position.y = bounds.maxY - radius
            body.velocity.y = -abs(body.velocity.y) * 0.8
        }
    }

    private func detectCollisions() {
        let potentialCollisions = spatialGrid.getPotentialCollisions()

        for (bodyA, bodyB) in potentialCollisions {
            if areColliding(bodyA, bodyB) {
                resolveCollision(bodyA, bodyB)
                DispatchQueue.main.async { [weak self] in
                    self?.collisionDelegate?.didBeginContact(between: bodyA, and: bodyB)
                }
            }
        }
    }

    private func areColliding(_ bodyA: PhysicsBody, _ bodyB: PhysicsBody) -> Bool {
        let distance = bodyA.position.distance(to: bodyB.position)
        return distance < (bodyA.radius + bodyB.radius)
    }

    private func resolveCollision(_ bodyA: PhysicsBody, _ bodyB: PhysicsBody) {
        let distance = bodyA.position.distance(to: bodyB.position)
        let overlap = (bodyA.radius + bodyB.radius) - distance

        guard overlap > 0 else { return }

        let normal = (bodyB.position - bodyA.position).normalized
        let correction = normal * (overlap * 0.5)

        if !bodyA.isStatic {
            bodyA.position -= correction
        }
        if !bodyB.isStatic {
            bodyB.position += correction
        }

        let relativeVelocity = bodyB.velocity - bodyA.velocity
        let velocityAlongNormal = simd_dot(relativeVelocity, normal)

        if velocityAlongNormal < 0 { return }

        let restitution: Float = 0.8
        let j = -(1 + restitution) * velocityAlongNormal
        let impulse = normal * j

        if !bodyA.isStatic {
            bodyA.velocity -= impulse / bodyA.mass
        }
        if !bodyB.isStatic {
            bodyB.velocity += impulse / bodyB.mass
        }
    }

    public func getAllBodies() -> [PhysicsBody] {
        return Array(bodies.values)
    }

    public func getAllForceFields() -> [ForceField] {
        return Array(forceFields.values)
    }

    public func removeAllBodies() {
        physicsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.bodies.removeAll()
            self.spatialGrid.clear()
        }
    }

    public func removeAllForceFields() {
        physicsQueue.async(flags: .barrier) { [weak self] in
            self?.forceFields.removeAll()
        }
    }

    public func clearAll() {
        removeAllBodies()
        removeAllForceFields()
    }
}

extension PhysicsWorld: Hashable {
    public static func == (lhs: PhysicsWorld, rhs: PhysicsWorld) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}