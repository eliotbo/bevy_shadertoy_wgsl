var<private>  R: vec2<f32>;
fn A(location: vec2<f32>) -> vec4<f32> {
	return textureLoad(buffer_a, vec2<i32>(location)) * texture_const;
} 

// fn B(location: vec2<f32>)-> vec4<f32> {
// 	return textureLoad(buffer_b, vec2<i32>(location)) * texture_const;
// } 

fn C(location: vec2<f32>) -> vec4<f32> {
	return textureLoad(buffer_c, vec2<i32>(location)) * texture_const;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
     let U = vec2<f32>(f32(location.x), f32(location.y));
// }

// fn mainImage( Q: vec4<f32>,  U: vec2<f32>) -> () {
	R = uni.iResolution.xy;
	let c: vec4<f32> = C(U);
	let n: vec4<f32> = C(U + vec2<f32>(0., 1.));
	let e: vec4<f32> = C(U + vec2<f32>(1., 0.));
	let s: vec4<f32> = C(U + vec2<f32>(0., -1.));
	let w: vec4<f32> = C(U + vec2<f32>(-1., 0.));
	let a: vec4<f32> = A(U);
	let r: f32 = smoothStep(1., 0.5, length(U - a.xy));

	let f: vec4<f32> = 
          r * f32(a.w == 0.) * vec4<f32>(0.8, 0.6, 0.3, 1.) 
        + r * f32(a.w == 1.) * vec4<f32>(0.9, 0.2, 0.4, 1.) 
        + r * f32(a.w == 2.) * vec4<f32>(0.2, 0.7, 0.9, 1.);

	var Q = 2. * f * (0.5 + 0.5 * (n - s + e - w));


    textureStore(buffer_d, location, Q / texture_const);

    // Q = textureLoad(buffer_c, vec2<i32>(location));
    // textureStore(buffer_d, location, Q);
} 



