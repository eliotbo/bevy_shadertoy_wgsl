#define TURBULENCE_SCALES 11
#define VORTICITY_SCALES 11
#define POISSON_SCALES 11



// If defined, recalculate the advection offset at every substep. Otherwise, subdivide the offset.
// Leaving this undefined is much cheaper for large ADVECTION_STEPS but yields worse results; this
// can be improved by defining the BLUR_* options below.

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

#define TURB_CH xy
#define TURB_SAMPLER iChannel0
#define DEGREE TURBULENCE_SCALES

#define D(d) textureLod(TURB_SAMPLER, fract(uv+d), mip).TURB_CH

void tex(vec2 uv, inout mat3 mx, inout mat3 my, int degree) {
    vec2 texel = 1.0/iResolution.xy;
    float stride = float(1 << degree);
    float mip = float(degree);
    vec4 t = stride * vec4(texel, -texel.y, 0);

    vec2 d =    D( t.ww); vec2 d_n =  D( t.wy); vec2 d_e =  D( t.xw);
    vec2 d_s =  D( t.wz); vec2 d_w =  D(-t.xw); vec2 d_nw = D(-t.xz);
    vec2 d_sw = D(-t.xy); vec2 d_ne = D( t.xy); vec2 d_se = D( t.xz);
    
    mx =  mat3(d_nw.x, d_n.x, d_ne.x,
               d_w.x,  d.x,   d_e.x,
               d_sw.x, d_s.x, d_se.x);
    
    my =  mat3(d_nw.y, d_n.y, d_ne.y,
               d_w.y,  d.y,   d_e.y,
               d_sw.y, d_s.y, d_se.y);
}

float reduce(mat3 a, mat3 b) {
    mat3 p = matrixCompMult(a, b);
    return p[0][0] + p[0][1] + p[0][2] +
           p[1][0] + p[1][1] + p[1][2] +
           p[2][0] + p[2][1] + p[2][2];
}

void turbulence(vec2 fragCoord, inout vec2 turb, inout float curl)
{
	vec2 uv = fragCoord.xy / iResolution.xy;
     
    mat3 turb_xx = (2.0 - TURB_ISOTROPY) * mat3(
        0.125,  0.25, 0.125,
       -0.25,  -0.5, -0.25,
        0.125,  0.25, 0.125
    );

    mat3 turb_yy = (2.0 - TURB_ISOTROPY) * mat3(
        0.125, -0.25, 0.125,
        0.25,  -0.5,  0.25,
        0.125, -0.25, 0.125
    );

    mat3 turb_xy = TURB_ISOTROPY * mat3(
       0.25, 0.0, -0.25,  
       0.0,  0.0,  0.0,
      -0.25, 0.0,  0.25
    );
    
    const float norm = 8.8 / (4.0 + 8.0 * CURL_ISOTROPY);  // 8.8 takes the isotropy as 0.6
    float c0 = CURL_ISOTROPY;
    
    mat3 curl_x = mat3(
        c0,   1.0,  c0,
        0.0,  0.0,  0.0,
       -c0,  -1.0, -c0
    );

    mat3 curl_y = mat3(
        c0, 0.0, -c0,
       1.0, 0.0, -1.0,
        c0, 0.0, -c0
    );
    
    mat3 mx, my;
    vec2 v = vec2(0);
    float turb_wc, curl_wc = 0.0;
    curl = 0.0;
    for (int i = 0; i < DEGREE; i++) {
        tex(uv, mx, my, i);
        float turb_w = TURB_W_FUNCTION;
        float curl_w = CURL_W_FUNCTION;
    	v += turb_w * vec2(reduce(turb_xx, mx) + reduce(turb_xy, my), reduce(turb_yy, my) + reduce(turb_xy, mx));
        curl += curl_w * (reduce(curl_x, mx) + reduce(curl_y, my));
        turb_wc += turb_w;
        curl_wc += curl_w;
    }

    turb = float(DEGREE) * v / turb_wc;
    curl = norm * curl / curl_wc;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 turb;
    float curl;
    turbulence(fragCoord, turb, curl);
    fragColor = vec4(turb,0,curl);
    // Adding a very small amount of noise on init fixes subtle numerical precision blowup problems
    if (iFrame==0) fragColor=1e-6*rand4(fragCoord, iResolution.xy, iFrame);
}