[[stage(compute), workgroup_size(8, 8, 1)]]
fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let color = vec4<f32>(0.60);

    textureStore(buffer_d, location, color);
}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    // textureStore(buffer_d, location, vec4<f32>(0.7));

    if (uni.iTime > 1.0) {
        storageBarrier();
        textureStore(buffer_d, location, vec4<f32>(0.95));
    }

    // storageBarrier();
}