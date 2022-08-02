// displays a gray screen by setting the color in buffer_a.wglsl and loading buffer_a
// here

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

fn toLinear(sRGB: vec4<f32>) -> vec4<f32> {
    let cutoff = vec4<f32>(sRGB < vec4<f32>(0.04045));
    let higher = pow((sRGB + vec4<f32>(0.055)) / vec4<f32>(1.055), vec4<f32>(2.4));
    let lower = sRGB / vec4<f32>(12.92);

    return mix(higher, lower, cutoff);
}


@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	var uv: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
	// let dither: vec3<f32> = textureSample(blue_noise_texture, 
    //     blue_noise_texture_sampler, fragCoord.xy / 1024.).rgb;
    // let dither: vec3<f32> = textureSample(rgba_noise_256_texture, 
    //     rgba_noise_256_texture_sampler, fragCoord.xy / 256.).rgb;

    let dither: vec3<f32> =  textureSampleGrad(blue_noise_texture,
                     blue_noise_texture_sampler,
                      fragCoord.xy / 1024.,
                      vec2<f32>(0.),
                      vec2<f32>(0.)).rbg;

	let data: vec4<f32> = sample_texture(buffer_a, uv);
	let gray: f32 = data.x;
	let range: f32 = 3.;
	let unit: vec3<f32> = vec3<f32>(range / uni.iResolution.xy, 0.);
	let normal: vec3<f32> = normalize(vec3<f32>(sample_texture(buffer_a, uv + unit.xz).r 
        - sample_texture(buffer_a, uv - unit.xz).r, 
        sample_texture(buffer_a, uv - unit.zy).r 
        - sample_texture(buffer_a, uv + unit.zy).r, gray * gray * gray));

	var color: vec3<f32> = vec3<f32>(0.3) * (1. - abs(dot(normal, vec3<f32>(0., 0., 1.))));
	let dir: vec3<f32> = normalize(vec3<f32>(0., 1., 2.));
	let specular: f32 = pow(dot(normal, dir) * 0.5 + 0.5, 20.);
	color = color + (vec3<f32>(0.5) * smoothstep(0.2, 1., specular));
	let tint: vec3<f32> = 0.5 + 0.5 * cos(vec3<f32>(1., 2., 3.) * 1. + dot(normal, dir) * 4. - uv.y * 3. - 3.);
	color = color + (tint * smoothstep(0.15, 0., gray));
	color = color - (dither.x * 0.1);
	var background: vec3<f32> = vec3<f32>(1.);
	background = background * (smoothstep(1.5, -0.5, length(uv - 0.5)));
	color = mix(background, clamp(color, vec3<f32>(0.), vec3<f32>(1.)), smoothstep(0.01, 0.1, gray));
	if (uni.iMouse.z > 0.5 && uni.iMouse.x / uni.iResolution.x < 0.1) {
		if (uv.x < 0.33) {		color = vec3<f32>(gray);
		} else { 		if (uv.x < 0.66) {		color = normal * 0.5 + 0.5;
		} else { 		color = vec3<f32>(tint);
		}
		}
	}
	fragColor = vec4<f32>(color, 1.);
    textureStore(texture, y_inverted_location, toLinear(fragColor));
} 




