#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// Defines a sphere primitive in 3D space
struct Sphere {
    vector_float3 center;
    float radius;
    vector_float3 color;
    float specular; // 0.0 = Matte, 1.0 = Mirror
};

// Global scene data updated per frame
struct Uniforms {
    vector_float3 cameraPosition;
    vector_float3 cameraTarget;
    vector_float2 resolution;
    float time;
};

#endif /* ShaderTypes_h */
