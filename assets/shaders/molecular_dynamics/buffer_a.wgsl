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
var buffer_a: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(2)]]
var buffer_b: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(3)]]
var buffer_c: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(4)]]
var buffer_d: texture_storage_2d<rgba32float, read_write>;

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

let dt = 0.4;

// let R = uni.iResolution.xy;

let cooling = 1.5;

fn GS(x1: vec2<f32>) -> f32 {
    return exp(-dot(x1, x1));
}

fn MF(dx: vec2<f32>) -> f32 {
	return -GS(0.75 * dx) + 0.15 * GS(0.4 * dx);

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
    return (clamp(
            vec2<f32>(f32(X % 65535u), f32(X / 65535u)) / 65534.0, 
            vec2<f32>(0.), 
            vec2<f32>(1.)
        ) * 2.0 - 1.0
    ) ;
}

fn pack(v: vec2<f32>) -> u32 {
    return  (     u32(round(65534.0*clamp(0.5*v.x+0.5, 0., 1.))) + 
           65535u*u32(round(65534.0*clamp(0.5*v.y+0.5, 0., 1.))) )   ;
}







fn PD(x: vec2<f32>, pos: vec2<f32>) -> vec3<f32> {
	return vec3<f32>(x, 1.) * Ha(x - (pos - 0.5)) * Hb(pos + 0.5 - x);

} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R = uni.iResolution.xy;
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    // let color = vec4<f32>(0.5);
    // textureStore(buffer_a, location, color);
// }

// fn mainImage( U: vec4<f32>,  pos: vec2<f32>)  {

    let pos = location;
	let p: vec2<i32> = vec2<i32>(pos);
	var X: vec2<f32> = vec2<f32>(0.);
	var V: vec2<f32> = vec2<f32>(0.);
	var M: f32 = 0.;
	for (var i: i32 = -1; i <= 1; i = i + 1) {
		for (var j: i32 = -1; j <= 1; j = j + 1) {
			let tpos: vec2<i32> = pos + vec2<i32>(i, j);
			// let data: vec4<f32> = T(tpos);

            let data: vec4<f32> = textureLoad(buffer_b, tpos % vec2<i32>( R));

            var X0: vec2<f32> = unpack(u32(data.x)) + vec2<f32>(tpos);
			var V0: vec2<f32> = unpack(u32(data.y));

			// var X0: vec2<f32> = DECODE(data.x) + tpos;
			// let V0: vec2<f32> = DECODE(data.y);

			let M0: i32 = i32(data.z);
			let M0H: i32 = M0 / 2;
			X0 = X0 + (V0 * dt);
			var m: vec3<f32>;

            if  (M0 >= 2) {
                 m =  f32(M0H) *      PD(X0 + vec2<f32>(0.5, 0.), vec3<f32>(pos)) 
                    + f32(M0 - M0H) * PD(X0 - vec2<f32>(0.5, 0.), vec3<f32>(pos)) ;
             } else {
                  m = f32(M0) * PD(X0, vec3<f32>(pos));
            }
			X = X + (m.xy);
			V = V + (V0 * m.z);
			M = M + (m.z);
		
		}	
	}	
    
    if (M != 0.) {
		X = X / (M);
		V = V / (M);
	}

	#ifdef INIT
		X = vec2<f32>(pos);
		V = vec2<f32>(0.);
		M = Ha(vec2<f32>(pos) - (R * 0.5 - R.x * 0.1)) * Hb(R * 0.5 + R.x * 0.1 - vec2<f32>(pos));
	#endif

	X = X - vec2<f32>(pos);

    let eX = f32(pack(X));
    let eV = f32(pack(V));

	let U = vec4<f32>(eX, eV, M, 0.);

    textureStore(buffer_a, location, U);

} 

