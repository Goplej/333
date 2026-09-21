#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:4 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
uniform sampler2D colortex3;
uniform float viewWidth;
uniform float viewHeight;
varying vec2 texcoord;
void main(){
#ifndef BLOOM
    gl_FragData[0]=vec4(0.0);
#else
    vec2 px=vec2(1.0/viewWidth,1.0/viewHeight)*(2.0+float(BLOOM_QUALITY));
    vec3 c=texture2D(colortex3,texcoord).rgb;
    if(luma(c)<0.62){ gl_FragData[0]=vec4(0.0); return; } // early exit тёмных блоков
    vec3 b=c*0.28;
    b+=texture2D(colortex3,texcoord+vec2(px.x,0)).rgb*.14;
    b+=texture2D(colortex3,texcoord-vec2(px.x,0)).rgb*.14;
    b+=texture2D(colortex3,texcoord+vec2(0,px.y)).rgb*.14;
    b+=texture2D(colortex3,texcoord-vec2(0,px.y)).rgb*.14;
#if BLOOM_QUALITY > 0
    b+=texture2D(colortex3,texcoord+px).rgb*.08;
    b+=texture2D(colortex3,texcoord-px).rgb*.08;
#endif
    b=max(b-vec3(.62),vec3(0.0));
    gl_FragData[0]=vec4(b,1.0);
#endif
}
