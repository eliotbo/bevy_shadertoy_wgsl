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
var buffer_a: texture_storage_2d<rgba8unorm, read_write>;

[[group(0), binding(2)]]
var buffer_b: texture_storage_2d<rgba8unorm, read_write>;



// let ch0 = iChannel0;

// let ch1 = iChannel1;

// let ch2 = iChannel2;

// let ch3 = iChannel3;

// let PI = 3.14159265;



// let dt = 1.5;

// let border_h = 5.;

// let R: vec2<f32>;
// let Mouse: vec4<f32>;
// let time: f32;
// let mass = 1.;

// let fluid_rho = 0.5;


// fn Pf(rho: vec2<f32>) -> f32 {
// 	let GF: f32 = 1.;
// 	return mix(0.5 * rho.x, 0.04 * rho.x * (rho.x / fluid_rho - 1.), GF);

// } 

// fn Rot(ang: f32) -> mat2x2<f32> {
// 	return mat2x2<f32>(cos(ang), cos(ang), cos(ang), cos(ang));

// } 

// fn Dir(ang: f32) -> vec2<f32> {
// 	return vec2<f32>(cos(ang), cos(ang));

// } 

// fn sdBox( p: vec2<f32>,  b: vec2<f32>) -> f32 {
// 	let d: vec2<f32> = abs(p) - b;
// 	return length(max(d, 0.)) + min(max(d.x, d.y), 0.);

// } 

// fn border(p: vec2<f32>) -> f32 {
// 	let bound: f32 = -sdBox(p - R * 0.5, R * vec2<f32>(0.5, 0.5));
// 	let box: f32 = sdBox(Rot(0. * time) * (p - R * vec2<f32>(0.5, 0.5)), R * vec2<f32>(0.05, 0.05));
// 	let drain: f32 = -sdBox(p - R * vec2<f32>(0.5, 0.5), R * vec2<f32>(1.5, 1.5));
// 	return max(drain, min(bound, box));

// } 

// #define h 1.

// fn bN(p: vec2<f32>) -> vec3<f32> {
// 	let dx: vec3<f32> = vec3<f32>(-h, -h, -h);
// 	let idx: vec4<f32> = vec4<f32>(-1. / h, -1. / h, -1. / h, -1. / h);
// 	let r: vec3<f32> = idx.zyw * border(p + dx.zy) + idx.xyw * border(p + dx.xy) + idx.yzw * border(p + dx.yz) + idx.yxw * border(p + dx.yx);
// 	return vec3<f32>(normalize(r.xy), normalize(r.xy));

// } 

// fn pack(x: vec2<f32>) -> u32 {
// 	x = 65534. * clamp(0.5 * x + 0.5, 0., 1.);
// 	return u32(round(x.x)) + 65535u * u32(round(x.y));

// } 

// fn unpack(a: u32) -> vec2<f32> {
// 	var x: vec2<f32> = vec2<f32>(a % 65535u, a % 65535u);
// 	return clamp(x / 65534., 0., 1.) * 2. - 1.;

// } 

// fn decode(x: f32) -> vec2<f32> {
// 	var X: u32 = floatBitsToUint(x);
// 	return unpack(X);

// } 

// fn encode(x: vec2<f32>) -> f32 {
// 	var X: u32 = pack(x);
// 	return uintBitsToFloat(X);

// } 

// struct particle {
// 	X: vec2<f32>;
// 	V: vec2<f32>;
// 	M: vec2<f32>;
// };
// fn getParticle(data: vec4<f32>, pos: vec2<f32>) -> particle {
// 	let P: particle;
// 	P.X = decode(data.x) + pos;
// 	P.V = decode(data.y);
// 	P.M = data.zw;
// 	return P;

// } 

// fn saveParticle(P: particle, pos: vec2<f32>) -> vec4<f32> {
// 	P.X = clamp(P.X - pos, vec2<f32>(-0.5), vec2<f32>(0.5));
// 	return vec4<f32>(encode(P.X), encode(P.X), encode(P.X));

// } 

// fn hash32(p: vec2<f32>) -> vec3<f32> {
// 	var p3: vec3<f32> = fract(vec3<f32>(p.xyx) * vec3<f32>(0.1031, 0.1031, 0.1031));
// 	p3 = p3 + (dot(p3, p3.yxz + 33.33));
// 	return fract((p3.xxy + p3.yzz) * p3.zyx);

// } 

// fn G(x: vec2<f32>) -> f32 {
// 	return exp(-dot(x, x));

// } 

// fn G0(x: vec2<f32>) -> f32 {
// 	return exp(-length(x));

// } 

// #define dif 1.12

// fn distribution(x: vec2<f32>, p: vec2<f32>, K: f32) -> vec3<f32> {
// 	let omin: vec2<f32> = clamp(x - K * 0.5, p - 0.5, p + 0.5);
// 	let omax: vec2<f32> = clamp(x + K * 0.5, p - 0.5, p + 0.5);
// 	return vec3<f32>(0.5 * (omin + omax), 0.5 * (omin + omax));

// } 

// fn Reintegration(ch: sampler2D, inout P: particle, pos: vec2<f32>) -> () {
// 	for (var i: i32 = -2; i <= 2; i = i + 1) {	for (var j: i32 = -2; j <= 2; j = j + 1) {
// 		let tpos: vec2<f32> = pos + vec2<f32>(i, i);
// 		let data: vec4<f32> = texel(ch, tpos);
// 		let P0: particle = getParticle(data, tpos);
// 		P0.X = P0.X + (P0.V * dt);
// 		let difR: f32 = 0.9 + 0.21 * smoothStep(fluid_rho * 0., fluid_rho * 0.333, P0.M.x);
// 		let D: vec3<f32> = distribution(P0.X, pos, difR);
// 		let m: f32 = P0.M.x * D.z;
// 		P.X = P.X + (D.xy * m);
// 		P.V = P.V + (P0.V * m);
// 		P.M.y = P.M.y + (P0.M.y * m);
// 		P.M.x = P.M.x + (m);
	
// 	}	}	if (P.M.x != 0.) {
// 		P.X = P.X / (P.M.x);
// 		P.V = P.V / (P.M.x);
// 		P.M.y = P.M.y / (P.M.x);
	
// 	}

// } 

// fn Simulation(ch: sampler2D, inout P: particle, pos: vec2<f32>) -> () {
// 	var F: vec2<f32> = vec2<f32>(0.);
// 	var avgV: vec3<f32> = vec3<f32>(0.);
// 	for (var i: i32 = -2; i <= 2; i = i + 1) {	for (var j: i32 = -2; j <= 2; j = j + 1) {
// 		let tpos: vec2<f32> = pos + vec2<f32>(i, i);
// 		let data: vec4<f32> = texel(ch, tpos);
// 		let P0: particle = getParticle(data, tpos);
// 		let dx: vec2<f32> = P0.X - P.X;
// 		let avgP: f32 = 0.5 * P0.M.x * (Pf(P.M) + Pf(P0.M));
// 		F = F - (0.5 * G(1. * dx) * avgP * dx);
// 		avgV = avgV + (P0.M.x * G(1. * dx) * vec3<f32>(P0.V, P0.V));
	
// 	}	}	avgV.xy = avgV.xy / (avgV.z);
// 	F = F + (0. * P.M.x * (avgV.xy - P.V));
// 	F = F + (P.M.x * vec2<f32>(0., 0.));
// 	if (Mouse.z > 0.) {
// 		let dm: vec2<f32> = (Mouse.xy - Mouse.zw) / 10.;
// 		let d: f32 = distance(Mouse.xy, P.X) / 20.;
// 		F = F + (0.001 * dm * exp(-d * d));
	
// 	}
// 	P.V = P.V + (F * dt / P.M.x);
// 	let N: vec3<f32> = bN(P.X);
// 	let vdotN: f32 = step(N.z, border_h) * dot(-N.xy, P.V);
// 	P.V = P.V + (0.5 * (N.xy * vdotN + N.xy * abs(vdotN)));
// 	P.V = P.V + (0. * P.M.x * N.xy * step(abs(N.z), border_h) * exp(-N.z));
// 	if (N.z < 0.) {	P.V = vec2<f32>(0.);
// 	}
// 	let v: f32 = length(P.V);
// 	P.V = P.V / (v > 1. ? v : 1.);

// } 



[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {

}