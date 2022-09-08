@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    // let R: vec2<f32> = uni.iResolution.xy;
    // let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	// var U: vec4<f32>;
	var pos = vec2<f32>(f32(location.x), f32(location.y) );

	R = uni.iResolution.xy;
	time = uni.iTime;
	Mouse = uni.iMouse;
	let data: vec4<f32> = textureLoad(buffer_c, vec2<i32>(pos));
	var P: particle = getParticle(data, pos);

	if (P.M > 0.) { Simulation(buffer_c, &P, pos); }

	let U = saveParticle(P, pos);
	textureStore(buffer_d, location, U);
} 

