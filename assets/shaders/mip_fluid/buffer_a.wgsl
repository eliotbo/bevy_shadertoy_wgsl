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



fn gaussian_turbulence(uv: vec2<f32>) -> vec2<f32> {
	var texel: vec2<f32> = 1. / uni.iResolution.xy;
	var t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	var d: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.ww + 0.)))).xy;
	var d_n: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.wy + 0.)))).xy;
	var d_e: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.xw + 0.)))).xy;
	var d_s: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.wz + 0.)))).xy;
	var d_w: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (-t.xw + 0.)))).xy;
	var d_nw: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (-t.xz + 0.)))).xy;
	var d_sw: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (-t.xy + 0.)))).xy;
	var d_ne: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.xy + 0.)))).xy;
	var d_se: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.xz + 0.)))).xy;
	return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
} 

fn gaussian_confinement(uv: vec2<f32>) -> vec2<f32> {
	var texel: vec2<f32> = 1. / uni.iResolution.xy;
	var t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	var d: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.ww + 0.)))).xy;
	var d_n: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.wy + 0.)))).xy;
	var d_e: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.xw + 0.)))).xy;
	var d_s: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.wz + 0.)))).xy;
	var d_w: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (-t.xw + 0.)))).xy;
	var d_nw: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (-t.xz + 0.)))).xy;
	var d_sw: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (-t.xy + 0.)))).xy;
	var d_ne: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.xy + 0.)))).xy;
	var d_se: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.xz + 0.)))).xy;
	return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
} 

fn diff(uv: vec2<f32>) -> vec2<f32> {
	var texel: vec2<f32> = 1. / uni.iResolution.xy;
	var t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	var d: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.ww))).x;
	var d_n: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.wy))).x;
	var d_e: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.xw))).x;
	var d_s: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.wz))).x;
	var d_w: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + -t.xw))).x;
	var d_nw: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + -t.xz))).x;
	var d_sw: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + -t.xy))).x;
	var d_ne: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.xy))).x;
	var d_se: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.xz))).x;
	return vec2<f32>(0.5 * (d_e - d_w) + 0.25 * (d_ne - d_nw + d_se - d_sw), 0.5 * (d_n - d_s) + 0.25 * (d_ne + d_nw - d_se - d_sw));
} 

fn gaussian_velocity(uv: vec2<f32>) -> vec4<f32> {
	var texel: vec2<f32> = 1. / uni.iResolution.xy;
	var t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	var d: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.ww + 0.))));
	var d_n: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.wy + 0.))));
	var d_e: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xw + 0.))));
	var d_s: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.wz + 0.))));
	var d_w: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xw + 0.))));
	var d_nw: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xz + 0.))));
	var d_sw: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xy + 0.))));
	var d_ne: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xy + 0.))));
	var d_se: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xz + 0.))));
	return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
} 

fn vector_laplacian(uv: vec2<f32>) -> vec2<f32> {
	let _K0: f32 = -20. / 6.;
let _K1: f32 = 4. / 6.;
let _K2: f32 = 1. / 6.;
	let texel: vec2<f32> = 1. / uni.iResolution.xy;
	let t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	let d: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.ww + 0.))));
	let d_n: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.wy + 0.))));
	let d_e: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xw + 0.))));
	let d_s: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.wz + 0.))));
	let d_w: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xw + 0.))));
	let d_nw: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xz + 0.))));
	let d_sw: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xy + 0.))));
	let d_ne: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xy + 0.))));
	let d_se: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xz + 0.))));
	return (_K0 * d + _K1 * (d_e + d_w + d_n + d_s) + _K2 * (d_ne + d_nw + d_se + d_sw)).xy;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	let uv: vec2<f32> = fragCoord / uni.iResolution.xy;
	let tx: vec2<f32> = 1. / uni.iResolution.xy;
	var turb: vec2<f32> = vec2<f32>(0.);
	var confine: vec2<f32> = vec2<f32>(0.);
	var div: vec2<f32> = vec2<f32>(0.);
	var delta_v: vec2<f32> = vec2<f32>(0.);
	var offset: vec2<f32> = vec2<f32>(0.);
	var lapl: vec2<f32> = vec2<f32>(0.);
	var vel: vec4<f32> = vec4<f32>(0.);
	var adv: vec4<f32> = vec4<f32>(0.);
	let init: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + +0.)));
	if (RECALCULATE_OFFSET) {

		for (var i: i32 = 0; i < 3; i = i + 1) {
			if (BLUR_TURBULENCE) {
				turb = gaussian_turbulence(uv + tx * offset);
			} else { 

				turb = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (tx * offset + 0.)))).xy;
			}
			if (BLUR_CONFINEMENT) {
				confine = gaussian_confinement(uv + tx * offset);
			} else { 

				confine = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (tx * offset + 0.)))).xy;
			}
			if (BLUR_VELOCITY) {
				vel = gaussian_velocity(uv + tx * offset);
			} else { 

				vel = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (tx * offset + 0.))));
			}
			offset = f32(i + 1.) / f32(3.) * -40. * (-0.05 * vel.xy + 1. * turb - 0.6 * confine + 0. * div);
			div = diff(uv + tx * 1. * offset);
			lapl = vector_laplacian(uv + tx * 1. * offset);
			adv = adv + (textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (tx * offset + 0.)))));
			delta_v = delta_v + (0.02 * lapl + 0. * turb + 0.01 * confine - 0.0001 * vel.xy - 0.1 * div);
		}

		adv = adv / (f32(3.));
		delta_v = delta_v / (f32(3.));
	} else { 

		if (BLUR_TURBULENCE) {
			turb = gaussian_turbulence(uv);
		} else { 

			turb = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + +0.))).xy;
		}
		if (BLUR_CONFINEMENT) {
			confine = gaussian_confinement(uv);
		} else { 

			confine = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + +0.))).xy;
		}
		if (BLUR_VELOCITY) {
			vel = gaussian_velocity(uv);
		} else { 

			vel = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + +0.)));
		}
		offset = -40. * (-0.05 * vel.xy + 1. * turb - 0.6 * confine + 0. * div);
		div = diff(uv + tx * 1. * offset);
		lapl = vector_laplacian(uv + tx * 1. * offset);
		delta_v = delta_v + (0.02 * lapl + 0. * turb + 0.01 * confine - 0.0001 * vel.xy - 0.1 * div);

		for (var i: i32 = 0; i < 3; i = i + 1) {
			adv = adv + (textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (f32(i + 1.) / f32(3.) * tx * offset + 0.)))));
		}

		adv = adv / (f32(3.));
	}
	let pq: vec2<f32> = 2. * (uv * 2. - 1.) * vec2<f32>(1., tx.x / tx.y);
	if (CENTER_PUMP) {
		var pump: vec2<f32> = sin(0.2 * uni.iTime) * 0.001 * pq.xy / (dot(pq, pq) + 0.01);
	} else { 

		var pump: vec2<f32> = vec2<f32>(0.);
		let uvy0: f32 = exp(-50. * pow(pq.y, 2.));
		let uvx0: f32 = exp(-50. * pow(uv.x, 2.));
		pump = pump + (-15. * vec2<f32>(max(0., cos(0.2 * uni.iTime)) * 0.001 * uvx0 * uvy0, 0.));
		let uvy1: f32 = exp(-50. * pow(pq.y, 2.));
		let uvx1: f32 = exp(-50. * pow(1. - uv.x, 2.));
		pump = pump + (15. * vec2<f32>(max(0., cos(0.2 * uni.iTime + 3.1416)) * 0.001 * uvx1 * uvy1, 0.));
		let uvy2: f32 = exp(-50. * pow(pq.x, 2.));
		let uvx2: f32 = exp(-50. * pow(uv.y, 2.));
		pump = pump + (-15. * vec2<f32>(0., max(0., sin(0.2 * uni.iTime)) * 0.001 * uvx2 * uvy2));
		let uvy3: f32 = exp(-50. * pow(pq.x, 2.));
		let uvx3: f32 = exp(-50. * pow(1. - uv.y, 2.));
		pump = pump + (15. * vec2<f32>(0., max(0., sin(0.2 * uni.iTime + 3.1416)) * 0.001 * uvx3 * uvy3));
	}
	fragColor = mix(adv + vec4<f32>(1. * (delta_v + pump), offset), init, 0.);
	if (uni.iMouse.z > 0.) {
		let mouseUV: vec4<f32> = uni.iMouse / uni.iResolution.xyxy;
		let delta: vec2<f32> = normz(mouseUV.zw - mouseUV.xy);
		let md: vec2<f32> = (mouseUV.xy - uv) * vec2<f32>(1., tx.x / tx.y);
		let amp: f32 = exp(max(-12., -dot(md, md) / 0.001));
		var fragColorxy = fragColor.xy;
	fragColorxy = fragColor.xy + (1. * 0.05 * clamp(amp * delta, -1., 1.));
	fragColor.x = fragColorxy.x;
	fragColor.y = fragColorxy.y;
	}
	if (uni.iFrame == 0) { fragColor = 0.000001 * rand4(fragCoord, uni.iResolution.xy, uni.iFrame); }
} 

