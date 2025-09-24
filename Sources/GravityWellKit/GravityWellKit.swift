import Foundation
import UIKit
import simd

@available(iOS 17.0, macOS 14.0, *)
public struct GravityWellKit {
    public static let version = "1.0.0"

    public static func initialize() {
        PhysicsEngine.shared.initialize()
    }
}

public typealias Vector2 = simd_float2
public typealias Vector3 = simd_float3

public extension Vector2 {
    static let zero = Vector2(0, 0)
    static let up = Vector2(0, -1)
    static let down = Vector2(0, 1)
    static let left = Vector2(-1, 0)
    static let right = Vector2(1, 0)

    var magnitude: Float {
        return sqrt(x * x + y * y)
    }

    var normalized: Vector2 {
        let mag = magnitude
        return mag > 0 ? Vector2(x / mag, y / mag) : .zero
    }

    func distance(to other: Vector2) -> Float {
        return (self - other).magnitude
    }
}

public extension CGPoint {
    var vector2: Vector2 {
        return Vector2(Float(x), Float(y))
    }

    init(_ vector: Vector2) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
}