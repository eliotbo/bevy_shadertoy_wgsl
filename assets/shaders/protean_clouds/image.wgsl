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



// [[group(0), binding(1)]]
// var buffer_a: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(2)]]
// var buffer_b: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(3)]]
// var buffer_c: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(4)]]
// var buffer_d: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(5)]]
var texture: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(6)]]
// var font_texture: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(6)]]
var font_texture: texture_2d<f32>;

[[group(0), binding(7)]]
var font_texture_sampler: sampler;

[[group(0), binding(8)]]
var rgba_noise_256_texture: texture_2d<f32>;

[[group(0), binding(9)]]
var rgba_noise_256_texture_sampler: sampler;



// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
//     let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

//     let color = vec4<f32>(f32(0));
//     textureStore(texture, location, color);
// }





// https://www.shadertoy.com/view/3l23Rh
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License


fn rot(a: f32) -> mat2x2<f32> {
	let c: f32 = cos(a);
	let s: f32 = sin(a);
	return mat2x2<f32>(vec2<f32>(c, s), vec2<f32>(-s, c));
} 

let m3: mat3x3<f32> = mat3x3<f32>(
    vec3<f32>(0.64342, 1.08146, -1.38607), 
    vec3<f32>(-1.696, 0.6302, -0.2957), 
    vec3<f32>(0.2926, 1.3432, 1.1838)
);

fn mag2(p: vec2<f32>) -> f32 {
	return dot(p, p);
} 

fn linstep(mn: f32, mx: f32, x: f32) -> f32 {
	return clamp((x - mn) / (mx - mn), 0., 1.);
} 

var<private>  prm1: f32 = 0.;
var<private> bsMo: vec2<f32> = vec2<f32>(0., 0.);
fn disp(t: f32) -> vec2<f32> {
	return vec2<f32>(sin(t * 0.22) * 1., cos(t * 0.175) * 1.) * 2.;
} 

fn map(p_in: vec3<f32>) -> vec2<f32> {
    var p = p_in;
	var p2: vec3<f32> = p;
	var p2xy = p2.xy;
	p2xy = p2.xy - (disp(p.z).xy);
	p2.x = p2xy.x;
	p2.y = p2xy.y;
	var pxy = p.xy;
	pxy = p.xy * (rot(sin(p.z + uni.iTime) * (0.1 + prm1 * 0.05) + uni.iTime * 0.09));
	p.x = pxy.x;
	p.y = pxy.y;
	let cl: f32 = mag2(p2.xy);
	var d: f32 = 0.;
	p = p * (0.61);
	var z: f32 = 1.;
	var trk: f32 = 1.;
	var dspAmp: f32 = 0.1 + prm1 * 0.2;

	for (var i: i32 = 0; i < 5; i = i + 1) {
		p = p + (sin(p.zxy * 0.75 * trk + uni.iTime * trk * 0.8) * dspAmp);
		d = d - (abs(dot(cos(p), sin(p.yzx)) * z));
		z = z * (0.57);
		trk = trk * (1.4);
		p = p * m3;
	}

	d = abs(d + prm1 * 3.) + prm1 * 0.3 - 2.5 + bsMo.y;
	return vec2<f32>(d + cl * 0.2 + 0.25, cl);
} 

fn render(ro: vec3<f32>, rd: vec3<f32>, time: f32) -> vec4<f32> {
	var rez: vec4<f32> = vec4<f32>(0.);
	let ldst: f32 = 8.;
	let lpos: vec3<f32> = vec3<f32>(disp(time + ldst) * 0.5, time + ldst);
	var t: f32 = 1.5;
	var fogT: f32 = 0.;

	for (var i: i32 = 0; i < 130; i = i + 1) {
		if (rez.a > 0.99) {		break;
 }
		let pos: vec3<f32> = ro + t * rd;
		let mpv: vec2<f32> = map(pos);
		let den: f32 = clamp(mpv.x - 0.3, 0., 1.) * 1.12;
		let dn: f32 = clamp(mpv.x + 2., 0., 3.);
		var col: vec4<f32> = vec4<f32>(0.);
		if (mpv.x > 0.6) {
			col = vec4<f32>(sin(vec3<f32>(5., 0.4, 0.2) + mpv.y * 0.1 + sin(pos.z * 0.4) * 0.5 + 1.8) * 0.5 + 0.5, 0.08);
			col = col * (den * den * den);
			var colrgb = col.rgb;
	colrgb = col.rgb * (linstep(4., -2.5, mpv.x) * 2.3);
	col.r = colrgb.r;
	col.g = colrgb.g;
	col.b = colrgb.b;
			var dif: f32 = clamp((den - map(pos + 0.8).x) / 9., 0.001, 1.);
			dif = dif + (clamp((den - map(pos + 0.35).x) / 2.5, 0.001, 1.));
			var colxyz = col.xyz;
	colxyz = col.xyz * (den * (vec3<f32>(0.005, 0.045, 0.075) + 1.5 * vec3<f32>(0.033, 0.07, 0.03) * dif));
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;
		}
		let fogC: f32 = exp(t * 0.2 - 2.2);
		var colrgba = col.rgba;
	colrgba = col.rgba + (vec4<f32>(0.06, 0.11, 0.11, 0.1) * clamp(fogC - fogT, 0., 1.));
	col.r = colrgba.r;
	col.g = colrgba.g;
	col.b = colrgba.b;
	col.a = colrgba.a;
		fogT = fogC;
		rez = rez + col * (1. - rez.a);
		t = t + (clamp(0.5 - dn * dn * 0.05, 0.09, 0.3));
	}

	return clamp(rez, vec4<f32>(0.), vec4<f32>(1.));
} 

fn getsat(c: vec3<f32>) -> f32 {
	let mi: f32 = min(min(c.x, c.y), c.z);
	let ma: f32 = max(max(c.x, c.y), c.z);
	return (ma - mi) / (ma + 0.0000001);
} 

fn iLerp(a: vec3<f32>, b: vec3<f32>, x: f32) -> vec3<f32> {
	var ic: vec3<f32> = mix(a, b, x) + vec3<f32>(0.000001, 0., 0.);
	let sd: f32 = abs(getsat(ic) - mix(getsat(a), getsat(b), x));
	let dir: vec3<f32> = normalize(vec3<f32>(2. * ic.x - ic.y - ic.z, 2. * ic.y - ic.x - ic.z, 2. * ic.z - ic.y - ic.x));
	let lgt: f32 = dot(vec3<f32>(1.), ic);
	let ff: f32 = dot(dir, normalize(ic));
	ic = ic + (1.5 * dir * sd * ff * lgt);
	return clamp(ic, vec3<f32>(0.), vec3<f32>(1.));
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	let q: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
	let p: vec2<f32> = (fragCoord - 0.5 * uni.iResolution.xy) / uni.iResolution.y;
	bsMo = (uni.iMouse.xy - 0.5 * uni.iResolution.xy) / uni.iResolution.y;
	let time: f32 = uni.iTime * 3.;
	var ro: vec3<f32> = vec3<f32>(0., 0., time);
	ro = ro + (vec3<f32>(sin(uni.iTime) * 0.5, sin(uni.iTime * 1.) * 0., 0.));
	let dspAmp: f32 = 0.85;
	var roxy = ro.xy;
	roxy = ro.xy + (disp(ro.z) * dspAmp);
	ro.x = roxy.x;
	ro.y = roxy.y;
	let tgtDst: f32 = 3.5;
	let target: vec3<f32> = normalize(ro - vec3<f32>(disp(time + tgtDst) * dspAmp, time + tgtDst));
	ro.x = ro.x - (bsMo.x * 2.);
	var rightdir: vec3<f32> = normalize(cross(target, vec3<f32>(0., 1., 0.)));
	let updir: vec3<f32> = normalize(cross(rightdir, target));
	rightdir = normalize(cross(updir, target));
	var rd: vec3<f32> = normalize((p.x * rightdir + p.y * updir) * 1. - target);
	var rdxy = rd.xy;
	rdxy = rd.xy * (rot(-disp(time + 3.5).x * 0.2 + bsMo.x));
	rd.x = rdxy.x;
	rd.y = rdxy.y;
	prm1 = smoothStep(-0.4, 0.4, sin(uni.iTime * 0.3));
	let scn: vec4<f32> = render(ro, rd, time);
	var col: vec3<f32> = scn.rgb;
	col = iLerp(col.bgr, col.rgb, clamp(1. - prm1, 0.05, 1.));
	col = pow(col, vec3<f32>(0.55, 0.65, 0.6)) * vec3<f32>(1., 0.97, 0.9);
	col = col * (pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), 0.12) * 0.7 + 0.3);
	fragColor = vec4<f32>(col, 1.);
    textureStore(texture, location, fragColor);
} 

