# GravityWell Demo App

A standalone iOS demo application for the GravityWell physics framework, designed for testing and profiling with Instruments.

## Features

- **Visual Physics Simulation**: Real-time Metal-based rendering of physics objects
- **Interactive Controls**: Add shapes and gravity wells with touch gestures
- **Performance Monitoring**: Built-in FPS counter and object tracking
- **Siri Integration**: Voice control for physics parameters
- **Profiling Ready**: Optimized for Instruments analysis

## Setup

### Requirements
- Xcode 15.0+
- iOS 17.0+ device or simulator
- macOS 14.0+ for development

### Building and Running

1. **Open in Xcode**:
   ```bash
   ./open-in-xcode.sh
   ```
   Or manually open `Package.swift` in Xcode.

2. **Select Scheme**: Choose "GravityWellDemo" from the scheme selector

3. **Run**: Press ⌘R to build and run on simulator or device

## Profiling with Instruments

### Time Profiler
1. In Xcode, select Product → Profile (⌘I)
2. Choose "Time Profiler" template
3. Click Record to start profiling
4. Interact with the app to generate physics simulations
5. Analyze CPU usage and identify performance bottlenecks

### Allocations
1. Select the "Allocations" template in Instruments
2. Monitor memory usage and object lifecycle
3. Check for memory leaks in the object pooling system

### Metal System Trace
1. Use "Metal System Trace" for GPU performance analysis
2. Examine rendering pipeline efficiency
3. Optimize Metal shader performance

## App Controls

### Touch Gestures
- **Tap**: Add a physics shape at tap location
- **Long Press**: Create a gravity well at press location

### UI Controls
- **Gravity Selector**: Switch between Earth, Moon, Mars, Jupiter, Sun gravity
- **Add Shapes**: Spawn multiple random shapes
- **Add Gravity Well**: Create a new gravity well
- **Clear All**: Remove all objects from simulation
- **Pause/Resume**: Control simulation playback
- **Reset**: Clear and reinitialize with default objects

### Siri Commands
Enable Siri shortcuts in iOS Settings for voice control:
- "Set gravity to Jupiter"
- "Spawn 10 shapes"
- "Create gravity well"
- "Clear simulation"

## Performance Metrics

The app displays real-time performance data:
- **FPS**: Frames per second (target: 60)
- **Objects**: Current physics body count
- **Physics Time**: Average time for physics calculations
- **Render Time**: GPU rendering duration

## Architecture

The demo app uses:
- **SwiftUI** for the user interface
- **Metal** for hardware-accelerated rendering
- **GravityWellKit** for physics simulation
- **Combine** for reactive updates

## Debugging

### Common Issues

1. **Low FPS**:
   - Reduce object count
   - Decrease gravity well range
   - Check for excessive force calculations

2. **Memory Growth**:
   - Verify object pooling is working
   - Check for retained references
   - Monitor with Allocations instrument

3. **Rendering Issues**:
   - Ensure Metal device is available
   - Check viewport size calculations
   - Verify shader compilation

## Development

### Project Structure
```
GravityWellDemo/
├── AppDelegate.swift       # App lifecycle
├── SceneDelegate.swift     # Scene management
├── ContentView.swift       # Main UI
├── PhysicsView.swift       # Metal rendering view
├── PhysicsViewModel.swift  # Business logic
└── Info.plist             # App configuration
```

### Adding Features

To add new physics features:
1. Implement in GravityWellKit framework
2. Update PhysicsViewModel with new controls
3. Add UI elements in ContentView
4. Test performance impact with Instruments

## License

This demo app is part of the GravityWell framework and follows the same license terms.