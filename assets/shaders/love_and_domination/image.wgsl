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

let s2 = 30.;

let BLUR_DEPTH = 25.;

let SPEED = 2.;

let MOUSE_SIZE = 60.;

let texture_const = 255.;




var<private> R: vec2<f32>;

fn D(location: vec2<f32>) -> vec4<f32> {
	// return texture(iChannel0, U / R);
    return textureLoad(buffer_d, vec2<i32>(location)) * texture_const;
} 




[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let U = vec2<f32>(f32(location.x), f32(location.y));

//     var O: vec4<f32> =  textureLoad(buffer_a, location);
//     textureStore(texture, location, O);
// }

// fn mainImage( Q: vec4<f32>,  U: vec2<f32>) -> () {

	R = uni.iResolution.xy;
	let n: vec4<f32> = D(U + vec2<f32>(0., 1.));
	let e: vec4<f32> = D(U + vec2<f32>(1., 0.));
	let s: vec4<f32> = D(U + vec2<f32>(0., -1.));
	let w: vec4<f32> = D(U + vec2<f32>(-1., 0.));
	let dx: vec4<f32> = e - w;
	let dy: vec4<f32> = n - s;
	var Q = (D(U) + abs(dx) + abs(dy)) / 3.;

    textureStore(texture, location, Q);

    // Q = textureLoad(buffer_b, vec2<i32>(location));
    // textureStore(texture, location, Q * texture_const );

} 