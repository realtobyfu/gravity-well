import Foundation
import Metal
import MetalKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import simd

@available(iOS 17.0, macOS 14.0, *)
public final class MetalRenderer: NSObject {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var renderPipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?

    private let maxObjectsCount = 2000
    private var objectsData: [ObjectInstanceData] = []

    public var viewportSize: simd_uint2 = simd_uint2(800, 600)

    public override init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        self.device = device
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        self.commandQueue = commandQueue

        super.init()
        setupMetal()
    }

    private func setupMetal() {
        createRenderPipeline()
        createBuffers()
    }

    private func createRenderPipeline() {
        let library = createShaderLibrary()

        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<simd_float2>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
    }

    private func createShaderLibrary() -> MTLLibrary {
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float2 position [[attribute(0)]];
        };

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
            float4 color;
            float radius;
            float2 center;
        };

        struct ObjectInstance {
            float2 position;
            float radius;
            float4 color;
            int shapeType;
        };

        struct Uniforms {
            float2 viewportSize;
            float time;
        };

        vertex VertexOut vertex_main(
            VertexIn in [[stage_in]],
            constant ObjectInstance *instances [[buffer(1)]],
            constant Uniforms &uniforms [[buffer(2)]],
            uint instanceID [[instance_id]]
        ) {
            VertexOut out;

            ObjectInstance instance = instances[instanceID];

            float2 scaledPosition = in.position * instance.radius;
            float2 worldPosition = scaledPosition + instance.position;

            float2 normalizedPosition = (worldPosition / uniforms.viewportSize) * 2.0 - 1.0;
            normalizedPosition.y = -normalizedPosition.y;

            out.position = float4(normalizedPosition, 0.0, 1.0);
            out.texCoord = in.position;
            out.color = instance.color;
            out.radius = instance.radius;
            out.center = instance.position;

            return out;
        }

        fragment float4 fragment_main(
            VertexOut in [[stage_in]],
            constant Uniforms &uniforms [[buffer(0)]]
        ) {
            float2 coord = in.texCoord;
            float distance = length(coord);

            // Anti-aliased circle
            float alpha = 1.0 - smoothstep(0.9, 1.0, distance);

            // Add some visual effects
            float pulse = sin(uniforms.time * 3.0) * 0.1 + 0.9;
            float4 color = in.color;
            color.rgb *= pulse;
            color.a *= alpha;

            return color;
        }
        """

        do {
            return try device.makeLibrary(source: shaderSource, options: nil)
        } catch {
            fatalError("Failed to create shader library: \(error)")
        }
    }

    private func createBuffers() {
        let quadVertices: [simd_float2] = [
            simd_float2(-1, -1),
            simd_float2( 1, -1),
            simd_float2(-1,  1),
            simd_float2( 1,  1)
        ]

        vertexBuffer = device.makeBuffer(
            bytes: quadVertices,
            length: quadVertices.count * MemoryLayout<simd_float2>.stride,
            options: []
        )

        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<RenderUniforms>.stride,
            options: [.storageModeShared]
        )
    }

    public func render(
        objects: [PhysicsBody],
        forceFields: [ForceField],
        in view: MTKView,
        time: TimeInterval
    ) {
        guard let renderPipelineState = renderPipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        updateObjectsData(objects: objects, forceFields: forceFields)
        updateUniforms(time: time)

        guard !objectsData.isEmpty else {
            renderEncoder.endEncoding()
            commandBuffer.present(view.currentDrawable!)
            commandBuffer.commit()
            return
        }

        let instanceBuffer = device.makeBuffer(
            bytes: objectsData,
            length: objectsData.count * MemoryLayout<ObjectInstanceData>.stride,
            options: []
        )

        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 2)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)

        renderEncoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: 4,
            instanceCount: objectsData.count
        )

        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }

    private func updateObjectsData(objects: [PhysicsBody], forceFields: [ForceField]) {
        objectsData.removeAll()

        for object in objects {
            let color = getColor(for: object)
            let instanceData = ObjectInstanceData(
                position: object.position,
                radius: object.radius,
                color: simd_float4(
                    Float(color.cgColor.components?[0] ?? 0),
                    Float(color.cgColor.components?[1] ?? 0),
                    Float(color.cgColor.components?[2] ?? 0),
                    Float(color.cgColor.alpha)
                ),
                shapeType: getShapeType(for: object)
            )
            objectsData.append(instanceData)
        }

        for field in forceFields {
            if let visualizable = field as? VisualizableForceField {
                let color = visualizable.visualColor
                let instanceData = ObjectInstanceData(
                    position: field.position,
                    radius: min(field.range * 0.1, 30),
                    color: simd_float4(
                        Float(color.cgColor.components?[0] ?? 0),
                        Float(color.cgColor.components?[1] ?? 0),
                        Float(color.cgColor.components?[2] ?? 0),
                        0.3
                    ),
                    shapeType: 0
                )
                objectsData.append(instanceData)
            }
        }
    }

    private func updateUniforms(time: TimeInterval) {
        guard let uniformBuffer = uniformBuffer else { return }

        let uniforms = RenderUniforms(
            viewportSize: simd_float2(Float(viewportSize.x), Float(viewportSize.y)),
            time: Float(time)
        )

        let uniformPointer = uniformBuffer.contents().bindMemory(
            to: RenderUniforms.self,
            capacity: 1
        )
        uniformPointer[0] = uniforms
    }

    #if canImport(UIKit)
    private func getColor(for object: PhysicsBody) -> UIColor {
        if let shape = object as? PhysicsShape {
            return shape.color
        } else if let particle = object as? PhysicsParticle {
            let ageRatio = Float(particle.age / particle.lifetime)
            let alpha = 1.0 - ageRatio
            return particle.color.withAlphaComponent(CGFloat(alpha))
        }
        return .systemBlue
    }
    #else
    private func getColor(for object: PhysicsBody) -> NSColor {
        if let shape = object as? PhysicsShape {
            return shape.color
        } else if let particle = object as? PhysicsParticle {
            let ageRatio = Float(particle.age / particle.lifetime)
            let alpha = 1.0 - ageRatio
            return particle.color.withAlphaComponent(CGFloat(alpha))
        }
        return .systemBlue
    }
    #endif

    private func getShapeType(for object: PhysicsBody) -> Int32 {
        if let shape = object as? PhysicsShape {
            switch shape.shapeType {
            case .circle: return 0
            case .rectangle: return 1
            case .polygon: return 2
            }
        }
        return 0
    }
}

private struct ObjectInstanceData {
    let position: simd_float2
    let radius: Float
    let color: simd_float4
    let shapeType: Int32
    private let padding: simd_float3 = simd_float3(0, 0, 0)
}

private struct RenderUniforms {
    let viewportSize: simd_float2
    let time: Float
    private let padding: Float = 0
}

public protocol VisualizableForceField: ForceField {
    #if canImport(UIKit)
    var visualColor: UIColor { get }
    #else
    var visualColor: NSColor { get }
    #endif
}

#if canImport(UIKit)
@available(iOS 17.0, macOS 14.0, *)
extension GravityWell: VisualizableForceField {
    public var visualColor: UIColor { color }
}

@available(iOS 17.0, macOS 14.0, *)
extension RepulsionField: VisualizableForceField {
    public var visualColor: UIColor { .systemRed }
}
#else
@available(iOS 17.0, macOS 14.0, *)
extension GravityWell: VisualizableForceField {
    public var visualColor: NSColor { color }
}

@available(iOS 17.0, macOS 14.0, *)
extension RepulsionField: VisualizableForceField {
    public var visualColor: NSColor { .systemRed }
}
#endif