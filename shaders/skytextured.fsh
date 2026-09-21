#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:0 */
uniform sampler2D texture;
varying vec2 texcoord;
varying vec4 color;
void main(){ vec4 c=texture2D(texture,texcoord)*color; if(c.a<0.01)discard; gl_FragData[0]=c; }
