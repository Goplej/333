#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
#include "/lib/common.glsl"
uniform sampler2D texture;
uniform sampler2D lightmap;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
void main(){
    vec4 a=texture2D(texture,texcoord)*vertexColor;
    if(a.a<.1)discard;
    vec3 lm=texture2D(lightmap,lmcoord).rgb;
    float facing=.88+.12*saturate(normalize(viewNormal).y);
    gl_FragData[0]=vec4(a.rgb*lm*facing,a.a);
    gl_FragData[1]=vec4(encodeNormal(normalize(viewNormal)),1.0);
    gl_FragData[2]=vec4(lmcoord,0.0,.08);
}
