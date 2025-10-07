import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public protocol PhysicsBody: AnyObject {
    var id: UUID { get }
    var position: Vector2 { get set }
    var velocity: Vector2 { get set }
    var acceleration: Vector2 { get set }
    var mass: Float { get }
    var radius: Float { get }
    var isStatic: Bool { get set }
    var isDynamic: Bool { get }
    var bounds: PhysicsBounds { get }

    func applyForce(_ force: Vector2)
    func applyImpulse(_ impulse: Vector2)
    func update(deltaTime: TimeInterval)
}

public protocol ForceField {
    var id: UUID { get }
    var position: Vector2 { get }
    var strength: Float { get set }
    var range: Float { get }
    var isActive: Bool { get set }

    func calculateForce(on body: PhysicsBody) -> Vector2
    func isInRange(of body: PhysicsBody) -> Bool
}

public protocol CollisionDelegate: AnyObject {
    func didBeginContact(between bodyA: PhysicsBody, and bodyB: PhysicsBody)
    func didEndContact(between bodyA: PhysicsBody, and bodyB: PhysicsBody)
}

public protocol PhysicsWorldDelegate: AnyObject {
    func physicsWorldDidUpdate(_ world: PhysicsWorld)
    func physicsWorld(_ world: PhysicsWorld, didAdd body: PhysicsBody)
    func physicsWorld(_ world: PhysicsWorld, didRemove body: PhysicsBody)
}

public struct PhysicsBounds {
    public let minX: Float
    public let maxX: Float
    public let minY: Float
    public let maxY: Float

    public init(minX: Float, maxX: Float, minY: Float, maxY: Float) {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    public func intersects(_ other: PhysicsBounds) -> Bool {
        return !(maxX < other.minX || minX > other.maxX ||
                maxY < other.minY || minY > other.maxY)
    }

    public func contains(_ point: Vector2) -> Bool {
        return point.x >= minX && point.x <= maxX &&
               point.y >= minY && point.y <= maxY
    }
}

public enum PhysicsShapeType {
    case circle
    case rectangle
    case polygon(vertices: [Vector2])

    public var isConvex: Bool {
        switch self {
        case .circle, .rectangle:
            return true
        case .polygon:
            return true
        }
    }
}