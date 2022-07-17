struct CommonUniform {
    iTime: f32;
    iTimeDelta: f32;
    iFrame: f32;
    iSampleRate: f32;

    
    iMouse: vec4<f32>;
    iResolution: vec2<f32>;

    

    iChannelTime: vec4<f32>;
    iChannelResolution: vec4<f32>;
    iDate: vec4<i32>;
};

[[group(0), binding(0)]]
var<uniform> uni: CommonUniform;

[[group(0), binding(1)]]
var buffer_a: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(2)]]
var buffer_b: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(3)]]
var buffer_c: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(4)]]
var buffer_d: texture_storage_2d<rgba32float, read_write>;

let RECALCULATE_OFFSET: bool = true;
let BLUR_TURBULENCE: bool = false;
let BLUR_CONFINEMENT: bool = false;
let BLUR_VELOCITY: bool = false;
let USE_PRESSURE_ADVECTION: bool = false;
let PREMULTIPLY_CURL: bool = true;
let VIEW_VELOCITY: bool = true;
let CENTER_PUMP: bool = false;
fn normz(x: vec4<f32>) -> vec4<f32> {
	return if (x.xyz == vec3<f32>(0.)) { vec4<f32>(0., 0., 0., x.w); } else { vec4<f32>(normalize(x.xyz), 0.); };
} 

fn normz(x: vec3<f32>) -> vec3<f32> {
	return if (x == vec3<f32>(0.)) { vec3<f32>(0.); } else { normalize(x); };
} 

fn normz(x: vec2<f32>) -> vec2<f32> {
	return if (x == vec2<f32>(0.)) { vec2<f32>(0.); } else { normalize(x); };
} 

fn softmax(a: f32, b: f32, k: f32) -> f32 {
	return log(exp(k * a) + exp(k * b)) / k;
} 

fn softmin(a: f32, b: f32, k: f32) -> f32 {
	return -log(exp(-k * a) + exp(-k * b)) / k;
} 

fn softmax(a: vec4<f32>, b: vec4<f32>, k: f32) -> vec4<f32> {
	return log(exp(k * a) + exp(k * b)) / k;
} 

fn softmin(a: vec4<f32>, b: vec4<f32>, k: f32) -> vec4<f32> {
	return -log(exp(-k * a) + exp(-k * b)) / k;
} 

fn softclamp(a: f32, b: f32, x: f32, k: f32) -> f32 {
	return (softmin(b, softmax(a, x, k), k) + softmax(a, softmin(b, x, k), k)) / 2.;
} 

fn softclamp(a: vec4<f32>, b: vec4<f32>, x: vec4<f32>, k: f32) -> vec4<f32> {
	return (softmin(b, softmax(a, x, k), k) + softmax(a, softmin(b, x, k), k)) / 2.;
} 

fn softclamp(a: f32, b: f32, x: vec4<f32>, k: f32) -> vec4<f32> {
	return (softmin(vec4<f32>(b), softmax(vec4<f32>(a), x, k), k) + softmax(vec4<f32>(a), softmin(vec4<f32>(b), x, k), k)) / 2.;
} 

fn G1V(dnv: f32, k: f32) -> f32 {
	return 1. / (dnv * (1. - k) + k);
} 

fn ggx(n: vec3<f32>, v: vec3<f32>, l: vec3<f32>, rough: f32, f0: f32) -> f32 {
	let alpha: f32 = rough * rough;
	let h: vec3<f32> = normalize(v + l);
	let dnl: f32 = clamp(dot(n, l), 0., 1.);
	let dnv: f32 = clamp(dot(n, v), 0., 1.);
	let dnh: f32 = clamp(dot(n, h), 0., 1.);
	var dlh: f32 = clamp(dot(l, h), 0., 1.);
	var f: f32;
	let d: f32;
	let vis: f32;
	let asqr: f32 = alpha * alpha;
	let pi: f32 = 3.14159;
	let den: f32 = dnh * dnh * (asqr - 1.) + 1.;
	d = asqr / (pi * den * den);
	dlh = pow(1. - dlh, 5.);
	f = f0 + (1. - f0) * dlh;
	var k: f32 = alpha / 1.;
	vis = G1V(dnl, k) * G1V(dnv, k);
	let spec: f32 = dnl * d * f * vis;
	return spec;
} 

fn light(uv: vec2<f32>, BUMP: f32, SRC_DIST: f32, dxy: vec2<f32>, uni.iTime: f32, avd: ptr<function, vec3<f32>>) -> vec3<f32> {
	let sp: vec3<f32> = vec3<f32>(uv - 0.5, 0.);
	let light: vec3<f32> = vec3<f32>(cos(uni.iTime / 2.) * 0.5, sin(uni.iTime / 2.) * 0.5, -SRC_DIST);
	var ld: vec3<f32> = light - sp;
	let lDist: f32 = max(length(ld), 0.001);
	ld = ld / (lDist);
	(*avd) = reflect(normalize(vec3<f32>(BUMP * dxy, -1.)), vec3<f32>(0., 1., 0.));
	return ld;
} 

fn hash1(n: u32) -> f32 {
	var n_var = n;
	n_var = n_var << 13u ^ n_var;
	n_var = n_var * (n_var * n_var * 15731u + 789221u) + 1376312589u;
	return f32(n_var & vec3<u32>(2147483600.)) / f32(2147483600.);
} 

fn hash3(n: u32) -> vec3<f32> {
	var n_var = n;
	n_var = n_var << 13u ^ n_var;
	n_var = n_var * (n_var * n_var * 15731u + 789221u) + 1376312589u;
	let k: vec3<u32> = n_var * vec3<u32>(n_var, n_var * 16807u, n_var * 48271u);
	return vec3<f32>(k & vec3<u32>(2147483600.)) / f32(2147483600.);
} 

fn rand4(fragCoord: vec2<f32>, uni.iResolution: vec2<f32>, uni.iFrame: i32) -> vec4<f32> {
	let p: vec2<u32> = vec2<u32>(fragCoord);
	let r: vec2<u32> = vec2<u32>(uni.iResolution);
	let c: u32 = p.x + r.x * p.y + r.x * r.y * u32(uni.iFrame);
	return vec4<f32>(hash3(c), hash1(c + 75132900.));
} 



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

