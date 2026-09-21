#ifndef COZY_SETTINGS_GLSL
#define COZY_SETTINGS_GLSL

// Эти параметры обнаруживаются меню OptiFine/Iris.
#define QUALITY_PRESET 2 // [0 1 2 3 4]
#define VOLUMETRIC_CLOUDS
#define GOD_RAYS
#define SOFT_SHADOWS
#define BLOOM
#define WATER_REFLECTIONS
#define VOLUMETRIC_FOG
#define WET_SURFACES
//#define SSR
//#define SSAO
//#define DOF
//#define MOTION_BLUR
#define LEAF_SSS
#define WAVING_FOLIAGE
#define FXAA
//#define HD_ASSETS

#define CLOUD_STEPS 8 // [4 6 8 10 12 14]
#define CLOUD_SCALE 1.0 // [0.5 0.7 1.0 1.3 1.6 2.0]
#define CLOUD_COVERAGE 0.52 // [0.35 0.40 0.45 0.50 0.52 0.55 0.60 0.65]
#define GODRAY_SAMPLES 16 // [8 12 16 20 24]
#define GODRAY_INTENSITY 0.65 // [0.0 0.2 0.35 0.5 0.65 0.8 1.0 1.25]
#define GODRAY_DECAY 0.94 // [0.85 0.88 0.91 0.94 0.96 0.98]
#define BLOOM_INTENSITY 0.28 // [0.0 0.1 0.2 0.28 0.4 0.55 0.7]
#define BLOOM_QUALITY 1 // [0 1 2]
#define FOG_STRENGTH 0.65 // [0.0 0.25 0.45 0.65 0.8 1.0 1.25]
#define SHADOW_FILTER 1 // [0 1 2]
#define WATER_QUALITY 1 // [0 1 2]
#define SSAO_QUALITY 1 // [0 1 2]
#define DOF_STRENGTH 0.45 // [0.0 0.25 0.45 0.7 1.0]
#define MOTION_BLUR_STRENGTH 0.35 // [0.0 0.2 0.35 0.5 0.75]
#define WAVE_STRENGTH 1.0 // [0.0 0.5 0.75 1.0 1.25 1.5]
#define EMISSIVE_STRENGTH 1.15 // [1.0 1.15 1.3 1.5 2.0]
#define EXPOSURE 1.0 // [0.75 0.85 1.0 1.1 1.25]
#define SATURATION 1.08 // [0.8 0.9 1.0 1.08 1.15 1.25]

const int shadowMapResolution = 1024; // [512 1024 2048]
const float shadowDistance = 96.0; // [48.0 64.0 80.0 96.0 128.0 160.0]
const float sunPathRotation = -35.0;
const int noiseTextureResolution = 256;

#endif
