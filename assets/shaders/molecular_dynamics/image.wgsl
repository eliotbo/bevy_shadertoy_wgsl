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

[[group(0), binding(5)]]
var texture: texture_storage_2d<rgba8unorm, read_write>;

// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
//     let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

//     let color = vec4<f32>(f32(0));
//     textureStore(texture, location, color);
// }

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




// displays a gray screen by setting the color in buffer_a.wglsl and loading buffer_a
// here



// fn hsv2rgb( c: vec3<f32>) -> vec3<f32> {

// 	var rgb: vec3<f32> = clamp(abs(mod(c.x * 6. + vec3<f32>(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
// 	rgb = rgb * rgb * (3. - 2. * rgb);
// 	return c.z * mix(vec3<f32>(1.), rgb, c.y);

// } 

fn hsv2rgb( c: vec3<f32>) -> vec3<f32> {
    var fractional: vec3<f32> = vec3<f32>( 0.0);
    let m = modf(c.x * 6. + vec3<f32>(0., 4., 2.) / 6., &fractional);

    // let v = vec3<f32>(0., 4., 2.);
    // let fractional: vec3<f32> = vec3<f32>(vec3<i32>( (c.x * 6. +  v) / 6.0)) ;
        
    // let whatever = modf(uv + 1.0, &tempo);
    // var temp2 = 0.;
    // let frac = modf(tempo / 2.0, &temp2);

    let af: vec3<f32>  = abs(fractional - 3.) - 1.;
	var rgb: vec3<f32> = clamp(af, vec3<f32>(0.), vec3<f32>(1.));

	rgb = rgb * rgb * (3. - 2. * rgb);
	return c.z * mix(vec3<f32>(1.), rgb, c.y);
} 



let radius = 1.0;

let zoom = 0.3;



[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R = uni.iResolution.xy;
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let pos = location;

//     var O: vec4<f32> =  textureLoad(buffer_a, location);
//     textureStore(texture, location, O);
// }

// fn mainImage( col: vec4<f32>,  pos: vec2<f32>) -> () {


	var rho: f32 = 0.001;
	var vel: vec2<f32> = vec2<f32>(0., 0.);
	for (var i: i32 = -2; i <= 2; i = i + 1) {
		for (var j: i32 = -2; j <= 2; j = j + 1) {
			let tpos: vec2<i32> = pos + vec2<i32>(i, j);

			// let data: vec4<f32> = texelFetch(buffer_b, ivec2(mod(tpos,R)), 0)
            let data: vec4<f32> = textureLoad(buffer_b, (tpos % vec2<i32>( R)));

			var X0: vec2<f32> = unpack(u32(data.x)) + vec2<f32>(tpos);
			var V0: vec2<f32> = unpack(u32(data.y));
			let M0: f32 = data.z;
			let dx: vec2<f32> = X0 - vec2<f32>(pos);

			let K: f32 = GS ((dx / radius)) / (radius * radius);

			rho = rho + (M0 * K);
			vel = vel + (M0 * K * V0);
		
		}	
	}	vel = vel / (rho);

	let vc: vec3<f32> = hsv2rgb(
        vec3<f32>(
            6. * atan2(vel.x, vel.y) / (2. * PI), 
            1.,
            rho * length(vel.xy)
        )
    );

	let col: vec3<f32> = cos(0.9 * vec3<f32>(3., 2., 1.) * rho) + 0. * vc;
    let U = vec4<f32>(col, 1.);

    textureStore(texture, location, U);

} 

