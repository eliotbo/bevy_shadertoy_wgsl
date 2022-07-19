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





// https://www.shadertoy.com/view/XsXSWS
// no licence

fn hash(p: vec2<f32>) -> vec2<f32> {
	var p_var = p;
	p_var = vec2<f32>(dot(p_var, vec2<f32>(127.1, 311.7)), dot(p_var, vec2<f32>(269.5, 183.3)));
	return -1. + 2. * fract(sin(p_var) * 43758.547);
} 

fn noise(p: vec2<f32>) -> f32 {
	let K1: f32 = 0.36602542;
	let K2: f32 = 0.21132487;
	let i: vec2<f32> = floor(p + (p.x + p.y) * K1);
	var a: vec2<f32> = p - i + (i.x + i.y) * K2;
	var o: vec2<f32>; 
    if (a.x > a.y) { o = vec2<f32>(1., 0.); } else { o = vec2<f32>(0., 1.); };
	let b: vec2<f32> = a - o + K2;
	var c: vec2<f32> = a - 1. + 2. * K2;
	let h: vec3<f32> = max(0.5 - vec3<f32>(dot(a, a), dot(b, b), dot(c, c)), vec3<f32>(0.));
	var n: vec3<f32> = h * h * h * h * vec3<f32>(dot(a, hash(i + 0.)), dot(b, hash(i + o)), dot(c, hash(i + 1.)));
	return dot(n, vec3<f32>(70.));
} 

fn fbm(uv_in: vec2<f32>) -> f32 {
	var f: f32;
    var uv = uv_in;
	let m: mat2x2<f32> = mat2x2<f32>(1.6, 1.2, -1.2, 1.6);
	f = 0.5 * noise(uv);
	uv = m * uv;
	f = f + (0.25 * noise(uv));
	uv = m * uv;
	f = f + (0.125 * noise(uv));
	uv = m * uv;
	f = f + (0.0625 * noise(uv));
	uv = m * uv;
	f = 0.5 + 0.5 * f;
	return f;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );
	let uv: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
	var q: vec2<f32> = uv;
	q.x = q.x * (5.);
	q.y = q.y * (2.);
	let strength: f32 = floor(q.x + 1.);
	let T3: f32 = max(3., 1.25 * strength) * uni.iTime;
	q.x = (q.x % 1.) - 0.5;
	q.y = q.y - (0.25);
	let n: f32 = fbm(strength * q - vec2<f32>(0., T3));
	let c: f32 = 1. - 16. * pow(max(0., length(q * vec2<f32>(1.8 + q.y * 1.5, 0.75)) - n * max(0., q.y + 0.25)), 1.2);
	var c1: f32 = n * c * (1.5 - pow(2.5 * uv.y, 4.));
	c1 = clamp(c1, 0., 1.);
	let col: vec3<f32> = vec3<f32>(1.5 * c1, 1.5 * c1 * c1 * c1, c1 * c1 * c1 * c1 * c1 * c1);
	let a: f32 = c * (1. - pow(uv.y, 3.));
	fragColor = vec4<f32>(mix(vec3<f32>(0.), col, a), 1.);

    textureStore(texture, y_inverted_location, fragColor);
} 



