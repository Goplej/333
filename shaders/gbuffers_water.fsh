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
uniform sampler2D colortex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;
uniform int worldTime;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertexColor;
varying vec3 viewPos;
varying vec3 worldPos;
varying vec3 viewNormal;
void main() {
    vec2 screenUV = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    vec2 wuv = worldPos.xz * 0.018;
    vec2 n1 = texture2D(noisetex, fract(wuv + vec2(frameTimeCounter*.012,-frameTimeCounter*.008))).rg - 0.5;
    vec2 n2 = texture2D(noisetex, fract(wuv*1.83 + vec2(-frameTimeCounter*.017,frameTimeCounter*.013))).rg - 0.5;
    vec2 wave = (n1 + n2 * 0.55) * (0.004 + 0.004 * float(WATER_QUALITY));
    vec3 N = normalize(viewNormal + vec3(wave.x, 0.0, wave.y) * 8.0);
    vec3 V = normalize(-viewPos);
    float fresnel = 0.03 + 0.97 * pow(1.0 - saturate(dot(N,V)), 5.0);

    // Преломление использует уже отрисованный непрозрачный цвет; проверка глубины
    // не даёт захватить передний план по другую сторону силуэта.
    vec2 refrUV = clamp(screenUV + wave * (0.7 + 0.4 * fresnel), 0.002, 0.998);
    float behind = texture2D(depthtex1, refrUV).r;
    if (behind < gl_FragCoord.z - 0.0003) refrUV = screenUV;
    vec3 refracted = texture2D(colortex0, refrUV).rgb * vec3(0.72,0.88,0.91);

    vec3 reflected = vec3(0.22,0.43,0.58);
#ifdef WATER_REFLECTIONS
    vec3 Rv = reflect(-V, N);
    vec3 Rw = normalize(mat3(gbufferModelViewInverse) * Rv);
    vec3 Sw = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    reflected = analyticSky(Rw, Sw, rainStrength, float(worldTime)/24000.0);
#endif
    vec3 waterTint = vec3(0.035,0.20,0.24) * texture2D(lightmap,lmcoord).rgb;
    vec3 color = mix(refracted * 0.75 + waterTint, reflected, fresnel * 0.78);
    color += pow(saturate(dot(reflect(-normalize(sunPosition),N),V)), 96.0) * vec3(1.0,0.78,0.45) * 0.6;
    float alpha = mix(0.34, 0.76, fresnel) * vertexColor.a;
    gl_FragData[0] = vec4(color, alpha);
    gl_FragData[1] = vec4(encodeNormal(N),1.0);
    gl_FragData[2] = vec4(lmcoord, 1.0, 1.0); // material=1: вода/отражение
}
