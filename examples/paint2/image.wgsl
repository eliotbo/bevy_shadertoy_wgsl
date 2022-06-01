[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var alive = true;

    var O: vec4<f32> =  textureLoad(buffer_a, location);

    textureStore(texture, location, O);
}