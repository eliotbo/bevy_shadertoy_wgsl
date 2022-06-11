// displays a gray screen by setting the color in buffer_a.wglsl and loading buffer_a
// here



// fn hsv2rgb( c: vec3<f32>) -> vec3<f32> {

// 	var rgb: vec3<f32> = clamp(abs(mod(c.x * 6. + vec3<f32>(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
// 	rgb = rgb * rgb * (3. - 2. * rgb);
// 	return c.z * mix(vec3<f32>(1.), rgb, c.y);

// } 

fn hsv2rgb( c: vec3<f32>) -> vec3<f32> {
    var fractional: vec3<f32> = vec3<f32>( 0.0);
    let m = modf(c.x * 6. + vec3<f32>(0., 4., 2.) / 6., &fractional);

    // let v = vec3<f32>(0., 4., 2.);
    // let fractional: vec3<f32> = vec3<f32>(vec3<i32>( (c.x * 6. +  v) / 6.0)) ;
        
    // let whatever = modf(uv + 1.0, &tempo);
    // var temp2 = 0.;
    // let frac = modf(tempo / 2.0, &temp2);

    let af: vec3<f32>  = abs(fractional - 3.) - 1.;
	var rgb: vec3<f32> = clamp(af, vec3<f32>(0.), vec3<f32>(1.));

	rgb = rgb * rgb * (3. - 2. * rgb);
	return c.z * mix(vec3<f32>(1.), rgb, c.y);
} 



let radius = 1.0;

let zoom = 0.3;



[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R = uni.iResolution.xy;
    // let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let pos = location;

//     var O: vec4<f32> =  textureLoad(buffer_a, location);
//     textureStore(texture, location, O);
// }

// fn mainImage( col: vec4<f32>,  pos: vec2<f32>) -> () {




	var rho: f32 = 0.001;
	var vel: vec2<f32> = vec2<f32>(0., 0.);
	for (var i: i32 = -2; i <= 2; i = i + 1) {
		for (var j: i32 = -2; j <= 2; j = j + 1) {
			let tpos: vec2<i32> = pos + vec2<i32>(i, j);

			// let data: vec4<f32> = texelFetch(buffer_b, ivec2(mod(tpos,R)), 0)
            let data: vec4<f32> = textureLoad(buffer_b, (tpos % vec2<i32>( R)));

			var X0: vec2<f32> = unpack(u32(data.x)) + vec2<f32>(tpos);
			var V0: vec2<f32> = unpack(u32(data.y));
			let M0: f32 = data.z;
			let dx: vec2<f32> = X0 - vec2<f32>(pos);

			let K: f32 = GS ((dx / radius)) / (radius * radius);

			rho = rho + (M0 * K);
			vel = vel + (M0 * K * V0);
		
		}	
	}	vel = vel / (rho);

	let vc: vec3<f32> = hsv2rgb(
        vec3<f32>(
            6. * atan2(vel.x, vel.y) / (2. * PI), 
            1.,
            rho * length(vel.xy)
        )
    );

	let col: vec3<f32> = cos(0.9 * vec3<f32>(3., 2., 1.) * rho) + 0. * vc;
    let U = vec4<f32>(col, 1.);

    textureStore(texture, y_inverted_location, U);

} 

