import Foundation
import UIKit

@available(iOS 17.0, macOS 14.0, *)
public final class GravityWell: ForceField {
    public let id = UUID()
    public let position: Vector2
    public var strength: Float
    public var range: Float
    public var isActive: Bool = true

    public var falloffType: FalloffType = .inverseSquare
    public var minDistance: Float = 5.0
    public var color: UIColor = .systemPurple

    public enum FalloffType {
        case linear
        case inverseSquare
        case exponential(decay: Float)
        case constant
    }

    public init(position: Vector2, strength: Float, range: Float = 300) {
        self.position = position
        self.strength = strength
        self.range = range
    }

    public func calculateForce(on body: PhysicsBody) -> Vector2 {
        let direction = position - body.position
        let distance = max(direction.magnitude, minDistance)

        guard distance <= range && distance > 0 else { return .zero }
        guard body.mass > 0 else { return .zero }

        let normalizedDirection = direction.normalized
        let forceMagnitude = calculateForceMagnitude(distance: distance, bodyMass: body.mass)

        // Clamp force magnitude to prevent physics instability
        let maxForce: Float = 10000.0
        let clampedMagnitude = min(abs(forceMagnitude), maxForce) * (forceMagnitude >= 0 ? 1 : -1)

        return normalizedDirection * clampedMagnitude
    }

    public func isInRange(of body: PhysicsBody) -> Bool {
        return position.distance(to: body.position) <= range
    }

    private func calculateForceMagnitude(distance: Float, bodyMass: Float) -> Float {
        switch falloffType {
        case .linear:
            let normalizedDistance = distance / range
            return strength * bodyMass * (1.0 - normalizedDistance)

        case .inverseSquare:
            return strength * bodyMass / (distance * distance)

        case .exponential(let decay):
            return strength * bodyMass * exp(-decay * distance / range)

        case .constant:
            return strength * bodyMass
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class MagneticField: ForceField {
    public let id = UUID()
    public let position: Vector2
    public var strength: Float
    public var range: Float
    public var isActive: Bool = true

    public var fieldDirection: Vector2
    public var affectsPositiveCharge: Bool = true
    public var affectsNegativeCharge: Bool = true

    public init(
        position: Vector2,
        strength: Float,
        direction: Vector2 = Vector2(1, 0),
        range: Float = 200
    ) {
        self.position = position
        self.strength = strength
        self.fieldDirection = direction.normalized
        self.range = range
    }

    public func calculateForce(on body: PhysicsBody) -> Vector2 {
        guard isInRange(of: body) else { return .zero }

        let charge = getCharge(of: body)
        guard shouldAffect(charge: charge) else { return .zero }

        let velocity = body.velocity
        let magneticForce = simd_float2(
            -velocity.y * fieldDirection.x,
            velocity.x * fieldDirection.y
        )

        let distance = position.distance(to: body.position)
        let falloff = 1.0 - (distance / range)

        return magneticForce * strength * charge * falloff
    }

    public func isInRange(of body: PhysicsBody) -> Bool {
        return position.distance(to: body.position) <= range
    }

    private func getCharge(of body: PhysicsBody) -> Float {
        if let charged = body as? ChargedBody {
            return charged.charge
        }
        return body.mass > 0 ? 1.0 : -1.0
    }

    private func shouldAffect(charge: Float) -> Bool {
        return (charge > 0 && affectsPositiveCharge) ||
               (charge < 0 && affectsNegativeCharge)
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class WindField: ForceField {
    public let id = UUID()
    public let position: Vector2
    public var strength: Float
    public var range: Float
    public var isActive: Bool = true

    public var windDirection: Vector2
    public var turbulence: Float = 0.1
    public var gustiness: Float = 0.2

    private var time: Float = 0

    public init(
        position: Vector2,
        strength: Float,
        direction: Vector2,
        range: Float = 400
    ) {
        self.position = position
        self.strength = strength
        self.windDirection = direction.normalized
        self.range = range
    }

    public func calculateForce(on body: PhysicsBody) -> Vector2 {
        guard isInRange(of: body) else { return .zero }

        time += 0.016

        let distance = position.distance(to: body.position)
        let falloff = 1.0 - (distance / range)

        let baseForce = windDirection * strength * falloff

        let turbulenceX = sin(time * 5.0 + body.position.x * 0.1) * turbulence
        let turbulenceY = cos(time * 3.0 + body.position.y * 0.1) * turbulence
        let turbulenceForce = Vector2(turbulenceX, turbulenceY) * strength

        let gust = sin(time * 2.0) * gustiness + 1.0
        let totalForce = (baseForce + turbulenceForce) * gust

        return totalForce * body.mass * 0.1
    }

    public func isInRange(of body: PhysicsBody) -> Bool {
        return position.distance(to: body.position) <= range
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class RepulsionField: ForceField {
    public let id = UUID()
    public let position: Vector2
    public var strength: Float
    public var range: Float
    public var isActive: Bool = true

    public var minDistance: Float = 10.0
    public var falloffExponent: Float = 2.0

    public init(position: Vector2, strength: Float, range: Float = 150) {
        self.position = position
        self.strength = strength
        self.range = range
    }

    public func calculateForce(on body: PhysicsBody) -> Vector2 {
        let direction = body.position - position
        let distance = max(direction.magnitude, minDistance)

        guard distance <= range else { return .zero }

        let normalizedDirection = direction.normalized
        let forceMagnitude = strength * body.mass / pow(distance, falloffExponent)

        return normalizedDirection * forceMagnitude
    }

    public func isInRange(of body: PhysicsBody) -> Bool {
        return position.distance(to: body.position) <= range
    }
}

public protocol ChargedBody: PhysicsBody {
    var charge: Float { get set }
}

@available(iOS 17.0, macOS 14.0, *)
extension PhysicsShape: ChargedBody {
    private static var chargeAssociation = ObjectAssociation<Float>()

    public var charge: Float {
        get { PhysicsShape.chargeAssociation[self] ?? 1.0 }
        set { PhysicsShape.chargeAssociation[self] = newValue }
    }
}

public final class ObjectAssociation<T> {
    private let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC

    public subscript(index: AnyObject) -> T? {
        get { objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as? T }
        set { objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy) }
    }
}