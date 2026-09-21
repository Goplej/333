#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"
uniform sampler2D noisetex;
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform int worldTime;
varying vec3 worldDir;
varying vec4 skyColor;

// Один «3D» noise sample = две дешёвые выборки из 2D noise, смешанные по высоте.
float noise3Dcheap(vec3 p, float speed) {
    vec2 wind = vec2(frameTimeCounter * speed, frameTimeCounter * speed * 0.37);
    float z = floor(p.y);
    float f = fract(p.y);
    vec2 uv0 = p.xz + vec2(z * 0.071, z * 0.113) + wind;
    vec2 uv1 = p.xz + vec2((z + 1.0) * 0.071, (z + 1.0) * 0.113) + wind;
    return mix(texture2D(noisetex, fract(uv0)).r,
               texture2D(noisetex, fract(uv1)).r, f * f * (3.0 - 2.0 * f));
}
float cloudShape(vec3 p) {
    // Четыре слоя/октавы движутся с разной скоростью.
    float n = noise3Dcheap(p * 0.0008 * CLOUD_SCALE, 0.0019) * 0.52;
    n += noise3Dcheap(p * 0.0016 * CLOUD_SCALE + 13.1, -0.0012) * 0.27;
    n += noise3Dcheap(p * 0.0032 * CLOUD_SCALE + 37.7, 0.0031) * 0.14;
    n += noise3Dcheap(p * 0.0064 * CLOUD_SCALE + 71.3, -0.0042) * 0.07;
    return smoothstep(CLOUD_COVERAGE - 0.10, CLOUD_COVERAGE + 0.12, n);
}
void main() {
    vec3 rd = normalize(worldDir);
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 color = analyticSky(rd, sunDir, rainStrength, float(worldTime) / 24000.0);
// Объёмный слой строится один раз в composite, без двойного шума.

    gl_FragData[0] = vec4(color * skyColor.rgb, 1.0);
}
