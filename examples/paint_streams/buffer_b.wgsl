[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {

// }

// fn mainImage( U: vec4<f32>,  pos: vec2<f32>) -> () {

    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let pos: vec2<f32> = vec2<f32>(location);

	R = uni.iResolution.xy;
	time = uni.iTime;
	Mouse = uni.iMouse;
	let p: vec2<i32> = location;


	// let data: vec4<f32> = texel(buffer_a, pos);
    let data: vec4<f32> =  textureLoad(buffer_a, location);

	var P: particle = getParticle(data, pos);

	if (P.M.x != 0.) {
		P = Simulation(buffer_a, P, pos);
	}

	if (length(P.X - R * vec2<f32>(0.8, 0.9)) < 10.) {
		P.X = pos;
		P.V = 0.5 * Dir(-PI * 0.25 - PI * 0.5 + 0.3 * sin(0.4 * time));
		P.M = mix(P.M, vec2<f32>(fluid_rho, 1.), 0.4);
	}
    
	if (length(P.X - R * vec2<f32>(0.2, 0.9)) < 10.) {
		P.X = pos;
		P.V = 0.5 * Dir(-PI * 0.25 + 0.3 * sin(0.3 * time));
		P.M = mix(P.M, vec2<f32>(fluid_rho, 0.), 0.4);
	}

	// U = saveParticle(P, pos);
    textureStore(buffer_b, location, saveParticle(P, pos));
} 

