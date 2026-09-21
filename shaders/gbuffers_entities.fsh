#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
#include "/lib/common.glsl"
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec4 entityColor;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
void main() {
    vec4 texel=texture2D(texture,texcoord);
    if(texel.a<.1) discard;
    vec3 albedo=texel.rgb*vertexColor.rgb;
    albedo=mix(albedo,entityColor.rgb,entityColor.a*.65);
    vec3 light=texture2D(lightmap,lmcoord).rgb;
    float rim=pow(1.0-abs(normalize(viewNormal).z),3.0);
    albedo*=light+rim*vec3(.035,.025,.018);
    gl_FragData[0]=vec4(albedo,texel.a*vertexColor.a);
    gl_FragData[1]=vec4(encodeNormal(normalize(viewNormal)),1.0);
    gl_FragData[2]=vec4(lmcoord,0.0,.1);
}
