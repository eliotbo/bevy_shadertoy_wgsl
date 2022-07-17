
var<private> location: vec2<i32>;

fn div(x: i32, y: i32) -> f32 {
	return textureLoad(buffer_c, vec2<i32>(location + vec2<i32>(x, y))).y;
} 

fn pre(x: i32, y: i32) -> f32 {
	return textureLoad(buffer_c, vec2<i32>(location + vec2<i32>(x, y))).x;
} 

fn getPre() -> f32 {
	var p: f32 = 0.;
	p = p + (1. * pre(-10, 0));
	p = p + (10. * pre(-9, -1));
	p = p + (10. * pre(-9, 1));
	p = p + (45. * pre(-8, -2));
	p = p + (100. * pre(-8, 0));
	p = p + (45. * pre(-8, 2));
	p = p + (120. * pre(-7, -3));
	p = p + (450. * pre(-7, -1));
	p = p + (450. * pre(-7, 1));
	p = p + (120. * pre(-7, 3));
	p = p + (210. * pre(-6, -4));
	p = p + (1200. * pre(-6, -2));
	p = p + (2025. * pre(-6, 0));
	p = p + (1200. * pre(-6, 2));
	p = p + (210. * pre(-6, 4));
	p = p + (252. * pre(-5, -5));
	p = p + (2100. * pre(-5, -3));
	p = p + (5400. * pre(-5, -1));
	p = p + (5400. * pre(-5, 1));
	p = p + (2100. * pre(-5, 3));
	p = p + (252. * pre(-5, 5));
	p = p + (210. * pre(-4, -6));
	p = p + (2520. * pre(-4, -4));
	p = p + (9450. * pre(-4, -2));
	p = p + (14400. * pre(-4, 0));
	p = p + (9450. * pre(-4, 2));
	p = p + (2520. * pre(-4, 4));
	p = p + (210. * pre(-4, 6));
	p = p + (120. * pre(-3, -7));
	p = p + (2100. * pre(-3, -5));
	p = p + (11340. * pre(-3, -3));
	p = p + (25200. * pre(-3, -1));
	p = p + (25200. * pre(-3, 1));
	p = p + (11340. * pre(-3, 3));
	p = p + (2100. * pre(-3, 5));
	p = p + (120. * pre(-3, 7));
	p = p + (45. * pre(-2, -8));
	p = p + (1200. * pre(-2, -6));
	p = p + (9450. * pre(-2, -4));
	p = p + (30240. * pre(-2, -2));
	p = p + (44100. * pre(-2, 0));
	p = p + (30240. * pre(-2, 2));
	p = p + (9450. * pre(-2, 4));
	p = p + (1200. * pre(-2, 6));
	p = p + (45. * pre(-2, 8));
	p = p + (10. * pre(-1, -9));
	p = p + (450. * pre(-1, -7));
	p = p + (5400. * pre(-1, -5));
	p = p + (25200. * pre(-1, -3));
	p = p + (52920. * pre(-1, -1));
	p = p + (52920. * pre(-1, 1));
	p = p + (25200. * pre(-1, 3));
	p = p + (5400. * pre(-1, 5));
	p = p + (450. * pre(-1, 7));
	p = p + (10. * pre(-1, 9));
	p = p + (1. * pre(0, -10));
	p = p + (100. * pre(0, -8));
	p = p + (2025. * pre(0, -6));
	p = p + (14400. * pre(0, -4));
	p = p + (44100. * pre(0, -2));
	p = p + (63504. * pre(0, 0));
	p = p + (44100. * pre(0, 2));
	p = p + (14400. * pre(0, 4));
	p = p + (2025. * pre(0, 6));
	p = p + (100. * pre(0, 8));
	p = p + (1. * pre(0, 10));
	p = p + (10. * pre(1, -9));
	p = p + (450. * pre(1, -7));
	p = p + (5400. * pre(1, -5));
	p = p + (25200. * pre(1, -3));
	p = p + (52920. * pre(1, -1));
	p = p + (52920. * pre(1, 1));
	p = p + (25200. * pre(1, 3));
	p = p + (5400. * pre(1, 5));
	p = p + (450. * pre(1, 7));
	p = p + (10. * pre(1, 9));
	p = p + (45. * pre(2, -8));
	p = p + (1200. * pre(2, -6));
	p = p + (9450. * pre(2, -4));
	p = p + (30240. * pre(2, -2));
	p = p + (44100. * pre(2, 0));
	p = p + (30240. * pre(2, 2));
	p = p + (9450. * pre(2, 4));
	p = p + (1200. * pre(2, 6));
	p = p + (45. * pre(2, 8));
	p = p + (120. * pre(3, -7));
	p = p + (2100. * pre(3, -5));
	p = p + (11340. * pre(3, -3));
	p = p + (25200. * pre(3, -1));
	p = p + (25200. * pre(3, 1));
	p = p + (11340. * pre(3, 3));
	p = p + (2100. * pre(3, 5));
	p = p + (120. * pre(3, 7));
	p = p + (210. * pre(4, -6));
	p = p + (2520. * pre(4, -4));
	p = p + (9450. * pre(4, -2));
	p = p + (14400. * pre(4, 0));
	p = p + (9450. * pre(4, 2));
	p = p + (2520. * pre(4, 4));
	p = p + (210. * pre(4, 6));
	p = p + (252. * pre(5, -5));
	p = p + (2100. * pre(5, -3));
	p = p + (5400. * pre(5, -1));
	p = p + (5400. * pre(5, 1));
	p = p + (2100. * pre(5, 3));
	p = p + (252. * pre(5, 5));
	p = p + (210. * pre(6, -4));
	p = p + (1200. * pre(6, -2));
	p = p + (2025. * pre(6, 0));
	p = p + (1200. * pre(6, 2));
	p = p + (210. * pre(6, 4));
	p = p + (120. * pre(7, -3));
	p = p + (450. * pre(7, -1));
	p = p + (450. * pre(7, 1));
	p = p + (120. * pre(7, 3));
	p = p + (45. * pre(8, -2));
	p = p + (100. * pre(8, 0));
	p = p + (45. * pre(8, 2));
	p = p + (10. * pre(9, -1));
	p = p + (10. * pre(9, 1));
	p = p + (1. * pre(10, 0));
	return p / 1048576.;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32> = vec4<f32>(0.0, 0.0, 0.0, 0.0);
	var C = vec2<f32>(f32(location.x), f32(location.y) );

	let p: f32 = getPre() - div(0, 0);
	fragColor = vec4<f32>(p, vec3<f32>(1.));
    textureStore(buffer_d, location, fragColor);
} 

