fn tex(uv: vec2<f32>, mx: ptr<function, mat3x3<f32>>, my: ptr<function, mat3x3<f32>>, degree: i32)  {
	let texel: vec2<f32> = 1. / uni.iResolution.xy;
	let stride: f32 = f32(1 << degree);
	let mip: f32 = f32(degree);
	let t: vec4<f32> = stride * vec4<f32>(texel, -texel.y, 0.);
	let d: vec2<f32> = textureLod(iChannel0, fract(uv + t.ww), mip).xy;
	let d_n: vec2<f32> = textureLod(iChannel0, fract(uv + t.wy), mip).xy;
	let d_e: vec2<f32> = textureLod(iChannel0, fract(uv + t.xw), mip).xy;
	let d_s: vec2<f32> = textureLod(iChannel0, fract(uv + t.wz), mip).xy;
	let d_w: vec2<f32> = textureLod(iChannel0, fract(uv + -t.xw), mip).xy;
	let d_nw: vec2<f32> = textureLod(iChannel0, fract(uv + -t.xz), mip).xy;
	let d_sw: vec2<f32> = textureLod(iChannel0, fract(uv + -t.xy), mip).xy;
	let d_ne: vec2<f32> = textureLod(iChannel0, fract(uv + t.xy), mip).xy;
	let d_se: vec2<f32> = textureLod(iChannel0, fract(uv + t.xz), mip).xy;
	(*mx) = mat3x3<f32>(d_nw.x, d_n.x, d_ne.x, d_w.x, d.x, d_e.x, d_sw.x, d_s.x, d_se.x);
	(*my) = mat3x3<f32>(d_nw.y, d_n.y, d_ne.y, d_w.y, d.y, d_e.y, d_sw.y, d_s.y, d_se.y);
} 

fn reduce(a: mat3x3<f32>, b: mat3x3<f32>) -> f32 {
	let p: mat3x3<f32> = matrixCompMult(a, b);
	return array<p,0>array<p,0> + array<p,0>array<p,1> + array<p,0>array<p,2> + array<p,1>array<p,0> + array<p,1>array<p,1> + array<p,1>array<p,2> + array<p,2>array<p,0> + array<p,2>array<p,1> + array<p,2>array<p,2>;
} 

fn turbulence(fragCoord: vec2<f32>, turb: ptr<function, vec2<f32>>, curl: ptr<function, f32>)  {
	let uv: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
	let turb_xx: mat3x3<f32> = (2. - 0.9) * mat3x3<f32>(0.125, 0.25, 0.125, -0.25, -0.5, -0.25, 0.125, 0.25, 0.125);
	let turb_yy: mat3x3<f32> = (2. - 0.9) * mat3x3<f32>(0.125, -0.25, 0.125, 0.25, -0.5, 0.25, 0.125, -0.25, 0.125);
	let turb_xy: mat3x3<f32> = 0.9 * mat3x3<f32>(0.25, 0., -0.25, 0., 0., 0., -0.25, 0., 0.25);
	let norm: f32 = 8.8 / (4. + 8. * 0.6);
	let c0: f32 = 0.6;
	let curl_x: mat3x3<f32> = mat3x3<f32>(c0, 1., c0, 0., 0., 0., -c0, -1., -c0);
	let curl_y: mat3x3<f32> = mat3x3<f32>(c0, 0., -c0, 1., 0., -1., c0, 0., -c0);
	var mx: mat3x3<f32>;
	let my: mat3x3<f32>;
	var v: vec2<f32> = vec2<f32>(0.);
	var turb_wc: f32 = 0.;
	var curl_wc: f32 = 0.;
	(*curl) = 0.;

	for (var i: i32 = 0; i < TURBULENCE_SCALES; i = i + 1) {
		tex(uv, mx, my, i);
		let turb_w: f32 = 1.;
		let curl_w: f32 = 1. / f32(i + 1.);
		v = v + (turb_w * vec2<f32>(reduce(turb_xx, mx) + reduce(turb_xy, my), reduce(turb_yy, my) + reduce(turb_xy, mx)));
		(*curl) = (*curl) + (curl_w * (reduce(curl_x, mx) + reduce(curl_y, my)));
		turb_wc = turb_wc + (turb_w);
		curl_wc = curl_wc + (curl_w);
	}

	(*turb) = f32(TURBULENCE_SCALES) * v / turb_wc;
	(*curl) = norm * (*curl) / curl_wc;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	var turb: vec2<f32>;
	var curl: f32;
	turbulence(fragCoord, turb, curl);
	fragColor = vec4<f32>(turb, 0., curl);
	if (uni.iFrame == 0) { fragColor = 0.000001 * rand4(fragCoord, uni.iResolution.xy, uni.iFrame); }
} 

