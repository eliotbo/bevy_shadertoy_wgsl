// displays a gray screen by setting the color in buffer_a.wglsl and loading buffer_a
// here

// TODO: 
//
// 1. ar<private> light: vec3<f32>; for global variables
//
// 2. p.xy = ...
// pattern -> 
//  var pxy = p.xy;
//  pxy = pxy * matrix;
//  p.x = pxy.x;
//  p.y = pxy.y ;

let pi = 3.1415926;
type v2 = vec2<f32>;

var<private> light: vec3<f32>;

fn ln(p2: vec3<f32>, a: vec3<f32>, b: vec3<f32>, R: f32) -> f32 {
	var r: f32 = dot(p2 - a, b - a) / dot(b - a, b - a);
	r = clamp(r, 0., 1.);
    var p = p2;
	p.x = p.x + (0.2 * sqrt(R) * smoothStep(1., 0., abs(r * 2. - 1.)) * cos(pi * (2. * uni.iTime)));
	return length(p - a - (b - a) * r) - R * (1.5 - 0.4 * r);

} 

fn ro(a: f32) -> mat2x2<f32> {
	let s: f32 = sin(a);
	let c: f32 = cos(a);
	return mat2x2<f32>(c, -s, s, c);

} 

fn map(p2: vec3<f32>) -> f32 {
    var p = p2;
	var l: f32 = length(p - light) - 0.01;
	l = min(l, abs(p.y + 0.4) - 0.01);
	l = min(l, abs(p.z - 0.4) - 0.01);
	l = min(l, abs(p.x - 0.7) - 0.01);
	p.y = p.y + (0.4);
	p.z = p.z + (0.1);
    var pzx = p.zx;
    pzx = pzx * ro(0.1 * uni.iTime);

	p.z = pzx.x;
    p.x = pzx.y;

	var rl: vec2<f32> = vec2<f32>(0.02, 0.25 + 0.01 * sin(pi * 4. * uni.iTime));
	for (var i: i32 = 1; i < 11; i = i + 1) {
		l = min(l, ln(p, vec3<f32>(0.), vec3<f32>(0., rl.y, 0.), rl.x));
		p.y = p.y - (rl.y);

        var pxy = p.xy;
        pxy = pxy * (ro(0.2 * sin(3.1 * uni.iTime + f32(i)) + sin(0.222 * uni.iTime) * (-0.1 * sin(0.4 * pi * uni.iTime) + sin(0.543 * uni.iTime) / max(f32(i), 2.))));
		p.x = pxy.x;
        p.y = pxy.y ;
		p.x = abs(p.x);

        var pxy = p.xy;
        pxy = pxy *(ro(0.6 + 0.4 * sin(uni.iTime) * sin(0.871 * uni.iTime) + 0.05 * f32(i) * sin(2. * uni.iTime)));
		p.x = pxy.x ; 
		p.y = pxy.y ;
		
        var pzx = p.zx;
        pzx = pzx * (ro(0.5 * pi + 0.2 * sin(0.5278 * uni.iTime) + 0.8 * f32(i) * (sin(0.1 * uni.iTime) * (sin(0.1 * pi * uni.iTime) + sin(0.333 * uni.iTime) + 0.2 * sin(1.292 * uni.iTime)))));
        p.z = pzx.x;  
		p.x = pzx.y; 
		
        rl = rl * (0.7 + 0.015 * f32(i) * (sin(uni.iTime) + 0.1 * sin(4. * pi * uni.iTime)));
		l = min(l, length(p) - 0.15 * sqrt(rl.x));
	
	}	return l;

} 

fn march(p2: vec3<f32>, d: vec3<f32>) -> vec3<f32> {
	let o: f32 = 1000.;
    var p = p2;
	for (var i: i32 = 0; i < 24; i = i + 1) {
		let l: f32 = map(p);
		p = p + (l * d);
		if (l < 0.001) {		break;
		}
	
	}	return p;

} 

fn norm(p: vec3<f32>) -> vec3<f32> {
	let e: vec2<f32> = vec2<f32>(0.001, 0.);
	return normalize(vec3<f32>(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy), map(p + e.yyx) - map(p - e.yyx)));

} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
	let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));

	light = vec3<f32>(0.2 * sin(uni.iTime), 0.5, -0.5);
	if (uni.iMouse.z > 0.) {	
        light = vec3<f32>(vec2<f32>(-0.5, 0.5) * 0. + 0.7 * (uni.iMouse.xy - 0.5 * R) / R.y, -0.3);
	}
	
    var U = (vec2<f32>(location) - 0.5 * R) / R.y;
    // U = vec2<f32>(U.x, -U.y);

	var p: vec3<f32> = vec3<f32>(0., 0., -1.);
	var d: vec3<f32> = normalize(vec3<f32>(U, 1.));
	p = march(p, d);
	let n: vec3<f32> = norm(p);
	var C = 0.6 + 0.4 * sin(1.1 * vec4<f32>(1., 2., 3., 4.) * dot(d, n));
	let D: vec3<f32> = light - p;
	d = normalize(D);
	let lp: vec3<f32> = march(p + d * 0.01, d);
	C = C * (2.5 * dot(d, n) * (0.3 + 0.7 * length(lp - p) / length(light - p)));
	C = atan(C) / pi * 2.;

    textureStore(texture, y_inverted_location, C);

} 

