#ifndef COZY_COMMON_GLSL
#define COZY_COMMON_GLSL

const float PI = 3.14159265359;
float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0.0), vec3(1.0)); }
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec3 decodeNormal(vec3 n) { return normalize(n * 2.0 - 1.0); }
vec3 encodeNormal(vec3 n) { return n * 0.5 + 0.5; }

// Быстрая ACES-аппроксимация: сохраняет детали светов без серой «плёнки».
vec3 acesFilm(vec3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

vec3 cozyGrade(vec3 c) {
    c *= vec3(1.035, 1.0, 0.955);
    float y = luma(c);
    c = mix(vec3(y), c, SATURATION);
    return max(c, vec3(0.0));
}
#endif
