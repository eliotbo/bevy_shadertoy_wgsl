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





[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    // let location2 = vec2<i32>(i32(R.x) - i32(invocation_id.x), i32(invocation_id.y));

    var alive = true;

	var q: f32;
	if (true) { 
		q = 1.;
	} else { 
		q = 4.;
	};

    var O: vec4<f32> =  mix(textureLoad(buffer_a, location),vec4<f32>(0.5), 0.1);

    // var O: vec4<f32> = vec4<f32>(0.5);

    textureStore(texture, y_inverted_location, O);
}