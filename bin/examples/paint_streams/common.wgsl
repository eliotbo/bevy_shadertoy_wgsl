


// struct Particle {
//      a: vec4<f32>;
//      b: vec4<f32>;
// };


// fn dum(x: Particle) {
//     let x2 = Particle(x.a, x.b);
//     let bah = x.a + 1.0;
//     return;
// }


// fn miam() -> Particle {
//     var out: Particle;
//     out.a = vec4<f32>(0.0);
//     out.b = vec4<f32>(1.0);
//     return out;
// }

// let ch0: texture_storage_2d<rgba8unorm, read_write> = buffer_a;

// let ch1: texture_storage_2d<rgba8unorm, read_write> = buffer_a;

// let ch2: texture_storage_2d<rgba8unorm, read_write> = buffer_a;

// let ch3: texture_storage_2d<rgba8unorm, read_write> = buffer_a;

// #define Bf(p) p
// #define Bi(p) ivec2(p)
// #define texel(a, p) texelFetch(a, Bi(p), 0)
// #define pixel(a, p) texture(a, (p)/R)

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

fn sdBox( p: vec2<f32>,  b: vec2<f32>) -> f32 {
	let d: vec2<f32> = abs(p) - b;
	return length(max(d, vec2<f32>(0.))) + min(max(d.x, d.y), 0.);

} 


fn pack(x: vec2<f32>) -> u32 {
	let x2: vec2<f32> = 65534. * clamp(0.5 * x + 0.5, vec2<f32>(0.), vec2<f32>(1.));
	return u32(round(x2.x)) + 65535u * u32(round(x2.y));

} 

fn unpack(a: u32) -> vec2<f32> {
	var x: vec2<f32> = vec2<f32>(f32(a % 65535u), f32(a / 65535u));
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






