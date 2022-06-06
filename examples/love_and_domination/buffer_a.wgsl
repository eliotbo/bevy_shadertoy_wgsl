var<private>  R: vec2<f32>;

fn A(location: vec2<f32>) -> vec4<f32> {
	return textureLoad(buffer_a, vec2<i32>(location)) * texture_const;
} 

// fn B(location: vec2<f32>)-> vec4<f32> {
// 	return textureLoad(buffer_b, vec2<i32>(location));
// } 

fn C(location: vec2<f32>) -> vec4<f32> {
	return textureLoad(buffer_c, vec2<i32>(location)) * texture_const;
} 

fn X(U: vec2<f32>, Q2: vec4<f32>, u: vec2<f32>) -> vec4<f32> {
    var Q = Q2;
	let p: vec4<f32> = A(U + u);
	if (length(p.xy - U) < length(Q.xy - U)) {	
        Q = p;
	}
    return Q;

} 

fn mod2(x: f32, d: f32) -> f32 {
	let y: f32 = (x / d - floor(x / d)) * d;
	return y;

} 



[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));



// fn mainImage( Q: vec4<f32>,  U: vec2<f32>) -> () {

    var U = vec2<f32>(f32(location.x), f32(location.y));
	R = uni.iResolution.xy;

    var Q: vec4<f32> = A(U);
    Q = X(U, Q, vec2<f32>(1., 0.));
    Q = X(U, Q, vec2<f32>(0., 1.));
    Q = X(U, Q, vec2<f32>(0., -1.));
    Q = X(U, Q, vec2<f32>(-1., 0.));
    Q = X(U, Q, vec2<f32>(1., 1.));
    Q = X(U, Q, vec2<f32>(-1., 1.));
    Q = X(U, Q, vec2<f32>(1., -1.));
    Q = X(U, Q, vec2<f32>(-1., -1.));
    let n: vec4<f32> = C(U + vec2<f32>(0., 1.));
    let e: vec4<f32> = C(U + vec2<f32>(1., 0.));
    let s: vec4<f32> = C(U + vec2<f32>(0., -1.));
    let w: vec4<f32> = C(U + vec2<f32>(-1., 0.));
    let dx: vec3<f32> = e.xyz - w.xyz;
    let dy: vec3<f32> = n.xyz - s.xyz;
    var v: vec2<f32> = vec2<f32>(0.);
    if (Q.w == 0.) {	v = vec2<f32>(dx.z - dx.y + 0.3 * dx.x, dy.z - dy.y + 0.3 * dy.x);
    }
    if (Q.w == 1.) {	v = vec2<f32>(dx.x - dx.z + 0.1 * dx.y, dy.x - dy.z + 0.1 * dy.y);
    }
    if (Q.w == 2.) {	v = vec2<f32>(dx.y - dx.x + 0.2 * dx.z, dy.y - dy.x + 0.2 * dy.z);
    }
    if (length(v) > 0.) {	
        let qxy = Q.xy + (normalize(v) * min(1., SPEED * length(v)));
        Q.x = qxy.x ;
        Q.y = qxy.y ;
    }

    #ifdef INIT
		U = floor(U / 8.) * 8. + 5.;
		var Q = vec4<f32>(U, 1., floor( mod2(-U.x / R.x * 5., 3.)));
    #endif
	


	if (uni.iMouse.z > 0. && length(uni.iMouse.xy - Q.xy) < MOUSE_SIZE) {	
        Q = vec4<f32>(-100., -100., 0., 0.);
	}

    textureStore(buffer_a, location, Q / texture_const );
    // textureStore(buffer_a, location, vec4<f32>(0.2, 0.7, 0.9, 1.) / texture_const);
} 

