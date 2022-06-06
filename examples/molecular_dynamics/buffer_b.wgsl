fn sdBox( p: vec2<f32>,  b: vec2<f32>) -> f32 {
	let d: vec2<f32> = abs(p) - b;
	return length(max(d, vec2<f32>(0.))) + min(max(d.x, d.y), 0.);

} 

fn border(p: vec2<f32>, R: vec2<f32>) -> f32 {
	let bound: f32 = -sdBox(p - R * 0.5, R * vec2<f32>(0.49, 0.49));
	let box: f32 = sdBox(p - R * vec2<f32>(0.5, 0.6), R * vec2<f32>(0.05, 0.01));
	let drain: f32 = -sdBox(p - R * vec2<f32>(0.5, 0.7), R * vec2<f32>(0., 0.));
	return bound;

} 

let h = 1.;

fn bN(p: vec2<f32>, R: vec2<f32>) -> vec3<f32> {
	let dx: vec3<f32> = vec3<f32>(-h, 0., h);
	let idx: vec4<f32> = vec4<f32>(-1. / h, 0., 1. / h, 0.25);
	let r: vec3<f32> = idx.zyw * border(p + dx.zy, R) 
        + idx.xyw * border(p + dx.xy, R) 
        + idx.yzw * border(p + dx.yz, R) 
        + idx.yxw * border(p + dx.yx, R);
	return vec3<f32>(normalize(r.xy), r.z + 0.0001);

} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {

// }

// fn mainImage( U: vec4<f32>,  pos: vec2<f32>)  {
    let R = uni.iResolution.xy;
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let pos = location;


	let p: vec2<i32> = vec2<i32>(pos);

    let data: vec4<f32> = textureLoad(buffer_a, pos % vec2<i32>( R));
	// let data: vec4<f32> = textureLoad(buffer_a, pos );


	// var X: vec2<f32> = DECODE(data.x) + pos;
	// var V: vec2<f32> = DECODE(data.y);

    var X: vec2<f32> = unpack(u32(data.x)) + vec2<f32>(pos);
    var V: vec2<f32> = unpack(u32(data.y));


	let M: f32 = data.z;
	if (M != 0.) {
		var Fa: vec2<f32> = vec2<f32>(0.);
		for (var i: i32 = -2; i <= 2; i = i + 1) {
			for (var j: i32 = -2; j <= 2; j = j + 1) {
				let tpos: vec2<i32> = pos + vec2<i32>(i, j);
				// let data: vec4<f32> = T(tpos);

                let data: vec4<f32> = textureLoad(buffer_a, (tpos % vec2<i32>( R)));
				// let data: vec4<f32> = textureLoad(buffer_a, (tpos ));

                //  texelFetch(iChannel0, ivec2(mod(p,R)), 0)

				// let X0: vec2<f32> = DECODE(data.x) + tpos;
				// let V0: vec2<f32> = DECODE(data.y);

                var X0: vec2<f32> = unpack(u32(data.x)) + vec2<f32>(tpos);
                var V0: vec2<f32> = unpack(u32(data.y));

				let M0: f32 = data.z;
				let dx: vec2<f32> = X0 - X;

				Fa = Fa + (M0 * MF(dx) * dx);
			
			}	
		}		
            
		var F: vec2<f32> = vec2<f32>(0.);
		if (uni.iMouse.z > 0.) {
			let dx: vec2<f32> = vec2<f32>(pos) - uni.iMouse.xy;
			F = F - (0.003 * dx * GS(dx / 30.));
		}

		F = F + (0.001 * vec2<f32>(0., -1.0));

		V = V + ((F + Fa) * dt / M);
		X = X + (cooling * Fa * dt / M);
		let BORD: vec3<f32> = bN(X, R);

		V = V + (0.5 * smoothStep(0., 5., -BORD.z) * BORD.xy);
		let v: f32 = length(V);

		var denom: f32 = 1.0;
		if (v > 1.) {
			denom = 1. * v;
		} 
		V = V / denom;
		// V = V / (v > 1. ? 1. * v : 1.);
		
			
	}
	X = X - vec2<f32>(pos);
	// U = vec4<f32>(ENCODE(X), ENCODE(V), M, 0.);

    let eX = f32(pack(X));
    let eV = f32(pack(V));

	let U = vec4<f32>(eX, eV, M, 0.);

    textureStore(buffer_b, location, U);

} 

