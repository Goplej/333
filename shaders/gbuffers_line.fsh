#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
uniform sampler2D texture;
uniform sampler2D lightmap;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
void main() {
    vec4 albedo = texture2D(texture, texcoord) * vertexColor;
    if (albedo.a < 0.1) discard;
    vec3 light = texture2D(lightmap, lmcoord).rgb;
    gl_FragData[0] = vec4(albedo.rgb * light, albedo.a);
    gl_FragData[1] = vec4(viewNormal * 0.5 + 0.5, 1.0);
    gl_FragData[2] = vec4(lmcoord, 0.0, 1.0);
}
