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

let PI = 3.14159265;

let dt = 2.5;

let border_h = 5.;

let h = 1.;

let mass = 1.;

let fluid_rho = 0.5;

// let  dif = 1.12;

var<private> R: vec2<f32>;
var<private> Mouse: vec4<f32>;
var<private> time: f32;



fn Pf(rho: vec2<f32>) -> f32 {
    let GF: f32 = 1.;
    return mix(0.5 * rho.x, 0.04 * rho.x * (rho.x / fluid_rho - 1.), GF);
} 

fn Rot(ang: f32) -> mat2x2<f32> {
    return mat2x2<f32>(cos(ang), -sin(ang), sin(ang), cos(ang));
} 

fn Dir(ang: f32) -> vec2<f32> {
    return vec2<f32>(cos(ang), sin(ang));
} 

fn sdBox(p: vec2<f32>, b: vec2<f32>) -> f32 {
    let d: vec2<f32> = abs(p) - b;
    // return length(max(d, 0.)) + min(max(d.x, d.y), 0.);
    return length(max(d, vec2<f32>(0.))) + min(max(d.x, d.y), 0.);
} 



// uint pack(vec2 x)
// {
//     x = 65534.0*clamp(0.5*x+0.5, 0., 1.);
//     return uint(round(x.x)) + 65535u*uint(round(x.y));
// }



// fn unpack(a: u32) -> vec2<f32> {
//     var x: vec2<f32> = vec2<f32>(f32(a) % 65535., f32(a) / 65535.);
//     return clamp(x / 65534., vec2<f32 >(0.), vec2<f32 >(1.)) * 2. - 1.;
// } 

// vec2 unpack(uint a)
// {
//     vec2 x = vec2(a % 65535u, a / 65535u);
//     return clamp(x/65534.0, 0.,1.)*2.0 - 1.0;
// }



// fn decode(x: f32) -> vec2<f32> {
// 	var X: u32 = floatBitsToUint(x);
// 	return unpack(X);
// } 

// fn encode(x: vec2<f32>) -> f32 {
// 	var X: u32 = pack(x);
// 	return uintBitsToFloat(X);
// } 

// fn decode(&self, place: u8, precision: u8) -> f32 {
//     let value_u32 = self >> (place - precision);

//     let mut mask = u32::MAX;
//     if precision < 32 {
//         mask = (1 << (precision)) - 1;
//     }

//     // println!("mask: {:#0b}", value_u32);
//     let masked_value_u32 = value_u32 & mask;
//     let value_f32 = masked_value_u32 as f32 / ((1u32 << (precision - 1u8)) as f32);

//     value_f32
// }

fn pack(xIn: vec2<f32 >) -> u32 {
    var x = xIn;
    let x = 65534. * clamp(0.5 * x + 0.5, vec2<f32 >(0.00), vec2<f32 >(1.0));
    return u32(round(x.x)) + 65535u * u32(round(x.y));
} 

fn unpack(a: u32) -> vec2<f32> {
    var x: vec2<f32> = vec2<f32>(f32(a % 65535u), f32(a / 65535u));
    return clamp(x / 65534., vec2<f32 >(0.), vec2<f32 >(1.)) * 2. - 1.;
} 

fn decode(x: f32) -> vec2<f32> {
    var X: u32 = u32(x);
    return unpack(X);
} 

fn encode(x: vec2<f32>) -> f32 {
    var X: u32 = pack(x);
    return f32(X);
} 



fn decode2(input: u32, place: u32, precision: u32) -> f32 {
    let value_u32 = input >> (place - precision);

    var mask: u32 = 4294967295u;
    if (precision < 32u) {
        mask = (1u << precision) - 1u;
    }

    let masked_value_u32 = value_u32 & mask;
    let max_val = 1u << (precision - 1u);
    let value_f32 = f32(masked_value_u32) / f32(max_val) ;

    return value_f32;
}

fn decode1uToVec2(q: f32) -> vec2<f32> {
    let uq = u32(q);
    let x = decode2(uq, 32u, 16u);
    let y = decode2(uq, 16u, 16u);
    return vec2<f32>(x, y) * 2. - 1.;
}

fn encode2(value: f32, input2: u32, place: u32, precision: u32) -> u32 {
    var input = input2;
    // let value_f32_normalized = value * f32(1u, 32u << (precision - 1u)) ;
    let value_f32_normalized = value * f32((1u << (precision - 1u)));
    let delta_bits = u32(place - precision);
    let value_u32 = u32(value_f32_normalized) << delta_bits;

    var mask: u32 = 0u;

    if (precision < 32u) {
        mask = 4294967295u - (((1u << precision) - 1u) << (place - precision));
    }

    let input = (input2 & mask) | value_u32;
    return input;
}

fn encodeVec2To1u(value: vec2<f32>) -> u32 {
    var input: u32 = 0u;
    let x = clamp(0.5 * value.x + 0.5, (0.00), (1.0));
    let y = clamp(0.5 * value.y + 0.5, (0.00), (1.0));
    input = encode2(x, input, 32u, 16u);
    input = encode2(y, input, 16u, 16u);

    return input;
}

struct particle {
	X: vec2<f32>;
	V: vec2<f32>;
	M: vec2<f32>;
};

fn getParticle(data: vec4<f32>, pos: vec2<f32>) -> particle {
    var P: particle;
    P.X = decode1uToVec2(data.x) + pos;
    P.V = decode1uToVec2(data.y);
    P.M = data.zw;
    return P;
} 

fn saveParticle(PIn: particle, pos: vec2<f32>) -> vec4<f32> {
    var P: particle = PIn;
    P.X = clamp(P.X - pos, vec2<f32>(-0.5), vec2<f32>(0.5));
    return vec4<f32>(
        f32(encodeVec2To1u(P.X)),
        f32(encodeVec2To1u(P.V)),
        P.M
    );
} 


// fn getParticle(data: vec4<f32>, pos: vec2<f32>) -> particle {
//     var P: particle = particle(
//         decode(data.x) + pos,
//         decode(data.y),
//         data.zw
//     );
//     return P;
// } 

// fn saveParticle(P: particle, pos: vec2<f32>) -> vec4<f32> {
//     var P2: particle = particle(P.X, P.V, P.M);
//     P2.X = clamp(P2.X - pos, vec2<f32>(-0.5), vec2<f32>(0.5));
//     return vec4<f32>(encode(P2.X), encode(P2.V), P2.M);
// } 

fn hash32(p: vec2<f32>) -> vec3<f32> {
    var p3: vec3<f32> = fract(vec3<f32>(p.xyx) * vec3<f32>(0.1031, 0.103, 0.0973));
    p3 = p3 + (dot(p3, p3.yxz + 33.33));
    return fract((p3.xxy + p3.yzz) * p3.zyx);
} 

fn G(x: vec2<f32>) -> f32 {
    return exp(-dot(x, x));
} 

fn G0(x: vec2<f32>) -> f32 {
    return exp(-length(x));
} 



fn distribution(x: vec2<f32>, p: vec2<f32>, K: f32) -> vec3<f32> {
    let omin: vec2<f32> = clamp(x - K * 0.5, p - 0.5, p + 0.5);
    let omax: vec2<f32> = clamp(x + K * 0.5, p - 0.5, p + 0.5);
    return vec3<f32>(0.5 * (omin + omax), (omax.x - omin.x) * (omax.y - omin.y) / (K * K));
} 

struct particle {
	X: vec2<f32>;
	V: vec2<f32>;
	M: vec2<f32>;
};

// fn fromLinear(linearRGB: vec4<f32>) -> vec4<f32> {
//     let cutoff: vec4<f32> = vec4<f32>(linearRGB < vec4<f32>(0.0031308));
//     let higher: vec4<f32> = vec4<f32>(1.055) * pow(linearRGB, vec4<f32>(1.0 / 2.4)) - vec4<f32>(0.055);
//     let lower: vec4<f32> = linearRGB * vec4<f32>(12.92);

//     return mix(higher, lower, cutoff);
// }

// Converts a color from sRGB gamma to linear light gamma
fn toLinear(sRGB: vec4<f32>) -> vec4<f32> {
    let cutoff = vec4<f32>(sRGB < vec4<f32>(0.04045));
    let higher = pow((sRGB + vec4<f32>(0.055)) / vec4<f32>(1.055), vec4<f32>(2.4));
    let lower = sRGB / vec4<f32>(12.92);

    return mix(higher, lower, cutoff);
}


[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    R = uni.iResolution.xy;

    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var fragColor: vec4<f32>;
    var pos = vec2<f32>(f32(location.x), f32(location.y));

	// R = uni.iResolution.xy;
    time = uni.iTime;
    let p: vec2<i32> = vec2<i32>(pos);
    // let data: vec4<f32> = texel(ch0, pos);
    let data: vec4<f32> = textureLoad(buffer_a, location);

    var P: particle = getParticle(data, pos);
    var rho: vec4<f32> = vec4<f32>(0.);

    for (var i: i32 = -1; i <= 1; i = i + 1) {
        for (var j: i32 = -1; j <= 1; j = j + 1) {
            let ij: vec2<i32> = vec2<i32>(i, j);
            // let data: vec4<f32> = texel(ch0, pos + ij);
            let data: vec4<f32> = textureLoad(buffer_a, location + ij);

            var P0: particle = getParticle(data, pos + vec2<f32>(ij));
            let x0: vec2<f32> = P0.X;
            rho = rho + (1. * vec4<f32>(P.V, P.M) * G((pos - x0) / 0.75));
        }
    }

    // fragColor = rho;d
    // rho = clamp(rho, vec4<f32>(0.), vec4<f32>(1.));
    textureStore(buffer_c, location, rho);
} 

