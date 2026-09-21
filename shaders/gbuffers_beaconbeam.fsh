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
    if(a.a<.01)discard;
    float core=pow(saturate(1.0-abs(texcoord.x-.5)*2.0),2.0);
    vec3 emission=a.rgb*(1.25+core*1.8);
    gl_FragData[0]=vec4(emission,a.a*.72);
    gl_FragData[1]=vec4(encodeNormal(normalize(viewNormal)),1.0);
    gl_FragData[2]=vec4(1.0,1.0,0.0,.75);
}
