#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:012 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float rainStrength;
uniform vec3 sunPosition;
uniform int worldTime;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
varying vec3 worldPos;
varying float materialId;
void main() {
    vec4 albedo = texture2D(texture, texcoord) * vertexColor;
    if (albedo.a < 0.1) discard;
    vec3 N = normalize(viewNormal);
    vec3 light = texture2D(lightmap, lmcoord).rgb;
    bool leaf = materialId > 10000.5 && materialId < 10001.5;
    bool plant = materialId > 10001.5 && materialId < 10002.5;
    bool emissive = materialId > 10002.5 && materialId < 10003.5;
#ifdef LEAF_SSS
    if (leaf || plant) {
        vec3 L = normalize(sunPosition);
        float transmission = pow(saturate(dot(-N,L)*0.5+0.5),3.0);
        vec3 transColor = leaf ? vec3(.14,.30,.055) : vec3(.19,.27,.07);
        light += transColor * transmission * (1.0-rainStrength*.55);
    }
#endif
    float wet = 0.0;
#ifdef WET_SURFACES
    float skyExposure = smoothstep(.72,.98,lmcoord.y);
    wet = rainStrength * saturate(N.y*2.7) * skyExposure;
    albedo.rgb *= 1.0-wet*.25;
    float wetSpec = pow(saturate(dot(reflect(-normalize(sunPosition),N),vec3(0.0,0.0,1.0))),48.0);
    albedo.rgb += wetSpec*wet*.12;
#endif
    if (emissive) {
        float e=max(max(albedo.r,albedo.g),albedo.b);
        light=max(light,vec3(.55+e*.45));
        albedo.rgb*=EMISSIVE_STRENGTH;
    }
    float material = emissive ? .75 : ((leaf||plant) ? .35 : 0.0);
    gl_FragData[0]=vec4(albedo.rgb*light,albedo.a);
    gl_FragData[1]=vec4(encodeNormal(N),1.0);
    gl_FragData[2]=vec4(lmcoord,wet,material);
}
