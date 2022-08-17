struct CommonUniform {
    iResolution: vec2<f32>,
    changed_window_size: f32,
    padding0: f32,
    
    iTime: f32,
    iTimeDelta: f32,
    iFrame: f32,
    iSampleRate: f32,
    
    iMouse: vec4<f32>,
    

    iChannelTime: vec4<f32>,
    iChannelResolution: vec4<f32>,
    iDate: vec4<f32>,
};


@group(0) @binding(0)
var<uniform> uni: CommonUniform;

@group(0) @binding(1)
var buffer_a: texture_storage_2d<rgba32float, read_write>;

@group(0) @binding(2)
var buffer_b: texture_storage_2d<rgba32float, read_write>;

@group(0) @binding(3)
var buffer_c: texture_storage_2d<rgba32float, read_write>;

@group(0) @binding(4)
var buffer_d: texture_storage_2d<rgba32float, read_write>;



@group(0) @binding(5)
var texture: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(6)]]
// var font_texture: texture_storage_2d<rgba32float, read_write>;

@group(0) @binding(6)
var font_texture: texture_2d<f32>;

@group(0) @binding(7)
var font_texture_sampler: sampler;

@group(0) @binding(8)
var rgba_noise_256_texture: texture_2d<f32>;

@group(0) @binding(9)
var rgba_noise_256_texture_sampler: sampler;

@group(0) @binding(10)
var blue_noise_texture: texture_2d<f32>;

@group(0) @binding(11)
var blue_noise_texture_sampler: sampler;




let dissipation: f32 = 0.95;
let ballRadius: f32 = 0.06;
let fogHeigth: f32 = 0.24;
let nbSlice: i32 = 24;
let fogSlice: f32 = 0.01;
let nbSphere: i32 = 3;
let shadowDensity: f32 = 25.;
let fogDensity: f32 = 20.;
let lightHeight: f32 = 1.;
let tau: f32 = 6.28318530718;

fn hash12(p: vec2<f32>) -> f32 {
	var p3: vec3<f32> = fract(vec3<f32>(p.xyx) * 0.1031);
	p3 = p3 + (dot(p3, p3.yzx + 33.33));
	return fract((p3.x + p3.y) * p3.z);
} 

fn hash41(p: f32) -> vec4<f32> {
	var p4: vec4<f32> = fract(vec4<f32>(p) * vec4<f32>(0.1031, 0.103, 0.0973, 0.1099));
	p4 = p4 + (dot(p4, p4.wzxy + 33.33));
	return fract((p4.xxyz + p4.yzzw) * p4.zywx);
} 

fn rotate(angle: f32, radius: f32) -> vec2<f32> {
	return vec2<f32>(cos(angle), -sin(angle)) * radius;
} 

fn floorIntersect(ro: vec3<f32>, rd: vec3<f32>, floorHeight: f32, t: ptr<function, f32>) -> bool {
	var ro_var = ro;
	ro_var.y = ro_var.y - (floorHeight);
	if (rd.y < -0.01) {
		(*t) = ro_var.y / -rd.y;
		return true;
	}
	return false;
} 

fn sphIntersect(ro: vec3<f32>, rd: vec3<f32>, ce: vec3<f32>, ra: f32) -> vec2<f32> {
	let oc: vec3<f32> = ro - ce;
	let b: f32 = dot(oc, rd);
	let c: f32 = dot(oc, oc) - ra * ra;
	var h: f32 = b * b - c;
	if (h < 0.) {	return vec2<f32>(-1.);
 }
	h = sqrt(h);
	return vec2<f32>(-b - h, -b + h);
} 

fn boxIntersection(ro: vec3<f32>, rd: vec3<f32>, rad: vec3<f32>, center: vec3<f32>, oN: ptr<function, vec3<f32>>) -> vec2<f32> {
	var ro_var = ro;
	ro_var = ro_var - (center);
	let m: vec3<f32> = 1. / rd;
	let n: vec3<f32> = m * ro_var;
	let k: vec3<f32> = abs(m) * rad;
	let t1: vec3<f32> = -n - k;
	let t2: vec3<f32> = -n + k;
	let tN: f32 = max(max(t1.x, t1.y), t1.z);
	let tF: f32 = min(min(t2.x, t2.y), t2.z);
	if (tN > tF || tF < 0.) {	return vec2<f32>(-1.);
 }
	(*oN) = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
	return vec2<f32>(tN, tF);
} 

fn spherePosition(id: i32, frame: i32) -> vec2<f32> {
	let offset: vec4<f32> = hash41(f32(id)) * tau;
	let fframe: f32 = f32(frame);
	return vec2<f32>(cos(offset.x + fframe * 0.015) + cos(offset.y + fframe * 0.02), cos(offset.z + fframe * 0.017) + cos(offset.w + fframe * 0.022)) * vec2<f32>(1., 0.5) * 0.9;
} 

fn dist2(v: vec3<f32>) -> f32 {
	return dot(v, v);
} 


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


// https://www.shadertoy.com/view/WlVyRV
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

fn sceneIntersection(ro: vec3<f32>, rd: vec3<f32>, inter: ptr<function, vec3<f32>>, normal: ptr<function, vec3<f32>>, color: ptr<function, vec3<f32>>, dist: f32, lightPos: ptr<function, vec3<f32>>) -> f32 {
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
		var boxNormal: vec3<f32>;
		let t: f32 = boxIntersection(ro, rd, vec3<f32>(aspecRatio, 0.1, 1.), vec3<f32>(0., -0.1, 0.), &boxNormal).x;
		if (t > 0. && t < mint) {
			mint = t;
			(*inter) = ro + mint * rd;
			(*normal) = boxNormal;
			let tileId: vec2<i32> = vec2<i32>(vec2<f32>((*inter).x, (*inter).z) * 3. + 100.);
			 if ((tileId.x & 1 ^ tileId.y & 1) == 0) { (*color) =vec3<f32>(0.3); } else { (*color) =vec3<f32>(0.15); };
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
	var inter: vec3<f32>;
	var normal: vec3<f32>;
	var baseColor: vec3<f32>;
	var lightPos: vec3<f32>;
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
	var t: f32;
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

fn radians (degrees: f32) -> f32 {
    return degrees * ( 3.1416 / 180.);
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

	var tot: vec3<f32> = vec3<f32>(0.);
	let p: vec2<f32> = (-uni.iResolution.xy + 2. * fragCoord) / uni.iResolution.y;
	let theta: f32 = radians(360.) * (uni.iMouse.x / uni.iResolution.x - 0.5) - radians(90.);
	let phi: f32 = -radians(30.);
	let ro: vec3<f32> = 2. * vec3<f32>(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta));
	let ta: vec3<f32> = vec3<f32>(0.);
	let ca: mat3x3<f32> = setCamera(ro, ta);
	let rd: vec3<f32> = ca * normalize(vec3<f32>(p, 1.5));
	let col: vec3<f32> = Render(ro, rd, 6., hash12(fragCoord + uni.iTime));
	tot = tot + (col);
	tot = vignette(tot, fragCoord / uni.iResolution.xy, 0.6);
	fragColor = vec4<f32>(sqrt(tot), 1.);

    textureStore(texture, y_inverted_location, toLinear(fragColor));
} 




// fn sceneIntersection(
//     ro: vec3<f32>, 
//     rd: vec3<f32>, 
//     inter: ptr<function, vec3<f32>>, 
//     normal: ptr<function, vec3<f32>>, 
//     color: ptr<function, vec3<f32>>, 
//     dist: f32, 
//     lightPos: ptr<function, vec3<f32>>
// ) -> f32 {
// 	var mint: f32 = dist;
// 	(*inter) = vec3<f32>(0.);
// 	(*normal) = vec3<f32>(0.);
// 	(*color) = vec3<f32>(0.);

// 	for (var i: i32 = 0; i < nbSphere; i = i + 1) {
// 		let p2d: vec2<f32> = spherePosition(i, i32(uni.iFrame));
// 		let pos: vec3<f32> = vec3<f32>(p2d.x, ballRadius, p2d.y);
// 		var ballColor: vec3<f32> = vec3<f32>(1., 0., 0.);
// 		if (i == 0) {
// 			ballColor = vec3<f32>(1.);
// 			(*lightPos) = pos + vec3<f32>(0., lightHeight, 0.);
// 		}
// 		var t: f32 = sphIntersect(ro, rd, pos, ballRadius).x;
// 		if (t > 0. && t < mint) {
// 			mint = t;
// 			(*inter) = ro + mint * rd;
// 			(*normal) = normalize((*inter) - pos);
// 			(*color) = ballColor;
// 		}
// 	}


// 		let aspecRatio: f32 = uni.iResolution.x / uni.iResolution.y;
// 		var boxNormal: vec3<f32> = vec3<f32>(0. );
// 		let t: f32 = boxIntersection(ro, rd, vec3<f32>(aspecRatio, 0.1, 1.), vec3<f32>(0., -0.1, 0.), &boxNormal).x;

// 		if (t > 0. && t < mint) {
// 			mint = t;
// 			(*inter) = ro + mint * rd;
// 			(*normal) = boxNormal;
// 			let tileId: vec2<i32> = vec2<i32>(vec2<f32>((*inter).x, (*inter).z) * 3. + 100.);
// 			 if ((tileId.x & 1 ^ tileId.y & 1) == 0) {(*color) = vec3<f32>(0.3); } else { (*color) = vec3<f32>(0.15); };
// 		}

// 	return mint;
// } 

// fn sampleFog(pos: vec3<f32>) -> f32 {
// 	var uv: vec2<f32> = pos.xz;
// 	uv.x = uv.x * (uni.iResolution.y / uni.iResolution.x);
// 	uv = uv * 0.5 + 0.5;
// 	if (max(uv.x, uv.y) > 1. || min(uv.x, uv.y) < 0.) {
// 		return 0.;
// 	}
// 	return sample_texture(buffer_a, uv).z;
// } 

// fn Render(ro: vec3<f32>, rd: vec3<f32>, dist: f32, fudge: f32) -> vec3<f32> {
// 	var inter: vec3<f32> = vec3<f32>(0.);
// 	var normal: vec3<f32> = vec3<f32>(0.);
// 	var baseColor: vec3<f32> = vec3<f32>(0.);
// 	var lightPos: vec3<f32> = vec3<f32>(0.);
// 	let mint: f32 = sceneIntersection(ro, rd, &inter, &normal, &baseColor, dist, &lightPos);
// 	var color: vec3<f32> = vec3<f32>(0.);
// 	if (mint < dist) {
// 		var lightDir: vec3<f32> = normalize(lightPos - inter);
// 		var lightDist2: f32 = dist2(lightPos - inter);
// 		var shadowStep: vec3<f32> = fogHeigth / f32(nbSlice) * lightDir / lightDir.y;
// 		var shadowDist: f32 = 0.;

// 		for (var i: i32 = 0; i < nbSlice; i = i + 1) {
// 			var shadowPos: vec3<f32> = inter + shadowStep * f32(i);
// 			let v: f32 = sampleFog(shadowPos) * fogHeigth;
// 			shadowDist = shadowDist + (min(max(0., v - shadowPos.y), fogSlice) * length(shadowStep) / fogSlice);
// 		}

// 		var shadowFactor: f32 = exp(-shadowDist * shadowDensity * 0.25);
// 		color = baseColor * (max(0., dot(normal, lightDir) * shadowFactor) + 0.2) / lightDist2;
// 	} else { 
// 		color = vec3<f32>(0.);
// 	}
// 	var t: f32 = 0.;
// 	if (floorIntersect(ro, rd, fogHeigth, &t)) {
// 		var curPos: vec3<f32> = ro + rd * t;
// 		let fogStep: vec3<f32> = fogHeigth / f32(nbSlice) * rd / abs(rd.y);
// 		curPos = curPos + (fudge * fogStep);
// 		let stepLen: f32 = length(fogStep);
// 		var curDensity: f32 = 0.;
// 		var transmittance: f32 = 1.;
// 		var lightEnergy: f32 = 0.;

// 		for (var i: i32 = 0; i < nbSlice; i = i + 1) {
// 			if (dot(curPos - ro, rd) > mint) {			break;
//  }
// 			let curHeigth: f32 = sampleFog(curPos) * fogHeigth;
// 			let curSample: f32 = min(max(0., curHeigth - curPos.y), fogSlice) * stepLen / fogSlice;
// 			if (curSample > 0.001) {
// 				let lightDir: vec3<f32> = normalize(lightPos - curPos);
// 				let shadowStep: vec3<f32> = fogHeigth / f32(nbSlice) * lightDir / lightDir.y;
// 				let lightDist2: f32 = dist2(lightPos - curPos);
// 				var shadowPos: vec3<f32> = curPos + shadowStep * fudge;
// 				var shadowDist: f32 = 0.;

// 				for (var j: i32 = 0; j < nbSlice; j = j + 1) {
// 					shadowPos = shadowPos + (shadowStep);
// 					if (shadowPos.y > fogHeigth) {
// 						break;
// 					}
// 					let curHeight: f32 = sampleFog(shadowPos) * fogHeigth;
// 					shadowDist = shadowDist + (min(max(0., curHeight - shadowPos.y), fogSlice) * length(shadowStep) / fogSlice);
// 				}

// 				let shadowFactor: f32 = exp(-shadowDist * shadowDensity) / lightDist2;
// 				curDensity = curSample * fogDensity;
// 				let absorbedlight: f32 = shadowFactor * (1. * curDensity);
// 				lightEnergy = lightEnergy + (absorbedlight * transmittance);
// 				transmittance = transmittance * (1. - curDensity);
// 			}
// 			curPos = curPos + (fogStep);
// 		}

// 		color = mix(color, vec3<f32>(lightEnergy), 1. - transmittance);
// 	}
// 	return color;
// } 

// fn vignette(color: vec3<f32>, q: vec2<f32>, v: f32) -> vec3<f32> {
// 	var color_var = color;
// 	color_var = color_var * (0.3 + 0.8 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), v));
// 	return color_var;
// } 

// fn setCamera(ro: vec3<f32>, ta: vec3<f32>) -> mat3x3<f32> {
// 	let cw: vec3<f32> = normalize(ta - ro);
// 	let up: vec3<f32> = vec3<f32>(0., 1., 0.);
// 	let cu: vec3<f32> = normalize(cross(cw, up));
// 	let cv: vec3<f32> = normalize(cross(cu, cw));
// 	return mat3x3<f32>(cu, cv, cw);
// } 

// fn radians(in: f32) -> f32 {
//     return in * (3.141592653589793 / 180.);
// }

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

// 	var tot: vec3<f32> = vec3<f32>(0.);
// 	var rook: array<vec2<f32>,4>;
// 	rook[0] = vec2<f32>(1. / 8., 3. / 8.);
// 	rook[1] = vec2<f32>(3. / 8., -1. / 8.);
// 	rook[2] = vec2<f32>(-1. / 8., -3. / 8.);
// 	rook[3] = vec2<f32>(-3. / 8., 1. / 8.);

// 	for (var n: i32 = 0; n < 4; n  = n + 1) {
// 		let o: vec2<f32> = rook[n];
// 		let p: vec2<f32> = (-uni.iResolution.xy + 2. * (fragCoord + o)) / uni.iResolution.y;
// 		let theta: f32 = radians(360.) * (uni.iMouse.x / uni.iResolution.x - 0.5) - radians(90.);
// 		let phi: f32 = -radians(30.);
// 		let ro: vec3<f32> = 2. * vec3<f32>(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta));
// 		let ta: vec3<f32> = vec3<f32>(0.);
// 		let ca: mat3x3<f32> = setCamera(ro, ta);
// 		let rd: vec3<f32> = ca * normalize(vec3<f32>(p, 1.5));
// 		let col: vec3<f32> = Render(ro, rd, 6., hash12(fragCoord + uni.iTime));
// 		tot = tot + (col);
// 	}

// 	tot = tot / (4.);
// 	tot = vignette(tot, fragCoord / uni.iResolution.xy, 0.6);
// 	fragColor = vec4<f32>(sqrt(tot), 1.);

//     textureStore(texture, y_inverted_location, toLinear(fragColor));
// } 


// // fn toLinear(sRGB: vec4<f32>) -> vec4<f32> {
// //     let cutoff = vec4<f32>(sRGB < vec4<f32>(0.04045));
// //     let higher = pow((sRGB + vec4<f32>(0.055)) / vec4<f32>(1.055), vec4<f32>(2.4));
// //     let lower = sRGB / vec4<f32>(12.92);

// //     return mix(higher, lower, cutoff);
// // }

// // [[stage(compute), workgroup_size(8, 8, 1)]]
// // fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
// //     let R: vec2<f32> = uni.iResolution.xy;
// //     let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
// //     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
// // 	var fragColor: vec4<f32>;
// // 	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

// // 	fragColor = vec4<f32>(vec3<f32>(sample_texture(buffer_a, fragCoord / uni.iResolution).z), 1.);
// //     textureStore(texture, y_inverted_location, toLinear(fragColor));
// // } 

