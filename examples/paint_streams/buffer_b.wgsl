fn border(p: vec2<f32>, R2: vec2<f32>, time: f32) -> f32 {
	let bound: f32 = -sdBox(p - R2 * 0.5, R2 * vec2<f32>(0.5, 0.5));
	let box: f32 = sdBox(Rot(0. * time) * (p - R2 * vec2<f32>(0.5, 0.6)), R2 * vec2<f32>(0.05, 0.01));
	let drain: f32 = -sdBox(p - R2 * vec2<f32>(0.5, 0.7), R2 * vec2<f32>(1.5, 0.5));
	return max(drain, min(bound, box));

} 

fn bN(p: vec2<f32>, R2: vec2<f32>, time: f32) -> vec3<f32> {
	let dx: vec3<f32> = vec3<f32>(-h, 0.0, h);
	let idx: vec4<f32> = vec4<f32>(-1./h, 0., 1./h, 0.25);
	let r: vec3<f32> = idx.zyw * border(p + dx.zy, R2, time) 
                     + idx.xyw * border(p + dx.xy, R2, time) 
                     + idx.yzw * border(p + dx.yz, R2, time) 
                     + idx.yxw * border(p + dx.yx, R2, time);
	return vec3<f32>(normalize(r.xy),  r.z + 1e-4);

} 

fn Simulation(
	ch: texture_storage_2d<rgba8unorm, read_write>, 
	P: particle, pos: vec2<f32>,  
	R2: vec2<f32>, 
	time: f32,
	Mouse: vec4<f32>,
) -> particle 
{
	var F: vec2<f32> = vec2<f32>(0.);
	var avgV: vec3<f32> = vec3<f32>(0.);
	for (var i: i32 = -2; i <= 2; i = i + 1) {	
        for (var j: i32 = -2; j <= 2; j = j + 1) {
            let tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(j));
            // let data: vec4<f32> = texel(ch, tpos);
            // let data: vec4<f32> = texelFetch(ch, ivec2(tpos), 0);
            let data: vec4<f32> =  textureLoad(ch, vec2<i32>(tpos));

            let P0: particle = getParticle(data, tpos);
            let dx: vec2<f32> = P0.X - P.X;

            let avgP: f32 = 0.5 * P0.M.x * (Pf(P.M) + Pf(P0.M));
            F = F - (0.5 * G(1. * dx) * avgP * dx);
            avgV = avgV + (P0.M.x * G(1. * dx) * vec3<f32>(P0.V, 1.));
	
        }	
    }	
    avgV.y = avgV.y / (avgV.z);
    avgV.x = avgV.x / (avgV.z);

    //viscosity
	F = F + (0. * P.M.x * (avgV.xy - P.V));

    //gravity
	F = F + (P.M.x * vec2<f32>(0., -0.0004));

	if (Mouse.z > 0.) {
		let dm: vec2<f32> = (Mouse.xy - Mouse.zw) / 10.;
		let d: f32 = distance(Mouse.xy, P.X) / 20.;
		F = F + (0.001 * dm * exp(-d * d));
	
	}

    var P1: particle = P;

    //integrate
	P1.V = P1.V + (F * dt / P1.M.x);

    //border 
	let N: vec3<f32> = bN(P1.X, R2, time);
	let vdotN: f32 = step(N.z, border_h) * dot(-N.xy, P1.V);
	P1.V = P1.V + (0.5 * (N.xy * vdotN + N.xy * abs(vdotN)));
	P1.V = P1.V + (0. * P1.M.x * N.xy * step(abs(N.z), border_h) * exp(-N.z));
	
    if (N.z < 0.) {	
        P1.V = vec2<f32>(0.);
	}

    //velocity limit
	let v: f32 = length(P1.V);

    var vv: f32;
    if (v > 1.) {
        vv = v; 
    } else {
        vv = 1.;
    };
	P1.V = P1.V / vv;

    return P1;

} 




[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {

	let R2 = uni.iResolution.xy;

	let location = vec2<i32>(i32(invocation_id.x), i32(R2.y)  - i32(invocation_id.y));

    let pos: vec2<f32> = vec2<f32>(location);

	
	let time = uni.iTime;
	let Mouse = uni.iMouse;
	let p: vec2<i32> = location;


	// let data: vec4<f32> = texel(buffer_a, pos);
    let data: vec4<f32> =  textureLoad(buffer_a, location);

	var P: particle = getParticle(data, pos);

	if (P.M.x != 0.) {
		P = Simulation(buffer_a, P, pos, R2, time, Mouse);
	}

	if (length(P.X - R2 * vec2<f32>(0.8, 0.9)) < 10.) {
		P.X = pos;
		P.V = 0.5 * Dir(-PI * 0.25 - PI * 0.5 + 0.3 * sin(0.4 * time));
		P.M = mix(P.M, vec2<f32>(fluid_rho, 1.), 0.4);
	}
    
	if (length(P.X - R2 * vec2<f32>(0.2, 0.9)) < 10.) {
		P.X = pos;
		P.V = 0.5 * Dir(-PI * 0.25 + 0.3 * sin(0.3 * time));
		P.M = mix(P.M, vec2<f32>(fluid_rho, 0.), 0.4);
	}

	// U = saveParticle(P, pos);
    textureStore(buffer_b, location, saveParticle(P, pos));
} 

