#version 120
uniform mat4 gbufferModelViewInverse;
varying vec3 worldDir;
varying vec4 skyColor;
void main() {
    gl_Position = ftransform();
    worldDir = normalize(mat3(gbufferModelViewInverse) * gl_Vertex.xyz);
    skyColor = gl_Color;
}
