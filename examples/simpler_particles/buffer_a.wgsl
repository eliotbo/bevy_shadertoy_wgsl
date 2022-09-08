// grid size = 

fn Integrate(
	ch: texture_storage_2d<rgba32float, read_write>, 
	P: ptr<function, particle>, 
	pos: vec2<f32>
)  {
	var I: i32 = 3;

	for (var i: i32 = -I; i <= I; i = i + 1) {
	for (var j: i32 = -I; j <= I; j = j + 1) {
		let tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(j));
		let data: vec4<f32> = textureLoad(ch, vec2<i32>(tpos));

		if (tpos.x < 0. || tpos.y < 0.) {		continue; }

		var P0: particle = getParticle(data, tpos);

		if (
			(P0.NX.x >= pos.x - 0.5 && P0.NX.x < pos.x + 0.5) 
			&& (P0.NX.y >= pos.y - 0.5) 
			&& (P0.NX.y < pos.y + 0.5) 
			&& (P0.M > 0.5)
		) {
			var P0V: vec2<f32> = (P0.NX - P0.X) / 2.;

			if (uni.iMouse.z > 0.) {
				let dm: vec2<f32> = P0.NX - uni.iMouse.xy;
				let d: f32 = length(dm / 50.);
				P0V = P0V + (normalize(dm) * exp(-d * d) * 0.3);
			}

			P0V = P0V + (vec2<f32>(0., -0.005));
			let v: f32 = length(P0V);
			var denom = 1.; 
			if (v > 1.) { denom = v; }
			P0V = P0V / denom;
			P0.X = P0.NX;
			P0.NX = P0.NX + P0V * 2.;
			(*P) = P0;

			break;
		}
	}

	}

} 



@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    // let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	// var U: vec4<f32>;
	var pos = vec2<f32>(f32(location.x), f32(location.y) );

	R = uni.iResolution.xy;
	rng_initialize(pos, i32(uni.iFrame));
	var P: particle;

	Integrate(buffer_d, &P, pos);

	// if (uni.iFrame == 0) {
	#ifdef INIT
		if (rand() > 0.992) {
			P.X = pos;
			P.NX = pos + (rand2() - 0.5) * 0.;
			let r: f32 = pow(rand(), 2.);
			P.M = mix(1., 4., r);
			P.R = mix(1., particle_size * 0.5, r);
		} else { 
			P.X = pos;
			P.NX = pos;
			P.M = 0.;
			P.R = particle_size * 0.5;
		}
	// }
	#endif

	let U = saveParticle(P, pos);
	textureStore(buffer_a, location, U);
    
} 


