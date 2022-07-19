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



// [[group(0), binding(1)]]
// var buffer_a: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(2)]]
// var buffer_b: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(3)]]
// var buffer_c: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(4)]]
// var buffer_d: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(5)]]
var texture: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(6)]]
// var font_texture: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(6)]]
var font_texture: texture_2d<f32>;

[[group(0), binding(7)]]
var font_texture_sampler: sampler;

[[group(0), binding(8)]]
var rgba_noise_256_texture: texture_2d<f32>;

[[group(0), binding(9)]]
var rgba_noise_256_texture_sampler: sampler;



// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
//     let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

//     let color = vec4<f32>(f32(0));
//     textureStore(texture, location, color);
// }





// original code: https://www.shadertoy.com/view/MlKSWm
// MIT licence

fn mod289(x: vec3<f32>) -> vec3<f32> {
	return x - floor(x * (1. / 289.)) * 289.;
} 

fn mod289_4(x: vec4<f32>) -> vec4<f32> {
	return x - floor(x * (1. / 289.)) * 289.;
} 

fn permute(x: vec4<f32>) -> vec4<f32> {
	return mod289_4((x * 34. + 1.) * x);
} 

fn taylorInvSqrt(r: vec4<f32>) -> vec4<f32> {
	return 1.7928429 - 0.85373473 * r;
} 

fn snoise(v: vec3<f32>) -> f32 {
	let C: vec2<f32> = vec2<f32>(1. / 6., 1. / 3.);
	let D: vec4<f32> = vec4<f32>(0., 0.5, 1., 2.);

	// First corner
	var i: vec3<f32> = floor(v + dot(v, C.yyy));
	let x0: vec3<f32> = v - i + dot(i, C.xxx);

	// Other corners
	let g: vec3<f32> = step(x0.yzx, x0.xyz);
	let l: vec3<f32> = 1. - g;
	let i1: vec3<f32> = min(g.xyz, l.zxy);
	let i2: vec3<f32> = max(g.xyz, l.zxy);
	let x1: vec3<f32> = x0 - i1 + C.xxx;
	let x2: vec3<f32> = x0 - i2 + C.yyy;
	let x3: vec3<f32> = x0 - D.yyy;

	// Permutations
	i = mod289(i);
	let p: vec4<f32> = permute(permute(permute(i.z + vec4<f32>(0., i1.z, i2.z, 1.)) + i.y + vec4<f32>(0., i1.y, i2.y, 1.)) + i.x + vec4<f32>(0., i1.x, i2.x, 1.));
	
	// Gradients: 7x7 points over a square, mapped onto an octahedron.
	// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
	let n_: f32 = 0.14285715;
	let ns: vec3<f32> = n_ * D.wyz - D.xzx;
	let j: vec4<f32> = p - 49. * floor(p * ns.z * ns.z);
	let x_: vec4<f32> = floor(j * ns.z);
	let y_: vec4<f32> = floor(j - 7. * x_);
	var x: vec4<f32> = x_ * ns.x + ns.yyyy;
	var y: vec4<f32> = y_ * ns.x + ns.yyyy;
	let h: vec4<f32> = 1. - abs(x) - abs(y);
	let b0: vec4<f32> = vec4<f32>(x.xy, y.xy);
	let b1: vec4<f32> = vec4<f32>(x.zw, y.zw);
	let s0: vec4<f32> = floor(b0) * 2. + 1.;
	let s1: vec4<f32> = floor(b1) * 2. + 1.;
	let sh: vec4<f32> = -step(h, vec4<f32>(0.));
	let a0: vec4<f32> = b0.xzyw + s0.xzyw * sh.xxyy;
	let a1: vec4<f32> = b1.xzyw + s1.xzyw * sh.zzww;

	//Normalise gradients
	var p0: vec3<f32> = vec3<f32>(a0.xy, h.x);
	var p1: vec3<f32> = vec3<f32>(a0.zw, h.y);
	var p2: vec3<f32> = vec3<f32>(a1.xy, h.z);
	var p3: vec3<f32> = vec3<f32>(a1.zw, h.w);
	let norm: vec4<f32> = inverseSqrt(vec4<f32>(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 = p0 * (norm.x);
	p1 = p1 * (norm.y);
	p2 = p2 * (norm.z);
	p3 = p3 * (norm.w);

	// Mix final noise value
	var m: vec4<f32> = max(0.6 - vec4<f32>(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), vec4<f32>(0.));
	m = m * m;
	return 42. * dot(m * m, vec4<f32>(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
} 

// PRNG
// From https://www.shadertoy.com/view/4djSRW
fn prng(seed: vec2<f32>) -> f32 {
	var seed_var = seed;
	seed_var = fract(seed_var * vec2<f32>(5.3983, 5.4427));
	seed_var = seed_var + (dot(seed_var.yx, seed_var.xy + vec2<f32>(21.5351, 14.3137)));
	return fract(seed_var.x * seed_var.y * 95.4337);
} 

let PI: f32 = 3.1415927;
fn noiseStack(pos_in: vec3<f32>, octaves: i32, falloff: f32) -> f32 {
	var pos = pos_in;
	var noise: f32 = snoise(vec3<f32>(pos));
	var off: f32 = 1.;
	if (octaves > 1) {
		pos = pos * (2.);
		off = off * (falloff);
		noise = (1. - off) * noise + off * snoise(vec3<f32>(pos));
	}
	if (octaves > 2) {
		pos = pos * (2.);
		off = off * (falloff);
		noise = (1. - off) * noise + off * snoise(vec3<f32>(pos));
	}
	if (octaves > 3) {
		pos = pos * (2.);
		off = off * (falloff);
		noise = (1. - off) * noise + off * snoise(vec3<f32>(pos));
	}
	return (1. + noise) / 2.;
} 

fn noiseStackUV(pos: vec3<f32>, octaves: i32, falloff: f32, diff: f32) -> vec2<f32> {
	let displaceA: f32 = noiseStack(pos, octaves, falloff);
	let displaceB: f32 = noiseStack(pos + vec3<f32>(3984.293, 423.21, 5235.19), octaves, falloff);
	return vec2<f32>(displaceA, displaceB);
} 

fn toLinear(sRGB: vec4<f32>) -> vec4<f32> {
    let cutoff = vec4<f32>(sRGB < vec4<f32>(0.04045));
    let higher = pow((sRGB + vec4<f32>(0.055)) / vec4<f32>(1.055), vec4<f32>(2.4));
    let lower = sRGB / vec4<f32>(12.92);

    return mix(higher, lower, cutoff);
}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );
	let time: f32 = uni.iTime;
	let resolution: vec2<f32> = uni.iResolution.xy;
	let drag: vec2<f32> = uni.iMouse.xy;
	let offset: vec2<f32> = uni.iMouse.xy;

	let xpart: f32 = fragCoord.x / resolution.x;
	let ypart: f32 = fragCoord.y / resolution.y;

	let clip: f32 = 210.;
	let ypartClip: f32 = fragCoord.y / clip;
	let ypartClippedFalloff: f32 = clamp(2. - ypartClip, 0., 1.);
	let ypartClipped: f32 = min(ypartClip, 1.);
	let ypartClippedn: f32 = 1. - ypartClipped;

	let xfuel: f32 = 1. - abs(2. * xpart - 1.);

	let timeSpeed: f32 = 0.5;
	let realTime: f32 = timeSpeed * time;

	let coordScaled: vec2<f32> = 0.01 * fragCoord - 0.02 * vec2<f32>(offset.x, 0.);
	let position: vec3<f32> = vec3<f32>(coordScaled, 0.) + vec3<f32>(1223., 6434., 8425.);
	let flow: vec3<f32> = vec3<f32>(4.1 * (0.5 - xpart) * pow(ypartClippedn, 4.), -2. * xfuel * pow(ypartClippedn, 64.), 0.);
	let timing: vec3<f32> = realTime * vec3<f32>(0., -1.7, 1.1) + flow;

	let displacePos: vec3<f32> = vec3<f32>(1., 0.5, 1.) * 2.4 * position + realTime * vec3<f32>(0.01, -0.7, 1.3);
	let displace3: vec3<f32> = vec3<f32>(noiseStackUV(displacePos, 2, 0.4, 0.1), 0.);

	let noiseCoord: vec3<f32> = (vec3<f32>(2., 1., 1.) * position + timing + 0.4 * displace3) / 1.;
	let noise: f32 = noiseStack(noiseCoord, 3, 0.4);

	let flames: f32 = pow(ypartClipped, 0.3 * xfuel) * pow(noise, 0.3 * xfuel);

	let f: f32 = ypartClippedFalloff * pow(1. - flames * flames * flames, 8.);
	let fff: f32 = f * f * f;
	let fire: vec3<f32> = 1.5 * vec3<f32>(f, fff, fff * fff);

	// smoke
	let smokeNoise: f32 = 0.5 + snoise(0.4 * position + timing * vec3<f32>(1., 1., 0.2)) / 2.;
	let smoke: vec3<f32> = vec3<f32>(0.3 * pow(xfuel, 3.) * pow(ypart, 2.) * (smokeNoise + 0.4 * (1. - noise)));

	// sparks
	var sparkGridSize: f32 = 30.;
	var sparkCoord: vec2<f32> = fragCoord - vec2<f32>(2. * offset.x, 190. * realTime);
	sparkCoord = sparkCoord - (30. * noiseStackUV(0.01 * vec3<f32>(sparkCoord, 30. * time), 1, 0.4, 0.1));
	sparkCoord = sparkCoord + (100. * flow.xy);

	if (((sparkCoord.y / sparkGridSize) % 2.) < 1.) { sparkCoord.x = sparkCoord.x + (0.5 * sparkGridSize); }
	let sparkGridIndex: vec2<f32> = vec2<f32>(floor(sparkCoord / sparkGridSize));
	let sparkRandom: f32 = prng(sparkGridIndex);
	let sparkLife: f32 = min(10. * (1. - min((sparkGridIndex.y + 190. * realTime / sparkGridSize) / (24. - 20. * sparkRandom), 1.)), 1.);
	var sparks: vec3<f32> = vec3<f32>(0.);
	if (sparkLife > 0.) {
		let sparkSize: f32 = xfuel * xfuel * sparkRandom * 0.08;
		let sparkRadians: f32 = 999. * sparkRandom * 2. * PI + 2. * time;
		let sparkCircular: vec2<f32> = vec2<f32>(sin(sparkRadians), cos(sparkRadians));
		let sparkOffset: vec2<f32> = (0.5 - sparkSize) * sparkGridSize * sparkCircular;
		let sparkModulus: vec2<f32> = ((sparkCoord + sparkOffset) % sparkGridSize) - 0.5 * vec2<f32>(sparkGridSize);
		let sparkLength: f32 = length(sparkModulus);
		let sparksGray: f32 = max(0., 1. - sparkLength / (sparkSize * sparkGridSize));
		sparks = sparkLife * sparksGray * vec3<f32>(1., 0.3, 0.);
	}

	fragColor = vec4<f32>(max(fire, sparks) + smoke, 1.);
	textureStore(texture, y_inverted_location, toLinear(fragColor));
} 



