fn noise(p_in: vec3<f32>) -> f32 {
    var p = p_in;
	let ip: vec3<f32> = floor(p);
	p = p - (ip);
	let s: vec3<f32> = vec3<f32>(7., 157., 113.);
	var h: vec4<f32> = vec4<f32>(0., s.yz, s.y + s.z) + dot(ip, s);
	p = p * p * (3. - 2. * p);
	h = mix(fract(sin(h) * 43758.5), fract(sin(h + s.x) * 43758.5), p.x);
	var hxy = h.xy;
	hxy = mix(h.xz, h.yw, p.y);
	h.x = hxy.x;
	h.y = hxy.y;
	return mix(h.x, h.y, p.z);
} 

fn fbm(p_in: vec3<f32>, octaveNum: i32) -> vec2<f32> {
    var p = p_in;
	var octaveNum_var = octaveNum;
	var acc: vec2<f32> = vec2<f32>(0.);
	let freq: f32 = 1.;
	var amp: f32 = 0.5;
	let shift: vec3<f32> = vec3<f32>(100.);

	for (var i: i32 = 0; i < octaveNum_var; i = i + 1) {
		acc = acc + (vec2<f32>(noise(p), noise(p + vec3<f32>(0., 0., 10.))) * amp);
		p = p * 2. + shift;
		amp = amp * (0.5);
	}

	return acc;
} 

fn sampleMinusGradient(coord: vec2<f32>) -> vec3<f32> {
	var veld: vec3<f32> = sample_texture(buffer_a, (coord / uni.iResolution.xy)).xyz;
	let left: f32 = sample_texture(buffer_d, ((coord + vec2<f32>(-1., 0.)) / uni.iResolution.xy)).x;
	let right: f32 = sample_texture(buffer_d, ((coord + vec2<f32>(1., 0.)) / uni.iResolution.xy)).x;
	let bottom: f32 = sample_texture(buffer_d, ((coord + vec2<f32>(0., -1.)) / uni.iResolution.xy)).x;
	let top: f32 = sample_texture(buffer_d, ((coord + vec2<f32>(0., 1.)) / uni.iResolution.xy)).x;
	let grad: vec2<f32> = vec2<f32>(right - left, top - bottom) * 0.5;
	return vec3<f32>(veld.xy - grad, veld.z);
} 

fn vignette(color: vec3<f32>, q: vec2<f32>, v: f32) -> vec3<f32> {
	var color_var = color;
	color_var = color_var * (mix(1., pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), v), 0.02));
	return color_var;
} 

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	var velocity: vec2<f32> = sampleMinusGradient(fragCoord).xy;
	var veld: vec3<f32> = sampleMinusGradient(fragCoord - dissipation * velocity).xyz;
	var density: f32 = veld.z;
	velocity = veld.xy;
	let uv: vec2<f32> = (2. * fragCoord - uni.iResolution.xy) / uni.iResolution.y;
	let detailNoise: vec2<f32> = fbm(vec3<f32>(uv * 40., uni.iTime * 0.5 + 30.), 7) - 0.5;
	velocity = velocity + (detailNoise * 0.2);
	density = density + (length(detailNoise) * 0.01);
	let injectionNoise: vec2<f32> = fbm(vec3<f32>(uv * 1.5, uni.iTime * 0.1 + 30.), 7) - 0.5;
	velocity = velocity + (injectionNoise * 0.1);
	density = density + (max(length(injectionNoise) * 0.04, 0.));
	let influenceRadius: f32 = ballRadius * 2.;

	for (var i: i32 = 0; i < nbSphere; i = i + 1) {
		let p: vec2<f32> = spherePosition(i, i32(uni.iFrame));
		let dist: f32 = distance(uv, p);
		if (dist < influenceRadius) {
			let op: vec2<f32> = spherePosition(i, i32(uni.iFrame) + 1);
			let ballVelocity: vec2<f32> = p - op;
			density = density - ((influenceRadius - dist) / influenceRadius * 0.15);
			density = max(0., density);
			velocity = velocity - (ballVelocity * 5.);
		}
	}

	density = min(1., density);
	density = density * (0.99);
	veld = vec3<f32>(vec3<f32>(velocity, density));
	veld = vignette(veld, fragCoord / uni.iResolution.xy, 1.);
	fragColor = vec4<f32>(veld, 1.);

    textureStore(buffer_a, location, fragColor);
} 



// fn noise(p_in: vec3<f32>) -> f32 {
//     var p = p_in;
// 	let ip: vec3<f32> = floor(p);
// 	p = p - (ip);
// 	let s: vec3<f32> = vec3<f32>(7., 157., 113.);
// 	var h: vec4<f32> = vec4<f32>(0., s.yz, s.y + s.z) + dot(ip, s);
// 	p = p * p * (3. - 2. * p);
// 	h = mix(fract(sin(h) * 43758.5), fract(sin(h + s.x) * 43758.5), p.x);
// 	var hxy = h.xy;
// 	hxy = mix(h.xz, h.yw, p.y);
// 	h.x = hxy.x;
// 	h.y = hxy.y;
// 	return mix(h.x, h.y, p.z);
// } 

// fn fbm(p_in: vec3<f32>, octaveNum: i32) -> vec2<f32> {
//     var p = p_in;
// 	var octaveNum_var = octaveNum;
// 	var acc: vec2<f32> = vec2<f32>(0.);
// 	let freq: f32 = 1.;
// 	var amp: f32 = 0.5;
// 	let shift: vec3<f32> = vec3<f32>(100.);

// 	for (var i: i32 = 0; i < octaveNum_var; i = i + 1) {
// 		acc = acc + (vec2<f32>(noise(p), noise(p + vec3<f32>(0., 0., 10.))) * amp);
// 		p = p * 2. + shift;
// 		amp = amp * (0.5);
// 	}

// 	return acc;
// } 

// fn sampleMinusGradient(coord: vec2<f32>) -> vec3<f32> {
// 	var veld: vec3<f32> = sample_texture(buffer_a,(coord / uni.iResolution.xy)).xyz;
// 	let left: f32 = sample_texture(buffer_d, ((coord + vec2<f32>(-1., 0.)) / uni.iResolution.xy)).x;
// 	let right: f32 = sample_texture(buffer_d, ((coord + vec2<f32>(1., 0.)) / uni.iResolution.xy)).x;
// 	let bottom: f32 = sample_texture(buffer_d, ((coord + vec2<f32>(0., -1.)) / uni.iResolution.xy)).x;
// 	let top: f32 = sample_texture(buffer_d, ((coord + vec2<f32>(0., 1.)) / uni.iResolution.xy)).x;
// 	let grad: vec2<f32> = vec2<f32>(right - left, top - bottom) * 0.5;
// 	return vec3<f32>(veld.xy - grad, veld.z);
// } 

// fn vignette(color: vec3<f32>, q: vec2<f32>, v: f32) -> vec3<f32> {
// 	var color_var = color;
// 	color_var = color_var * (mix(1., pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), v), 0.02));
// 	return color_var;
// } 

// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
//     let R: vec2<f32> = uni.iResolution.xy;
//     let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
// 	var fragColor: vec4<f32> = vec4<f32>(0.);
// 	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

// 	var velocity: vec2<f32> = sampleMinusGradient(fragCoord).xy;
// 	var veld: vec3<f32> = sampleMinusGradient(fragCoord - dissipation * velocity).xyz;
// 	var density: f32 = veld.z;
// 	velocity = veld.xy;
// 	let uv: vec2<f32> = (2. * fragCoord - uni.iResolution.xy) / uni.iResolution.y;


// 	let detailNoise: vec2<f32> = fbm(vec3<f32>(uv * 40., uni.iTime * 0.5 + 30.), 7) - 0.5;
// 	velocity = velocity + (detailNoise * 0.2);
// 	density = density + (length(detailNoise) * 0.01);

// 	let injectionNoise: vec2<f32> = fbm(vec3<f32>(uv * 1.5, uni.iTime * 0.1 + 30.), 7) - 0.5;
// 	velocity = velocity + (injectionNoise * 0.1);
// 	density = density + (max(length(injectionNoise) * 0.04, 0.));

// 	let influenceRadius: f32 = ballRadius * 2.;

// 	for (var i: i32 = 0; i < nbSphere; i = i + 1) {
// 		let p: vec2<f32> = spherePosition(i, i32(uni.iFrame));
// 		let dist: f32 = distance(uv, p);
// 		if (dist < influenceRadius) {
// 			let op: vec2<f32> = spherePosition(i, i32(uni.iFrame) + 1);
// 			let ballVelocity: vec2<f32> = p - op;
// 			density = density - ((influenceRadius - dist) / influenceRadius * 0.15);
// 			density = max(0., density);
// 			velocity = velocity - (ballVelocity * 5.);
// 		}
// 	}

// 	density = min(1., density);
// 	density = density * (0.99);
// 	veld = vec3<f32>(vec3<f32>(velocity, density));
// 	// veld = vignette(veld, fragCoord / uni.iResolution.xy, 1.);
// 	fragColor = vec4<f32>(veld, 1.);

//     textureStore(buffer_a, location, fragColor);

// } 

