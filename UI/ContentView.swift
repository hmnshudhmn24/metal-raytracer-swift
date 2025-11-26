import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    func makeCoordinator() -> Renderer {
        let view = MTKView()
        // Initialize the renderer with a temporary view to check support
        guard let renderer = Renderer(metalKitView: view) else {
            fatalError("Metal is not supported on this device")
        }
        return renderer
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false

        // Critical: Allow writing to the texture from a Compute Kernel
        view.framebufferOnly = false

        // Use the device created by the renderer
        view.device = context.coordinator.device

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Updates are handled by the Renderer delegate
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            MetalView()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text("Swift Metal Ray Tracer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                Spacer()
                Text("Drag to look around (Implementation Pending)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom)
            }
            .padding(.top, 50)
        }
    }
}
