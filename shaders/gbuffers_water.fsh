#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform int worldTime;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertexColor;
varying vec3 viewPos;
varying vec3 worldPos;
varying vec3 viewNormal;

vec2 waterWaveNormal(vec2 worldUV) {
    vec2 flowA=vec2(frameTimeCounter*.012,-frameTimeCounter*.008);
    vec2 flowB=vec2(-frameTimeCounter*.017,frameTimeCounter*.013);
    vec2 a=texture2D(noisetex,fract(worldUV+flowA)).rg*2.0-1.0;
    vec2 b=texture2D(noisetex,fract(worldUV*1.83+flowB)).rg*2.0-1.0;
    vec2 c=texture2D(noisetex,fract(worldUV*3.71-flowA*.63)).rg*2.0-1.0;
    return a*.56+b*.31+c*.13;
}
void main() {
    vec4 vanillaWater=texture2D(texture,texcoord)*vertexColor;
    vec2 wave=waterWaveNormal(worldPos.xz*.018);
    float waveStrength=.075+.035*float(WATER_QUALITY);
    vec3 N=normalize(viewNormal+vec3(wave.x,0.0,wave.y)*waveStrength);
    vec3 V=normalize(-viewPos);
    float ndv=saturate(dot(N,V));
    float fresnel=.025+.975*pow(1.0-ndv,5.0);

    vec3 reflected=vec3(.16,.32,.43);
#ifdef WATER_REFLECTIONS
    vec3 reflectedView=reflect(-V,N);
    vec3 reflectedWorld=normalize(mat3(gbufferModelViewInverse)*reflectedView);
    vec3 sunWorld=normalize(mat3(gbufferModelViewInverse)*sunPosition);
    reflected=analyticSky(reflectedWorld,sunWorld,rainStrength,float(worldTime)/24000.0);
#endif

    vec3 light=texture2D(lightmap,lmcoord).rgb;
    float shallow=saturate(ndv*.85+.15);
    vec3 absorption=mix(vec3(.018,.105,.125),vec3(.055,.25,.27),shallow);
    vec3 bodyColor=mix(absorption,vanillaWater.rgb*vec3(.64,.86,.90),.34)*(.58+.42*light);
    vec3 color=mix(bodyColor,reflected,fresnel*.82);

    vec3 L=normalize(sunPosition);
    float sunGlint=pow(saturate(dot(reflect(-L,N),V)),96.0);
    color+=sunGlint*vec3(1.0,.74,.42)*(.32+.28*(1.0-rainStrength));
    float foam=smoothstep(.76,.96,abs(wave.x-wave.y))*smoothstep(.15,.75,1.0-ndv);
    color+=foam*vec3(.34,.39,.40)*.12;

    // Важно: этот проход не читает colortex0, в который одновременно пишет.
    // Это исключает framebuffer feedback и показ texture atlas вместо отражения.
    float alpha=mix(.34,.78,fresnel)*vanillaWater.a;
    gl_FragData[0]=vec4(color,alpha);
    gl_FragData[1]=vec4(encodeNormal(N),1.0);
    gl_FragData[2]=vec4(lmcoord,1.0,1.0);
}
