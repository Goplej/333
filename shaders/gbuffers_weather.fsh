#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
uniform sampler2D texture;
uniform float rainStrength;
uniform float frameTimeCounter;
varying vec2 texcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
void main(){
    vec4 drop=texture2D(texture,texcoord)*vertexColor;
    if(drop.a<.03)discard;
    float sparkle=.82+.18*sin(frameTimeCounter*11.0+gl_FragCoord.y*.17);
    drop.rgb*=mix(vec3(.72,.80,.88),vec3(.92,.96,1.0),sparkle);
    gl_FragData[0]=vec4(drop.rgb,drop.a*(.55+.35*rainStrength));
    gl_FragData[1]=vec4(.5,.5,1.0,1.0);
    gl_FragData[2]=vec4(1.0,1.0,0.0,.05);
}
