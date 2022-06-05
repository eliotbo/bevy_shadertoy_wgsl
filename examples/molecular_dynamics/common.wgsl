// #define T(p) texelFetch(iChannel0, ivec2(mod(p,R)), 0)

// #define P(p) texture(iChannel0, mod(p,R)/R)

// #define C(p) texture(iChannel1, mod(p,R)/R)

// #define GS(x) exp(-dot(x,x))

// #define GS0(x) exp(-length(x))

// #define CI(x) smoothstep(1.0, 0.9, length(x))

// #define Dir(ang) vec2(cos(ang), sin(ang))

// #define Rot(ang) mat2(cos(ang), sin(ang), -sin(ang), cos(ang))


// #define PACK(X) ( uint(round(65534.0*clamp(0.5*X.x+0.5, 0., 1.))) + \
//            65535u*uint(round(65534.0*clamp(0.5*X.y+0.5, 0., 1.))) )   

// #define UNPACK(X) (clamp(vec2(X%65535u, X/65535u)/65534.0, 0.,1.)*2.0 - 1.0)              

// #define DECODE(X) UNPACK(floatBitsToUint(X))

// #define ENCODE(X) uintBitsToFloat(PACK(X))

let PI = 3.14159265;

let dt = 0.5;

// let R = uni.iResolution.xy;

let cooling = 1.5;

fn GS(x1: vec2<f32>) -> f32 {
    return exp(-dot(x1, x1));
}

fn MF(dx: vec2<f32>) -> f32 {
	return -GS(0.75 * dx) + 0.13 * GS(0.4 * dx);

} 

fn Ha(x: vec2<f32>) -> f32 {
    var x2: f32;
    if (x.x >= 0.) {
        x2 = 1.;
    } else {
        x2 = 0.0;
    }

    if (x.y >= 0.) {
        x2 = x2;
    } else {
        x2 = 0.0;
    }
	// return (x.x >= 0. ? 1. : 0.) * (x.y >= 0. ? 1. : 0.);
    return x2;

} 

fn Hb(x: vec2<f32>) -> f32 {
	// return (x.x > 0. ? 1. : 0.) * (x.y > 0. ? 1. : 0.);
    var x2: f32;
    if (x.x > 0.) {
        x2 = 1.;
    } else {
        x2 = 0.0;
    }

    if (x.y > 0.) {
        x2 = x2;
    } else {
        x2 = 0.0;
    }

    return x2;

} 

fn unpack(X: u32) -> vec2<f32> {
    return (clamp(vec2<f32>(f32(X % 65535u), f32(X / 65535u)) / 65534.0, vec2<f32>(0.), vec2<f32>(1.)) *2.0 - 1.0) ;
}

fn pack(v: vec2<f32>) -> u32 {
    return  (     u32(round(65534.0*clamp(0.5*v.x+0.5, 0., 1.))) + 
           65535u*u32(round(65534.0*clamp(0.5*v.y+0.5, 0., 1.))) )   ;
}

