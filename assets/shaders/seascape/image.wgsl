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






// https://www.shadertoy.com/view/Ms2SD1
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

let NUM_STEPS: i32 = 8;
let PI: f32 = 3.141592;
let EPSILON: f32 = 0.001;
let ITER_GEOMETRY: i32 = 3;
let ITER_FRAGMENT: i32 = 5;
let SEA_HEIGHT: f32 = 0.6;
let SEA_CHOPPY: f32 = 4.;
let SEA_SPEED: f32 = 0.8;
let SEA_FREQ: f32 = 0.16;
let SEA_BASE: vec3<f32> = vec3<f32>(0., 0.09, 0.18);
let SEA_WATER_COLOR: vec3<f32> = vec3<f32>(0.48, 0.54, 0.36);
let octave_m: mat2x2<f32> = mat2x2<f32>(vec2<f32>(1.6, 1.2), vec2<f32>(-1.2, 1.6));

fn fromEuler(ang: vec3<f32>) -> mat3x3<f32> {
	let a1: vec2<f32> = vec2<f32>(sin(ang.x), cos(ang.x));
	let a2: vec2<f32> = vec2<f32>(sin(ang.y), cos(ang.y));
	let a3: vec2<f32> = vec2<f32>(sin(ang.z), cos(ang.z));
	var m: mat3x3<f32>;
    m[0] = vec3<f32>(a1.y * a3.y + a1.x * a2.x * a3.x, a1.y * a2.x * a3.x + a3.y * a1.x, -a2.y * a3.x);
    m[1] =  vec3<f32>(-a2.y * a1.x, a1.y * a2.y, a2.x);
    m[2] =  vec3<f32>(a3.y * a1.x * a2.x + a1.y * a3.x, a1.x * a3.x - a1.y * a3.y * a2.x, a2.y * a3.y);
	return m;
} 

fn hash(p: vec2<f32>) -> f32 {
	let h: f32 = dot(p, vec2<f32>(127.1, 311.7));
	return fract(sin(h) * 43758.547);
} 

fn noise(p: vec2<f32>) -> f32 {
	let i: vec2<f32> = floor(p);
	let f: vec2<f32> = fract(p);
	let u: vec2<f32> = f * f * (3. - 2. * f);
	return -1. + 2. * mix(mix(hash(i + vec2<f32>(0., 0.)), hash(i + vec2<f32>(1., 0.)), u.x), mix(hash(i + vec2<f32>(0., 1.)), hash(i + vec2<f32>(1., 1.)), u.x), u.y);
} 

fn diffuse(n: vec3<f32>, l: vec3<f32>, p: f32) -> f32 {
	return pow(dot(n, l) * 0.4 + 0.6, p);
} 

fn specular(n: vec3<f32>, l: vec3<f32>, e: vec3<f32>, s: f32) -> f32 {
	let nrm: f32 = (s + 8.) / (PI * 8.);
	return pow(max(dot(reflect(e, n), l), 0.), s) * nrm;
} 

fn getSkyColor(e: vec3<f32>) -> vec3<f32> {
	var e_var = e;
	e_var.y = (max(e_var.y, 0.) * 0.8 + 0.2) * 0.8;
	return vec3<f32>(pow(1. - e_var.y, 2.), 1. - e_var.y, 0.6 + (1. - e_var.y) * 0.4) * 1.1;
} 

fn sea_octave(uv: vec2<f32>, choppy: f32) -> f32 {
	var uv_var = uv;
	uv_var = uv_var + (noise(uv_var));
	var wv: vec2<f32> = 1. - abs(sin(uv_var));
	let swv: vec2<f32> = abs(cos(uv_var));
	wv = mix(wv, swv, wv);
	return pow(1. - pow(wv.x * wv.y, 0.65), choppy);
} 

fn map(p: vec3<f32>) -> f32 {
	var freq: f32 = SEA_FREQ;
	var amp: f32 = SEA_HEIGHT;
	var choppy: f32 = SEA_CHOPPY;
	var uv: vec2<f32> = p.xz;
	uv.x = uv.x * (0.75);
	var d: f32;
	var h: f32 = 0.;

	for (var i: i32 = 0; i < ITER_GEOMETRY; i = i + 1) {
		d = sea_octave((uv + (1. + uni.iTime * SEA_SPEED)) * freq, choppy);
		d = d + (sea_octave((uv - (1. + uni.iTime * SEA_SPEED)) * freq, choppy));
		h = h + (d * amp);
		uv = uv * (octave_m);
		freq = freq * (1.9);
		amp = amp * (0.22);
		choppy = mix(choppy, 1., 0.2);
	}

	return p.y - h;
} 

fn map_detailed(p: vec3<f32>) -> f32 {
	var freq: f32 = SEA_FREQ;
	var amp: f32 = SEA_HEIGHT;
	var choppy: f32 = SEA_CHOPPY;
	var uv: vec2<f32> = p.xz;
	uv.x = uv.x * (0.75);
	var d: f32;
	var h: f32 = 0.;

	for (var i: i32 = 0; i < ITER_FRAGMENT; i = i + 1) {
		d = sea_octave((uv + (1. + uni.iTime * SEA_SPEED)) * freq, choppy);
		d = d + (sea_octave((uv - (1. + uni.iTime * SEA_SPEED)) * freq, choppy));
		h = h + (d * amp);
		uv = uv * (octave_m);
		freq = freq * (1.9);
		amp = amp * (0.22);
		choppy = mix(choppy, 1., 0.2);
	}

	return p.y - h;
} 

fn getSeaColor(p: vec3<f32>, n: vec3<f32>, l: vec3<f32>, eye: vec3<f32>, dist: vec3<f32>) -> vec3<f32> {
	var fresnel: f32 = clamp(1. - dot(n, -eye), 0., 1.);
	fresnel = pow(fresnel, 3.) * 0.5;
	let reflected: vec3<f32> = getSkyColor(reflect(eye, n));
	let refracted: vec3<f32> = SEA_BASE + diffuse(n, l, 80.) * SEA_WATER_COLOR * 0.12;
	var color: vec3<f32> = mix(refracted, reflected, fresnel);
	let atten: f32 = max(1. - dot(dist, dist) * 0.001, 0.);
	color = color + (SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten);
	color = color + (vec3<f32>(specular(n, l, eye, 60.)));
	return color;
} 

fn getNormal(p: vec3<f32>, eps: f32) -> vec3<f32> {
	var n: vec3<f32>;
	n.y = map_detailed(p);
	n.x = map_detailed(vec3<f32>(p.x + eps, p.y, p.z)) - n.y;
	n.z = map_detailed(vec3<f32>(p.x, p.y, p.z + eps)) - n.y;
	n.y = eps;
	return normalize(n);
} 

fn heightMapTracing(ori: vec3<f32>, dir: vec3<f32>,  p: ptr<function, vec3<f32>>) -> f32 {
	var p_var: vec3<f32>;
	var tm: f32 = 0.;
	var tx: f32 = 1000.;
	var hx: f32 = map(ori + dir * tx);
	if (hx > 0.) {
		p_var = ori + dir * tx;
		return tx;
	}
	var hm: f32 = map(ori + dir * tm);
	var tmid: f32 = 0.;

	for (var i: i32 = 0; i < NUM_STEPS; i = i + 1) {
		tmid = mix(tm, tx, hm / (hm - hx));
		p_var = ori + dir * tmid;
		let hmid: f32 = map(p_var);
		if (hmid < 0.) {
			tx = tmid;
			hx = hmid;
		} else { 

			tm = tmid;
			hm = hmid;
		}
	}
    *p = p_var;

	return tmid;
} 

fn getPixel(coord: vec2<f32>, time: f32) -> vec3<f32> {
	var uv: vec2<f32> = coord / uni.iResolution.xy;
	uv = uv * 2. - 1.;
	uv.x = uv.x * (uni.iResolution.x / uni.iResolution.y);
	let ang: vec3<f32> = vec3<f32>(sin(time * 3.) * 0.1, sin(time) * 0.2 + 0.3, time);
	let ori: vec3<f32> = vec3<f32>(0., 3.5, time * 5.);
	var dir: vec3<f32> = normalize(vec3<f32>(uv.xy, -2.));
	dir.z = dir.z + (length(uv) * 0.14);
	dir = normalize(dir) * fromEuler(ang);
	var p: vec3<f32>;
	heightMapTracing(ori, dir, &p);
	let dist: vec3<f32> = p - ori;
	let n: vec3<f32> = getNormal(p, dot(dist, dist) * (0.1 / uni.iResolution.x));
	let light: vec3<f32> = normalize(vec3<f32>(0., 1., 0.8));
	return mix(getSkyColor(dir), getSeaColor(p, n, light, dir, dist), pow(smoothstep(0., -0.02, dir.y), 0.2));
} 

fn toLinear(sRGB: vec4<f32>) -> vec4<f32> {
    let cutoff = vec4<f32>(sRGB < vec4<f32>(0.04045));
    let higher = pow((sRGB + vec4<f32>(0.055)) / vec4<f32>(1.055), vec4<f32>(2.4));
    let lower = sRGB / vec4<f32>(12.92);

    return mix(higher, lower, cutoff);
}

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	let time: f32 = uni.iTime * 0.3 + uni.iMouse.x * 0.01;

	// var color: vec3<f32> = vec3<f32>(0.);

	// for (var i: i32 = -1; i <= 1; i = i + 1) {

	// 	for (var j: i32 = -1; j <= 1; j = j + 1) {
	// 		let uv2: vec2<f32> = fragCoord + vec2<f32>(f32(i), f32(j)) / 3.;
	// 		color = color + (getPixel(uv2, time));
	// 	}

	// }
    // color = color / (9.);

    var color: vec3<f32> = getPixel(fragCoord, time);

	
	fragColor = vec4<f32>(pow(color, vec3<f32>(0.65)), 1.);
    // fragColor = vec4<f32>(1.);
    // fragColor = getSkyColor(location);

    // let col_debug_info = show_debug_info(location, fragColor.xyz);

    textureStore(texture, y_inverted_location, toLinear(fragColor));
} 

