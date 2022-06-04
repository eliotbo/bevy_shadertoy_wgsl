

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
//     let color = vec4<f32>(0.5);
//     textureStore(buffer_a, location, color);
// }


// fn mainImage( U: vec4<f32>,  pos: vec2<f32>) -> () {
    let pos: vec2<f32> = vec2<f32>(location);

	R = uni.iResolution.xy;
	time = uni.iTime;
	Mouse = uni.iMouse;
	let p: vec2<i32> = location;

	// let data: vec4<f32> = texel(ch0, pos);

    // buffer_b is set as the channel 0 in Buffer A of the paint
    // streams inside shadertoy 
    let data: vec4<f32> =  textureLoad(buffer_b, location);

	var P: particle = Reintegration(buffer_b, pos);

	// if (uni.iFrame < 4.0) {
    # ifdef INIT 
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
    # endif
	// }

    textureStore(buffer_a, location, saveParticle(P, pos));
} 

