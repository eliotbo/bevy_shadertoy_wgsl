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

