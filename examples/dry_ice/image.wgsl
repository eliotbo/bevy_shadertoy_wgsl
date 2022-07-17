fn sceneIntersection(
    ro: vec3<f32>, 
    rd: vec3<f32>, 
    inter: ptr<function, vec3<f32>>, 
    normal: ptr<function, vec3<f32>>, 
    color: ptr<function, vec3<f32>>, 
    dist: f32, 
    lightPos: ptr<function, vec3<f32>>
) -> f32 {
	var mint: f32 = dist;
	(*inter) = vec3<f32>(0.);
	(*normal) = vec3<f32>(0.);
	(*color) = vec3<f32>(0.);

	for (var i: i32 = 0; i < nbSphere; i = i + 1) {
		let p2d: vec2<f32> = spherePosition(i, i32(uni.iFrame));
		let pos: vec3<f32> = vec3<f32>(p2d.x, ballRadius, p2d.y);
		var ballColor: vec3<f32> = vec3<f32>(1., 0., 0.);
		if (i == 0) {
			ballColor = vec3<f32>(1.);
			(*lightPos) = pos + vec3<f32>(0., lightHeight, 0.);
		}
		var t: f32 = sphIntersect(ro, rd, pos, ballRadius).x;
		if (t > 0. && t < mint) {
			mint = t;
			(*inter) = ro + mint * rd;
			(*normal) = normalize((*inter) - pos);
			(*color) = ballColor;
		}
	}


		let aspecRatio: f32 = uni.iResolution.x / uni.iResolution.y;
		var boxNormal: vec3<f32> = vec3<f32>(0. );
		let t: f32 = boxIntersection(ro, rd, vec3<f32>(aspecRatio, 0.1, 1.), vec3<f32>(0., -0.1, 0.), &boxNormal).x;

		if (t > 0. && t < mint) {
			mint = t;
			(*inter) = ro + mint * rd;
			(*normal) = boxNormal;
			let tileId: vec2<i32> = vec2<i32>(vec2<f32>((*inter).x, (*inter).z) * 3. + 100.);
			 if ((tileId.x & 1 ^ tileId.y & 1) == 0) {(*color) = vec3<f32>(0.3); } else { (*color) = vec3<f32>(0.15); };
		}

	return mint;
} 

fn sampleFog(pos: vec3<f32>) -> f32 {
	var uv: vec2<f32> = pos.xz;
	uv.x = uv.x * (uni.iResolution.y / uni.iResolution.x);
	uv = uv * 0.5 + 0.5;
	if (max(uv.x, uv.y) > 1. || min(uv.x, uv.y) < 0.) {
		return 0.;
	}
	return sample_texture(buffer_a, uv).z;
} 

fn Render(ro: vec3<f32>, rd: vec3<f32>, dist: f32, fudge: f32) -> vec3<f32> {
	var inter: vec3<f32> = vec3<f32>(0.);
	var normal: vec3<f32> = vec3<f32>(0.);
	var baseColor: vec3<f32> = vec3<f32>(0.);
	var lightPos: vec3<f32> = vec3<f32>(0.);
	let mint: f32 = sceneIntersection(ro, rd, &inter, &normal, &baseColor, dist, &lightPos);
	var color: vec3<f32> = vec3<f32>(0.);
	if (mint < dist) {
		var lightDir: vec3<f32> = normalize(lightPos - inter);
		var lightDist2: f32 = dist2(lightPos - inter);
		var shadowStep: vec3<f32> = fogHeigth / f32(nbSlice) * lightDir / lightDir.y;
		var shadowDist: f32 = 0.;

		for (var i: i32 = 0; i < nbSlice; i = i + 1) {
			var shadowPos: vec3<f32> = inter + shadowStep * f32(i);
			let v: f32 = sampleFog(shadowPos) * fogHeigth;
			shadowDist = shadowDist + (min(max(0., v - shadowPos.y), fogSlice) * length(shadowStep) / fogSlice);
		}

		var shadowFactor: f32 = exp(-shadowDist * shadowDensity * 0.25);
		color = baseColor * (max(0., dot(normal, lightDir) * shadowFactor) + 0.2) / lightDist2;
	} else { 
		color = vec3<f32>(0.);
	}
	var t: f32 = 0.;
	if (floorIntersect(ro, rd, fogHeigth, &t)) {
		var curPos: vec3<f32> = ro + rd * t;
		let fogStep: vec3<f32> = fogHeigth / f32(nbSlice) * rd / abs(rd.y);
		curPos = curPos + (fudge * fogStep);
		let stepLen: f32 = length(fogStep);
		var curDensity: f32 = 0.;
		var transmittance: f32 = 1.;
		var lightEnergy: f32 = 0.;

		for (var i: i32 = 0; i < nbSlice; i = i + 1) {
			if (dot(curPos - ro, rd) > mint) {			break;
 }
			let curHeigth: f32 = sampleFog(curPos) * fogHeigth;
			let curSample: f32 = min(max(0., curHeigth - curPos.y), fogSlice) * stepLen / fogSlice;
			if (curSample > 0.001) {
				let lightDir: vec3<f32> = normalize(lightPos - curPos);
				let shadowStep: vec3<f32> = fogHeigth / f32(nbSlice) * lightDir / lightDir.y;
				let lightDist2: f32 = dist2(lightPos - curPos);
				var shadowPos: vec3<f32> = curPos + shadowStep * fudge;
				var shadowDist: f32 = 0.;

				for (var j: i32 = 0; j < nbSlice; j = j + 1) {
					shadowPos = shadowPos + (shadowStep);
					if (shadowPos.y > fogHeigth) {
						break;
					}
					let curHeight: f32 = sampleFog(shadowPos) * fogHeigth;
					shadowDist = shadowDist + (min(max(0., curHeight - shadowPos.y), fogSlice) * length(shadowStep) / fogSlice);
				}

				let shadowFactor: f32 = exp(-shadowDist * shadowDensity) / lightDist2;
				curDensity = curSample * fogDensity;
				let absorbedlight: f32 = shadowFactor * (1. * curDensity);
				lightEnergy = lightEnergy + (absorbedlight * transmittance);
				transmittance = transmittance * (1. - curDensity);
			}
			curPos = curPos + (fogStep);
		}

		color = mix(color, vec3<f32>(lightEnergy), 1. - transmittance);
	}
	return color;
} 

fn vignette(color: vec3<f32>, q: vec2<f32>, v: f32) -> vec3<f32> {
	var color_var = color;
	color_var = color_var * (0.3 + 0.8 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), v));
	return color_var;
} 

fn setCamera(ro: vec3<f32>, ta: vec3<f32>) -> mat3x3<f32> {
	let cw: vec3<f32> = normalize(ta - ro);
	let up: vec3<f32> = vec3<f32>(0., 1., 0.);
	let cu: vec3<f32> = normalize(cross(cw, up));
	let cv: vec3<f32> = normalize(cross(cu, cw));
	return mat3x3<f32>(cu, cv, cw);
} 

fn radians(in: f32) -> f32 {
    return in * (3.141592653589793 / 180.);
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
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	var tot: vec3<f32> = vec3<f32>(0.);
	var rook: array<vec2<f32>,4>;
	rook[0] = vec2<f32>(1. / 8., 3. / 8.);
	rook[1] = vec2<f32>(3. / 8., -1. / 8.);
	rook[2] = vec2<f32>(-1. / 8., -3. / 8.);
	rook[3] = vec2<f32>(-3. / 8., 1. / 8.);

	for (var n: i32 = 0; n < 4; n  = n + 1) {
		let o: vec2<f32> = rook[n];
		let p: vec2<f32> = (-uni.iResolution.xy + 2. * (fragCoord + o)) / uni.iResolution.y;
		let theta: f32 = radians(360.) * (uni.iMouse.x / uni.iResolution.x - 0.5) - radians(90.);
		let phi: f32 = -radians(30.);
		let ro: vec3<f32> = 2. * vec3<f32>(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta));
		let ta: vec3<f32> = vec3<f32>(0.);
		let ca: mat3x3<f32> = setCamera(ro, ta);
		let rd: vec3<f32> = ca * normalize(vec3<f32>(p, 1.5));
		let col: vec3<f32> = Render(ro, rd, 6., hash12(fragCoord + uni.iTime));
		tot = tot + (col);
	}

	tot = tot / (4.);
	tot = vignette(tot, fragCoord / uni.iResolution.xy, 0.6);
	fragColor = vec4<f32>(sqrt(tot), 1.);

    textureStore(texture, y_inverted_location, toLinear(fragColor));
} 


// fn toLinear(sRGB: vec4<f32>) -> vec4<f32> {
//     let cutoff = vec4<f32>(sRGB < vec4<f32>(0.04045));
//     let higher = pow((sRGB + vec4<f32>(0.055)) / vec4<f32>(1.055), vec4<f32>(2.4));
//     let lower = sRGB / vec4<f32>(12.92);

//     return mix(higher, lower, cutoff);
// }

// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
//     let R: vec2<f32> = uni.iResolution.xy;
//     let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
// 	var fragColor: vec4<f32>;
// 	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

// 	fragColor = vec4<f32>(vec3<f32>(sample_texture(buffer_a, fragCoord / uni.iResolution).z), 1.);
//     textureStore(texture, y_inverted_location, toLinear(fragColor));
// } 

