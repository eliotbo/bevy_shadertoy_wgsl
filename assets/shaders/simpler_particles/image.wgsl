struct CommonUniform {
    iResolution: vec2<f32>,
    changed_window_size: f32,
    padding0: f32,
    
    iTime: f32,
    iTimeDelta: f32,
    iFrame: f32,
    iSampleRate: f32,
    
    iMouse: vec4<f32>,
    

    iChannelTime: vec4<f32>,
    iChannelResolution: vec4<f32>,
    iDate: vec4<f32>,
};


@group(0) @binding(0)
var<uniform> uni: CommonUniform;

@group(0) @binding(1)
var buffer_a: texture_storage_2d<rgba32float, read_write>;

@group(0) @binding(2)
var buffer_b: texture_storage_2d<rgba32float, read_write>;

@group(0) @binding(3)
var buffer_c: texture_storage_2d<rgba32float, read_write>;

@group(0) @binding(4)
var buffer_d: texture_storage_2d<rgba32float, read_write>;



@group(0) @binding(5)
var texture: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(6)]]
// var font_texture: texture_storage_2d<rgba32float, read_write>;

@group(0) @binding(6)
var font_texture: texture_2d<f32>;

@group(0) @binding(7)
var font_texture_sampler: sampler;

@group(0) @binding(8)
var rgba_noise_256_texture: texture_2d<f32>;

@group(0) @binding(9)
var rgba_noise_256_texture_sampler: sampler;

@group(0) @binding(10)
var blue_noise_texture: texture_2d<f32>;

@group(0) @binding(11)
var blue_noise_texture_sampler: sampler;




var<private> R: vec2<f32>;
var<private> Mouse: vec4<f32>;
var<private> time: f32;
var<private> s0: vec4<u32>;
let particle_size: f32 = 10.5;
let relax_value: f32 = 0.3;

fn Rot(ang: f32) -> mat2x2<f32> {
	return mat2x2<f32>(cos(ang), -sin(ang), sin(ang), cos(ang));
} 

fn Dir(ang: f32) -> vec2<f32> {
	return vec2<f32>(cos(ang), sin(ang));
} 

fn sdBox(p: vec2<f32>, b: vec2<f32>) -> f32 {
	var d: vec2<f32> = abs(p) - b;
	return length(max(d, vec2<f32>(0.))) + min(max(d.x, d.y), 0.);
} 

fn border(p: vec2<f32>) -> f32 {
	let bound: f32 = -sdBox(p - R * 0.5, R * vec2<f32>(0.5, 0.5));
	let box: f32 = sdBox(Rot(0. * time - 0.) * (p - R * vec2<f32>(0.5, 0.6)), R * vec2<f32>(0.05, 0.01));
	let drain: f32 = -sdBox(p - R * vec2<f32>(0.5, 0.7), R * vec2<f32>(1.5, 0.5));
	// return bound - 15.;
	// return min(bound, box);
	return max(drain, min(bound, box));
} 

fn bN(p: vec2<f32>) -> vec3<f32> {
	var dx: vec3<f32> = vec3<f32>(-1., 0., 1.);
	let idx: vec4<f32> = vec4<f32>(-1. / 1., 0., 1. / 1., 0.25);
	var r: vec3<f32> = idx.zyw * border(p + dx.zy) + idx.xyw * border(p + dx.xy) + idx.yzw * border(p + dx.yz) + idx.yxw * border(p + dx.yx);
	return vec3<f32>(normalize(r.xy), r.z + 0.0001);
} 

// fn decode(x: f32) -> vec2<f32> {
// 	var X: u32 = floatBitsToUint(x);
// 	return unpackHalf2x16(X);
// } 

// fn encode(x: vec2<f32>) -> f32 {
// 	var X: u32 = packHalf2x16(x);
// 	return uintBitsToFloat(X);
// } 

fn encode2(value: f32, input2: u32, place: u32, precis: u32) -> u32 {
    var input = input2;
    // let value_f32_normalized = value * f32(1u, 32u << (precis - 1u)) ;
    let value_f32_normalized = value * f32((1u << (precis - 1u)));
    let delta_bits = u32(place - precis);
    let value_u32 = u32(value_f32_normalized) << delta_bits;

    var mask: u32 = 0u;

    if (precis < 32u) {
        mask = 4294967295u - (((1u << precis) - 1u) << (place - precis));
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

fn decode2(input: u32, place: u32, precis: u32) -> f32 {
    let value_u32 = input >> (place - precis);

    var mask: u32 = 4294967295u;
    if (precis < 32u) {
        mask = (1u << precis) - 1u;
    }

    let masked_value_u32 = value_u32 & mask;
    let max_val = 1u << (precis - 1u);
    let value_f32 = f32(masked_value_u32) / f32(max_val) ;

    return value_f32;
}

fn decode1uToVec2(q: f32) -> vec2<f32> {
    let uq = u32(q);
    let x = decode2(uq, 32u, 16u);
    let y = decode2(uq, 16u, 16u);
    return vec2<f32>(x, y) * 2. - 1.;
}


struct particle {
	X: vec2<f32>,
	NX: vec2<f32>,
	R: f32,
	M: f32,
};
fn getParticle(data: vec4<f32>, pos: vec2<f32>) -> particle {
	var P: particle;
	P.X = decode1uToVec2(data.x) + pos;
	P.NX = decode1uToVec2(data.y) + pos;
	P.R = data.z;
	P.M = data.w;
	return P;
} 

fn saveParticle(P_in: particle, pos: vec2<f32>) -> vec4<f32> {
	var P = P_in;
	P.X = P.X - pos;
	P.NX = P.NX - pos;
	return vec4<f32>(
		f32(encodeVec2To1u(P.X)), 
		f32(encodeVec2To1u(P.NX)), 
		P.R, 
		P.M
	);
} 


fn rng_initialize(p: vec2<f32>, frame: i32)  {
	s0 = vec4<u32>(u32(p.x), u32(p.y), u32(frame), u32(p.x) + u32(p.y));
} 

// // https://www.pcg-random.org/
// void pcg4d(inout uvec4 v)
// {
// 	v = v * 1664525u + 1013904223u;
//     v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
//     v = v ^ (v>>16u);
//     v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
// }


fn pcg4d(v: ptr<private, vec4<u32>>)  {

	(*v) = (*v) * 1664525u + 1013904223u;
	(*v).x = (*v).x + ((*v).y * (*v).w);
	(*v).y = (*v).y + ((*v).z * (*v).x);
	(*v).z = (*v).z + ((*v).x * (*v).y);
	(*v).w = (*v).w + ((*v).y * (*v).z);


	let v2 = vec4<u32>((*v).x >> 16u, (*v).y >> 16u, (*v).z >> 16u, (*v).w >> 16u);

	(*v) = (*v) ^ v2;
	// (*v) = (*v) ^ ((*v) >> 16u);
	(*v).x = (*v).x + ((*v).y * (*v).w);
	(*v).y = (*v).y + ((*v).z * (*v).x);
	(*v).z = (*v).z + ((*v).x * (*v).y);
	(*v).w = (*v).w + ((*v).y * (*v).z);
} 

fn rand() -> f32 {
	pcg4d(&s0);
	return f32(s0.x) / f32(4294967300.);
} 

fn rand2() -> vec2<f32> {
	pcg4d(&s0);
	return vec2<f32>(s0.xy) / f32(4294967300.);
} 

fn rand3() -> vec3<f32> {
	pcg4d(&s0);
	return vec3<f32>(s0.xyz) / f32(4294967300.);
} 

fn rand4() -> vec4<f32> {
	pcg4d(&s0);
	return vec4<f32>(s0) / f32(4294967300.);
} 

fn Simulation(
	ch: texture_storage_2d<rgba32float, read_write>,  
	P: ptr<function, particle>, 
	pos: vec2<f32>
)  {
	var F: vec2<f32> = vec2<f32>(0.);
	var I: i32 = i32(ceil(10.5));

	for (var i: i32 = -I; i <= I; i = i + 1) {
	for (var j: i32 = -I; j <= I; j = j + 1) {

		if (i == 0 && j == 0) {		continue;   }


		let tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(j));

		let data: vec4<f32> = textureLoad(ch, vec2<i32>(tpos));
		let P0: particle = getParticle(data, tpos);

		if (P0.M == 0.) {	continue;   }

		let dx: vec2<f32> = P0.NX - (*P).NX;
		var d: f32 = length(dx);
		var r: f32 = (*P).R + P0.R;

		var m: f32 = 1. / (*P).M / (1. / (*P).M + 1. / P0.M) * 2.;
		m = ((*P).M - P0.M) / ((*P).M + P0.M) + 2. * P0.M / ((*P).M + P0.M);
		m = P0.M / ((*P).M + P0.M);

		if (d < r) { F = F - (normalize(dx) * (r - d) * m); }
	}
	}

	let dp: vec2<f32> = (*P).NX;
	var d: f32 = border(dp);
	if (d < 0.) { F = F - (bN(dp).xy * d); }
	(*P).NX = (*P).NX + (F * 0.9 / 3.);
} 

// RUST_LOG="wgpu=error,naga=warn,info" cargo run --release --example simpler_particles  



@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    R = uni.iResolution.xy;

    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));

    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var col: vec4<f32>;
	var pos = vec2<f32>(f32(location.x), f32(location.y) );

	R = uni.iResolution.xy;
	time = uni.iTime;
	var colxyz = col.xyz;
	colxyz = vec3<f32>(1.);
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;

	var d: f32 = 100.;
	var c: vec3<f32> = vec3<f32>(1.);
	var m: f32 = 1.;
	var I: i32 = i32(ceil(particle_size * 0.5)) + 2;
	

	for (var i: i32 = -I; i <= I; i = i + 1) {
	for (var j: i32 = -I; j <= I; j = j + 1) {

		var tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(j));
		var data: vec4<f32> = textureLoad(buffer_d, vec2<i32>(tpos));
		var P0: particle = getParticle(data, tpos);

		if (P0.M == 0.) {		continue; }

		var nd: f32 = distance(pos, P0.NX) - P0.R;

		if (nd < d) {
			let V: vec2<f32> = (P0.NX - P0.X) * 1. / 2.;
			c = vec3<f32>(V * 0.5 + 0.5, (P0.M - 1.) / 3.);
			c = mix(vec3<f32>(1.), c, length(V));
			m = P0.M;
		}

		d = min(d, nd);

		if (d < 0.) {		break;  }
	}

	}

	var s: f32 = 100.;
	let off: vec2<f32> = vec2<f32>(5., 5.);
	if (d > 0. && i32(pos.x) % 2 == 0 && i32(pos.y) % 2 == 0) {

		for (var i: i32 = -I; i <= I; i = i + 1) {
		for (var j: i32 = -I; j <= I; j = j + 1) {

			let tpos: vec2<f32> = pos - off + vec2<f32>(f32(i), f32(j));
			let data: vec4<f32> = textureLoad(buffer_d, vec2<i32>(tpos));
			let P0: particle = getParticle(data, tpos);
			if (tpos.x < 0. || tpos.x > R.x || tpos.y < 0. || tpos.y > R.x) {
				s = 0.;
				break;
			}
			if (P0.M == 0.) {
				continue;
			}
			let nd: f32 = distance(pos - off, P0.NX) - P0.R;
			s = min(s, nd);
		}

		}

	}

	if (d < 0.) { d = sin(d); }

	var colxyz = col.xyz;
	colxyz = vec3<f32>(abs(d));
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;

	if (d < 0.) {
		var colxyz = col.xyz;
		colxyz = col.xyz * (c);
		col.x = colxyz.x;
		col.y = colxyz.y;
		col.z = colxyz.z;

		var colxyz = col.xyz;
		colxyz = col.xyz / (0.4 + m * 0.25);
		col.x = colxyz.x;
		col.y = colxyz.y;
		col.z = colxyz.z;
	}

	var colxyz = col.xyz;
	colxyz = clamp(col.xyz, vec3<f32>(0.), vec3<f32>(1.));
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;

	if (d > 0.) {
		 var colxyz = col.xyz;
		colxyz = col.xyz * (mix(vec3<f32>(0.5), vec3<f32>(1.), clamp(s, 0., 1.)));
		col.x = colxyz.x;
		col.y = colxyz.y;
		col.z = colxyz.z; 
	}

	if (pos.x < 3.) || (pos.x > R.x - 3.) || (pos.y < 3.) || (pos.y > R.y - 3.) { 
		var colxyz = col.xyz;
		colxyz = vec3<f32>(0.5);
		col.x = colxyz.x;
		col.y = colxyz.y;
		col.z = colxyz.z; 
	}

	// col = vec4<f32>(1.0, 0.0, 0.0, 1.0);
	col.w = 1.0;

	textureStore(texture, y_inverted_location, col);
} 

