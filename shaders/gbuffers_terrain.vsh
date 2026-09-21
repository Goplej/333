#version 120
#ifdef GL_ES
precision mediump float;
#endif
#include "/lib/settings.glsl"
attribute vec4 mc_Entity;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
varying vec3 worldPos;
varying float materialId;

vec3 animateVegetation(vec3 p, float id) {
#ifdef WAVING_FOLIAGE
    float topMask = clamp(gl_MultiTexCoord0.t * 1.35, 0.0, 1.0);
    float phase = dot(p.xz, vec2(0.071, 0.053));
    float gust = sin(frameTimeCounter * 1.65 + phase) * 0.62;
    gust += sin(frameTimeCounter * 0.73 - phase * 1.91) * 0.26;
    gust += sin(frameTimeCounter * 2.31 + p.z * 0.037) * 0.12;
    if (id > 10000.5 && id < 10002.5) {
        float strength = (id < 10001.5 ? 0.055 : 0.085) * WAVE_STRENGTH;
        p.xz += vec2(gust, gust * 0.57) * strength * topMask;
        p.y += sin(frameTimeCounter * 1.2 + phase * 1.4) * strength * 0.16 * topMask;
    }
#endif
    return p;
}
void main() {
    materialId = mc_Entity.x;
    vec4 vertex = gl_Vertex;
    vec3 relativeWorld = (gbufferModelViewInverse * gl_ModelViewMatrix * vertex).xyz;
    vec3 absoluteWorld = relativeWorld + cameraPosition;
    vec3 animatedWorld = animateVegetation(absoluteWorld, materialId);
    vertex.xyz += animatedWorld - absoluteWorld;
    vec4 view = gl_ModelViewMatrix * vertex;
    gl_Position = gl_ProjectionMatrix * view;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    worldPos = animatedWorld;
}
