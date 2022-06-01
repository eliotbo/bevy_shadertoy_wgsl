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



// fn get(location: vec2<i32>, offset_x: i32, offset_y: i32) -> i32 {
//     let value: vec4<f32> = textureLoad(texture, location + vec2<i32>(offset_x, offset_y));
//     return i32(value.x);
// }

// fn count_alive(location: vec2<i32>) -> i32 {
//     return get(location, -1, -1) +
//            get(location, -1,  0) +
//            get(location, -1,  1) +
//            get(location,  0, -1) +
//            get(location,  0,  1) +
//            get(location,  1, -1) +
//            get(location,  1,  0) +
//            get(location,  1,  1);
// }

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    // let n_alive = count_alive(location);
    // let color = vec4<f32>(f32(n_alive) / 8.0);

    // var alive: bool;
    // if (n_alive == 3) {
    //     alive = true;
    // } else if (n_alive == 2) {
    //     let currently_alive = get(location, 0, 0);
    //     alive = bool(currently_alive);
    // } else {
    //     alive = false;
    // }

    var alive = true;

    // let value: vec4<f32> = textureLoad(buffer_a, vec2<i32>(0,1));
    // if (value.x > 0.51) {
    //     alive = false;
    // }

    // let value: vec4<f32> = textureLoad(buffer_b, vec2<i32>(0,1));
    // if (value.x > 0.74) {
    //     alive = false;
    // }

    // let value: vec4<f32> = textureLoad(buffer_c, vec2<i32>(0,1));
    // if (value.x > 0.61) {
    //     alive = false;
    // }

    let value: vec4<f32> = textureLoad(buffer_a, vec2<i32>(0,1));
    if (value.x > 0.79) {
        alive = false;
    }

    // if (ga > 2) {
    //     alive = true;
    // }

    // if (uni.iTime > 1.0) {
    //     alive = false;
    // }

    // alive = false;

    storageBarrier();

    textureStore(texture, location, vec4<f32>(f32(alive)));
}