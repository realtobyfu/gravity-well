import Foundation
import GravityWellKit

@available(macOS 14.0, *)
final class PoolingDemo {
    var world: PhysicsWorld?
    var isRunning = true
    var cycleCount = 0

    func printPoolStats() {
        let stats = PhysicsObjectPool.shared.getShapePoolStatistics()
        print("""

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📊 Object Pool Statistics
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Total Acquires:  \(stats.totalAcquires)
        New Creations:   \(stats.totalCreations)
        Reused Objects:  \(stats.totalReuses)
        Total Releases:  \(stats.totalReleases)
        Available:       \(stats.availableCount)
        Reuse Rate:      \(String(format: "%.1f", stats.reuseRate))%
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """)
    }

    func run() {
        print("""
        ┌──────────────────────────────────────────┐
        │   GravityWell Object Pooling Demo       │
        │   Press Ctrl+C to stop                   │
        └──────────────────────────────────────────┘

        Demonstrating object pooling with rapid
        spawn/destroy cycles to show reuse...
        """)

        // Setup physics world
        let bounds = PhysicsBounds(minX: 0, maxX: 1000, minY: 0, maxY: 1000)
        world = PhysicsWorld(bounds: bounds)
        world?.gravity = Vector2(0, 98)

        // Setup signal handler for graceful shutdown
        signal(SIGINT) { _ in
            print("\n\nShutting down...")
            exit(0)
        }

        // Run simulation cycles
        let shapesPerCycle = 50

        print("\nStarting simulation...\n")

        // Initial warmup to populate pool
        print("⏳ Warming up object pool...")
        warmupPool(count: 100)
        print("✓ Pool warmed up\n")

        // Run cycles
        for cycle in 1...20 {
            cycleCount = cycle
            print("Cycle \(cycle)/20: Spawning \(shapesPerCycle) shapes...")

            // Spawn many shapes using pool
            var shapes: [PhysicsShape] = []
            for _ in 0..<shapesPerCycle {
                let shape = PhysicsObjectPool.shared.acquireShape()
                // Configure the pooled shape
                shape.position = Vector2(
                    Float.random(in: 100...900),
                    Float.random(in: 100...900)
                )
                shape.radius = Float.random(in: 5...15)
                shape.mass = Float.random(in: 0.5...2.0)
                shape.velocity = Vector2(
                    Float.random(in: -50...50),
                    Float.random(in: -50...50)
                )
                shapes.append(shape)
                world?.addBody(shape)
            }

            // Simulate for a bit
            Thread.sleep(forTimeInterval: 0.1)

            // Remove shapes (return to pool)
            for shape in shapes {
                world?.removeBody(shape)
                PhysicsObjectPool.shared.releaseShape(shape)
            }

            // Print stats every few cycles
            if cycle % 5 == 0 {
                printPoolStats()
                printPerformanceMetrics()
            }
        }

        // Final statistics
        print("\n")
        printPoolStats()
        printPerformanceMetrics()

        print("""

        ✅ Demo Complete!

        Object pooling reduces memory allocations by
        reusing objects instead of creating new ones.

        To profile with Instruments:
        1. Build in release mode: swift build -c release
        2. Run Instruments → Allocations
        3. Watch for object reuse vs new allocations
        """)
    }

    private func warmupPool(count: Int) {
        var shapes: [PhysicsShape] = []
        for _ in 0..<count {
            let shape = PhysicsObjectPool.shared.acquireShape()
            shapes.append(shape)
        }
        for shape in shapes {
            PhysicsObjectPool.shared.releaseShape(shape)
        }
    }

    private func printPerformanceMetrics() {
        guard let world = world else { return }
        let report = PerformanceMonitor.shared.getPerformanceReport()

        print("""

        🎯 Performance Metrics
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Active Bodies:       \(world.getAllBodies().count)
        Performance Grade:   \(report.performanceGrade)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """)
    }
}

// Main entry point
if #available(macOS 14.0, *) {
    let demo = PoolingDemo()
    demo.run()
} else {
    print("This demo requires macOS 14.0 or later")
}
