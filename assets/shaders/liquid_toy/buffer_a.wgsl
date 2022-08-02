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





let speed: f32 = 0.01;
let scale: f32 = 0.1;
let falloff: f32 = 3.;
let fade: f32 = 0.4;
let strength: f32 = 1.;
let range: f32 = 5.;
fn random3(c: vec3<f32>) -> vec3<f32> {
	var j: f32 = 4096. * sin(dot(c, vec3<f32>(17., 59.4, 15.)));
	var r: vec3<f32>;
	r.z = fract(512. * j);
	j = j * (0.125);
	r.x = fract(512. * j);
	j = j * (0.125);
	r.y = fract(512. * j);
	return r - 0.5;
} 

let F3: f32 = 0.3333333;
let G3: f32 = 0.1666667;
fn simplex3d(p: vec3<f32>) -> f32 {
	let s: vec3<f32> = floor(p + dot(p, vec3<f32>(F3)));
	var x: vec3<f32> = p - s + dot(s, vec3<f32>(G3));
	let e: vec3<f32> = step(vec3<f32>(0.), x - x.yzx);
	let i1: vec3<f32> = e * (1. - e.zxy);
	let i2: vec3<f32> = 1. - e.zxy * (1. - e);
	let x1: vec3<f32> = x - i1 + G3;
	let x2: vec3<f32> = x - i2 + 2. * G3;
	let x3: vec3<f32> = x - 1. + 3. * G3;
	var w: vec4<f32>;
	var d: vec4<f32>;
	w.x = dot(x, x);
	w.y = dot(x1, x1);
	w.z = dot(x2, x2);
	w.w = dot(x3, x3);
	w = max(0.6 - w, vec4<f32>(0.));
	d.x = dot(random3(s), x);
	d.y = dot(random3(s + i1), x1);
	d.z = dot(random3(s + i2), x2);
	d.w = dot(random3(s + 1.), x3);
	w = w * (w);
	w = w * (w);
	d = d * (w);
	return dot(d, vec4<f32>(52.));
} 

let rot1: mat3x3<f32> = mat3x3<f32>(
    vec3<f32>(-0.37, 0.36, 0.85), 
    vec3<f32>(-0.14, -0.93, 0.34), 
    vec3<f32>(0.92, 0.01, 0.4));

let rot2: mat3x3<f32> = mat3x3<f32>(
     vec3<f32>(-0.55, -0.39, 0.74), 
     vec3<f32>(0.33, -0.91, -0.24), 
     vec3<f32>(0.77, 0.12, 0.63));

let rot3: mat3x3<f32> = mat3x3<f32>(
     vec3<f32>(-0.71, 0.52, -0.47), 
     vec3<f32>(-0.08, -0.72, -0.68), 
     vec3<f32>(-0.7, -0.45, 0.56));

fn simplex3d_fractal(m: vec3<f32>) -> f32 {
	return 0.5333333 * simplex3d(m * rot1) + 0.2666667 * simplex3d(2. * m * rot2) + 0.1333333 * simplex3d(4. * m * rot3) + 0.0666667 * simplex3d(8. * m);
} 

fn dummy(p3: vec3<f32>) -> vec3<f32> {
	var value: f32 = simplex3d(p3 * 16.);
	value = 0.5 + 0.5 * value;
	return vec3<f32>(value);
} 

fn fbm(p: vec3<f32>) -> vec3<f32> {
	var result: vec3<f32> = vec3<f32>(0.);
	var amplitude: f32 = 0.5;

	for (var index: f32 = 0.; index < 3.; index  = index + 1.) {
		let what: vec3<f32> = dummy(p / amplitude);
		result = result + (what * amplitude);
		amplitude = amplitude / (falloff);
	}

	return result;
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

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	var uv: vec2<f32> = (fragCoord.xy - uni.iResolution.xy / 2.) / uni.iResolution.y;
	var spice: vec3<f32> = fbm(vec3<f32>(uv * scale, uni.iTime * speed));
	let t: f32 = uni.iTime * 2.;
	let mouse: vec2<f32> = (uni.iMouse.xy - uni.iResolution.xy / 2.) / uni.iResolution.y;
	if (uni.iMouse.z > 0.5) {	uv = uv - (mouse);
	} else { 	uv = uv - (vec2<f32>(cos(t), sin(t)) * 0.3);
	}
	var paint: f32 = smoothstep(0.1, 0., length(uv));
	var offset: vec2<f32> = vec2<f32>(0.);
	uv = fragCoord.xy / uni.iResolution.xy;

	let data: vec4<f32> = sample_texture(buffer_a, uv);
	let unit: vec3<f32> = vec3<f32>(range / uni.iResolution.xy, 0.);

	let normal: vec3<f32> = normalize(vec3<f32>(
        sample_texture(buffer_a, uv - unit.xz).r 
        - sample_texture(buffer_a, uv + unit.xz).r, sample_texture(buffer_a, uv - unit.zy).r 
        - sample_texture(buffer_a, uv + unit.zy).r, data.x * data.x) + 0.001);

	offset = offset - (normal.xy);
	spice.x = spice.x * (6.28 * 2.);
	spice.x = spice.x + (uni.iTime);
	offset = offset + (vec2<f32>(cos(spice.x), sin(spice.x)));
	let frame: vec4<f32> = sample_texture(buffer_a, uv + strength * offset / uni.iResolution.xy);
	paint = max(paint, frame.x - uni.iTimeDelta * fade);
	fragColor = vec4<f32>(clamp(paint, 0., 1.));

    textureStore(buffer_a, location, fragColor);
} 



