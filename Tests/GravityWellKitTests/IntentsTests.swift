import XCTest
@testable import GravityWellKit

@available(iOS 17.0, macOS 14.0, *)
final class IntentsTests: XCTestCase {

    func testGravityTypeConversion() {
        XCTAssertEqual(GravityType.earth.rawValue, "Earth")
        XCTAssertEqual(GravityType.jupiter.rawValue, "Jupiter")
        XCTAssertEqual(GravityType.moon.rawValue, "Moon")
    }

    func testShapeTypeIntentConversion() {
        let circleType = ShapeTypeIntent.circle
        let rectangleType = ShapeTypeIntent.rectangle
        let randomType = ShapeTypeIntent.random

        XCTAssertEqual(circleType.toPhysicsShapeType(), .circle)
        XCTAssertEqual(rectangleType.toPhysicsShapeType(), .rectangle)

        // Random should return either circle or rectangle
        let randomResult = randomType.toPhysicsShapeType()
        XCTAssertTrue(randomResult == .circle || randomResult == .rectangle)
    }

    func testSpawnPositionConversion() {
        let bounds = PhysicsBounds(minX: 0, maxX: 800, minY: 0, maxY: 600)

        let centerPos = SpawnPosition.center.toVector2(bounds: bounds)
        XCTAssertEqual(centerPos.x, 400)
        XCTAssertEqual(centerPos.y, 300)

        let topLeftPos = SpawnPosition.topLeft.toVector2(bounds: bounds)
        XCTAssertEqual(topLeftPos.x, 50)
        XCTAssertEqual(topLeftPos.y, 50)

        let randomPos = SpawnPosition.random.toVector2(bounds: bounds)
        XCTAssertGreaterThanOrEqual(randomPos.x, bounds.minX + 50)
        XCTAssertLessThanOrEqual(randomPos.x, bounds.maxX - 50)
        XCTAssertGreaterThanOrEqual(randomPos.y, bounds.minY + 50)
        XCTAssertLessThanOrEqual(randomPos.y, bounds.maxY - 50)
    }

    func testSetGravityIntent() async throws {
        let intent = SetGravityIntent(gravityType: .jupiter, customValue: nil)
        let result = try await intent.perform()

        // Should return a result indicating Jupiter gravity was set
        XCTAssertNotNil(result)
    }

    func testSpawnShapesIntent() async throws {
        let intent = SpawnShapesIntent(
            count: 5,
            shapeType: .circle,
            spawnPosition: .center
        )
        let result = try await intent.perform()

        // Should return a result indicating shapes were spawned
        XCTAssertNotNil(result)
    }

    func testCreateGravityWellIntent() async throws {
        let intent = CreateGravityWellIntent(
            strength: 1500,
            position: .center
        )
        let result = try await intent.perform()

        // Should return a result indicating gravity well was created
        XCTAssertNotNil(result)
    }

    func testClearSimulationIntent() async throws {
        let intent = ClearSimulationIntent()
        let result = try await intent.perform()

        // Should return a result indicating simulation was cleared
        XCTAssertNotNil(result)
    }

    func testPhysicsIntentHandler() {
        let handler = PhysicsIntentHandler.shared
        let world = PhysicsWorld()

        handler.setActiveWorld(world)
        XCTAssertNotNil(handler.activeWorld)
        XCTAssertEqual(handler.activeWorld?.id, world.id)
    }

    func testClearSimulationIntentHandler() async throws {
        let handler = PhysicsIntentHandler.shared
        let world = PhysicsWorld()
        handler.setActiveWorld(world)

        // Add some objects to the world
        let shape = PhysicsShape(type: .circle, position: Vector2(10, 10), radius: 5, mass: 1.0)
        let gravityWell = GravityWell(position: Vector2(50, 50), strength: 100, range: 200)
        world.addBody(shape)
        world.addForceField(gravityWell)

        // Verify objects were added
        XCTAssertEqual(world.getAllBodies().count, 1)
        XCTAssertEqual(world.getAllForceFields().count, 1)

        // Clear simulation via intent handler
        await handler.clearSimulation()

        // Give some time for async operations
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify everything was cleared
        XCTAssertEqual(world.getAllBodies().count, 0)
        XCTAssertEqual(world.getAllForceFields().count, 0)
    }
}