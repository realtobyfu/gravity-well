import XCTest
@testable import GravityWellKit

@available(iOS 17.0, macOS 14.0, *)
final class PhysicsEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        GravityWellKit.initialize()
    }

    func testPhysicsWorldCreation() {
        let bounds = PhysicsBounds(minX: 0, maxX: 100, minY: 0, maxY: 100)
        let world = PhysicsWorld(bounds: bounds)

        XCTAssertEqual(world.bounds.minX, 0)
        XCTAssertEqual(world.bounds.maxX, 100)
        XCTAssertEqual(world.gravity.x, 0)
        XCTAssertEqual(world.gravity.y, 98)
    }

    func testPhysicsShapeCreation() {
        let position = Vector2(50, 50)
        let shape = PhysicsShape(
            type: .circle,
            position: position,
            radius: 10,
            mass: 1.0
        )

        XCTAssertEqual(shape.position.x, 50)
        XCTAssertEqual(shape.position.y, 50)
        XCTAssertEqual(shape.radius, 10)
        XCTAssertEqual(shape.mass, 1.0)
        XCTAssertFalse(shape.isStatic)
        XCTAssertTrue(shape.isDynamic)
    }

    func testGravityWellCreation() {
        let position = Vector2(100, 100)
        let gravityWell = GravityWell(
            position: position,
            strength: 1000,
            range: 200
        )

        XCTAssertEqual(gravityWell.position.x, 100)
        XCTAssertEqual(gravityWell.position.y, 100)
        XCTAssertEqual(gravityWell.strength, 1000)
        XCTAssertEqual(gravityWell.range, 200)
        XCTAssertTrue(gravityWell.isActive)
    }

    func testGravityWellForceCalculation() {
        let gravityWell = GravityWell(
            position: Vector2(0, 0),
            strength: 100,
            range: 200
        )

        let shape = PhysicsShape(
            type: .circle,
            position: Vector2(50, 0),
            radius: 10,
            mass: 1.0
        )

        let force = gravityWell.calculateForce(on: shape)

        // Force should point toward the gravity well (negative x direction)
        XCTAssertLessThan(force.x, 0)
        XCTAssertEqual(force.y, 0, accuracy: 0.001)
        XCTAssertGreaterThan(force.magnitude, 0)
    }

    func testPhysicsBodyMovement() {
        let shape = PhysicsShape(
            type: .circle,
            position: Vector2(0, 0),
            radius: 10,
            mass: 1.0
        )

        let initialPosition = shape.position
        shape.velocity = Vector2(10, 0)

        shape.update(deltaTime: 1.0)

        XCTAssertEqual(shape.position.x, initialPosition.x + 10)
        XCTAssertEqual(shape.position.y, initialPosition.y)
    }

    func testForceApplication() {
        let shape = PhysicsShape(
            type: .circle,
            position: Vector2(0, 0),
            radius: 10,
            mass: 2.0
        )

        let force = Vector2(20, 0)
        shape.applyForce(force)
        shape.update(deltaTime: 1.0)

        // Force = mass * acceleration, so acceleration = force / mass = 20 / 2 = 10
        // After 1 second: velocity = acceleration * time = 10 * 1 = 10
        // Position = velocity * time = 10 * 1 = 10
        XCTAssertEqual(shape.velocity.x, 10, accuracy: 0.001)
        XCTAssertEqual(shape.position.x, 10, accuracy: 0.001)
    }

    func testBoundsEnforcement() {
        let bounds = PhysicsBounds(minX: 0, maxX: 100, minY: 0, maxY: 100)
        let world = PhysicsWorld(bounds: bounds)

        let shape = PhysicsShape(
            type: .circle,
            position: Vector2(95, 50),
            radius: 10,
            mass: 1.0
        )
        shape.velocity = Vector2(20, 0) // Moving toward right boundary

        world.addBody(shape)

        // Simulate a few updates to let bounds enforcement kick in
        for _ in 0..<10 {
            world.update(deltaTime: 0.016) // ~60 FPS
        }

        // Shape should be within bounds
        XCTAssertLessThanOrEqual(shape.position.x + shape.radius, bounds.maxX)
        XCTAssertGreaterThanOrEqual(shape.position.x - shape.radius, bounds.minX)
    }

    func testPhysicsBoundsIntersection() {
        let bounds1 = PhysicsBounds(minX: 0, maxX: 10, minY: 0, maxY: 10)
        let bounds2 = PhysicsBounds(minX: 5, maxX: 15, minY: 5, maxY: 15)
        let bounds3 = PhysicsBounds(minX: 20, maxX: 30, minY: 20, maxY: 30)

        XCTAssertTrue(bounds1.intersects(bounds2))
        XCTAssertFalse(bounds1.intersects(bounds3))
    }

    func testVector2Operations() {
        let v1 = Vector2(3, 4)
        let v2 = Vector2(1, 2)

        XCTAssertEqual(v1.magnitude, 5, accuracy: 0.001)

        let normalized = v1.normalized
        XCTAssertEqual(normalized.magnitude, 1, accuracy: 0.001)

        let distance = v1.distance(to: v2)
        XCTAssertEqual(distance, sqrt(8), accuracy: 0.001)
    }

    func testObjectPooling() {
        let pool = PhysicsObjectPool.shared
        let shape1 = pool.acquireShape()
        let shape2 = pool.acquireShape()

        XCTAssertNotEqual(shape1.id, shape2.id)

        pool.releaseShape(shape1)
        let shape3 = pool.acquireShape()

        // shape3 should be the recycled shape1
        XCTAssertEqual(shape1.id, shape3.id)
    }

    func testPerformanceMonitoring() {
        let monitor = PerformanceMonitor.shared

        // Record some mock times
        monitor.recordPhysicsTime(0.008) // 8ms
        monitor.recordRenderTime(0.012)  // 12ms

        for _ in 0..<60 {
            monitor.recordFrame()
        }

        let report = monitor.getPerformanceReport()
        XCTAssertGreaterThan(report.fps, 0)
        XCTAssertGreaterThan(report.averagePhysicsTime, 0)
        XCTAssertGreaterThan(report.averageRenderTime, 0)
    }

    func testGetAllBodiesAndForceFields() {
        let world = PhysicsWorld()

        // Add some bodies
        let shape1 = PhysicsShape(type: .circle, position: Vector2(10, 10), radius: 5, mass: 1.0)
        let shape2 = PhysicsShape(type: .rectangle, position: Vector2(20, 20), radius: 8, mass: 2.0)
        world.addBody(shape1)
        world.addBody(shape2)

        // Add some force fields
        let gravityWell = GravityWell(position: Vector2(50, 50), strength: 100, range: 200)
        let repulsion = RepulsionField(position: Vector2(100, 100), strength: 200, range: 150)
        world.addForceField(gravityWell)
        world.addForceField(repulsion)

        // Test getAllBodies
        let bodies = world.getAllBodies()
        XCTAssertEqual(bodies.count, 2)

        // Test getAllForceFields
        let forceFields = world.getAllForceFields()
        XCTAssertEqual(forceFields.count, 2)
    }

    func testClearAll() {
        let world = PhysicsWorld()

        // Add some bodies and force fields
        let shape = PhysicsShape(type: .circle, position: Vector2(10, 10), radius: 5, mass: 1.0)
        let gravityWell = GravityWell(position: Vector2(50, 50), strength: 100, range: 200)
        world.addBody(shape)
        world.addForceField(gravityWell)

        // Verify they were added
        XCTAssertEqual(world.getAllBodies().count, 1)
        XCTAssertEqual(world.getAllForceFields().count, 1)

        // Clear all
        world.clearAll()

        // Give some time for async operations to complete
        let expectation = XCTestExpectation(description: "Clear completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify everything was cleared
        XCTAssertEqual(world.getAllBodies().count, 0)
        XCTAssertEqual(world.getAllForceFields().count, 0)
    }

    func testSafetyLimits() {
        // Test that extreme values are handled safely
        let shape = PhysicsShape(
            type: .circle,
            position: Vector2(0, 0),
            radius: 0, // Should be clamped to minimum
            mass: -5.0 // Should be clamped to minimum
        )

        XCTAssertGreaterThan(shape.radius, 0)
        XCTAssertGreaterThan(shape.mass, 0)

        // Test extreme force application
        let extremeForce = Vector2(1000000, 1000000)
        shape.applyForce(extremeForce)
        shape.update(deltaTime: 1.0)

        // Velocity should be clamped
        XCTAssertLessThanOrEqual(abs(shape.velocity.x), 2000.0)
        XCTAssertLessThanOrEqual(abs(shape.velocity.y), 2000.0)
    }
}