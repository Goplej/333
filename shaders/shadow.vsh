#version 120
#ifdef GL_ES
precision mediump float;
#endif
#include "/lib/settings.glsl"
attribute vec4 mc_Entity;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform mat4 shadowModelViewInverse;
varying vec2 texcoord;
varying vec4 color;
void main(){
    vec4 vertex=gl_Vertex;
#ifdef WAVING_FOLIAGE
    float id=mc_Entity.x;
    if(id>10000.5&&id<10002.5){
        vec3 wp=(shadowModelViewInverse*gl_ModelViewMatrix*vertex).xyz+cameraPosition;
        float phase=dot(wp.xz,vec2(.071,.053));
        float gust=sin(frameTimeCounter*1.65+phase)*.62+sin(frameTimeCounter*.73-phase*1.91)*.26;
        float strength=(id<10001.5?.055:.085)*WAVE_STRENGTH;
        vertex.xz+=vec2(gust,gust*.57)*strength*clamp(gl_MultiTexCoord0.t*1.35,0.0,1.0);
    }
#endif
    gl_Position=gl_ProjectionMatrix*gl_ModelViewMatrix*vertex;
    // Perspective shadow distortion concentrates texels around the player.
    float shadowRadius=length(gl_Position.xy);
    gl_Position.xy/=mix(1.0,shadowRadius,.84);
    texcoord=(gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;
    color=gl_Color;
}
