import Foundation
import UIKit

@available(iOS 17.0, macOS 14.0, *)
public final class PhysicsShape: PhysicsBody {
    public let id = UUID()
    public var position: Vector2
    public var velocity: Vector2 = .zero
    public var acceleration: Vector2 = .zero
    public var mass: Float
    public var radius: Float
    public var isStatic: Bool = false

    public var isDynamic: Bool { !isStatic }
    public let shapeType: PhysicsShapeType
    public var color: UIColor = .systemBlue
    public var restitution: Float = 0.8

    private var accumulatedForces: Vector2 = .zero
    private let forceAccumulator = NSLock()

    public var bounds: PhysicsBounds {
        return PhysicsBounds(
            minX: position.x - radius,
            maxX: position.x + radius,
            minY: position.y - radius,
            maxY: position.y + radius
        )
    }

    public init(
        type: PhysicsShapeType,
        position: Vector2,
        radius: Float? = nil,
        mass: Float = 1.0
    ) {
        self.shapeType = type
        self.position = position
        self.mass = max(mass, 0.1) // Ensure minimum mass to prevent division by zero

        switch type {
        case .circle:
            self.radius = max(radius ?? 10.0, 1.0) // Ensure minimum radius
        case .rectangle:
            self.radius = max(radius ?? 15.0, 1.0)
        case .polygon:
            self.radius = max(radius ?? 12.0, 1.0)
        }
    }

    public convenience init(
        circleAt position: Vector2,
        radius: Float,
        mass: Float = 1.0
    ) {
        self.init(type: .circle, position: position, radius: radius, mass: mass)
    }

    public convenience init(
        rectangleAt position: Vector2,
        size: Float,
        mass: Float = 1.0
    ) {
        self.init(type: .rectangle, position: position, radius: size * 0.7, mass: mass)
    }

    public func applyForce(_ force: Vector2) {
        forceAccumulator.lock()
        accumulatedForces += force
        forceAccumulator.unlock()
    }

    public func applyImpulse(_ impulse: Vector2) {
        velocity += impulse / mass
    }

    public func update(deltaTime: TimeInterval) {
        guard isDynamic else { return }
        guard deltaTime > 0 && deltaTime < 1.0 else { return } // Safety check for valid deltaTime

        let dt = Float(deltaTime)

        forceAccumulator.lock()
        acceleration += accumulatedForces / mass
        accumulatedForces = .zero
        forceAccumulator.unlock()

        // Clamp velocity to prevent runaway physics
        let maxVelocity: Float = 2000.0
        velocity += acceleration * dt
        velocity.x = max(-maxVelocity, min(maxVelocity, velocity.x))
        velocity.y = max(-maxVelocity, min(maxVelocity, velocity.y))

        // Update position
        position += velocity * dt

        // Clamp acceleration to prevent instability
        let maxAcceleration: Float = 5000.0
        acceleration.x = max(-maxAcceleration, min(maxAcceleration, acceleration.x))
        acceleration.y = max(-maxAcceleration, min(maxAcceleration, acceleration.y))

        acceleration = .zero
    }

    public func setStatic(_ static: Bool) {
        isStatic = static
        if static {
            velocity = .zero
            acceleration = .zero
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class PhysicsParticle: PhysicsBody {
    public let id = UUID()
    public var position: Vector2
    public var velocity: Vector2 = .zero
    public var acceleration: Vector2 = .zero
    public var mass: Float
    public let radius: Float = 2.0
    public var isStatic: Bool = false

    public var isDynamic: Bool { !isStatic }
    public var color: UIColor = .systemRed
    public var lifetime: TimeInterval
    public private(set) var age: TimeInterval = 0

    public var bounds: PhysicsBounds {
        return PhysicsBounds(
            minX: position.x - radius,
            maxX: position.x + radius,
            minY: position.y - radius,
            maxY: position.y + radius
        )
    }

    public var isExpired: Bool {
        return age >= lifetime
    }

    public init(
        position: Vector2,
        velocity: Vector2 = .zero,
        mass: Float = 0.1,
        lifetime: TimeInterval = 5.0
    ) {
        self.position = position
        self.velocity = velocity
        self.mass = max(mass, 0.01)
        self.lifetime = lifetime
    }

    public func applyForce(_ force: Vector2) {
        acceleration += force / mass
    }

    public func applyImpulse(_ impulse: Vector2) {
        velocity += impulse / mass
    }

    public func update(deltaTime: TimeInterval) {
        guard isDynamic else { return }

        age += deltaTime
        let dt = Float(deltaTime)

        velocity += acceleration * dt
        position += velocity * dt

        acceleration = .zero
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class PhysicsComposite: PhysicsBody {
    public let id = UUID()
    public var position: Vector2 {
        get { center }
        set { moveCenter(to: newValue) }
    }
    public var velocity: Vector2 = .zero
    public var acceleration: Vector2 = .zero
    public var mass: Float { bodies.reduce(0) { $0 + $1.mass } }
    public var radius: Float { calculateBoundingRadius() }
    public var isStatic: Bool = false

    public var isDynamic: Bool { !isStatic && !bodies.isEmpty }
    private var bodies: [PhysicsBody] = []
    private var center: Vector2

    public var bounds: PhysicsBounds {
        guard !bodies.isEmpty else {
            return PhysicsBounds(minX: 0, maxX: 0, minY: 0, maxY: 0)
        }

        let allBounds = bodies.map { $0.bounds }
        let minX = allBounds.map { $0.minX }.min() ?? 0
        let maxX = allBounds.map { $0.maxX }.max() ?? 0
        let minY = allBounds.map { $0.minY }.min() ?? 0
        let maxY = allBounds.map { $0.maxY }.max() ?? 0

        return PhysicsBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }

    public init(center: Vector2) {
        self.center = center
    }

    public func addBody(_ body: PhysicsBody) {
        bodies.append(body)
        body.isStatic = true
        updateCenter()
    }

    public func removeBody(_ body: PhysicsBody) {
        bodies.removeAll { $0.id == body.id }
        updateCenter()
    }

    public func applyForce(_ force: Vector2) {
        let forcePerBody = force / Float(bodies.count)
        bodies.forEach { $0.applyForce(forcePerBody) }
    }

    public func applyImpulse(_ impulse: Vector2) {
        velocity += impulse / mass
    }

    public func update(deltaTime: TimeInterval) {
        guard isDynamic else { return }

        let dt = Float(deltaTime)
        velocity += acceleration * dt

        let displacement = velocity * dt
        moveCenter(to: center + displacement)

        acceleration = .zero
    }

    private func updateCenter() {
        guard !bodies.isEmpty else { return }
        let totalMass = mass
        let weightedSum = bodies.reduce(Vector2.zero) { sum, body in
            sum + (body.position * body.mass)
        }
        center = weightedSum / totalMass
    }

    private func moveCenter(to newCenter: Vector2) {
        let displacement = newCenter - center
        bodies.forEach { body in
            body.position += displacement
        }
        center = newCenter
    }

    private func calculateBoundingRadius() -> Float {
        guard !bodies.isEmpty else { return 0 }
        return bodies.map { center.distance(to: $0.position) + $0.radius }.max() ?? 0
    }
}