# Metal Ray Tracer

A high-performance, real-time 3D ray-tracing engine built from scratch using **Swift** and **Metal Compute Shaders**.

## 🚀 Overview
This project demonstrates how to build a custom 3D rendering engine *without* relying on high-level frameworks such as SceneKit, RealityKit, or Unity.  
Instead, it directly connects **Swift (CPU)** with **Metal Shading Language (GPU)** to simulate realistic light behavior in real time.

Unlike the traditional vertex/fragment pipeline, this engine uses **Compute Kernels**, launching **one GPU thread per pixel** to calculate ray–sphere intersections, diffuse lighting, hard shadows, and multi-bounce reflections.

## ✨ Features
- **Pure Metal Implementation**
- **Compute Shaders**
- **Real-Time Performance (~60 FPS)**
- **Physics-Inspired Rendering:**  
  - Ray–Sphere Intersection  
  - Lambertian Diffuse Lighting  
  - Hard Shadows  
  - Recursive Reflections  

## 📁 Directory Structure
```
MetalRayTracerSwift/
├── App/
├── UI/
├── Renderer/
└── Shaders/
```

## 🛠️ Getting Started
### Prerequisites
- Xcode 13.0+
- iOS 15+

### Installation
1. Clone repo  
2. Open project  
3. Run on device  

## 🧩 Technical Architecture

### 1. Memory “Mirroring” Pattern
`ShaderTypes.h` defines GPU structs;  
`Renderer.swift` mirrors them in Swift.  
They must remain identical.

### 2. Compute Pipeline
- CPU updates uniforms + scene  
- GPU runs `rayTracingKernel` per pixel  
- Performs intersection, shading, reflections  

## 🎨 Customization Example
```swift
spheres.append(Sphere(
    center: SIMD3<Float>(0, 5, 0),
    radius: 1.0,
    color: SIMD3<Float>(0, 1, 0),
    specular: 0.5
))
```

## 📄 License
Open source for educational and experimental use.
