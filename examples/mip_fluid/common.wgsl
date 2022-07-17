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

