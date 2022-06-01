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

[[group(0), binding(3)]]
var buffer_c: texture_storage_2d<rgba8unorm, read_write>;

[[group(0), binding(4)]]
var buffer_d: texture_storage_2d<rgba8unorm, read_write>;

[[group(0), binding(5)]]
var texture: texture_storage_2d<rgba8unorm, read_write>;

fn hash(value: u32) -> u32 {
    var state = value;
    state = state ^ 2747636419u;
    state = state * 2654435769u;
    state = state ^ state >> 16u;
    state = state * 2654435769u;
    state = state ^ state >> 16u;
    state = state * 2654435769u;
    return state;
}
fn randomFloat(value: u32) -> f32 {
    return f32(hash(value)) / 4294967295.0;
}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

    let randomNumber = randomFloat(invocation_id.y * num_workgroups.x + invocation_id.x);
    let alive = randomNumber > 0.9;
    let color = vec4<f32>(f32(alive));

    textureStore(texture, location, color);
}

fn t(v: vec2<i32>) -> vec4<f32> {
	return textureLoad(buffer_a, v );
}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));


    var me: vec4<f32> = t(location) ;
    let U = location;

	me.z = me.z - (1.);
	var C = 1. - 3.*me.www;
	let d: vec3<f32> = vec3<f32>(t(U+vec2<i32>(1, 0)).w-t(U-vec2<i32>(1, 0)).w, t(U+vec2<i32>(0, 1)).w-t(U-vec2<i32>(0, 1)).w, 2.);
	C = C - (max(vec3<f32>(0.), sin(vec3<f32>(100.*length(me.xy), -5.*me.z, 368.*d.y)*me.w)));


    storageBarrier();

    textureStore(texture, location, vec4<f32>(C.x, C.y, C.z, me.w));
}



// fn mainImage( C: vec4<f32>,  U: vec2<f32>) -> () {
// 	let me: vec4<f32> = t(U);
// 	me.z = me.z - (1.);
// 	C = 1.-3.*me.wwww;
// 	let d: vec3<f32> = vec3<f32>(t(U+vec2<f32>(1, 0)).w-t(U-vec2<f32>(1, 0)).w, t(U+vec2<f32>(0, 1)).w-t(U-vec2<f32>(0, 1)).w, 2.);
// 	C.xyz = C.xyz - (max(vec3<f32>(0), sin(vec3<f32>(100.*length(me.xy), -5.*me.z, 368.*d.y)*me.w)));

// }

