#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
#ifdef HD_ASSETS
uniform sampler2D cloudBaseTex;
uniform sampler2D cloudDetailTex;
uniform sampler2D weatherMapTex;
uniform sampler2D blueNoiseTex;
#endif
uniform sampler2D shadowtex0;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform int worldTime;
varying vec2 texcoord;

vec3 viewFromDepth(vec2 uv, float depth) {
    vec4 p = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    return p.xyz / max(p.w, 0.00001);
}
vec3 worldFromDepth(vec2 uv, float depth) {
    return (gbufferModelViewInverse * vec4(viewFromDepth(uv,depth),1.0)).xyz + cameraPosition;
}
float linearDepth(float d) { return (2.0*near) / (far+near-d*(far-near)); }

float cloudBaseSample(vec2 uv) {
#ifdef HD_ASSETS
    return texture2D(cloudBaseTex,fract(uv)).r;
#else
    return texture2D(noisetex,fract(uv)).r;
#endif
}
float cloudDetailSample(vec2 uv) {
#ifdef HD_ASSETS
    return texture2D(cloudDetailTex,fract(uv)).r;
#else
    return texture2D(noisetex,fract(uv)).g;
#endif
}
float cloudNoise3D(vec3 p, float speed) {
    vec2 wind = vec2(frameTimeCounter * speed, frameTimeCounter * speed * 0.31);
    float z = floor(p.y), f = fract(p.y);
    vec2 a = p.xz + vec2(z*0.071,z*0.113) + wind;
    vec2 b = p.xz + vec2((z+1.0)*0.071,(z+1.0)*0.113) + wind;
    f = f*f*(3.0-2.0*f);
    return mix(cloudBaseSample(a),cloudBaseSample(b),f);
}
float cloudDensity(vec3 p, float height01) {
    // 4 движущихся слоя 2D-noise имитируют 3D Simplex намного дешевле настоящего 3D texture.
    p *= CLOUD_SCALE;
    float n = cloudNoise3D(p*0.0030, 0.0018)*0.50;
    n += cloudNoise3D(p*0.0061+17.0,-0.0011)*0.27;
    n += cloudNoise3D(p*0.0123+41.0,0.0027)*0.15;
    n += cloudNoise3D(p*0.0247+83.0,-0.0039)*0.08;
#ifdef HD_ASSETS
    float detail=cloudDetailSample(p.xz*.031+frameTimeCounter*vec2(.0031,-.0022));
    vec3 weather=texture2D(weatherMapTex,fract(p.xz*.00031+frameTimeCounter*.000025)).rgb;
    n += (detail-.5)*.075;
    n += (weather.r-.5)*.12 + (weather.g-.5)*.045;
#endif
    float vertical = smoothstep(0.0,0.14,height01) * (1.0-smoothstep(0.72,1.0,height01));
    return smoothstep(CLOUD_COVERAGE-0.09,CLOUD_COVERAGE+0.11,n) * vertical;
}
vec4 raymarchClouds(vec3 ro, vec3 rd, vec3 sunDir) {
#if !defined(VOLUMETRIC_CLOUDS) || defined(DIM_NETHER) || defined(DIM_END)
    return vec4(0.0);
#else
    // Ограничиваем raymarch небом и CLOUD_STEPS: на Low это 4 шага, максимум 14.
    if (rd.y <= 0.025) return vec4(0.0);
    float bottom=145.0, top=255.0;
    float t0=max((bottom-ro.y)/rd.y,0.0), t1=(top-ro.y)/rd.y;
    if (t1<=t0 || t0>9000.0) return vec4(0.0);
    float dt=(t1-t0)/float(CLOUD_STEPS);
#ifdef HD_ASSETS
    float jitter=texture2D(blueNoiseTex,fract(gl_FragCoord.xy/2048.0+frameTimeCounter*.00013)).r;
#else
    float jitter=hash12(gl_FragCoord.xy+fract(frameTimeCounter)*19.0);
#endif
    vec4 sum=vec4(0.0);
    for(int i=0;i<14;i++) {
        if(i>=CLOUD_STEPS || sum.a>0.96) break;
        float t=t0+(float(i)+jitter)*dt;
        vec3 p=ro+rd*t;
        float h=saturate((p.y-bottom)/(top-bottom));
        float d=cloudDensity(p,h);
        if(d<0.025) continue; // early exit пустой ячейки
        float sunFacing=saturate(dot(rd,sunDir)*0.5+0.5);
        float silver=pow(sunFacing,10.0)*0.55;
        vec3 bottomCol=mix(vec3(.19,.22,.28),vec3(.12,.14,.18),rainStrength);
        vec3 topCol=mix(vec3(1.08,.94,.79),vec3(.54,.57,.61),rainStrength);
        vec3 lit=mix(bottomCol,topCol,smoothstep(0.05,.9,h));
        lit += vec3(1.0,.68,.34)*silver*(1.0-rainStrength*.7);
        float a=d*(0.22+dt*0.0018);
        sum.rgb += (1.0-sum.a)*lit*a;
        sum.a += (1.0-sum.a)*a;
    }
    return sum;
#endif
}

float shadowPCF(vec3 worldPos) {
    vec4 s=shadowProjection*shadowModelView*vec4(worldPos-cameraPosition,1.0);
    s.xyz=s.xyz/max(s.w,0.0001);
    float shadowRadius=length(s.xy);
    s.xy/=mix(1.0,shadowRadius,.84);
    s.xyz=s.xyz*0.5+0.5;
    if(any(lessThan(s.xy,vec2(0.002)))||any(greaterThan(s.xy,vec2(0.998)))||s.z>1.0) return 1.0;
    float bias=0.0011;
#ifndef SOFT_SHADOWS
    return step(s.z-bias,texture2D(shadowtex0,s.xy).r);
#endif
#if SHADOW_FILTER == 0
    return step(s.z-bias,texture2D(shadowtex0,s.xy).r);
#else
    float sum=0.0;
    float px=1.0/float(shadowMapResolution);
    // 4 taps rotated: мягче 3x3 и почти вдвое дешевле.
    sum+=step(s.z-bias,texture2D(shadowtex0,s.xy+vec2(-.7,-.3)*px).r);
    sum+=step(s.z-bias,texture2D(shadowtex0,s.xy+vec2(.3,-.7)*px).r);
    sum+=step(s.z-bias,texture2D(shadowtex0,s.xy+vec2(.7,.3)*px).r);
    sum+=step(s.z-bias,texture2D(shadowtex0,s.xy+vec2(-.3,.7)*px).r);
#if SHADOW_FILTER == 2
    sum+=step(s.z-bias,texture2D(shadowtex0,s.xy+vec2(1.4,0.0)*px).r);
    sum+=step(s.z-bias,texture2D(shadowtex0,s.xy+vec2(-1.4,0.0)*px).r);
    sum+=step(s.z-bias,texture2D(shadowtex0,s.xy+vec2(0.0,1.4)*px).r);
    sum+=step(s.z-bias,texture2D(shadowtex0,s.xy+vec2(0.0,-1.4)*px).r);
    return sum*.125;
#else
    return sum*.25;
#endif
#endif
}

vec3 lightShafts(vec2 uv, vec2 lightUV, vec3 lightColor) {
#if !defined(GOD_RAYS) || defined(DIM_NETHER) || defined(DIM_END)
    return vec3(0.0);
#else
    if(GODRAY_INTENSITY<0.01 || any(lessThan(lightUV,vec2(-.1))) || any(greaterThan(lightUV,vec2(1.1)))) return vec3(0.0);
    vec2 delta=(uv-lightUV)/float(GODRAY_SAMPLES);
    float jitter=hash12(gl_FragCoord.xy+floor(frameTimeCounter*20.0));
    vec2 p=uv-delta*jitter;
    float illumination=1.0, accum=0.0;
    for(int i=0;i<24;i++) {
        if(i>=GODRAY_SAMPLES) break;
        p-=delta;
        if(any(lessThan(p,vec2(0.001)))||any(greaterThan(p,vec2(.999)))) break;
        float d=texture2D(depthtex0,p).r;
        // Depth создаёт экранную маску; shadow map добавляет occlusion листвы.
        float visible=smoothstep(0.985,1.0,d);
        if(d<0.9995) visible*=shadowPCF(worldFromDepth(p,d));
        accum += visible*illumination;
        illumination*=GODRAY_DECAY;
    }
    return lightColor*accum/float(GODRAY_SAMPLES)*GODRAY_INTENSITY;
#endif
}

float cheapAO(vec2 uv,float depth,vec3 normal) {
#ifndef SSAO
    return 1.0;
#else
    if(depth>.999) return 1.0;
    vec2 px=vec2(1.0/viewWidth,1.0/viewHeight)*(2.0+float(SSAO_QUALITY));
    float z=linearDepth(depth), occ=0.0;
    occ+=step(linearDepth(texture2D(depthtex0,uv+vec2(px.x,0)).r),z-.001);
    occ+=step(linearDepth(texture2D(depthtex0,uv-vec2(px.x,0)).r),z-.001);
    occ+=step(linearDepth(texture2D(depthtex0,uv+vec2(0,px.y)).r),z-.001);
    occ+=step(linearDepth(texture2D(depthtex0,uv-vec2(0,px.y)).r),z-.001);
    return 1.0-occ*.09;
#endif
}

vec3 screenReflection(vec2 uv, vec3 viewPos, vec3 normal, vec3 fallback) {
#ifndef SSR
    return fallback;
#else
    vec3 dir=reflect(normalize(viewPos),normal);
    if(dir.z>-0.02) return fallback;
    vec3 p=viewPos;
    for(int i=0;i<8;i++) {
        p+=dir*(0.45+float(i)*0.18);
        vec4 q=gbufferProjection*vec4(p,1.0);
        vec2 suv=q.xy/q.w*.5+.5;
        if(any(lessThan(suv,vec2(.01)))||any(greaterThan(suv,vec2(.99)))) break;
        vec3 hit=viewFromDepth(suv,texture2D(depthtex0,suv).r);
        if(abs(hit.z-p.z)<0.35+float(i)*.08) return texture2D(colortex0,suv).rgb;
    }
    return fallback;
#endif
}

void main() {
    vec2 uv=texcoord;
    float depth=texture2D(depthtex0,uv).r;
    vec3 color=texture2D(colortex0,uv).rgb;
    vec3 normal=decodeNormal(texture2D(colortex1,uv).rgb);
    vec3 material=texture2D(colortex2,uv).rgb;
    vec3 viewPos=viewFromDepth(uv,depth);
    vec3 worldPos=(gbufferModelViewInverse*vec4(viewPos,1.0)).xyz+cameraPosition;
    vec3 worldRay=normalize((gbufferModelViewInverse*vec4(normalize(viewPos),0.0)).xyz);
    vec3 sunWorld=normalize(mat3(gbufferModelViewInverse)*sunPosition);

    if(depth>.9998) {
#if defined(DIM_NETHER)
        color=mix(vec3(.055,.008,.004),vec3(.31,.045,.012),pow(saturate(worldRay.y*.5+.5),1.6));
#elif defined(DIM_END)
        float stars=step(.9975,hash12(floor((worldRay.xy/max(abs(worldRay.z),.15))*420.0)));
        color=vec3(.012,.006,.025)+vec3(.34,.20,.55)*stars;
#else
        vec4 clouds=raymarchClouds(cameraPosition,worldRay,sunWorld);
        color=mix(color,clouds.rgb/max(clouds.a,.001),clouds.a);
#endif
    } else {
        float shadow=shadowPCF(worldPos);
        color*=mix(.58,1.0,shadow);
        color*=cheapAO(uv,depth,normal);
        if(material.b>.72) {
            vec3 refl=screenReflection(uv,viewPos,normal,color);
            color=mix(color,refl,.18+material.b*.18);
        }
    }

    // Проекция активного светила (солнце днём, луна ночью) в screen space.
    bool isDay=(worldTime<12700 || worldTime>23250);
    vec3 lightView=isDay?sunPosition:moonPosition;
    vec4 lp=gbufferProjection*vec4(normalize(lightView)*far,1.0);
    vec2 lightUV=lp.xy/max(abs(lp.w),.0001)*.5+.5;
    vec3 shaftColor=isDay?vec3(1.0,.67,.35):vec3(.34,.43,.62);
    color+=lightShafts(uv,lightUV,shaftColor)*(1.0-rainStrength*.7);

#ifdef VOLUMETRIC_FOG
    if(depth<.9999) {
        float distanceFog=length(viewPos);
        float fog=1.0-exp(-distanceFog*(.0022+.0045*rainStrength)*FOG_STRENGTH);
        float noise=texture2D(noisetex,fract(worldPos.xz*.002+frameTimeCounter*.0007)).r;
        fog*=mix(.82,1.14,noise);
        float scatter=pow(saturate(dot(worldRay,sunWorld)),8.0)*(1.0-rainStrength*.5);
#if defined(DIM_NETHER)
        fog=min(1.0,fog*2.8+distanceFog*.0025*FOG_STRENGTH);
        vec3 fogColor=mix(vec3(.075,.008,.004),vec3(.32,.045,.008),noise);
#elif defined(DIM_END)
        fog=min(1.0,fog*1.35+distanceFog*.0007*FOG_STRENGTH);
        vec3 fogColor=mix(vec3(.018,.008,.035),vec3(.105,.045,.16),noise);
#else
        vec3 fogColor=analyticSky(worldRay,sunWorld,rainStrength,float(worldTime)/24000.0);
        fogColor+=vec3(1.0,.57,.26)*scatter*.28;
#endif
        color=mix(color,fogColor,fog*saturate(1.0-depth*.12));
    }
#endif
    gl_FragData[0]=vec4(max(color,vec3(0.0)),1.0);
}
