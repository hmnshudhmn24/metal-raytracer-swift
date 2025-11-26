#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

// MARK: - Constants
constant float FLT_MAX = 1e37f;
constant int MAX_REFLECTIONS = 3;

// MARK: - Structures
struct Ray {
    float3 origin;
    float3 direction;
};

// MARK: - Math Functions
float intersectSphere(Ray ray, Sphere sphere) {
    float3 oc = ray.origin - sphere.center;
    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.radius * sphere.radius;
    float discriminant = b * b - 4 * a * c;

    if (discriminant < 0) {
        return -1.0;
    } else {
        return (-b - sqrt(discriminant)) / (2.0 * a);
    }
}

// MARK: - Tracing Logic
float3 trace(Ray ray, constant Sphere *spheres, int sphereCount, float3 lightDir) {
    float3 color = float3(0.0);
    float3 mask = float3(1.0); // Reflection mask

    for (int bounce = 0; bounce < MAX_REFLECTIONS; bounce++) {
        float closestDist = FLT_MAX;
        int closestIndex = -1;

        // Find closest object
        for (int i = 0; i < sphereCount; i++) {
            float dist = intersectSphere(ray, spheres[i]);
            if (dist > 0.001 && dist < closestDist) {
                closestDist = dist;
                closestIndex = i;
            }
        }

        // Sky Color (Gradient)
        if (closestIndex == -1) {
            float3 skyTop = float3(0.1, 0.1, 0.3);
            float3 skyBottom = float3(0.05, 0.05, 0.1);
            float t = 0.5 * (ray.direction.y + 1.0);
            color += mask * mix(skyBottom, skyTop, t);
            break;
        }

        // Hit Object
        Sphere sphere = spheres[closestIndex];
        float3 hitPoint = ray.origin + ray.direction * closestDist;
        float3 normal = normalize(hitPoint - sphere.center);

        // Shadow Ray
        Ray shadowRay;
        shadowRay.origin = hitPoint + normal * 0.001;
        shadowRay.direction = lightDir;

        bool inShadow = false;
        for (int j = 0; j < sphereCount; j++) {
            if (intersectSphere(shadowRay, spheres[j]) > 0.0) {
                inShadow = true;
                break;
            }
        }

        // Calculate Diffuse Lighting
        float diff = max(dot(normal, lightDir), 0.0);
        if (inShadow) diff *= 0.1; // Ambient only if in shadow

        float3 sphereColor = sphere.color * (diff + 0.1);
        color += mask * sphereColor * (1.0 - sphere.specular);

        // Prepare for next bounce (if reflective)
        mask *= sphere.specular;
        if (sphere.specular <= 0.0) break;

        ray.origin = hitPoint + normal * 0.001;
        ray.direction = reflect(ray.direction, normal);
    }

    return color;
}

// MARK: - Main Kernel
kernel void rayTracingKernel(texture2d<float, access::write> output [[texture(0)]],
                             constant Uniforms &uniforms [[buffer(0)]],
                             constant Sphere *spheres [[buffer(1)]],
                             uint2 gid [[thread_position_in_grid]]) {

    // 1. Boundary Check
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) { return; }

    // 2. UV Mapping
    float width = float(output.get_width());
    float height = float(output.get_height());
    float2 uv = float2(gid) / float2(width, height);
    uv = uv * 2.0 - 1.0;
    uv.y = -uv.y;
    uv.x *= width / height; // Fix Aspect Ratio

    // 3. Camera Vectors
    float3 camOrigin = uniforms.cameraPosition;
    float3 camTarget = uniforms.cameraTarget;
    float3 forward = normalize(camTarget - camOrigin);
    float3 right = normalize(cross(forward, float3(0.0, 1.0, 0.0)));
    float3 up = cross(right, forward);

    // 4. Generate Primary Ray
    float3 rayDir = normalize(forward * 1.5 + right * uv.x + up * uv.y);
    Ray ray = { camOrigin, rayDir };

    // 5. Trace
    float3 lightDir = normalize(float3(1.0, 1.0, -0.5));
    // Note: 4 is the hardcoded number of spheres in Renderer.swift
    float3 pixelColor = trace(ray, spheres, 4, lightDir);

    // 6. Write Output
    output.write(float4(pixelColor, 1.0), gid);
}
