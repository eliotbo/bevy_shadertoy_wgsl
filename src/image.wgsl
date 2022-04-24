

[[group(1), binding(0)]]
var buffer_a: texture_storage_2d<rgba8unorm, read_write>;

[[group(2), binding(0)]]
var buffer_b: texture_storage_2d<rgba8unorm, read_write>;

[[group(3), binding(0)]]
var buffer_c: texture_storage_2d<rgba8unorm, read_write>;

[[group(4), binding(0)]]
var buffer_d: texture_storage_2d<rgba8unorm, read_write>;

[[group(5), binding(0)]]
var texture: texture_storage_2d<rgba8unorm, read_write>;



// [[group(1), binding(0)]]
// var buffer_b: texture_storage_2d<rgba8unorm, read_write>;

// [[group(2), binding(0)]]
// var buffer_c: texture_storage_2d<rgba8unorm, read_write>;

// [[group(3), binding(0)]]
// var buffer_d: texture_storage_2d<rgba8unorm, read_write>;

// [[group(4), binding(0)]]
// var texture: texture_storage_2d<rgba8unorm, read_write>;

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

[[group(0), binding(0)]]
var<uniform> uni: CommonUniform;

{{COMMON}}

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


fn get(location: vec2<i32>, offset_x: i32, offset_y: i32) -> i32 {
    let value: vec4<f32> = textureLoad(texture, location + vec2<i32>(offset_x, offset_y));
    return i32(value.x);
}

fn count_alive(location: vec2<i32>) -> i32 {
    return get(location, -1, -1) +
           get(location, -1,  0) +
           get(location, -1,  1) +
           get(location,  0, -1) +
           get(location,  0,  1) +
           get(location,  1, -1) +
           get(location,  1,  0) +
           get(location,  1,  1);
}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let n_alive = count_alive(location);
    let color = vec4<f32>(f32(n_alive) / 8.0);

    var alive: bool;
    if (n_alive == 3) {
        alive = true;
    } else if (n_alive == 2) {
        let currently_alive = get(location, 0, 0);
        alive = bool(currently_alive);
    } else {
        alive = false;
    }

    let value: vec4<f32> = textureLoad(buffer_a, vec2<i32>(0,1));
    if (value.x > 0.51) {
        alive = false;
    }

    // let value: vec4<f32> = textureLoad(buffer_b, vec2<i32>(0,1));
    // if (value.x > 0.74) {
    //     alive = false;
    // }


    // let value: vec4<f32> = textureLoad(buffer_c, vec2<i32>(0,1));
    // if (value.x < 0.61) {
    //     alive = false;
    // }

    // let value: vec4<f32> = textureLoad(buffer_d, vec2<i32>(0,1));
    // if (value.x > 0.79) {
    //     alive = false;
    // }

    // if (uni.iTime > 2.0) {
    //     alive = false;
    // }
    


    // if (xxx < 0.5) {
    //     alive = false;
    // }


    storageBarrier();

    textureStore(texture, location, vec4<f32>(f32(alive)));
}