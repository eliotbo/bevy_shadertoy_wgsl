struct CommonUniform {
    iTime: f32;
    iTimeDelta: f32;
    iFrame: i32;
    iSampleRate: i32;

    iChannelTime: vec4<f32>;
    iChannelResolution: vec4<f32>;
    iDate: vec4<i32>;
    
    iResolution: vec2<f32>;
    iMouse: vec2<f32>;
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

[[stage(compute), workgroup_size(8, 8, 1)]]
fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

    let color = vec4<f32>(f32(0));
    textureStore(texture, location, color);
}




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
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var alive = true;

    var O: vec4<f32> =  textureLoad(buffer_a, location);
    // let color = vec4<f32>(O.x, 0.1, 0.12, 1.0);

    // storageBarrier();

    // textureStore(texture, location, vec4<f32>(color));
    textureStore(texture, location, O);
}



