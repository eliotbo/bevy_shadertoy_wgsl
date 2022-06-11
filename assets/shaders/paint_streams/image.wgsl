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

[[group(0), binding(5)]]
var texture: texture_storage_2d<rgba32float, read_write>;

// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
//     let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

//     let color = vec4<f32>(f32(0));
//     textureStore(texture, location, color);
// }

let PI = 3.14159265;
let dt = 1.5;
let border_h = 5.;

// var<private> R: vec2<f32> ;
// var<private> Mouse: vec4<f32> ;
// var<private> time: f32;
let mass = 1.;
let h: f32 = 1.;

let fluid_rho = 0.5;

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
    return length(max(d, vec2<f32>(0.))) + min(max(d.x, d.y), 0.);
} 


fn pack(x: vec2<f32>) -> u32 {
    let x2: vec2<f32> = 65534. * clamp(0.5 * x + 0.5, vec2<f32>(0.), vec2<f32>(1.));
    return u32(round(x2.x)) + 65535u * u32(round(x2.y));
} 

fn unpack(a: u32) -> vec2<f32> {
    var x: vec2<f32> = vec2<f32>(f32(a) % 65535., f32(a) / 65535.);
    return clamp(x / 65534., vec2<f32>(0.), vec2<f32>(1.)) * 2. - 1.;
} 

fn decode(x: f32) -> vec2<f32> {
    var X: u32 = u32(x);
    return unpack(X);
} 

fn encode(x: vec2<f32>) -> f32 {
    var X: u32 = pack(x);
    return f32(X);
} 

struct particle {
	X: vec2<f32>;
	V: vec2<f32>;
	M: vec2<f32>;
};

fn getParticle(data: vec4<f32>, pos: vec2<f32>) -> particle {
    var P: particle = particle(
        decode(data.x) + pos,
        decode(data.y),
        data.zw
    );
    return P;
} 

fn saveParticle(P: particle, pos: vec2<f32>) -> vec4<f32> {
    var P2: particle = particle(P.X, P.V, P.M);
    P2.X = clamp(P2.X - pos, vec2<f32>(-0.5), vec2<f32>(0.5));
    return vec4<f32>(encode(P2.X), encode(P2.V), P2.M);
} 

fn hash32(p: vec2<f32>) -> vec3<f32> {
    var p3: vec3<f32> = fract(vec3<f32>(p.xyx) * vec3<f32>(.1031, .1030, .0973));
    p3 = p3 + (dot(p3, p3.yxz + 33.33));
    return fract((p3.xxy + p3.yzz) * p3.zyx);
} 

fn G(x: vec2<f32>) -> f32 {
    return exp(-dot(x, x));
} 

fn G0(x: vec2<f32>) -> f32 {
    return exp(-length(x));
} 

let dif: f32 = 1.12;

fn distribution(x: vec2<f32>, p: vec2<f32>, K: f32) -> vec3<f32> {
    let omin: vec2<f32> = clamp(x - K * 0.5, p - 0.5, p + 0.5);
    let omax: vec2<f32> = clamp(x + K * 0.5, p - 0.5, p + 0.5);
    return vec3<f32>(0.5 * (omin + omax), (omax.x - omin.x) * (omax.y - omin.y) / (K * K));
} 










// fn hsv2rgb( c: vec3<f32>) -> vec3<f32> {
//     // var fractional: f32 = 0.0;
//     // let m = modf(c.x * 6. + vec3<f32>(0., 4., 2.) / 6., &fractional);

//     let v = vec3<f32>(0., 4., 2.);
//     let fractional: vec3<f32> = vec3<f32>(vec3<i32>( (c.x * 6. +  v) / 6.0)) ;
        
//     // let whatever = modf(uv + 1.0, &tempo);
//     // var temp2 = 0.;
//     // let frac = modf(tempo / 2.0, &temp2);
//     let af: vec3<f32>  = abs(fractional - 3.) - 1.;

// 	var rgb: vec3<f32> = clamp(af, vec3<f32>(0.), vec3<f32>(1.));

// 	rgb = rgb * rgb * (3. - 2. * rgb);
// 	return c.z * mix(vec3<f32>(1.), rgb, c.y);

// } 

fn mixN(a: vec3<f32>, b: vec3<f32>, k: f32) -> vec3<f32> {
    return sqrt(mix(a * a, b * b, clamp(k, 0., 1.)));
} 

fn V(location: vec2<i32>, R2: vec2<f32>) -> vec4<f32> {
	// return pixel(ch1, p);
    // return textureLoad(buffer_c, vec2<i32>(p ));
    let data: vec4<f32> = textureLoad(buffer_c, location);
    return data;
} 

fn border(p: vec2<f32>, R2: vec2<f32>, time: f32) -> f32 {
    let bound: f32 = -sdBox(p - R2 * 0.5, R2 * vec2<f32>(0.5, 0.5));
    let box: f32 = sdBox(Rot(0. * time) * (p - R2 * vec2<f32>(0.5, 0.6)), R2 * vec2<f32>(0.05, 0.01));
    let drain: f32 = -sdBox(p - R2 * vec2<f32>(0.5, 0.7), R2 * vec2<f32>(1.5, 0.5));
    return max(drain, min(bound, box));
} 

// fn bN(p: vec2<f32>, R2: vec2<f32>, time: f32) -> vec3<f32> {
//     let dx: vec3<f32> = vec3<f32>(-h, 0.0, h);
//     let idx: vec4<f32> = vec4<f32>(-1. / h, 0., 1. / h, 0.25);
//     let r: vec3<f32> = idx.zyw * border(p + dx.zy, R2, time) + idx.xyw * border(p + dx.xy, R2, time) + idx.yzw * border(p + dx.yz, R2, time) + idx.yxw * border(p + dx.yx, R2, time);
//     return vec3<f32>(normalize(r.xy), r.z + 1, e, -4);
// } 

fn bN(p: vec2<f32>, R2: vec2<f32>, time: f32) -> vec3<f32> {
    let dx: vec3<f32> = vec3<f32>(-h, 0., h);
    let idx: vec4<f32> = vec4<f32>(-1. / h, 0., 1. / h, 0.25);
    let r: vec3<f32> = idx.zyw * border(p + dx.zy, R2, time) + idx.xyw * border(p + dx.xy, R2, time) + idx.yzw * border(p + dx.yz, R2, time) + idx.yxw * border(p + dx.yx, R2, time);
    return vec3<f32>(normalize(r.xy), r.z + 0.0001);
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    

//     var O: vec4<f32> =  textureLoad(buffer_a, location);
//     textureStore(texture, location, O);
// }

// fn mainImage( col: vec4<f32>,  pos: vec2<f32>) -> () {

    let R2 = uni.iResolution.xy;

	// let location = vec2<i32>(i32(invocation_id.x),  i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let time = uni.iTime;

	// let p: vec2<i32> = vec2<i32>(pos);
	// let data: vec4<f32> = texel(ch0, pos);

    // let p: vec2<i32> = vec2<i32>(location.x, i32(R2.y) - location.y);

    let data: vec4<f32> = textureLoad(buffer_a, location);

    let pos = vec2<f32>(location) ;

    var P: particle = getParticle(data, pos);

    let Nb: vec3<f32> = bN(P.X, R2, time);
    let bord: f32 = smoothStep(2. * border_h, border_h * 0.5, border(pos, R2, time));
    let rho: vec4<f32> = V(location, R2);
    let dx: vec3<i32> = vec3<i32>(-2, 0, 2);

    let grad: vec4<f32> = -0.5 * vec4<f32>(V(location + dx.zy, R2).zw - V(location + dx.xy, R2).zw, V(location + dx.yz, R2).zw - V(location + dx.yx, R2).zw);
    let N: vec2<f32> = pow(length(grad.xz), 0.2) * normalize(grad.xz + 0.00001);

    let specular: f32 = pow(max(dot(N, Dir(1.4)), 0.), 3.5);
	// let specularb: f32 = G(0.4 * (Nb.zz - border_h)) * pow(max(dot(Nb.xy, Dir(1.4)), 0.), 3.);


    let a: f32 = pow(smoothStep(fluid_rho * 0., fluid_rho * 2., rho.z), 0.1);
    let b: f32 = exp(-1.7 * smoothStep(fluid_rho * 1., fluid_rho * 7.5, rho.z));
    let col0: vec3<f32> = vec3<f32>(1., 0.5, 0.);
    let col1: vec3<f32> = vec3<f32>(0.1, 0.4, 1.);


    let fcol: vec3<f32> = mixN(col0, col1, tanh(3. * (rho.w - 0.7)) * 0.5 + 0.5);
    // var col: vec4<f32>;

    var col: vec3<f32> = vec3<f32>(3.);
    col = mixN(col.xyz, fcol.xyz * (1.5 * b + specular * 5.), a);


    col = mixN(col, 0. * vec3<f32>(0.5, 0.5, 1.), bord);
    col = tanh(col);
    let col4 = vec4<f32>(col, 1.0);

	// let grey = vec4<f32>(0.8);

    textureStore(texture, location, col4);
    // textureStore(texture, location, data);
} 
