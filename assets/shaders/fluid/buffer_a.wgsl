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





// var<private> R: vec2<f32>;

fn lnln(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>) -> f32 {
	return length(p - a - (b - a) * clamp(dot(p - a, b - a) / dot(b - a, b - a), 0., 1.));
} 

fn T(U: vec2<f32>) -> vec4<f32> {
	let f = vec2<i32>(floor(U));
	let c = vec2<i32>(ceil(U));
	let fr = fract(U);

	let upleft =    vec2<i32>( f.x,  c.y );
	let upright =   vec2<i32>( c.x , c.y );
	let downleft =  vec2<i32>( f.x,  f.y );
	let downright = vec2<i32>( c.x , f.y );


	let interpolated_2d = (
		 (1. - fr.x) * (1. - fr.y) 	* textureLoad(buffer_a, downleft)
		+ (1. - fr.x) * fr.y 		* textureLoad(buffer_a, upleft)
		+ fr.x * fr.y  				* textureLoad(buffer_a, upright)
		+  fr.x * (1. - fr.y) 		* textureLoad(buffer_a, downright)
	);

	return interpolated_2d;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var Q: vec4<f32>;
	var U = vec2<f32>(f32(location.x), f32(location.y) );

	// let R = uni.iResolution.xy;
	let O: vec2<f32> = U;
	var A: vec2<f32> = U + vec2<f32>(1., 0.);
	var B: vec2<f32> = U + vec2<f32>(0., 1.);
	var C: vec2<f32> = U + vec2<f32>(-1., 0.);
	var D: vec2<f32> = U + vec2<f32>(0., -1.);
	var u: vec4<f32> = T(U);
	var a: vec4<f32> = T(A);
	var b: vec4<f32> = T(B);
	var c: vec4<f32> = T(C);
	var d: vec4<f32> = T(D);
	var p: vec4<f32> = vec4<f32>(0.);
	var g: vec2<f32> = vec2<f32>(0.);

	for (var i: i32 = 0; i < 2; i = i + 1) {
		U = U - (u.xy);
		A = A - (a.xy);
		B = B - (b.xy);
		C = C - (c.xy);
		D = D - (d.xy);

		p = p + (vec4<f32>(length(U - A), length(U - B), length(U - C), length(U - D)) - 1.);

		g = g + (vec2<f32>(a.z - c.z, b.z - d.z));
		u = T(U);
		a = T(A);
		b = T(B);
		c = T(C);
		d = T(D);
	}

	Q = u;
	let N: vec4<f32> = 0.25 * (a + b + c + d);
	Q = mix(Q, N, vec4<f32>(0., 0., 1., 0.));
	var Qxy = Q.xy;
	Qxy = Q.xy - (g / 10. / f32(2.));
	Q.x = Qxy.x;
	Q.y = Qxy.y;
	Q.z = Q.z + ((p.x + p.y + p.z + p.w) / 10.);
	Q.z = Q.z * (0.95);

	let mouse: vec4<f32> = textureLoad(buffer_d, vec2<i32>(vec2<f32>(0.5) * R));
	let q: f32 = lnln(U, mouse.xy, mouse.zw);
	let m: vec2<f32> = mouse.xy - mouse.zw;
	let l: f32 = length(m);

	if (mouse.z > 0. && l > 0.) {
		var Qxyw = Q.xyw;
        Qxyw = mix(Q.xyw, vec3<f32>(-normalize(m) * min(l, 20.) / 25., 1.), max(0., 5. - q) / 25.);
        Q.x = Qxyw.x;
        Q.y = Qxyw.y;
        Q.w = Qxyw.z;
	}
	// ifuni.iFrame < 1) { 
        
    #ifdef INIT
        Q = vec4<f32>(0.); 
    #endif
        
        
	if (uni.iFrame < 140. && length(U - 0.5 * R) < 20.) {
        var Qxyw = Q.xyw;
        Qxyw = vec3<f32>(0., 0.1, 1.);
        Q.x = Qxyw.x;
        Q.y = Qxyw.y;
        Q.w = Qxyw.z; 
    }
	if (U.x < 1. || U.y < 1. || R.x - U.x < 1. || R.y - U.y < 1.) { 
        var Qxyw = Q.xyw;
        Qxyw = Q.xyw * (0.);
        Q.x = Qxyw.x;
        Q.y = Qxyw.y;
        Q.w = Qxyw.z; 
    }

    textureStore(buffer_a, location, Q);
} 

