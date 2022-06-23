// Sample Pinning
// https://www.shadertoy.com/view/XdfXzn
// MIT License

var<private> STRUCTURED: bool;
var<private> sundir: vec3<f32>;
fn noise(x: vec3<f32>) -> f32 {
	var p: vec3<f32> = floor(x);
	var f: vec3<f32> = fract(x);
	f = f * f * (3. - 2. * f);
	let uv: vec2<f32> = p.xy + vec2<f32>(37., 17.) * p.z + f.xy;
	// let rg: vec2<f32> = textureLod(iChannel0, (uv + 0.5) / 256., 0.).yx;
    // let rg: vec2<f32> = textureLoad(rgba_noise_256_texture, vec2<i32>((uv + 0.5) ), 0).yx;

    let rg: vec2<f32> = textureSampleLevel(
        rgba_noise_256_texture,
        rgba_noise_256_texture_sampler,
        (uv + 0.5) / 256.,
        0.
    ).yx ;

	return mix(rg.x, rg.y, f.z);
} 

fn map(p: vec3<f32>) -> vec4<f32> {
	var d: f32 = 0.1 + 0.8 * sin(0.6 * p.z) * sin(0.5 * p.x) - p.y;
	var q: vec3<f32> = p;
	var f: f32;
	f = 0.5 * noise(q);
	q = q * 2.02;
	f = f + (0.25 * noise(q));
	q = q * 2.03;
	f = f + (0.125 * noise(q));
	q = q * 2.01;
	f = f + (0.0625 * noise(q));
	d = d + (2.75 * f);
	d = clamp(d, 0., 1.);
	var res: vec4<f32> = vec4<f32>(d);
	var col: vec3<f32> = 1.15 * vec3<f32>(1., 0.95, 0.8);
	col = col + (vec3<f32>(1., 0., 0.) * exp2(res.x * 10. - 10.));
	var resxyz = res.xyz;
	resxyz = mix(col, vec3<f32>(0.7, 0.7, 0.7), res.x);
	res.x = resxyz.x;
	res.y = resxyz.y;
	res.z = resxyz.z;
	return res;
} 

fn mysign(x: f32) -> f32 {

	if (x < 0.) { return -1.; } else { return 1.; };
} 

fn mysign2(x: vec2<f32>) -> vec2<f32> {
    var x2: vec2<f32>;
    if (x.x < 0.) { x2.x = -1.; } else { x2.x =1.; };
    if (x.y < 0.) { x2.y = -1.; } else { x2.y = 1.; }
	return x2;
} 

fn SetupSampling(t: ptr<function, vec2<f32>>, dt: ptr<function, vec2<f32>>, wt: ptr<function, vec2<f32>>, ro: vec3<f32>, rd: vec3<f32>)  {
	var rd_var = rd;
	if (!STRUCTURED) {
		(*dt) = vec2<f32>(1., 1.);
		(*t) = (*dt);
		(*wt) = vec2<f32>(0.5, 0.5);
		return ;
	}
	var n0: vec3<f32>; 
    if (abs(rd_var.x) > abs(rd_var.z)) { n0 = vec3<f32>(1., 0., 0.); } else { n0 = vec3<f32>(0., 0., 1.); };

	var n1: vec3<f32> = vec3<f32>(mysign(rd_var.x * rd_var.z), 0., 1.);
	let ln: vec2<f32> = vec2<f32>(length(n0), length(n1));
	n0 = n0 / (ln.x);
	n1 = n1 / (ln.y);
	let ndotro: vec2<f32> = vec2<f32>(dot(ro, n0), dot(ro, n1));
	var ndotrd: vec2<f32> = vec2<f32>(dot(rd_var, n0), dot(rd_var, n1));
	let period: vec2<f32> = ln * 1.;
	(*dt) = period / abs(ndotrd);
	let dist: vec2<f32> = abs(ndotro / ndotrd);
	(*t) = -mysign2(ndotrd) * (ndotro % period) / abs(ndotrd);

	if (ndotrd.x > 0.) { (*t).x = (*t).x + ((*dt).x); }
	if (ndotrd.y > 0.) { (*t).y = (*t).y + ((*dt).y); }
	let minperiod: f32 = 1.;
	let maxperiod: f32 = sqrt(2.) * 1.;
	(*wt) = smoothStep(vec2<f32>(maxperiod), vec2<f32>(minperiod), (*dt) / ln);
	(*wt) = (*wt) / ((*wt).x + (*wt).y);
} 

fn raymarch(ro: vec3<f32>, rd: vec3<f32>) -> vec4<f32> {
	var sum: vec4<f32> = vec4<f32>(0., 0., 0., 0.);
	var t: vec2<f32>;
	var dt: vec2<f32>;
	var wt: vec2<f32>;
	SetupSampling(&t, &dt, &wt, ro, rd);
	let f: f32 = 0.6;
	let endFade: f32 = f * f32(40.) * 1.;
	let startFade: f32 = 0.8 * endFade;

	for (var i: i32 = 0; i < 40; i = i + 1) {
		if (sum.a > 0.99) {		continue;
 }
		var data: vec4<f32>;
        if (t.x < t.y) { data = vec4<f32>(t.x, wt.x, dt.x, 0.); } else { data = vec4<f32>(t.y, wt.y, 0., dt.y); };

		let pos: vec3<f32> = ro + data.x * rd;
		var w: f32 = data.y;
		t = t + (data.zw);
		w = w * (smoothStep(endFade, startFade, data.x));
		var col: vec4<f32> = map(pos);
		let dif: f32 = clamp((col.w - map(pos + 0.6 * sundir).w) / 0.6, 0., 1.);
		let lin: vec3<f32> = vec3<f32>(0.51, 0.53, 0.63) * 1.35 + 0.55 * vec3<f32>(0.85, 0.57, 0.3) * dif;
		var colxyz = col.xyz;
	colxyz = col.xyz * (lin);
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;
		var colxyz = col.xyz;
	colxyz = col.xyz * (col.xyz);
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;
		col.a = col.a * (0.75);
		var colrgb = col.rgb;
	colrgb = col.rgb * (col.a);
	col.r = colrgb.r;
	col.g = colrgb.g;
	col.b = colrgb.b;
		sum = sum + (col * (1. - sum.a) * w);
	}

	var sumxyz = sum.xyz;
	sumxyz = sum.xyz / (0.001 + sum.w);
	sum.x = sumxyz.x;
	sum.y = sumxyz.y;
	sum.z = sumxyz.z;
	return clamp(sum, vec4<f32>(0.), vec4<f32>(1.));
} 

fn sky(rd: vec3<f32>) -> vec3<f32> {
	var col: vec3<f32> = vec3<f32>(0.);
	let hort: f32 = 1. - clamp(abs(rd.y), 0., 1.);
	col = col + (0.5 * vec3<f32>(0.99, 0.5, 0.) * exp2(hort * 8. - 8.));
	col = col + (0.1 * vec3<f32>(0.5, 0.9, 1.) * exp2(hort * 3. - 3.));
	col = col + (0.55 * vec3<f32>(0.6, 0.6, 0.9));
	let sun: f32 = clamp(dot(sundir, rd), 0., 1.);
	col = col + (0.2 * vec3<f32>(1., 0.3, 0.2) * pow(sun, 2.));
	col = col + (0.5 * vec3<f32>(1., 0.9, 0.9) * exp2(sun * 650. - 650.));
	col = col + (0.1 * vec3<f32>(1., 1., 0.1) * exp2(sun * 100. - 100.));
	col = col + (0.3 * vec3<f32>(1., 0.7, 0.) * exp2(sun * 50. - 50.));
	col = col + (0.5 * vec3<f32>(1., 0.3, 0.05) * exp2(sun * 10. - 10.));
	let ax: f32 = atan2(rd.y, length(rd.xz)) / 1.;
	let ay: f32 = atan2(rd.z, rd.x) / 2.;
    
	var st: f32 = textureLoad(rgba_noise_256_texture, vec2<i32>(vec2<f32>(ax, ay) * 255.), 0 ).x;

	let st2: f32 = textureLoad(rgba_noise_256_texture, vec2<i32>(0.25 * vec2<f32>(ax, ay) * 255.), 0 ).x;
	st = st * (st2);
	st = smoothStep(0.65, 0.9, st);
	col = mix(col, col + 1.8 * st, clamp(1. - 1.1 * length(col), 0., 1.));
	return col;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	STRUCTURED = uni.iMouse.z <= 0.;
	sundir = normalize(vec3<f32>(-1., 0., -1.));
	let q: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
	var p: vec2<f32> = -1. + 2. * q;
	p.x = p.x * (uni.iResolution.x / uni.iResolution.y);
	let mo: vec2<f32> = -1. + 2. * uni.iMouse.xy / uni.iResolution.xy;
	let lookDir: vec3<f32> = vec3<f32>(cos(0.53 * uni.iTime), 0., sin(uni.iTime));
	let camVel: vec3<f32> = vec3<f32>(-20., 0., 0.);
	let ro: vec3<f32> = vec3<f32>(0., 1.5, 0.) + uni.iTime * camVel;
	let ta: vec3<f32> = ro + lookDir;
	let ww: vec3<f32> = normalize(ta - ro);
	let uu: vec3<f32> = normalize(cross(vec3<f32>(0., 1., 0.), ww));
	let vv: vec3<f32> = normalize(cross(ww, uu));
	let fov: f32 = 1.;
	let rd: vec3<f32> = normalize(fov * p.x * uu + fov * 1.2 * p.y * vv + 1.5 * ww);
	var clouds: vec4<f32> = raymarch(ro, rd);
	var col: vec3<f32> = clouds.xyz;
	if (clouds.w <= 0.99) { col = mix(sky(rd), col, clouds.w); }
	col = clamp(col, vec3<f32>(0.), vec3<f32>(1.));
	col = smoothStep(vec3<f32>(0.), vec3<f32>(1.), col);
	col = col * (pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), 0.12));
	// (*fragColor) = vec4<f32>(col, 1.);
    textureStore(texture, y_inverted_location, vec4<f32>(col, 1.));

    let test: vec4<f32> = textureSampleLevel(
        rgba_noise_256_texture,
        rgba_noise_256_texture_sampler,
        vec2<f32>(location) / R * 2.0,
        0.
    ) ;

    // textureStore(texture, y_inverted_location, test);


} 




    



// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
//     let R: vec2<f32> = uni.iResolution.xy;
//     let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

// 	if (uni.iMouse.z > 0.) { useNewApproach = false; }
// 	let q: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
// 	var p: vec2<f32> = -1. + 2. * q;
// 	p.x = p.x * (uni.iResolution.x / uni.iResolution.y);
// 	let mo: vec2<f32> = -1. + 2. * uni.iMouse.xy / uni.iResolution.xy;
// 	let ro: vec3<f32> = vec3<f32>(0., 1.9, 0.) + uni.iTime * camVel;
// 	let ta: vec3<f32> = ro + lookDir;
// 	let ww: vec3<f32> = normalize(ta - ro);
// 	let uu: vec3<f32> = normalize(cross(vec3<f32>(0., 1., 0.), ww));
// 	let vv: vec3<f32> = normalize(cross(ww, uu));
// 	let rd: vec3<f32> = normalize(p.x * uu + 1.2 * p.y * vv + 1.5 * ww);
// 	var col: vec3<f32> = sky(rd);
// 	let rd_layout: vec3<f32> = rd / mix(dot(rd, ww), 1., samplesCurvature);
// 	let clouds: vec4<f32> = raymarch(ro, rd_layout);
// 	col = mix(col, clouds.xyz, clouds.w);
// 	col = clamp(col, 0., 1.);
// 	col = smoothStep(0., 1., col);
// 	col = col * (pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), 0.12));
// 	// (*fragColor) = vec4<f32>(col, 1.);
//     textureStore(texture, y_inverted_location, vec4<f32>(col, 1.));

    
// } 

