fn t(v: vec2<f32>) -> vec4<f32> {
	return textureLoad(buffer_a, vec2<i32>(v ));
} 

fn toLinear(sRGB: vec4<f32>) -> vec4<f32> {
    let cutoff = vec4<f32>(sRGB < vec4<f32>(0.04045));
    let higher = pow((sRGB + vec4<f32>(0.055)) / vec4<f32>(1.055), vec4<f32>(2.4));
    let lower = sRGB / vec4<f32>(12.92);

    return mix(higher, lower, cutoff);
}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var C: vec4<f32>;
	let U = vec2<f32>( f32(location.x), f32(location.y) );

	var me: vec4<f32> = t(U);
	me.z = me.z - (1.);
	C = 1. - 3. * me.wwww;

	let d: vec3<f32> = vec3<f32>(
        t(U + vec2<f32>(1., 0.)).w - t(U - vec2<f32>(1., 0.)).w, 
        t(U + vec2<f32>(0., 1.)).w - t(U - vec2<f32>(0., 1.)).w, 
        2.
    );

	var Cxyz = C.xyz;
	Cxyz = C.xyz - (
        max(
            vec3<f32>(0.), 
            sin(vec3<f32>(
                100. * length(me.xy), 
                -5. * me.z, 
                368. * d.y
            ) * me.w)
        ));

	C.x = Cxyz.x;
	C.y = Cxyz.y;
	C.z = Cxyz.z;

    let col_debug_info = show_debug_info(location, C.xyz);

    // textureStore(texture, y_inverted_location, toLinear(col_debug_info));

    // textureStore(texture, y_inverted_location, (C));
    textureStore(texture, y_inverted_location, t(U));
}