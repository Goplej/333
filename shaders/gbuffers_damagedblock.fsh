#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
uniform sampler2D texture;
varying vec2 texcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
void main(){
    vec4 crack=texture2D(texture,texcoord)*vertexColor;
    if(crack.a<.02)discard;
    gl_FragData[0]=vec4(crack.rgb*.28,crack.a*.72);
    gl_FragData[1]=vec4(normalize(viewNormal)*.5+.5,1.0);
    gl_FragData[2]=vec4(0.0);
}
