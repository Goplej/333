#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
uniform sampler2D texture;
uniform float rainStrength;
varying vec2 texcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
void main(){
    vec4 c=texture2D(texture,texcoord)*vertexColor;
    if(c.a<.02)discard;
    c.rgb=mix(c.rgb,vec3(.32,.35,.40),rainStrength*.58);
    gl_FragData[0]=c;
    gl_FragData[1]=vec4(normalize(viewNormal)*.5+.5,1.0);
    gl_FragData[2]=vec4(1.0,1.0,0.0,0.0);
}
