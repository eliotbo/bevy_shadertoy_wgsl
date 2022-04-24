[[group(0), binding(0)]]
var texture_a: texture_storage_2d<rgba8unorm, read_write>;

struct CommonUniform {
    iResolution: vec2<f32>;

    iTime: f32;
    iTimeDelta: f32;
    iFrame: i32;
    iChannelTime: vec4<f32>;

    iChannelResolution: vec4<f32>;
    iMouse: vec2<f32>;
    iDate: vec4<i32>;
    iSampleRate: i32;
};

// [[group(0), binding(1)]]
// var<uniform> uni: CommonUniform;

{{COMMON}}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

    let color = vec4<f32>(0.0);

    textureStore(texture_a, location, color);
}


[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    textureStore(texture_a, location, vec4<f32>(0.065));
}