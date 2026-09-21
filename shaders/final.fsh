#version 120
#ifdef GL_ES
precision mediump float;
#endif
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 previousProjection;
uniform mat4 previousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;
varying vec2 texcoord;
vec3 viewFromDepthFinal(vec2 uv,float d){vec4 p=gbufferProjectionInverse*vec4(uv*2.0-1.0,d*2.0-1.0,1.0);return p.xyz/p.w;}
vec2 velocityAt(vec2 uv,float d){
    vec3 view=viewFromDepthFinal(uv,d);
    vec3 world=(gbufferModelViewInverse*vec4(view,1.0)).xyz+cameraPosition-previousCameraPosition;
    vec4 old=previousProjection*previousModelView*vec4(world,1.0);
    vec2 oldUV=old.xy/max(old.w,.0001)*.5+.5;
    return uv-oldUV;
}
void main(){
    vec2 uv=texcoord;
    if(isEyeInWater==1){
        // Две волны с разными фазами убирают регулярный «синусоидальный» вид.
        vec2 wobble=vec2(sin(uv.y*46.0+frameTimeCounter*2.1),cos(uv.x*39.0-frameTimeCounter*1.7));
        uv=clamp(uv+wobble*.0018,.002,.998);
    }
    float depth=texture2D(depthtex0,uv).r;
    vec3 color=texture2D(colortex3,uv).rgb;
#ifdef MOTION_BLUR
    vec2 vel=clamp(velocityAt(uv,depth)*MOTION_BLUR_STRENGTH,vec2(-.025),vec2(.025));
    if(dot(vel,vel)>0.0000005){
        color*=.30;
        color+=texture2D(colortex3,clamp(uv-vel*.55,0.0,1.0)).rgb*.20;
        color+=texture2D(colortex3,clamp(uv-vel*.20,0.0,1.0)).rgb*.20;
        color+=texture2D(colortex3,clamp(uv+vel*.20,0.0,1.0)).rgb*.15;
        color+=texture2D(colortex3,clamp(uv+vel*.55,0.0,1.0)).rgb*.15;
    }
#endif
#ifdef DOF
    float focus=texture2D(depthtex0,vec2(.5)).r;
    float coc=clamp(abs(depth-focus)*DOF_STRENGTH*18.0,0.0,.006);
    if(coc>.0002){
        vec2 a=vec2(coc,0.0), b=vec2(0.0,coc);
        color=color*.36+texture2D(colortex3,uv+a).rgb*.16+texture2D(colortex3,uv-a).rgb*.16
              +texture2D(colortex3,uv+b).rgb*.16+texture2D(colortex3,uv-b).rgb*.16;
    }
#endif
#ifdef BLOOM
    color+=texture2D(colortex4,uv).rgb*BLOOM_INTENSITY;
#endif
    if(isEyeInWater==1) color=mix(color,color*vec3(.54,.82,.88),.46);
#ifdef FXAA
    // Упрощённый FXAA: сохраняет резкость текстур, сглаживая только контрастные рёбра.
    vec2 fxpx=vec2(1.0/viewWidth,1.0/viewHeight);
    float lumC=luma(color);
    vec3 cN=texture2D(colortex3,clamp(uv+vec2(0.0,fxpx.y),0.0,1.0)).rgb;
    vec3 cS=texture2D(colortex3,clamp(uv-vec2(0.0,fxpx.y),0.0,1.0)).rgb;
    vec3 cE=texture2D(colortex3,clamp(uv+vec2(fxpx.x,0.0),0.0,1.0)).rgb;
    vec3 cW=texture2D(colortex3,clamp(uv-vec2(fxpx.x,0.0),0.0,1.0)).rgb;
    float edge=max(max(abs(lumC-luma(cN)),abs(lumC-luma(cS))),max(abs(lumC-luma(cE)),abs(lumC-luma(cW))));
    color=mix(color,(cN+cS+cE+cW)*.25,smoothstep(.08,.25,edge)*.36);
#endif
    color=acesFilm(cozyGrade(color*EXPOSURE));
    // G-buffer legacy pipeline уже содержит gamma-encoded texture/lightmap values.
    // Не применяем вторую gamma-коррекцию: она давала молочно-белую картинку.
    float vignette=1.0-dot(texcoord-.5,texcoord-.5)*.36;
    gl_FragColor=vec4(color*vignette,1.0);
}
