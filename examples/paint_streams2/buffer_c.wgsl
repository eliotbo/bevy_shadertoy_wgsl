
[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    R = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var fragColor: vec4<f32>;
    var pos = vec2<f32>(f32(location.x), f32(location.y));

	// R = uni.iResolution.xy;
    time = uni.iTime;
    let p: vec2<i32> = vec2<i32>(pos);
    // let data: vec4<f32> = texel(ch0, pos);
    let data: vec4<f32> = textureLoad(buffer_a, location);

    var P: particle = getParticle(data, pos);
    var rho: vec4<f32> = vec4<f32>(0.);

    for (var i: i32 = -1; i <= 1; i = i + 1) {
        for (var j: i32 = -1; j <= 1; j = j + 1) {
            let ij: vec2<i32> = vec2<i32>(i, j);
            // let data: vec4<f32> = texel(ch0, pos + ij);
            let data: vec4<f32> = textureLoad(buffer_a, location + ij);
            var P0: particle = getParticle(data, pos + vec2<f32>(ij));
            let x0: vec2<f32> = P0.X;
            rho = rho + (1. * vec4<f32>(P.V, P.M) * G((pos - x0) / 0.75));
        }
    }

    fragColor = rho;
    textureStore(buffer_c, location, fragColor);
} 

