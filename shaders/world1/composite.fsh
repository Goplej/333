#version 120
#ifdef GL_ES
precision mediump float;
#endif
/* DRAWBUFFERS:3 */
/*
const int colortex3Format = RGBA16F;
const int colortex4Format = RGBA16F;
*/
#define DIM_END
#include "/lib/program/composite.glsl"
