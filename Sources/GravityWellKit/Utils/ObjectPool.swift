import Foundation

@available(iOS 17.0, macOS 14.0, *)
public final class ObjectPool<T: AnyObject> {
    private var objects: [T] = []
    private let createObject: () -> T
    private let resetObject: (T) -> Void
    private let maxSize: Int
    private let lock = NSLock()

    // Statistics tracking
    private var totalAcquires: Int = 0
    private var totalCreations: Int = 0
    private var totalReleases: Int = 0
    private var totalReuses: Int = 0

    public init(
        maxSize: Int = 100,
        createObject: @escaping () -> T,
        resetObject: @escaping (T) -> Void = { _ in }
    ) {
        self.maxSize = maxSize
        self.createObject = createObject
        self.resetObject = resetObject
    }

    public func acquire() -> T {
        lock.lock()
        defer { lock.unlock() }

        totalAcquires += 1

        if let object = objects.popLast() {
            totalReuses += 1
            return object
        } else {
            totalCreations += 1
            return createObject()
        }
    }

    public func release(_ object: T) {
        lock.lock()
        defer { lock.unlock() }

        guard objects.count < maxSize else { return }

        totalReleases += 1
        resetObject(object)
        objects.append(object)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        objects.removeAll()
    }

    public var availableCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return objects.count
    }

    public func getStatistics() -> PoolStatistics {
        lock.lock()
        defer { lock.unlock() }
        return PoolStatistics(
            totalAcquires: totalAcquires,
            totalCreations: totalCreations,
            totalReuses: totalReuses,
            totalReleases: totalReleases,
            availableCount: objects.count,
            reuseRate: totalAcquires > 0 ? Double(totalReuses) / Double(totalAcquires) * 100 : 0
        )
    }

    public func resetStatistics() {
        lock.lock()
        defer { lock.unlock() }
        totalAcquires = 0
        totalCreations = 0
        totalReuses = 0
        totalReleases = 0
    }
}

public struct PoolStatistics {
    public let totalAcquires: Int
    public let totalCreations: Int
    public let totalReuses: Int
    public let totalReleases: Int
    public let availableCount: Int
    public let reuseRate: Double
}

@available(iOS 17.0, macOS 14.0, *)
public final class PhysicsObjectPool {
    public static let shared = PhysicsObjectPool()

    private let shapePool = ObjectPool<PhysicsShape>(
        maxSize: 200,
        createObject: {
            PhysicsShape(type: .circle, position: .zero, radius: 10, mass: 1.0)
        },
        resetObject: { shape in
            shape.position = .zero
            shape.velocity = .zero
            shape.acceleration = .zero
            shape.mass = 1.0
            shape.isStatic = false
            #if canImport(UIKit)
            shape.color = .systemBlue
            #else
            shape.color = .blue
            #endif
        }
    )

    private let particlePool = ObjectPool<PhysicsParticle>(
        maxSize: 500,
        createObject: {
            PhysicsParticle(position: .zero, velocity: .zero, mass: 0.1, lifetime: 5.0)
        },
        resetObject: { particle in
            particle.position = .zero
            particle.velocity = .zero
            particle.acceleration = .zero
            particle.mass = 0.1
            particle.isStatic = false
        }
    )

    private init() {}

    public func acquireShape() -> PhysicsShape {
        return shapePool.acquire()
    }

    public func releaseShape(_ shape: PhysicsShape) {
        shapePool.release(shape)
    }

    public func acquireParticle() -> PhysicsParticle {
        return particlePool.acquire()
    }

    public func releaseParticle(_ particle: PhysicsParticle) {
        particlePool.release(particle)
    }

    public func clearAll() {
        shapePool.clear()
        particlePool.clear()
    }

    public func getShapePoolStatistics() -> PoolStatistics {
        return shapePool.getStatistics()
    }

    public func getParticlePoolStatistics() -> PoolStatistics {
        return particlePool.getStatistics()
    }

    public func resetStatistics() {
        shapePool.resetStatistics()
        particlePool.resetStatistics()
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class PerformanceMonitor {
    public static let shared = PerformanceMonitor()

    private var frameCount = 0
    private var lastFPSUpdate: CFTimeInterval = 0
    private var currentFPS: Double = 0

    private var physicsUpdateTimes: [CFTimeInterval] = []
    private var renderTimes: [CFTimeInterval] = []

    private let maxSamples = 60

    public var fps: Double { currentFPS }
    public var averagePhysicsTime: CFTimeInterval {
        return physicsUpdateTimes.isEmpty ? 0 : physicsUpdateTimes.reduce(0, +) / Double(physicsUpdateTimes.count)
    }
    public var averageRenderTime: CFTimeInterval {
        return renderTimes.isEmpty ? 0 : renderTimes.reduce(0, +) / Double(renderTimes.count)
    }

    private init() {}

    public func recordFrame() {
        frameCount += 1
        let currentTime = CFAbsoluteTimeGetCurrent()

        if currentTime - lastFPSUpdate >= 1.0 {
            currentFPS = Double(frameCount)
            frameCount = 0
            lastFPSUpdate = currentTime
        }
    }

    public func recordPhysicsTime(_ time: CFTimeInterval) {
        physicsUpdateTimes.append(time)
        if physicsUpdateTimes.count > maxSamples {
            physicsUpdateTimes.removeFirst()
        }
    }

    public func recordRenderTime(_ time: CFTimeInterval) {
        renderTimes.append(time)
        if renderTimes.count > maxSamples {
            renderTimes.removeFirst()
        }
    }

    public func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            fps: fps,
            averagePhysicsTime: averagePhysicsTime * 1000, // Convert to ms
            averageRenderTime: averageRenderTime * 1000,
            physicsTimeVariance: calculateVariance(physicsUpdateTimes) * 1000,
            renderTimeVariance: calculateVariance(renderTimes) * 1000
        )
    }

    private func calculateVariance(_ times: [CFTimeInterval]) -> CFTimeInterval {
        guard times.count > 1 else { return 0 }

        let average = times.reduce(0, +) / Double(times.count)
        let variance = times.map { pow($0 - average, 2) }.reduce(0, +) / Double(times.count)
        return sqrt(variance)
    }
}

public struct PerformanceReport {
    public let fps: Double
    public let averagePhysicsTime: CFTimeInterval
    public let averageRenderTime: CFTimeInterval
    public let physicsTimeVariance: CFTimeInterval
    public let renderTimeVariance: CFTimeInterval

    public var isPerformanceGood: Bool {
        return fps >= 55 && averagePhysicsTime < 8.0 && averageRenderTime < 12.0
    }

    public var performanceGrade: String {
        switch fps {
        case 55...:
            return "Excellent"
        case 45..<55:
            return "Good"
        case 30..<45:
            return "Fair"
        default:
            return "Poor"
        }
    }
}