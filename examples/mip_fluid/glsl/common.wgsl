/*
	Number of scales to use in computation of each value. Lowering these will change the 
    result drastically, also note that the heightmap is used for rendering, so changing 
    POISSON_SCALES will alter the appearance of lighting/shadows. Weighting functions
    for each scale are defined below.
*/
#define TURBULENCE_SCALES 11
#define VORTICITY_SCALES 11
#define POISSON_SCALES 11



// If defined, recalculate the advection offset at every substep. Otherwise, subdivide the offset.
// Leaving this undefined is much cheaper for large ADVECTION_STEPS but yields worse results; this
// can be improved by defining the BLUR_* options below.
#define RECALCULATE_OFFSET
// Number of advection substeps to use. Useful to increase this for large ADVECTION_SCALE. Must be >= 1
#define ADVECTION_STEPS 3
// Advection distance multiplier.
#define ADVECTION_SCALE 40.0
// Scales the effect of turbulence on advection.
#define ADVECTION_TURBULENCE 1.0
// Scales the effect of turbulence on velocity. Use small values.
#define VELOCITY_TURBULENCE 0.0000
// Scales the effect of vorticity confinement on velocity.
#define VELOCITY_CONFINEMENT 0.01
// Scales diffusion.
#define VELOCITY_LAPLACIAN 0.02
// Scales the effect of vorticity confinement on advection.
#define ADVECTION_CONFINEMENT 0.6
// Scales the effect of divergence on advection.
#define ADVECTION_DIVERGENCE  0.0
// Scales the effect of velocity on advection.
#define ADVECTION_VELOCITY -0.05
// Amount of divergence minimization. Too much will cause instability.
#define DIVERGENCE_MINIMIZATION 0.1
// If 0.0, compute the gradient at (0,0). If 1.0, compute the gradient at the advection distance.
#define DIVERGENCE_LOOKAHEAD 1.0
// If 0.0, compute the laplacian at (0,0). If 1.0, compute the laplacian at the advection distance.
#define LAPLACIAN_LOOKAHEAD 1.0
// Scales damping force.
#define DAMPING 0.0001
// Overall velocity multiplier
#define VELOCITY_SCALE 1.0
// Mixes the previous velocity with the new velocity (range 0..1).
#define UPDATE_SMOOTHING 0.0



// These control the (an)isotropy of the various kernels
#define TURB_ISOTROPY 0.9  // [0..2.0]
#define CURL_ISOTROPY 0.6  // >= 0
#define CONF_ISOTROPY 0.25 // [0..0.5]
#define POIS_ISOTROPY 0.16 // [0..0.5]





// These apply a gaussian blur to the various values used in the velocity/advection update. More expensive when defined.
//#define BLUR_TURBULENCE
//#define BLUR_CONFINEMENT
//#define BLUR_VELOCITY



// These define weighting functions applied at each of the scales, i=0 being the finest detail.
//#define TURB_W_FUNCTION 1.0/float(i+1)
#define TURB_W_FUNCTION 1.0
//#define TURB_W_FUNCTION float(i+1)

//#define CURL_W_FUNCTION 1.0/float(1 << i)
#define CURL_W_FUNCTION 1.0/float(i+1)
//#define CURL_W_FUNCTION 1.0

//#define CONF_W_FUNCTION 1.0/float(i+1)
#define CONF_W_FUNCTION 1.0
//#define CONF_W_FUNCTION float(i+1)
//#define CONF_W_FUNCTION float(1 << i)

//#define POIS_W_FUNCTION 1.0
#define POIS_W_FUNCTION 1.0/float(i+1)
//#define POIS_W_FUNCTION 1.0/float(1 << i)
//#define POIS_W_FUNCTION float(i+1)
//#define POIS_W_FUNCTION float(1 << i)



// These can help reduce mipmap artifacting, especially when POIS_W_FUNCTION emphasizes large scales.
//#define 
// Scales pressure advection distance.
#define PRESSURE_ADVECTION 0.0002 // higher values more likely to cause blowup if laplacian > 0.0
// Pressure diffusion.
#define PRESSURE_LAPLACIAN 0.1 // [0..0.3] higher values more likely to cause blowup
// Mixes the previous pressure with the new pressure.
#define PRESSURE_UPDATE_SMOOTHING 0.0 // [0..1]



// Scales mouse interaction effect
#define MOUSE_AMP 0.05
// Scales mouse interaction radius
#define MOUSE_RADIUS 0.001



// Amplitude and cycle time for the "pump" at the center of the screen.
#define PUMP_SCALE 0.001
#define PUMP_CYCLE 0.2

// If defined, recalculate the advection offset at every substep. Otherwise, subdivide the offset.
// Leaving this undefined is much cheaper for large ADVECTION_STEPS but yields worse results; this
// can be improved by defining the BLUR_* options below.
bool RECALCULATE_OFFSET = true;
bool USE_PRESSURE_ADVECTION = false;

// These apply a gaussian blur to the various values used in the velocity/advection update. More expensive when defined.
bool BLUR_TURBULENCE = false;
bool BLUR_CONFINEMENT = false;
bool BLUR_VELOCITY = false;


// These can help reduce mipmap artifacting, especially when POIS_W_FUNCTION emphasizes large scales.
bool USE_PRESSURE_ADVECTION = false;

// If defined, multiply curl by vorticity, then accumulate. If undefined, accumulate, then multiply.
bool PREMULTIPLY_CURL = true;

bool VIEW_VELOCITY = true;


// If defined, "pump" velocity in the center of the screen. If undefined, alternate pumping from the sides of the screen.
bool CENTER_PUMP = false;


vec4 normz(vec4 x) {
	return x.xyz == vec3(0) ? vec4(0,0,0,x.w) : vec4(normalize(x.xyz),0);
}

vec3 normz(vec3 x) {
	return x == vec3(0) ? vec3(0) : normalize(x);
}

vec2 normz(vec2 x) {
	return x == vec2(0) ? vec2(0) : normalize(x);
}


// Only used for rendering, but useful helpers
float softmax(float a, float b, float k) {
	return log(exp(k*a)+exp(k*b))/k;    
}

float softmin(float a, float b, float k) {
	return -log(exp(-k*a)+exp(-k*b))/k;    
}

vec4 softmax4(vec4 a, vec4 b, float k) {
	return log(exp(k*a)+exp(k*b))/k;    
}

vec4 softmin4(vec4 a, vec4 b, float k) {
	return -log(exp(-k*a)+exp(-k*b))/k;    
}

float softclamp(float a, float b, float x, float k) {
	return (softmin(b,softmax(a,x,k),k) + softmax(a,softmin(b,x,k),k)) / 2.0;    
}

vec4 softclamp444(vec4 a, vec4 b, vec4 x, float k) {
	return (softmin4(b,softmax4(a,x,k),k) + softmax4(a,softmin4(b,x,k),k)) / 2.0;    
}

vec4 softclamp4(float a, float b, vec4 x, float k) {
	return (softmin4(vec4(b),softmax4(vec4(a),x,k),k) + softmax4(vec4(a),softmin4(vec4(b),x,k),k)) / 2.0;    
}




// GGX from Noby's Goo shader https://www.shadertoy.com/view/lllBDM

// MIT License: https://opensource.org/licenses/MIT
float G1V(float dnv, float k){
    return 1.0/(dnv*(1.0-k)+k);
}

float ggx(vec3 n, vec3 v, vec3 l, float rough, float f0){
    float alpha = rough*rough;
    vec3 h = normalize(v+l);
    float dnl = clamp(dot(n,l), 0.0, 1.0);
    float dnv = clamp(dot(n,v), 0.0, 1.0);
    float dnh = clamp(dot(n,h), 0.0, 1.0);
    float dlh = clamp(dot(l,h), 0.0, 1.0);
    float f, d, vis;
    float asqr = alpha*alpha;
    const float pi = 3.14159;
    float den = dnh*dnh*(asqr-1.0)+1.0;
    d = asqr/(pi * den * den);
    dlh = pow(1.0-dlh, 5.0);
    f = f0 + (1.0-f0)*dlh;
    float k = alpha/1.0;
    vis = G1V(dnl, k)*G1V(dnv, k);
    float spec = dnl * d * f * vis;
    return spec;
}
// End Noby's GGX


// Modified from Shane's Bumped Sinusoidal Warp shadertoy here:
// https://www.shadertoy.com/view/4l2XWK
vec3 light(vec2 uv, float BUMP, float SRC_DIST, vec2 dxy, float iTime, inout vec3 avd) {
    vec3 sp = vec3(uv-0.5, 0);
    vec3 light = vec3(cos(iTime/2.0)*0.5, sin(iTime/2.0)*0.5, -SRC_DIST);
    vec3 ld = light - sp;
    float lDist = max(length(ld), 0.001);
    ld /= lDist;
    avd = reflect(normalize(vec3(BUMP*dxy, -1.0)), vec3(0,1,0));
    return ld;
}
// End Shane's bumpmapping section


// The MIT License
// Copyright © 2017 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
float hash1( uint n ) 
{
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

vec3 hash3( uint n ) 
{
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    uvec3 k = n * uvec3(n,n*16807U,n*48271U);
    return vec3( k & uvec3(0x7fffffffU))/float(0x7fffffff);
}

// a simple modification for this shader to get a vec4
vec4 rand4( vec2 fragCoord, vec2 iResolution, int iFrame ) {
    uvec2 p = uvec2(fragCoord);
    uvec2 r = uvec2(iResolution);
    uint c = p.x + r.x*p.y + r.x*r.y*uint(iFrame);
	return vec4(hash3(c),hash1(c + 75132895U));   
}
// End IQ's integer hash