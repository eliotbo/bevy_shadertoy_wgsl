fn tex(uv: vec2<f32>, mc: ptr<function, mat3x3<f32>>, curl: ptr<function, f32>, degree: i32)  {
	let texel: vec2<f32> = 1. / uni.iResolution.xy;
	let stride: f32 = f32(1 << degree);
	let mip: f32 = f32(degree);
	let t: vec4<f32> = stride * vec4<f32>(texel, -texel.y, 0.);
	let d: f32 = abs(textureLod(iChannel0, fract(uv + t.ww), mip).w);
	let d_n: f32 = abs(textureLod(iChannel0, fract(uv + t.wy), mip).w);
	let d_e: f32 = abs(textureLod(iChannel0, fract(uv + t.xw), mip).w);
	let d_s: f32 = abs(textureLod(iChannel0, fract(uv + t.wz), mip).w);
	let d_w: f32 = abs(textureLod(iChannel0, fract(uv + -t.xw), mip).w);
	let d_nw: f32 = abs(textureLod(iChannel0, fract(uv + -t.xz), mip).w);
	let d_sw: f32 = abs(textureLod(iChannel0, fract(uv + -t.xy), mip).w);
	let d_ne: f32 = abs(textureLod(iChannel0, fract(uv + t.xy), mip).w);
	let d_se: f32 = abs(textureLod(iChannel0, fract(uv + t.xz), mip).w);
	(*mc) = mat3x3<f32>(d_nw, d_n, d_ne, d_w, d, d_e, d_sw, d_s, d_se);
	(*curl) = textureLod(iChannel0, fract(uv + +0.), mip).w;
} 

fn reduce(a: mat3x3<f32>, b: mat3x3<f32>) -> f32 {
	let p: mat3x3<f32> = matrixCompMult(a, b);
	return array<p,0>array<p,0> + array<p,0>array<p,1> + array<p,0>array<p,2> + array<p,1>array<p,0> + array<p,1>array<p,1> + array<p,1>array<p,2> + array<p,2>array<p,0> + array<p,2>array<p,1> + array<p,2>array<p,2>;
} 

fn confinement(fragCoord: vec2<f32>) -> vec2<f32> {
	let uv: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
	let k0: f32 = 0.25;
	let k1: f32 = 1. - 2. * 0.25;
	let conf_x: mat3x3<f32> = mat3x3<f32>(-k0, -k1, -k0, 0., 0., 0., k0, k1, k0);
	let conf_y: mat3x3<f32> = mat3x3<f32>(-k0, 0., k0, -k1, 0., k1, -k0, 0., k0);
	var mc: mat3x3<f32>;
	var v: vec2<f32> = vec2<f32>(0.);
	var curl: f32;
	var cacc: f32 = 0.;
	var nacc: vec2<f32> = vec2<f32>(0.);
	var wc: f32 = 0.;

	for (var i: i32 = 0; i < VORTICITY_SCALES; i = i + 1) {
		tex(uv, mc, curl, i);
		let w: f32 = 1.;
		let n: vec2<f32> = w * normz(vec2<f32>(reduce(conf_x, mc), reduce(conf_y, mc)));
		v = v + (curl * n);
		cacc = cacc + (curl);
		nacc = nacc + (n);
		wc = wc + (w);
	}

	if (PREMULTIPLY_CURL) {
		return v / wc;
	} else { 

		return nacc * cacc / wc;
	}
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	fragColor = vec4<f32>(confinement(fragCoord), 0., 0.);
	if (uni.iFrame == 0) { fragColor = 0.000001 * rand4(fragCoord, uni.iResolution.xy, uni.iFrame); }
} 

