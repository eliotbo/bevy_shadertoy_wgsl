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

let s2 = 30.;

let BLUR_DEPTH = 25.;

let SPEED = 2.;

let MOUSE_SIZE = 60.;

let texture_const = 255.;



var<private>  R: vec2<f32>;
fn A(location: vec2<f32>) -> vec4<f32> {
	return textureLoad(buffer_a, vec2<i32>(location)) * texture_const;
} 


[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let U = vec2<f32>(f32(location.x), f32(location.y));


// fn mainImage( Q: vec4<f32>,  U: vec2<f32>) -> () {
	R = uni.iResolution.xy;
	var Q = vec4<f32>(0.);

	for (var i: f32 = -BLUR_DEPTH; i <= BLUR_DEPTH; i = i + 1.) {
		let a: vec4<f32> = A(U + vec2<f32>(i, 0.));
		let c: vec4<f32> = a.z * smoothStep(1., 0.5, length(U + vec2<f32>(i, 0.) - a.xy)) 
            * vec4<f32>(f32(a.w == 0.), f32(a.w == 1.), f32(a.w == 2.), 0.);
		Q = Q + (c * sqrt(s2) / s2 * exp(-i * i * 0.5 / s2));
	
	}

    textureStore(buffer_b, location, Q / texture_const);

    // Q = textureLoad(buffer_a, vec2<i32>(location));
    // textureStore(buffer_b, location, Q);
} 

