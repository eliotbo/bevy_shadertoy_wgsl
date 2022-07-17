fn gaussian_turbulence(uv: vec2<f32>) -> vec2<f32> {
	var texel: vec2<f32> = 1. / uni.iResolution.xy;
	var t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	var d: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.ww + 0.)))).xy;
	var d_n: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.wy + 0.)))).xy;
	var d_e: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.xw + 0.)))).xy;
	var d_s: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.wz + 0.)))).xy;
	var d_w: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (-t.xw + 0.)))).xy;
	var d_nw: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (-t.xz + 0.)))).xy;
	var d_sw: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (-t.xy + 0.)))).xy;
	var d_ne: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.xy + 0.)))).xy;
	var d_se: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (t.xz + 0.)))).xy;
	return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
} 

fn gaussian_confinement(uv: vec2<f32>) -> vec2<f32> {
	var texel: vec2<f32> = 1. / uni.iResolution.xy;
	var t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	var d: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.ww + 0.)))).xy;
	var d_n: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.wy + 0.)))).xy;
	var d_e: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.xw + 0.)))).xy;
	var d_s: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.wz + 0.)))).xy;
	var d_w: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (-t.xw + 0.)))).xy;
	var d_nw: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (-t.xz + 0.)))).xy;
	var d_sw: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (-t.xy + 0.)))).xy;
	var d_ne: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.xy + 0.)))).xy;
	var d_se: vec2<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (t.xz + 0.)))).xy;
	return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
} 

fn diff(uv: vec2<f32>) -> vec2<f32> {
	var texel: vec2<f32> = 1. / uni.iResolution.xy;
	var t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	var d: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.ww))).x;
	var d_n: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.wy))).x;
	var d_e: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.xw))).x;
	var d_s: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.wz))).x;
	var d_w: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + -t.xw))).x;
	var d_nw: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + -t.xz))).x;
	var d_sw: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + -t.xy))).x;
	var d_ne: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.xy))).x;
	var d_se: f32 = textureLoad_CONVERT_TO_i32(BUFFER_iChannel1, vec2<i32>(fract(uv + t.xz))).x;
	return vec2<f32>(0.5 * (d_e - d_w) + 0.25 * (d_ne - d_nw + d_se - d_sw), 0.5 * (d_n - d_s) + 0.25 * (d_ne + d_nw - d_se - d_sw));
} 

fn gaussian_velocity(uv: vec2<f32>) -> vec4<f32> {
	var texel: vec2<f32> = 1. / uni.iResolution.xy;
	var t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	var d: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.ww + 0.))));
	var d_n: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.wy + 0.))));
	var d_e: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xw + 0.))));
	var d_s: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.wz + 0.))));
	var d_w: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xw + 0.))));
	var d_nw: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xz + 0.))));
	var d_sw: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xy + 0.))));
	var d_ne: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xy + 0.))));
	var d_se: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xz + 0.))));
	return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
} 

fn vector_laplacian(uv: vec2<f32>) -> vec2<f32> {
	let _K0: f32 = -20. / 6.;
let _K1: f32 = 4. / 6.;
let _K2: f32 = 1. / 6.;
	let texel: vec2<f32> = 1. / uni.iResolution.xy;
	let t: vec4<f32> = vec4<f32>(texel, -texel.y, 0.);
	let d: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.ww + 0.))));
	let d_n: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.wy + 0.))));
	let d_e: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xw + 0.))));
	let d_s: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.wz + 0.))));
	let d_w: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xw + 0.))));
	let d_nw: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xz + 0.))));
	let d_sw: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (-t.xy + 0.))));
	let d_ne: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xy + 0.))));
	let d_se: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (t.xz + 0.))));
	return (_K0 * d + _K1 * (d_e + d_w + d_n + d_s) + _K2 * (d_ne + d_nw + d_se + d_sw)).xy;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	let uv: vec2<f32> = fragCoord / uni.iResolution.xy;
	let tx: vec2<f32> = 1. / uni.iResolution.xy;
	var turb: vec2<f32> = vec2<f32>(0.);
	var confine: vec2<f32> = vec2<f32>(0.);
	var div: vec2<f32> = vec2<f32>(0.);
	var delta_v: vec2<f32> = vec2<f32>(0.);
	var offset: vec2<f32> = vec2<f32>(0.);
	var lapl: vec2<f32> = vec2<f32>(0.);
	var vel: vec4<f32> = vec4<f32>(0.);
	var adv: vec4<f32> = vec4<f32>(0.);
	let init: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + +0.)));
	if (RECALCULATE_OFFSET) {

		for (var i: i32 = 0; i < 3; i = i + 1) {
			if (BLUR_TURBULENCE) {
				turb = gaussian_turbulence(uv + tx * offset);
			} else { 

				turb = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + (tx * offset + 0.)))).xy;
			}
			if (BLUR_CONFINEMENT) {
				confine = gaussian_confinement(uv + tx * offset);
			} else { 

				confine = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + (tx * offset + 0.)))).xy;
			}
			if (BLUR_VELOCITY) {
				vel = gaussian_velocity(uv + tx * offset);
			} else { 

				vel = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (tx * offset + 0.))));
			}
			offset = f32(i + 1.) / f32(3.) * -40. * (-0.05 * vel.xy + 1. * turb - 0.6 * confine + 0. * div);
			div = diff(uv + tx * 1. * offset);
			lapl = vector_laplacian(uv + tx * 1. * offset);
			adv = adv + (textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (tx * offset + 0.)))));
			delta_v = delta_v + (0.02 * lapl + 0. * turb + 0.01 * confine - 0.0001 * vel.xy - 0.1 * div);
		}

		adv = adv / (f32(3.));
		delta_v = delta_v / (f32(3.));
	} else { 

		if (BLUR_TURBULENCE) {
			turb = gaussian_turbulence(uv);
		} else { 

			turb = textureLoad_CONVERT_TO_i32(BUFFER_iChannel3, vec2<i32>(fract(uv + +0.))).xy;
		}
		if (BLUR_CONFINEMENT) {
			confine = gaussian_confinement(uv);
		} else { 

			confine = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, vec2<i32>(fract(uv + +0.))).xy;
		}
		if (BLUR_VELOCITY) {
			vel = gaussian_velocity(uv);
		} else { 

			vel = textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + +0.)));
		}
		offset = -40. * (-0.05 * vel.xy + 1. * turb - 0.6 * confine + 0. * div);
		div = diff(uv + tx * 1. * offset);
		lapl = vector_laplacian(uv + tx * 1. * offset);
		delta_v = delta_v + (0.02 * lapl + 0. * turb + 0.01 * confine - 0.0001 * vel.xy - 0.1 * div);

		for (var i: i32 = 0; i < 3; i = i + 1) {
			adv = adv + (textureLoad_CONVERT_TO_i32(BUFFER_iChannel0, vec2<i32>(fract(uv + (f32(i + 1.) / f32(3.) * tx * offset + 0.)))));
		}

		adv = adv / (f32(3.));
	}
	let pq: vec2<f32> = 2. * (uv * 2. - 1.) * vec2<f32>(1., tx.x / tx.y);
	if (CENTER_PUMP) {
		var pump: vec2<f32> = sin(0.2 * uni.iTime) * 0.001 * pq.xy / (dot(pq, pq) + 0.01);
	} else { 

		var pump: vec2<f32> = vec2<f32>(0.);
		let uvy0: f32 = exp(-50. * pow(pq.y, 2.));
		let uvx0: f32 = exp(-50. * pow(uv.x, 2.));
		pump = pump + (-15. * vec2<f32>(max(0., cos(0.2 * uni.iTime)) * 0.001 * uvx0 * uvy0, 0.));
		let uvy1: f32 = exp(-50. * pow(pq.y, 2.));
		let uvx1: f32 = exp(-50. * pow(1. - uv.x, 2.));
		pump = pump + (15. * vec2<f32>(max(0., cos(0.2 * uni.iTime + 3.1416)) * 0.001 * uvx1 * uvy1, 0.));
		let uvy2: f32 = exp(-50. * pow(pq.x, 2.));
		let uvx2: f32 = exp(-50. * pow(uv.y, 2.));
		pump = pump + (-15. * vec2<f32>(0., max(0., sin(0.2 * uni.iTime)) * 0.001 * uvx2 * uvy2));
		let uvy3: f32 = exp(-50. * pow(pq.x, 2.));
		let uvx3: f32 = exp(-50. * pow(1. - uv.y, 2.));
		pump = pump + (15. * vec2<f32>(0., max(0., sin(0.2 * uni.iTime + 3.1416)) * 0.001 * uvx3 * uvy3));
	}
	fragColor = mix(adv + vec4<f32>(1. * (delta_v + pump), offset), init, 0.);
	if (uni.iMouse.z > 0.) {
		let mouseUV: vec4<f32> = uni.iMouse / uni.iResolution.xyxy;
		let delta: vec2<f32> = normz(mouseUV.zw - mouseUV.xy);
		let md: vec2<f32> = (mouseUV.xy - uv) * vec2<f32>(1., tx.x / tx.y);
		let amp: f32 = exp(max(-12., -dot(md, md) / 0.001));
		var fragColorxy = fragColor.xy;
	fragColorxy = fragColor.xy + (1. * 0.05 * clamp(amp * delta, -1., 1.));
	fragColor.x = fragColorxy.x;
	fragColor.y = fragColorxy.y;
	}
	if (uni.iFrame == 0) { fragColor = 0.000001 * rand4(fragCoord, uni.iResolution.xy, uni.iFrame); }
} 

