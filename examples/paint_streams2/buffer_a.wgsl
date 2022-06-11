fn Reintegration(ch: texture_storage_2d<rgba32float, read_write>, pos: vec2<f32>) -> particle {

    var P: particle = particle(vec2<f32>(0.0), vec2<f32>(0.0), vec2<f32>(0.0));
    for (var i: i32 = -2; i <= 2; i = i + 1) {
        for (var j: i32 = -2; j <= 2; j = j + 1) {
            let tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(j));


            let data: vec4<f32> = textureLoad(ch, vec2<i32>(tpos));

            var P0: particle = getParticle(data, tpos);
            P0.X = P0.X + (P0.V * dt);
            let difR: f32 = 0.9 + 0.21 * smoothStep(fluid_rho * 0., fluid_rho * 0.333, P0.M.x);
            let D: vec3<f32> = distribution(P0.X, pos, difR);
            let m: f32 = P0.M.x * D.z;
            P.X = P.X + (D.xy * m);
            P.V = P.V + (P0.V * m);
            P.M.y = P.M.y + (P0.M.y * m);
            P.M.x = P.M.x + (m);
        }
    }


    if (P.M.x != 0.) {
        P.X = P.X / (P.M.x);
        P.V = P.V / (P.M.x);
        P.M.y = P.M.y / (P.M.x);
    }

    return P;
} 



[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var U: vec4<f32>;
    var pos = vec2<f32>(f32(location.x), f32(location.y));

	// R = uni.iResolution.xy;
	// time = uni.iTime;
	// Mouse = uni.iMouse;
    // let p: vec2<i32> = vec2<i32>(pos);
	// let data: vec4<f32> = texel(ch0, pos);
    // var P: particle;
    var P: particle = Reintegration(buffer_b, pos);

	// if (uni.iFrame < 1) {
    #ifdef INIT
    let rand: vec3<f32> = hash32(pos);

    if (rand.z < 0.) {
        P.X = pos;
        P.V = 0.5 * (rand.xy - 0.5) + vec2<f32>(0., 0.);
        P.M = vec2<f32>(mass, 0.);
    } else {

        P.X = pos;
        P.V = vec2<f32>(0.);
        P.M = vec2<f32>(0.000001);
    }
    #endif
	// }

    U = saveParticle(P, pos);
    textureStore(buffer_a, location, U);
} 
