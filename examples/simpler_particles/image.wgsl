

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    R = uni.iResolution.xy;

    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));

    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var col: vec4<f32>;
	var pos = vec2<f32>(f32(location.x), f32(location.y) );

	R = uni.iResolution.xy;
	time = uni.iTime;
	var colxyz = col.xyz;
	colxyz = vec3<f32>(1.);
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;

	var d: f32 = 100.;
	var c: vec3<f32> = vec3<f32>(1.);
	var m: f32 = 1.;
	var I: i32 = i32(ceil(particle_size * 0.5)) + 2;
	

	for (var i: i32 = -I; i <= I; i = i + 1) {
	for (var j: i32 = -I; j <= I; j = j + 1) {

		var tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(j));
		var data: vec4<f32> = textureLoad(buffer_d, vec2<i32>(tpos));
		var P0: particle = getParticle(data, tpos);

		if (P0.M == 0.) {		continue; }

		var nd: f32 = distance(pos, P0.NX) - P0.R;

		if (nd < d) {
			let V: vec2<f32> = (P0.NX - P0.X) * 1. / 2.;
			c = vec3<f32>(V * 0.5 + 0.5, (P0.M - 1.) / 3.);
			c = mix(vec3<f32>(1.), c, length(V));
			m = P0.M;
		}

		d = min(d, nd);

		if (d < 0.) {		break;  }
	}

	}

	var s: f32 = 100.;
	let off: vec2<f32> = vec2<f32>(5., 5.);
	if (d > 0. && i32(pos.x) % 2 == 0 && i32(pos.y) % 2 == 0) {

		for (var i: i32 = -I; i <= I; i = i + 1) {
		for (var j: i32 = -I; j <= I; j = j + 1) {

			let tpos: vec2<f32> = pos - off + vec2<f32>(f32(i), f32(j));
			let data: vec4<f32> = textureLoad(buffer_d, vec2<i32>(tpos));
			let P0: particle = getParticle(data, tpos);
			if (tpos.x < 0. || tpos.x > R.x || tpos.y < 0. || tpos.y > R.x) {
				s = 0.;
				break;
			}
			if (P0.M == 0.) {
				continue;
			}
			let nd: f32 = distance(pos - off, P0.NX) - P0.R;
			s = min(s, nd);
		}

		}

	}

	if (d < 0.) { d = sin(d); }

	var colxyz = col.xyz;
	colxyz = vec3<f32>(abs(d));
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;

	if (d < 0.) {
		var colxyz = col.xyz;
		colxyz = col.xyz * (c);
		col.x = colxyz.x;
		col.y = colxyz.y;
		col.z = colxyz.z;

		var colxyz = col.xyz;
		colxyz = col.xyz / (0.4 + m * 0.25);
		col.x = colxyz.x;
		col.y = colxyz.y;
		col.z = colxyz.z;
	}

	var colxyz = col.xyz;
	colxyz = clamp(col.xyz, vec3<f32>(0.), vec3<f32>(1.));
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;

	if (d > 0.) {
		 var colxyz = col.xyz;
		colxyz = col.xyz * (mix(vec3<f32>(0.5), vec3<f32>(1.), clamp(s, 0., 1.)));
		col.x = colxyz.x;
		col.y = colxyz.y;
		col.z = colxyz.z; 
	}

	if (pos.x < 3.) || (pos.x > R.x - 3.) || (pos.y < 3.) || (pos.y > R.y - 3.) { 
		var colxyz = col.xyz;
		colxyz = vec3<f32>(0.5);
		col.x = colxyz.x;
		col.y = colxyz.y;
		col.z = colxyz.z; 
	}

	// col = vec4<f32>(1.0, 0.0, 0.0, 1.0);
	col.w = 1.0;

	textureStore(texture, y_inverted_location, col);
} 

