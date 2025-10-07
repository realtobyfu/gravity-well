import SwiftUI
import UIKit
import MetalKit
import GravityWellKit

struct PhysicsView: UIViewRepresentable {
    @ObservedObject var viewModel: PhysicsViewModel

    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        metalView.delegate = context.coordinator
        metalView.preferredFramesPerSecond = 60
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false

        // Set up tap gesture for adding objects
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        metalView.addGestureRecognizer(tapGesture)

        // Set up long press gesture for gravity wells
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        metalView.addGestureRecognizer(longPressGesture)

        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Update Metal view if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var viewModel: PhysicsViewModel
        var renderer: MetalRenderer?

        init(viewModel: PhysicsViewModel) {
            self.viewModel = viewModel
            super.init()

            if let device = MTLCreateSystemDefaultDevice() {
                do {
                    self.renderer = try MetalRenderer(device: device)
                } catch {
                    print("Failed to create renderer: \(error)")
                }
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            renderer?.viewportSize = simd_uint2(UInt32(size.width), UInt32(size.height))
        }

        func draw(in view: MTKView) {
            guard let renderer = renderer,
                  let drawable = view.currentDrawable,
                  let world = viewModel.world else { return }

            // Update FPS
            viewModel.updateFPS()

            // Render the physics world
            renderer.render(
                world: world,
                to: drawable,
                viewportSize: CGSize(width: CGFloat(view.drawableSize.width),
                                    height: CGFloat(view.drawableSize.height))
            )
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            viewModel.addShape(at: location)
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            let location = gesture.location(in: gesture.view)
            viewModel.addGravityWell(at: location)
        }
    }
}