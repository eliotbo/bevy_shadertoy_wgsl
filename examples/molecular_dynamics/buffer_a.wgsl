



fn PD(x: vec2<f32>, pos: vec2<f32>) -> vec3<f32> {
	return vec3<f32>(x, 1.) * Ha(x - (pos - 0.5)) * Hb(pos + 0.5 - x);

} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R = uni.iResolution.xy;
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    // let color = vec4<f32>(0.5);
    // textureStore(buffer_a, location, color);
// }

// fn mainImage( U: vec4<f32>,  pos: vec2<f32>)  {

    let pos = location;
	let p: vec2<i32> = vec2<i32>(pos);
	var X: vec2<f32> = vec2<f32>(0.);
	var V: vec2<f32> = vec2<f32>(0.);
	var M: f32 = 0.;
	for (var i: i32 = -1; i <= 1; i = i + 1) {
		for (var j: i32 = -1; j <= 1; j = j + 1) {
			let tpos: vec2<i32> = pos + vec2<i32>(i, j);
			// let data: vec4<f32> = T(tpos);

            let data: vec4<f32> = textureLoad(buffer_b, tpos % vec2<i32>( R));

            var X0: vec2<f32> = unpack(u32(data.x)) + vec2<f32>(tpos);
			var V0: vec2<f32> = unpack(u32(data.y));

			// var X0: vec2<f32> = DECODE(data.x) + tpos;
			// let V0: vec2<f32> = DECODE(data.y);

			let M0: i32 = i32(data.z);
			let M0H: i32 = M0 / 2;
			X0 = X0 + (V0 * dt);
			var m: vec3<f32>;

            if  (M0 >= 2) {
                 m =  f32(M0H) *      PD(X0 + vec2<f32>(0.5, 0.), vec3<f32>(pos)) 
                    + f32(M0 - M0H) * PD(X0 - vec2<f32>(0.5, 0.), vec3<f32>(pos)) ;
             } else {
                  m = f32(M0) * PD(X0, vec3<f32>(pos));
            }
			X = X + (m.xy);
			V = V + (V0 * m.z);
			M = M + (m.z);
		
		}	
	}	
    
    if (M != 0.) {
		X = X / (M);
		V = V / (M);
	}

	#ifdef INIT
		X = vec2<f32>(pos);
		V = vec2<f32>(0.);
		M = Ha(vec2<f32>(pos) - (R * 0.5 - R.x * 0.1)) * Hb(R * 0.5 + R.x * 0.1 - vec2<f32>(pos));
	#endif

	X = X - vec2<f32>(pos);

    let eX = f32(pack(X));
    let eV = f32(pack(V));

	let U = vec4<f32>(eX, eV, M, 0.);

    textureStore(buffer_a, location, U);

} 

