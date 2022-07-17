let dissipation: f32 = 0.95;
let ballRadius: f32 = 0.06;
let fogHeigth: f32 = 0.24;
let nbSlice: i32 = 24;
let fogSlice: f32 = 0.01;
let nbSphere: i32 = 3;
let shadowDensity: f32 = 25.;
let fogDensity: f32 = 20.;
let lightHeight: f32 = 1.;
let tau: f32 = 6.28318530718;

fn hash12(p: vec2<f32>) -> f32 {
	var p3: vec3<f32> = fract(vec3<f32>(p.xyx) * 0.1031);
	p3 = p3 + (dot(p3, p3.yzx + 33.33));
	return fract((p3.x + p3.y) * p3.z);
} 

fn hash41(p: f32) -> vec4<f32> {
	var p4: vec4<f32> = fract(vec4<f32>(p) * vec4<f32>(0.1031, 0.103, 0.0973, 0.1099));
	p4 = p4 + (dot(p4, p4.wzxy + 33.33));
	return fract((p4.xxyz + p4.yzzw) * p4.zywx);
} 

fn rotate(angle: f32, radius: f32) -> vec2<f32> {
	return vec2<f32>(cos(angle), -sin(angle)) * radius;
} 

fn floorIntersect(ro: vec3<f32>, rd: vec3<f32>, floorHeight: f32, t: ptr<function, f32>) -> bool {
	var ro_var = ro;
	ro_var.y = ro_var.y - (floorHeight);
	if (rd.y < -0.01) {
		(*t) = ro_var.y / -rd.y;
		return true;
	}
	return false;
} 

fn sphIntersect(ro: vec3<f32>, rd: vec3<f32>, ce: vec3<f32>, ra: f32) -> vec2<f32> {
	let oc: vec3<f32> = ro - ce;
	let b: f32 = dot(oc, rd);
	let c: f32 = dot(oc, oc) - ra * ra;
	var h: f32 = b * b - c;
	if (h < 0.) {	return vec2<f32>(-1.);
 }
	h = sqrt(h);
	return vec2<f32>(-b - h, -b + h);
} 

fn boxIntersection(ro: vec3<f32>, rd: vec3<f32>, rad: vec3<f32>, center: vec3<f32>, oN: ptr<function, vec3<f32>>) -> vec2<f32> {
	var ro_var = ro;
	ro_var = ro_var - (center);
	let m: vec3<f32> = 1. / rd;
	let n: vec3<f32> = m * ro_var;
	let k: vec3<f32> = abs(m) * rad;
	let t1: vec3<f32> = -n - k;
	let t2: vec3<f32> = -n + k;
	let tN: f32 = max(max(t1.x, t1.y), t1.z);
	let tF: f32 = min(min(t2.x, t2.y), t2.z);
	if (tN > tF || tF < 0.) {	return vec2<f32>(-1.);
 }
	(*oN) = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
	return vec2<f32>(tN, tF);
} 

fn spherePosition(id: i32, frame: i32) -> vec2<f32> {
	let offset: vec4<f32> = hash41(f32(id)) * tau;
	let fframe: f32 = f32(frame);
	return vec2<f32>(cos(offset.x + fframe * 0.015) + cos(offset.y + fframe * 0.02), cos(offset.z + fframe * 0.017) + cos(offset.w + fframe * 0.022)) * vec2<f32>(1., 0.5) * 0.9;
} 

fn dist2(v: vec3<f32>) -> f32 {
	return dot(v, v);
} 


fn sample_texture(ch: texture_storage_2d<rgba32float, read_write>, U01: vec2<f32>) -> vec4<f32> {
	let U = U01 * uni.iResolution;
	let f = vec2<i32>(floor(U));
	let c = vec2<i32>(ceil(U));
	let fr = fract(U);

	let upleft =    vec2<i32>( f.x,  c.y );
	let upright =   vec2<i32>( c.x , c.y );
	let downleft =  vec2<i32>( f.x,  f.y );
	let downright = vec2<i32>( c.x , f.y );


	let interpolated_2d = (
		 (1. - fr.x) * (1. - fr.y) 	* textureLoad(ch, downleft)
		+ (1. - fr.x) * fr.y 		* textureLoad(ch, upleft)
		+ fr.x * fr.y  				* textureLoad(ch, upright)
		+  fr.x * (1. - fr.y) 		* textureLoad(ch, downright)
	);

	return interpolated_2d;
} 
