

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
//     let color = vec4<f32>(0.5);
//     textureStore(buffer_a, location, color);
// }


// fn mainImage( U: vec4<f32>,  pos: vec2<f32>) -> () {
    // let pos = vec2<f32>(location); 
	// R = uni.iResolution.xy;
	// time = uni.iTime;
	// Mouse = uni.iMouse;
	// let p: vec2<i32> = vec2<i32>(pos);
	// let data: vec4<f32> = texel(ch0, pos);
	// let P: particle;
	// Reintegration(buffer_b, P, pos);
	// if (uni.iFrame < 1) {
	// 	let rand: vec3<f32> = hash32(pos);
	// 	if (rand.z < 0.) {
	// 		P.X = pos;
	// 		P.V = 0.5 * (rand.xy - 0.5) + vec2<f32>(0., 0.);
	// 		P.M = vec2<f32>(mass, mass);
		
	// 	} else {
	// 		P.X = pos;
	// 		P.V = vec2<f32>(0.);
	// 		P.M = vec2<f32>(0.000001);
		
	// 	}
	
	// }
	// U = saveParticle(P, pos);

} 