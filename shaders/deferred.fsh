#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:0 */
uniform sampler2D colortex0;
varying vec2 texcoord;
void main(){ gl_FragData[0]=texture2D(colortex0,texcoord); }
