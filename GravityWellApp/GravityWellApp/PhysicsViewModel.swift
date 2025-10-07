import Foundation
import SwiftUI
import GravityWellKit

@MainActor
class PhysicsViewModel: NSObject, ObservableObject {
    @Published var fps: Double = 0
    @Published var objectCount: Int = 0
    @Published var isPaused: Bool = false

    var world: PhysicsWorld?
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount = 0
    private var viewportSize: CGSize = CGSize(width: 390, height: 844) // Default iPhone size

    override init() {
        super.init()
    }

    func setupDemo(viewportSize: CGSize = CGSize(width: 390, height: 844)) {
        self.viewportSize = viewportSize
        // Create physics world matching viewport size
        let bounds = PhysicsBounds(
            minX: 0,
            maxX: Float(viewportSize.width),
            minY: 0,
            maxY: Float(viewportSize.height)
        )
        world = PhysicsWorld(bounds: bounds)
        world?.delegate = self

        // Register with intent handler for Siri support
        if let world = world {
            PhysicsIntentHandler.shared.setActiveWorld(world)
        }

        // Add initial objects
        addInitialObjects()
    }

    private func addInitialObjects() {
        guard let world = world else { return }

        // Add some initial shapes distributed across the screen
        let centerX = Float(viewportSize.width / 2)
        let centerY = Float(viewportSize.height / 2)

        for i in 0..<10 {
            let shape = PhysicsShape(
                circleAt: Vector2(
                    Float.random(in: 50...Float(viewportSize.width - 50)),
                    Float.random(in: 50...Float(viewportSize.height / 2))
                ),
                radius: Float.random(in: 10...25),
                mass: Float.random(in: 0.5...2.0)
            )
            shape.velocity = Vector2(
                Float.random(in: -50...50),
                Float.random(in: -50...50)
            )
            world.addBody(shape)
        }

        // Add central gravity well
        let gravityWell = GravityWell(
            position: Vector2(centerX, centerY),
            strength: 1500,
            range: 300
        )
        world.addForceField(gravityWell)

        updateObjectCount()
    }

    func spawnShapes() {
        guard let world = world else { return }

        for _ in 0..<5 {
            let shape = PhysicsShape(
                type: Bool.random() ? .circle : .rectangle,
                position: Vector2(
                    Float.random(in: 100...900),
                    Float.random(in: 100...900)
                ),
                radius: Float.random(in: 8...20),
                mass: Float.random(in: 0.3...1.5)
            )
            shape.velocity = Vector2(
                Float.random(in: -100...100),
                Float.random(in: -100...100)
            )
            world.addBody(shape)
        }

        updateObjectCount()
    }

    func addShape(at location: CGPoint) {
        guard let world = world else { return }

        let shape = PhysicsShape(
            circleAt: Vector2(Float(location.x), Float(location.y)),
            radius: Float.random(in: 10...20),
            mass: 1.0
        )
        shape.velocity = Vector2(
            Float.random(in: -50...50),
            Float.random(in: -50...50)
        )
        world.addBody(shape)

        updateObjectCount()
    }

    func addGravityWell(at location: CGPoint? = nil) {
        guard let world = world else { return }

        let position: Vector2
        if let loc = location {
            position = Vector2(Float(loc.x), Float(loc.y))
        } else {
            position = Vector2(
                Float.random(in: 200...800),
                Float.random(in: 200...800)
            )
        }

        let gravityWell = GravityWell(
            position: position,
            strength: Float.random(in: 800...2000),
            range: Float.random(in: 150...300)
        )
        world.addForceField(gravityWell)
    }

    func setGravity(to planet: String) {
        guard let world = world else { return }

        let gravityValue: Float = switch planet {
        case "Moon": 16.3
        case "Mars": 37.1
        case "Jupiter": 248.0
        case "Sun": 500.0  // Scaled down for demo
        default: 98.0  // Earth
        }

        world.gravity = Vector2(0, gravityValue)
    }

    func clearAll() {
        world?.clearAll()
        updateObjectCount()
    }

    func reset() {
        world?.clearAll()
        addInitialObjects()
    }

    func togglePause() {
        if isPaused {
            PhysicsEngine.shared.resume()
        } else {
            PhysicsEngine.shared.pause()
        }
        isPaused.toggle()
    }

    func updateFPS() {
        frameCount += 1
        let currentTime = CFAbsoluteTimeGetCurrent()

        if currentTime - lastFrameTime >= 1.0 {
            fps = Double(frameCount)
            frameCount = 0
            lastFrameTime = currentTime
        }

        PerformanceMonitor.shared.recordFrame()
    }

    private func updateObjectCount() {
        objectCount = world?.getAllBodies().count ?? 0
    }
}

// MARK: - PhysicsWorldDelegate
extension PhysicsViewModel: PhysicsWorldDelegate {
    nonisolated func physicsWorldDidUpdate(_ world: PhysicsWorld) {
        Task { @MainActor in
            updateObjectCount()
        }
    }

    nonisolated func physicsWorld(_ world: PhysicsWorld, didAdd body: any PhysicsBody) {
        Task { @MainActor in
            updateObjectCount()
        }
    }

    nonisolated func physicsWorld(_ world: PhysicsWorld, didRemove body: any PhysicsBody) {
        Task { @MainActor in
            updateObjectCount()
        }
    }
}
