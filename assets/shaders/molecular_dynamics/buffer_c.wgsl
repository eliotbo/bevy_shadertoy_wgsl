struct CommonUniform {
    iTime: f32;
    iTimeDelta: f32;
    iFrame: f32;
    iSampleRate: f32;

    
    iMouse: vec4<f32>;
    iResolution: vec2<f32>;

    

    iChannelTime: vec4<f32>;
    iChannelResolution: vec4<f32>;
    iDate: vec4<i32>;
};

[[group(0), binding(0)]]
var<uniform> uni: CommonUniform;

[[group(0), binding(1)]]
var buffer_a: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(2)]]
var buffer_b: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(3)]]
var buffer_c: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(4)]]
var buffer_d: texture_storage_2d<rgba32float, read_write>;

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

let dt = 0.4;

// let R = uni.iResolution.xy;

let cooling = 1.5;

fn GS(x1: vec2<f32>) -> f32 {
    return exp(-dot(x1, x1));
}

fn MF(dx: vec2<f32>) -> f32 {
	return -GS(0.75 * dx) + 0.15 * GS(0.4 * dx);

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
    return (clamp(
            vec2<f32>(f32(X % 65535u), f32(X / 65535u)) / 65534.0, 
            vec2<f32>(0.), 
            vec2<f32>(1.)
        ) * 2.0 - 1.0
    ) ;
}

fn pack(v: vec2<f32>) -> u32 {
    return  (     u32(round(65534.0*clamp(0.5*v.x+0.5, 0., 1.))) + 
           65535u*u32(round(65534.0*clamp(0.5*v.y+0.5, 0., 1.))) )   ;
}



[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {

}