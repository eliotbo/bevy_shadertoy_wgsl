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



// Scales pressure advection distance.
// #define PRESSURE_ADVECTION 0.0002 // higher values more likely to cause blowup if laplacian > 0.0
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

#define VORT_CH xy
#define VORT_SAMPLER iChannel0
#define POIS_SAMPLER iChannel1
#define POIS_CH x
#define DEGREE POISSON_SCALES

#define D(d) textureLod(VORT_SAMPLER, fract(uv+d), mip).VORT_CH
#define P(d) textureLod(POIS_SAMPLER, fract(uv+d), mip).POIS_CH

float laplacian_poisson(vec2 fragCoord) {
    const float _K0 = -20.0/6.0, _K1 = 4.0/6.0, _K2 = 1.0/6.0;
    vec2 texel = 1.0/iResolution.xy;
    vec2 uv = fragCoord * texel;
    vec4 t = vec4(texel, -texel.y, 0);
    float mip = 0.0;

    float p =    P( t.ww); float p_n =  P( t.wy); float p_e =  P( t.xw);
    float p_s =  P( t.wz); float p_w =  P(-t.xw); float p_nw = P(-t.xz);
    float p_sw = P(-t.xy); float p_ne = P( t.xy); float p_se = P( t.xz);
    
    return _K0 * p + _K1 * (p_e + p_w + p_n + p_s) + _K2 * (p_ne + p_nw + p_se + p_sw);
}

void tex(vec2 uv, inout mat3 mx, inout mat3 my, inout mat3 mp, int degree) {
    vec2 texel = 1.0/iResolution.xy;
    float stride = float(1 << degree);
    float mip = float(degree);
    vec4 t = stride * vec4(texel, -texel.y, 0);

    vec2 d =    D( t.ww); vec2 d_n =  D( t.wy); vec2 d_e =  D( t.xw);
    vec2 d_s =  D( t.wz); vec2 d_w =  D(-t.xw); vec2 d_nw = D(-t.xz);
    vec2 d_sw = D(-t.xy); vec2 d_ne = D( t.xy); vec2 d_se = D( t.xz);
    
    float p =    P( t.ww); float p_n =  P( t.wy); float p_e =  P( t.xw);
    float p_s =  P( t.wz); float p_w =  P(-t.xw); float p_nw = P(-t.xz);
    float p_sw = P(-t.xy); float p_ne = P( t.xy); float p_se = P( t.xz);
    
    mx =  mat3(d_nw.x, d_n.x, d_ne.x,
               d_w.x,  d.x,   d_e.x,
               d_sw.x, d_s.x, d_se.x);
    
    my =  mat3(d_nw.y, d_n.y, d_ne.y,
               d_w.y,  d.y,   d_e.y,
               d_sw.y, d_s.y, d_se.y);
    
    mp =  mat3(p_nw, p_n, p_ne,
               p_w,  p,   p_e,
               p_sw, p_s, p_se);
}

float reduce(mat3 a, mat3 b) {
    mat3 p = matrixCompMult(a, b);
    return p[0][0] + p[0][1] + p[0][2] +
           p[1][0] + p[1][1] + p[1][2] +
           p[2][0] + p[2][1] + p[2][2];
}

vec2 pois(vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    float k0 = POIS_ISOTROPY;
    float k1 = 1.0 - 2.0*(POIS_ISOTROPY);
    
    mat3 pois_x = mat3(
        k0,  0.0, -k0,
        k1,  0.0, -k1,
        k0,  0.0, -k0
    );
     
    mat3 pois_y = mat3(
       -k0,  -k1,  -k0,
        0.0,  0.0,  0.0,
        k0,   k1,   k0
    );

    mat3 gauss = mat3(
       0.0625, 0.125, 0.0625,  
       0.125,  0.25,  0.125,
       0.0625, 0.125, 0.0625
    );
    
    mat3 mx, my, mp;
    vec2 v = vec2(0);
    
    float wc = 0.0;
    for (int i = 0; i < DEGREE; i++) {
        tex(uv, mx, my, mp, i);
        float w = POIS_W_FUNCTION;
        wc += w;
    	v += w * vec2(reduce(pois_x, mx) + reduce(pois_y, my), reduce(gauss, mp));
    }

    return v / wc;

}

#define V(d) textureLod(VORT_SAMPLER, fract(uv+d), mip).zw

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    vec2 p = pois(fragCoord);
    if (true) {
        float mip = 0.0;
        vec2 tx = 1.0 / iResolution.xy;
        vec2 uv = fragCoord * tx;
        float prev = P(0.0002 * 0.0002 * tx * V(vec2(0.0)));
        fragColor = vec4(mix(p.x + p.y, prev + PRESSURE_LAPLACIAN * laplacian_poisson(fragCoord), PRESSURE_UPDATE_SMOOTHING));
    } else {
    	fragColor = vec4(p.x + p.y);
    }
    // Adding a very small amount of noise on init fixes subtle numerical precision blowup problems
    if (iFrame==0) fragColor=1e-6*rand4(fragCoord, iResolution.xy, iFrame);
}