


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

var<private> R: vec2<f32> ;
var<private> Mouse: vec4<f32> ;
var<private> time: f32;
let mass = 1.;

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

fn border(p: vec2<f32>) -> f32 {
	let bound: f32 = -sdBox(p - R * 0.5, R * vec2<f32>(0.5, 0.5));
	let box: f32 = sdBox(Rot(0. * time) * (p - R * vec2<f32>(0.5, 0.6)), R * vec2<f32>(0.05, 0.01));
	let drain: f32 = -sdBox(p - R * vec2<f32>(0.5, 0.7), R * vec2<f32>(1.5, 0.5));
	return max(drain, min(bound, box));

} 

let h: f32 = 1.;

fn bN(p: vec2<f32>) -> vec3<f32> {
	let dx: vec3<f32> = vec3<f32>(-h, 0.0, h);
	let idx: vec4<f32> = vec4<f32>(-1./h, 0., 1./h, 0.25);
	let r: vec3<f32> = idx.zyw * border(p + dx.zy) 
                     + idx.xyw * border(p + dx.xy) 
                     + idx.yzw * border(p + dx.yz) 
                     + idx.yxw * border(p + dx.yx);
	return vec3<f32>(normalize(r.xy),  r.z + 1e-4);

} 

fn pack(x: vec2<f32>) -> u32 {
	let x2: vec2<f32> = 65534. * clamp(0.5 * x + 0.5, vec2<f32>(0.), vec2<f32>(1.));
	return u32(round(x.x)) + 65535u * u32(round(x.y));

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
    var P: particle = particle(decode(data.x) + pos, decode(data.y), data.zw);
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


// don't forget to use a return value when using Reintegration
fn Reintegration(ch: texture_storage_2d<rgba8unorm, read_write>, pos: vec2<f32>) -> particle {
	
    //basically integral over all updated neighbor distributions
    //that fall inside of this pixel
    //this makes the tracking conservative
    for (var i: i32 = -2; i <= 2; i = i + 1) {	
        for (var j: i32 = -2; j <= 2; j = j + 1) {
            let tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(i));

            // let data: vec4<f32> = texel(ch, tpos);
            // let data: vec4<f32> = texelFetch(ch, ivec2(tpos), 0);
            let data: vec4<f32> =  textureLoad(ch, vec2<i32>(tpos));

            var P0: particle = getParticle(data, tpos);

            P0.X = P0.X + (P0.V * dt);//integrate position

            let difR: f32 = 0.9 + 0.21 * smoothStep(fluid_rho * 0., fluid_rho * 0.333, P0.M.x);
            let D: vec3<f32> = distribution(P0.X, pos, difR);

            //the deposited mass into this cell
            let m: f32 = P0.M.x * D.z;

            var P1: particle;
            // TODO: change the input particle directly using (*P).X = ...
            //add weighted by mass
            P1.X = P1.X + (D.xy * m);
            P1.V = P1.V + (P0.V * m);
            P1.M.y = P1.M.y + (P0.M.y * m);

            //add mass
            P1.M.x = P1.M.x + (m);
	
        }	
    }

    //normalization
    if (P1.M.x != 0.) {
		P1.X = P1.X / (P1.M.x);
		P1.V = P1.V / (P1.M.x);
		P1.M.y = P1.M.y / (P1.M.x);
	}

    return P1;
} 

fn Simulation(ch: texture_storage_2d<rgba8unorm, read_write>, P: particle, pos: vec2<f32>) -> particle {
	var F: vec2<f32> = vec2<f32>(0.);
	var avgV: vec3<f32> = vec3<f32>(0.);
	for (var i: i32 = -2; i <= 2; i = i + 1) {	
        for (var j: i32 = -2; j <= 2; j = j + 1) {
            let tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(i));
            // let data: vec4<f32> = texel(ch, tpos);
            // let data: vec4<f32> = texelFetch(ch, ivec2(tpos), 0);
            let data: vec4<f32> =  textureLoad(ch, vec2<i32>(tpos));

            let P0: particle = getParticle(data, tpos);
            let dx: vec2<f32> = P0.X - P.X;

            let avgP: f32 = 0.5 * P0.M.x * (Pf(P.M) + Pf(P0.M));
            F = F - (0.5 * G(1. * dx) * avgP * dx);
            avgV = avgV + (P0.M.x * G(1. * dx) * vec3<f32>(P0.V, 1.));
	
        }	
    }	
    avgV.y = avgV.y / (avgV.z);
    avgV.x = avgV.x / (avgV.z);

    //viscosity
	F = F + (0. * P.M.x * (avgV.xy - P.V));

    //gravity
	F = F + (P.M.x * vec2<f32>(0., -0.0004));

	if (Mouse.z > 0.) {
		let dm: vec2<f32> = (Mouse.xy - Mouse.zw) / 10.;
		let d: f32 = distance(Mouse.xy, P.X) / 20.;
		F = F + (0.001 * dm * exp(-d * d));
	
	}

    var P1: particle = P;

    //integrate
	P1.V = P1.V + (F * dt / P1.M.x);

    //border 
	let N: vec3<f32> = bN(P1.X);
	let vdotN: f32 = step(N.z, border_h) * dot(-N.xy, P1.V);
	P1.V = P1.V + (0.5 * (N.xy * vdotN + N.xy * abs(vdotN)));
	P1.V = P1.V + (0. * P1.M.x * N.xy * step(abs(N.z), border_h) * exp(-N.z));
	
    if (N.z < 0.) {	
        P1.V = vec2<f32>(0.);
	}

    //velocity limit
	let v: f32 = length(P1.V);

    var vv: f32;
    if (v > 1.) {
        vv = v; 
    } else {
        vv = 1.;
    };
	P1.V = P1.V / vv;

    return P1;

} 

