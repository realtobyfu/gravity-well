import Foundation
import AppIntents
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 17.0, macOS 14.0, *)
public struct SetGravityIntent: AppIntent {
    public static let title: LocalizedStringResource = "Set Gravity"
    public static let description = IntentDescription("Set gravity to a planet's gravity or custom value")

    @Parameter(title: "Gravity Type")
    public var gravityType: GravityType

    @Parameter(title: "Custom Value", default: 98)
    public var customValue: Double?

    public static var parameterSummary: some ParameterSummary {
        Summary("Set gravity to \(\.$gravityType)") {
            \.$customValue
        }
    }

    public func perform() async throws -> some IntentResult {
        let gravityValue: Float

        switch gravityType {
        case .earth:
            gravityValue = 98.0
        case .moon:
            gravityValue = 16.3
        case .mars:
            gravityValue = 37.1
        case .jupiter:
            gravityValue = 248.0
        case .sun:
            gravityValue = 2740.0
        case .custom:
            gravityValue = Float(customValue ?? 98.0)
        }

        await PhysicsIntentHandler.shared.setGravity(Vector2(0, gravityValue))

        let planetName = gravityType == .custom ? "custom value" : gravityType.rawValue
        return .result(value: "Gravity set to \(planetName) (\(gravityValue) m/s²)")
    }

    public init() {}

    public init(gravityType: GravityType, customValue: Double? = nil) {
        self.gravityType = gravityType
        self.customValue = customValue
    }
}

@available(iOS 17.0, macOS 14.0, *)
public enum GravityType: String, CaseIterable, AppEnum {
    case earth = "Earth"
    case moon = "Moon"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case sun = "Sun"
    case custom = "Custom"

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Gravity Type")

    public static let caseDisplayRepresentations: [GravityType: DisplayRepresentation] = [
        .earth: "Earth",
        .moon: "Moon",
        .mars: "Mars",
        .jupiter: "Jupiter",
        .sun: "Sun",
        .custom: "Custom Value"
    ]
}

@available(iOS 17.0, macOS 14.0, *)
public struct SpawnShapesIntent: AppIntent {
    public static let title: LocalizedStringResource = "Spawn Shapes"
    public static let description = IntentDescription("Spawn physics shapes in the simulation")

    @Parameter(title: "Number of Shapes", default: 5)
    public var count: Int

    @Parameter(title: "Shape Type")
    public var shapeType: ShapeTypeIntent

    @Parameter(title: "Position")
    public var spawnPosition: SpawnPosition?

    public static var parameterSummary: some ParameterSummary {
        Summary("Spawn \(\.$count) \(\.$shapeType) shapes") {
            \.$spawnPosition
        }
    }

    public func perform() async throws -> some IntentResult {
        let clampedCount = max(1, min(count, 50))

        await PhysicsIntentHandler.shared.spawnShapes(
            count: clampedCount,
            type: shapeType.toPhysicsShapeType(),
            position: spawnPosition?.toVector2()
        )

        return .result(value: "Spawned \(clampedCount) \(shapeType.rawValue) shapes")
    }

    public init() {}

    public init(count: Int, shapeType: ShapeTypeIntent, spawnPosition: SpawnPosition? = nil) {
        self.count = count
        self.shapeType = shapeType
        self.spawnPosition = spawnPosition
    }
}

@available(iOS 17.0, macOS 14.0, *)
public enum ShapeTypeIntent: String, CaseIterable, AppEnum {
    case circle = "Circle"
    case rectangle = "Rectangle"
    case random = "Random"

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Shape Type")

    public static let caseDisplayRepresentations: [ShapeTypeIntent: DisplayRepresentation] = [
        .circle: "Circle",
        .rectangle: "Rectangle",
        .random: "Random"
    ]

    func toPhysicsShapeType() -> PhysicsShapeType {
        switch self {
        case .circle:
            return .circle
        case .rectangle:
            return .rectangle
        case .random:
            return Bool.random() ? .circle : .rectangle
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public enum SpawnPosition: String, CaseIterable, AppEnum {
    case center = "Center"
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
    case random = "Random"

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Spawn Position")

    public static let caseDisplayRepresentations: [SpawnPosition: DisplayRepresentation] = [
        .center: "Center",
        .topLeft: "Top Left",
        .topRight: "Top Right",
        .bottomLeft: "Bottom Left",
        .bottomRight: "Bottom Right",
        .random: "Random"
    ]

    func toVector2(bounds: PhysicsBounds = PhysicsBounds(minX: 0, maxX: 800, minY: 0, maxY: 600)) -> Vector2 {
        switch self {
        case .center:
            return Vector2((bounds.maxX + bounds.minX) / 2, (bounds.maxY + bounds.minY) / 2)
        case .topLeft:
            return Vector2(bounds.minX + 50, bounds.minY + 50)
        case .topRight:
            return Vector2(bounds.maxX - 50, bounds.minY + 50)
        case .bottomLeft:
            return Vector2(bounds.minX + 50, bounds.maxY - 50)
        case .bottomRight:
            return Vector2(bounds.maxX - 50, bounds.maxY - 50)
        case .random:
            return Vector2(
                Float.random(in: (bounds.minX + 50)...(bounds.maxX - 50)),
                Float.random(in: (bounds.minY + 50)...(bounds.maxY - 50))
            )
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct CreateGravityWellIntent: AppIntent {
    public static let title: LocalizedStringResource = "Create Gravity Well"
    public static let description = IntentDescription("Create a gravity well at specified location")

    @Parameter(title: "Strength", default: 1000)
    public var strength: Double

    @Parameter(title: "Position")
    public var position: SpawnPosition?

    public static var parameterSummary: some ParameterSummary {
        Summary("Create gravity well with strength \(\.$strength)") {
            \.$position
        }
    }

    public func perform() async throws -> some IntentResult {
        let wellPosition = position?.toVector2() ?? Vector2(400, 300)
        let wellStrength = Float(max(100, min(strength, 5000)))

        await PhysicsIntentHandler.shared.createGravityWell(
            position: wellPosition,
            strength: wellStrength
        )

        return .result(value: "Created gravity well with strength \(wellStrength)")
    }

    public init() {}

    public init(strength: Double, position: SpawnPosition? = nil) {
        self.strength = strength
        self.position = position
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct ClearSimulationIntent: AppIntent {
    public static let title: LocalizedStringResource = "Clear Simulation"
    public static let description = IntentDescription("Clear all objects from the physics simulation")

    public func perform() async throws -> some IntentResult {
        await PhysicsIntentHandler.shared.clearSimulation()
        return .result(value: "Simulation cleared")
    }

    public init() {}
}

@available(iOS 17.0, macOS 14.0, *)
public struct PhysicsShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetGravityIntent(),
            phrases: [
                "Set gravity in \(.applicationName)",
                "Change gravity in \(.applicationName)"
            ],
            shortTitle: "Set Gravity",
            systemImageName: "globe"
        )

        AppShortcut(
            intent: SpawnShapesIntent(),
            phrases: [
                "Spawn shapes in \(.applicationName)",
                "Add shapes to \(.applicationName)"
            ],
            shortTitle: "Spawn Shapes",
            systemImageName: "circle.fill"
        )

        AppShortcut(
            intent: CreateGravityWellIntent(),
            phrases: [
                "Create gravity well in \(.applicationName)",
                "Add gravity well in \(.applicationName)",
                "Place gravity well in \(.applicationName)"
            ],
            shortTitle: "Create Gravity Well",
            systemImageName: "dot.radiowaves.left.and.right"
        )

        AppShortcut(
            intent: ClearSimulationIntent(),
            phrases: [
                "Clear simulation in \(.applicationName)",
                "Reset physics in \(.applicationName)",
                "Clear all objects in \(.applicationName)"
            ],
            shortTitle: "Clear Simulation",
            systemImageName: "trash"
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class PhysicsIntentHandler: ObservableObject {
    public static let shared = PhysicsIntentHandler()

    public weak var activeWorld: PhysicsWorld?
    private var objectFactory = PhysicsObjectFactory()

    private init() {}

    public func setActiveWorld(_ world: PhysicsWorld) {
        activeWorld = world
    }

    public func setGravity(_ gravity: Vector2) async {
        activeWorld?.gravity = gravity
    }

    public func spawnShapes(count: Int, type: PhysicsShapeType, position: Vector2?) async {
        guard let world = activeWorld else { return }

        let spawnPosition = position ?? Vector2(400, 300)

        for _ in 0..<count {
            let offset = Vector2(
                Float.random(in: -50...50),
                Float.random(in: -50...50)
            )
            let shape = objectFactory.createShape(
                type: type,
                position: spawnPosition + offset
            )
            world.addBody(shape)
        }
    }

    public func createGravityWell(position: Vector2, strength: Float) async {
        guard let world = activeWorld else { return }

        let gravityWell = GravityWell(
            position: position,
            strength: strength,
            range: 300
        )
        world.addForceField(gravityWell)
    }

    public func clearSimulation() async {
        guard let world = activeWorld else { return }
        world.clearAll()
    }
}

private final class PhysicsObjectFactory {
    func createShape(type: PhysicsShapeType, position: Vector2) -> PhysicsShape {
        let shape = PhysicsShape(
            type: type,
            position: position,
            radius: Float.random(in: 8...15),
            mass: Float.random(in: 0.5...2.0)
        )

        #if canImport(UIKit)
        shape.color = [
            .systemBlue, .systemRed, .systemGreen,
            .systemOrange, .systemPurple, .systemPink
        ].randomElement() ?? .systemBlue
        #else
        shape.color = [
            .blue, .red, .green,
            .orange, .purple, .systemPink
        ].randomElement() ?? .blue
        #endif

        return shape
    }
}
