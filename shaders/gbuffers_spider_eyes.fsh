#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
#include "/lib/common.glsl"
uniform sampler2D texture;
varying vec2 texcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
void main(){
    vec4 a=texture2D(texture,texcoord)*vertexColor;
    if(a.a<.05)discard;
    gl_FragData[0]=vec4(a.rgb*1.65,a.a);
    gl_FragData[1]=vec4(encodeNormal(normalize(viewNormal)),1.0);
    gl_FragData[2]=vec4(1.0,1.0,0.0,.75);
}
