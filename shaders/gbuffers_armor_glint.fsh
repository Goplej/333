#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
#include "/lib/common.glsl"
uniform sampler2D texture;
uniform float frameTimeCounter;
varying vec2 texcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
void main(){
    vec2 uv=texcoord+vec2(frameTimeCounter*.015,-frameTimeCounter*.009);
    vec4 g=texture2D(texture,uv)*vertexColor;
    if(g.a<.02)discard;
    float pulse=.78+.22*sin(frameTimeCounter*2.3+texcoord.x*18.0);
    gl_FragData[0]=vec4(g.rgb*vec3(.82,.64,1.18)*pulse,g.a*.68);
    gl_FragData[1]=vec4(encodeNormal(normalize(viewNormal)),1.0);
    gl_FragData[2]=vec4(1.0,1.0,0.0,.5);
}
