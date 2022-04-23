[[group(0), binding(0)]]
var texture_d: texture_storage_2d<rgba8unorm, read_write>;

[[group(1), binding(0)]]
var texture_c: texture_storage_2d<rgba8unorm, read_write>;

[[group(2)), binding(0)]]
var texture_b: texture_storage_2d<rgba8unorm, read_write>;

[[group(3), binding(0)]]
var texture_a: texture_storage_2d<rgba8unorm, read_write>;

{{COMMON}}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

    let color = vec4<f32>(0.0);

    textureStore(texture_b, location, color);
}


[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    textureStore(texture_b, location, vec4<f32>(0.6));
}