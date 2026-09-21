#version 120
uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertexColor;
varying vec3 viewPos;
varying vec3 worldPos;
varying vec3 viewNormal;
void main() {
    vec4 v = gl_Vertex;
    vec3 wp = (gbufferModelViewInverse * gl_ModelViewMatrix * v).xyz;
    float wave = sin(wp.x * 0.16 + frameTimeCounter * 1.35) * 0.018;
    wave += sin(wp.z * 0.21 - frameTimeCounter * 1.05) * 0.014;
    v.y += wave;
    vec4 vp = gl_ModelViewMatrix * v;
    gl_Position = gl_ProjectionMatrix * vp;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    viewPos = vp.xyz; worldPos = wp;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
}
