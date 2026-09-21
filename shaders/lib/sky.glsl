#ifndef COZY_SKY_GLSL
#define COZY_SKY_GLSL
vec3 analyticSky(vec3 rd, vec3 sunDir, float rain, float time01) {
    float up = saturate(rd.y * 0.5 + 0.5);
    float horizon = pow(1.0 - abs(rd.y), 5.0);
    float sunHeight = saturate(sunDir.y * 2.0 + 0.25);
    float dusk = pow(1.0 - abs(sunDir.y), 5.0) * (1.0 - rain * 0.65);
    vec3 zenith = mix(vec3(0.015, 0.025, 0.07), vec3(0.075, 0.27, 0.62), sunHeight);
    vec3 horizonColor = mix(vec3(0.025, 0.035, 0.08), vec3(0.52, 0.70, 0.91), sunHeight);
    horizonColor = mix(horizonColor, vec3(1.0, 0.24, 0.055), dusk * 0.82);
    vec3 sky = mix(horizonColor, zenith, pow(up, 0.65));
    sky += vec3(1.0, 0.34, 0.08) * dusk * horizon * 0.55;
    sky = mix(sky, vec3(0.19,0.24,0.31), rain * 0.58);
    float sunDisk = smoothstep(0.9993, 0.9998, dot(rd, sunDir));
    sky += vec3(1.0, 0.72, 0.38) * sunDisk * (2.0 - rain);
    return sky;
}
#endif
