#version 120
#ifdef GL_ES
precision mediump float;
#endif
uniform sampler2D texture;
varying vec2 texcoord;
varying vec4 color;
void main(){ vec4 a=texture2D(texture,texcoord)*color; if(a.a<0.15)discard; gl_FragColor=vec4(1.0); }
