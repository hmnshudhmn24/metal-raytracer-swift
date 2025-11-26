import Metal
import MetalKit
import SIMD

// MARK: - Swift Mirror of ShaderTypes
// These must match the C structs in ShaderTypes.h exactly.

struct Sphere {
    var center: SIMD3<Float>
    var radius: Float
    var color: SIMD3<Float>
    var specular: Float
}

struct Uniforms {
    var cameraPosition: SIMD3<Float>
    var cameraTarget: SIMD3<Float>
    var resolution: SIMD2<Float>
    var time: Float
}

// MARK: - Renderer
class Renderer: NSObject, MTKViewDelegate {

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var computePipelineState: MTLComputePipelineState!

    // Scene Data
    var spheres: [Sphere] = []
    var spheresBuffer: MTLBuffer!

    // Animation
    var startTime: Date = Date()

    init?(metalKitView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else { return nil }

        self.device = device
        self.commandQueue = queue
        super.init()

        metalKitView.device = device
        metalKitView.delegate = self

        setupScene()
        buildPipelineState()
    }

    func setupScene() {
        // 1. Red Sphere
        spheres.append(Sphere(center: SIMD3<Float>(0, 0, 0), radius: 1.0, color: SIMD3<Float>(1, 0, 0), specular: 0.2))
        // 2. Ground Sphere (Huge sphere acting as a floor)
        spheres.append(Sphere(center: SIMD3<Float>(0, -101, 0), radius: 100.0, color: SIMD3<Float>(0.5, 0.5, 0.5), specular: 0.0))
        // 3. Mirror Sphere
        spheres.append(Sphere(center: SIMD3<Float>(-2.2, 0, -1), radius: 1.0, color: SIMD3<Float>(0.9, 0.9, 0.9), specular: 0.95))
        // 4. Blue Sphere
        spheres.append(Sphere(center: SIMD3<Float>(2.2, 0, -1), radius: 1.0, color: SIMD3<Float>(0, 0, 1), specular: 0.5))

        // Create the buffer to send to GPU
        let size = spheres.count * MemoryLayout<Sphere>.stride
        spheresBuffer = device.makeBuffer(bytes: spheres, length: size, options: .storageModeShared)
    }

    func buildPipelineState() {
        // Load the shader function from the default library (Shaders.metal)
        guard let library = device.makeDefaultLibrary(),
              let kernelFunction = library.makeFunction(name: "rayTracingKernel") else {
            fatalError("Could not find 'rayTracingKernel' in Shaders.metal")
        }

        do {
            computePipelineState = try device.makeComputePipelineState(function: kernelFunction)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    // Called when window resizes
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    // Called every frame
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

        // Calculate Thread Groups
        let w = computePipelineState.threadExecutionWidth
        let h = computePipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)

        let width = Int(view.drawableSize.width)
        let height = Int(view.drawableSize.height)
        let threadsPerGrid = MTLSizeMake(width, height, 1)

        // Update Uniforms (Animation Logic)
        let time = Float(Date().timeIntervalSince(startTime))
        let camX = sin(time * 0.5) * 6.0
        let camZ = cos(time * 0.5) * 6.0 + 5.0

        var uniforms = Uniforms(
            cameraPosition: SIMD3<Float>(camX, 2.0, camZ),
            cameraTarget: SIMD3<Float>(0, 0, 0),
            resolution: SIMD2<Float>(Float(width), Float(height)),
            time: time
        )

        // Encode Commands
        commandEncoder.setComputePipelineState(computePipelineState)
        commandEncoder.setTexture(drawable.texture, index: 0)
        commandEncoder.setBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        commandEncoder.setBuffer(spheresBuffer, offset: 0, index: 1)

        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
