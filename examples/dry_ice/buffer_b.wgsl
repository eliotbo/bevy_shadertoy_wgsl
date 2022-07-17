[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32> = vec4<f32>(0.0, 0.0, 0.0, 1.0);
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	let icoord: vec2<i32> = vec2<i32>(fragCoord);
	let vel_x_left: f32 = sample_texture(buffer_a, vec2<f32>(icoord + vec2<i32>(-1, 0))).x;
	let vel_x_right: f32 = sample_texture(buffer_a, vec2<f32>(icoord + vec2<i32>(1, 0))).x;
	let vel_y_bottom: f32 = sample_texture(buffer_a, vec2<f32>(icoord + vec2<i32>(0, -1))).y;
	let vel_y_top: f32 = sample_texture(buffer_a, vec2<f32>(icoord + vec2<i32>(0, 1))).y;
	let divergence: f32 = (vel_x_right - vel_x_left + vel_y_top - vel_y_bottom) * 0.5;
	fragColor = vec4<f32>(divergence, vec3<f32>(1.));
    textureStore(buffer_b, location, fragColor);


} 

