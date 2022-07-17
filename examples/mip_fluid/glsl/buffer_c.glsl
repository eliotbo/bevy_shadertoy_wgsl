#define TURBULENCE_SCALES 11
#define VORTICITY_SCALES 11
#define POISSON_SCALES 11



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
//#define USE_PRESSURE_ADVECTION
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



// If defined, "pump" velocity in the center of the screen. If undefined, alternate pumping from the sides of the screen.
//#define CENTER_PUMP
// Amplitude and cycle time for the "pump" at the center of the screen.
#define PUMP_SCALE 0.001
#define PUMP_CYCLE 0.2

#define CURL_CH w
#define CURL_SAMPLER iChannel0
#define DEGREE VORTICITY_SCALES

#define CURL(d) textureLod(CURL_SAMPLER, fract(uv+(d+0.0)), mip).CURL_CH
#define D(d) abs(textureLod(CURL_SAMPLER, fract(uv+d), mip).CURL_CH)

void tex(vec2 uv, inout mat3 mc, inout float curl, int degree) {
    vec2 texel = 1.0/iResolution.xy;
    float stride = float(1 << degree);
    float mip = float(degree);
    vec4 t = stride * vec4(texel, -texel.y, 0);

    float d =    D( t.ww); float d_n =  D( t.wy); float d_e =  D( t.xw);
    float d_s =  D( t.wz); float d_w =  D(-t.xw); float d_nw = D(-t.xz);
    float d_sw = D(-t.xy); float d_ne = D( t.xy); float d_se = D( t.xz);
    
    mc =  mat3(d_nw, d_n, d_ne,
               d_w,  d,   d_e,
               d_sw, d_s, d_se);
    
    curl = CURL();
    
}

float reduce(mat3 a, mat3 b) {
    mat3 p = matrixCompMult(a, b);
    return p[0][0] + p[0][1] + p[0][2] +
           p[1][0] + p[1][1] + p[1][2] +
           p[2][0] + p[2][1] + p[2][2];
}

vec2 confinement(vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    float k0 = CONF_ISOTROPY;
    float k1 = 1.0 - 2.0*(CONF_ISOTROPY);

    mat3 conf_x = mat3(
       -k0, -k1, -k0,
        0.0, 0.0, 0.0,
        k0,  k1,  k0
    );

    mat3 conf_y = mat3(
       -k0,  0.0,  k0,
       -k1,  0.0,  k1,
       -k0,  0.0,  k0
    );
    
    mat3 mc;
    vec2 v = vec2(0);
    float curl;
    
    float cacc = 0.0;
    vec2 nacc = vec2(0);
    float wc = 0.0;
    for (int i = 0; i < DEGREE; i++) {
        tex(uv, mc, curl, i);
        float w = CONF_W_FUNCTION;
        vec2 n = w * normz(vec2(reduce(conf_x, mc), reduce(conf_y, mc)));
        v += curl * n;
        cacc += curl;
        nacc += n;
        wc += w;
    }

    if (PREMULTIPLY_CURL) {
        return v / wc;
    } else {
    	return nacc * cacc / wc;
    }

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(confinement(fragCoord),0,0);
    // Adding a very small amount of noise on init fixes subtle numerical precision blowup problems
    if (iFrame==0) fragColor=1e-6*rand4(fragCoord, iResolution.xy, iFrame);
}