# Gravity Well - Physics Framework with Visual Intelligence

A high-performance iOS physics framework built with Swift, featuring visual intelligence integration and App Intents support for natural language physics control.

## Features

- 🚀 **High Performance**: 60 FPS with 1000+ concurrent objects
- 🧠 **Visual Intelligence**: Camera-based shape recognition and interaction
- 🗣️ **App Intents**: Voice control ("Set gravity to Jupiter", "Spawn 10 shapes")
- 🔧 **Extensible**: Protocol-oriented architecture for third-party extensions
- ⚡ **Optimized**: Multi-threaded physics with spatial partitioning

## Quick Start

```swift
import GravityWellKit

// Create physics world
let world = PhysicsWorld()

// Add gravity well
let gravityWell = GravityWell(
    position: CGPoint(x: 200, y: 200),
    strength: 1000
)
world.addForceField(gravityWell)

// Spawn physics objects
let shape = PhysicsShape(
    type: .circle,
    radius: 20,
    position: CGPoint(x: 100, y: 100)
)
world.addBody(shape)

// Start simulation
world.startSimulation()
```

## Demo App

A standalone iOS demo application is available in the `GravityWellDemo/` directory for testing and profiling with Instruments. See [GravityWellDemo/README.md](GravityWellDemo/README.md) for setup instructions.

## Architecture

- **Physics Layer**: UIKit Dynamics with custom extensions
- **Rendering Layer**: Metal-accelerated graphics pipeline
- **Intelligence Layer**: Core ML + Vision for shape recognition
- **Intent Layer**: App Intents for Siri integration

## Performance

- Spatial partitioning for O(n log n) collision detection
- Object pooling for memory efficiency
- GCD-based multi-threading
- Cache-friendly data structures

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+