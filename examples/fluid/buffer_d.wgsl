@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	var p: vec4<f32> = textureLoad(buffer_d, vec2<i32>(fragCoord));
	if (uni.iMouse.z > 0.) {
		if (p.z > 0.) {		
            fragColor = vec4<f32>(uni.iMouse.xy, p.xy);
		} else { 		
            fragColor = vec4<f32>(uni.iMouse.xy, uni.iMouse.xy);
		}
	} else { 	
        fragColor = vec4<f32>(-uni.iResolution.xy, -uni.iResolution.xy);
	}

    textureStore(buffer_d, location, fragColor);
} 

