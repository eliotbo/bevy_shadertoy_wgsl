struct CommonUniform {
    iTime: f32;
    iTimeDelta: f32;
    iFrame: f32;
    iSampleRate: f32;

    iMouse: vec4<f32>;
    iResolution: vec2<f32>;
    

    iChannelTime: vec4<f32>;
    iChannelResolution: vec4<f32>;
    iDate: vec4<i32>;
};

[[group(0), binding(0)]]
var<uniform> uni: CommonUniform;

[[group(0), binding(1)]]
var buffer_a: texture_storage_2d<rgba8unorm, read_write>;

[[group(0), binding(2)]]
var buffer_b: texture_storage_2d<rgba8unorm, read_write>;

[[group(0), binding(3)]]
var buffer_c: texture_storage_2d<rgba8unorm, read_write>;

[[group(0), binding(4)]]
var buffer_d: texture_storage_2d<rgba8unorm, read_write>;

// #define T(p) texelFetch(iChannel0, ivec2(mod(p,R)), 0)

// #define P(p) texture(iChannel0, mod(p,R)/R)

// #define C(p) texture(iChannel1, mod(p,R)/R)

// #define GS(x) exp(-dot(x,x))

// #define GS0(x) exp(-length(x))

// #define CI(x) smoothstep(1.0, 0.9, length(x))

// #define Dir(ang) vec2(cos(ang), sin(ang))

// #define Rot(ang) mat2(cos(ang), sin(ang), -sin(ang), cos(ang))


// #define PACK(X) ( uint(round(65534.0*clamp(0.5*X.x+0.5, 0., 1.))) + \
//            65535u*uint(round(65534.0*clamp(0.5*X.y+0.5, 0., 1.))) )   

// #define UNPACK(X) (clamp(vec2(X%65535u, X/65535u)/65534.0, 0.,1.)*2.0 - 1.0)              

// #define DECODE(X) UNPACK(floatBitsToUint(X))

// #define ENCODE(X) uintBitsToFloat(PACK(X))

let PI = 3.14159265;

let dt = 0.5;

// let R = uni.iResolution.xy;

let cooling = 1.5;

fn GS(x1: vec2<f32>) -> f32 {
    return exp(-dot(x1, x1));
}

fn MF(dx: vec2<f32>) -> f32 {
	return -GS(0.75 * dx) + 0.13 * GS(0.4 * dx);

} 

fn Ha(x: vec2<f32>) -> f32 {
    var x2: f32;
    if (x.x >= 0.) {
        x2 = 1.;
    } else {
        x2 = 0.0;
    }

    if (x.y >= 0.) {
        x2 = x2;
    } else {
        x2 = 0.0;
    }
	// return (x.x >= 0. ? 1. : 0.) * (x.y >= 0. ? 1. : 0.);
    return x2;

} 

fn Hb(x: vec2<f32>) -> f32 {
	// return (x.x > 0. ? 1. : 0.) * (x.y > 0. ? 1. : 0.);
    var x2: f32;
    if (x.x > 0.) {
        x2 = 1.;
    } else {
        x2 = 0.0;
    }

    if (x.y > 0.) {
        x2 = x2;
    } else {
        x2 = 0.0;
    }

    return x2;

} 

fn unpack(X: u32) -> vec2<f32> {
    return (clamp(vec2<f32>(f32(X % 65535u), f32(X / 65535u)) / 65534.0, vec2<f32>(0.), vec2<f32>(1.)) *2.0 - 1.0) ;
}

fn pack(v: vec2<f32>) -> u32 {
    return  (     u32(round(65534.0*clamp(0.5*v.x+0.5, 0., 1.))) + 
           65535u*u32(round(65534.0*clamp(0.5*v.y+0.5, 0., 1.))) )   ;
}





fn sdBox( p: vec2<f32>,  b: vec2<f32>) -> f32 {
	let d: vec2<f32> = abs(p) - b;
	return length(max(d, vec2<f32>(0.))) + min(max(d.x, d.y), 0.);

} 

fn border(p: vec2<f32>, R: vec2<f32>) -> f32 {
	let bound: f32 = -sdBox(p - R * 0.5, R * vec2<f32>(0.49, 0.49));
	let box: f32 = sdBox(p - R * vec2<f32>(0.5, 0.6), R * vec2<f32>(0.05, 0.01));
	let drain: f32 = -sdBox(p - R * vec2<f32>(0.5, 0.7), R * vec2<f32>(0., 0.));
	return bound;

} 

let h = 1.;

fn bN(p: vec2<f32>, R: vec2<f32>) -> vec3<f32> {
	let dx: vec3<f32> = vec3<f32>(-h, 0., h);
	let idx: vec4<f32> = vec4<f32>(-1. / h, 0., 1. / h, 0.25);
	let r: vec3<f32> = idx.zyw * border(p + dx.zy, R) 
        + idx.xyw * border(p + dx.xy, R) 
        + idx.yzw * border(p + dx.yz, R) 
        + idx.yxw * border(p + dx.yx, R);
	return vec3<f32>(normalize(r.xy), r.z + 0.0001);

} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {

// }

// fn mainImage( U: vec4<f32>,  pos: vec2<f32>)  {
    let R = uni.iResolution.xy;
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let pos = location;

	let uv: vec2<f32> = vec2<f32>(pos) / R;
	let p: vec2<i32> = vec2<i32>(pos);

    let data: vec4<f32> = textureLoad(buffer_a, pos % vec2<i32>( R));


	// var X: vec2<f32> = DECODE(data.x) + pos;
	// var V: vec2<f32> = DECODE(data.y);

    var X: vec2<f32> = unpack(u32(data.x)) + vec2<f32>(pos);
    var V: vec2<f32> = unpack(u32(data.y));


	let M: f32 = data.z;
	if (M != 0.) {
		var Fa: vec2<f32> = vec2<f32>(0.);
		for (var i: i32 = -2; i <= 2; i = i + 1) {
			for (var j: i32 = -2; j <= 2; j = j + 1) {
				let tpos: vec2<i32> = pos + vec2<i32>(i, j);
				// let data: vec4<f32> = T(tpos);

                let data: vec4<f32> = textureLoad(buffer_a, (tpos % vec2<i32>( R)));

                //  texelFetch(iChannel0, ivec2(mod(p,R)), 0)

				// let X0: vec2<f32> = DECODE(data.x) + tpos;
				// let V0: vec2<f32> = DECODE(data.y);

                var X0: vec2<f32> = unpack(u32(data.x)) + vec2<f32>(tpos);
                var V0: vec2<f32> = unpack(u32(data.y));

				let M0: f32 = data.z;
				let dx: vec2<f32> = X0 - X;

				Fa = Fa + (M0 * MF(dx) * dx);
			
			}			
            
            var F: vec2<f32> = vec2<f32>(0.);
			if (uni.iMouse.z > 0.) {
				let dx: vec2<f32> = vec2<f32>(pos) - uni.iMouse.xy;
				F = F - (0.003 * dx * GS(dx / 30.));
			}

			F = F + (0.001 * vec2<f32>(0., -1.0));

			V = V + ((F + Fa) * dt / M);
			X = X + (cooling * Fa * dt / M);
			let BORD: vec3<f32> = bN(X, R);
			V = V + (0.5 * smoothStep(0., 5., -BORD.z) * BORD.xy);
			let v: f32 = length(V);

            var denom: f32 = 1.0;
            if (v > 1.) {
                denom = 1. * v;
            } 
            V = V / denom;
			// V = V / (v > 1. ? 1. * v : 1.);
		
		}	
	}
	X = X - vec2<f32>(pos);
	// U = vec4<f32>(ENCODE(X), ENCODE(V), M, 0.);

    let eX = f32(pack(X));
    let eV = f32(pack(V));

	let U = vec4<f32>(eX, eV, M, 0.);

    textureStore(buffer_b, location, U);

} 

