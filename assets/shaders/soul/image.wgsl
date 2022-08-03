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






// https://www.shadertoy.com/view/3ltyRB
// by leon
// License Attribution-NonCommercial 2.0 Generic (CC BY-NC 2.0)

struct Volume {
	dist: f32,
	mate: i32,
	density: f32,
	space: f32,
};

fn select2(a: Volume, b: Volume) -> Volume {
	if (a.dist < b.dist) {	return a;
 }
	return b;
} 

let mat_eye_globe: i32 = 1;
let mat_pupils: i32 = 2;
let mat_eyebrows: i32 = 3;
let mat_iris: i32 = 4;
let mat_glass: i32 = 5;
fn rot(a: f32) -> mat2x2<f32> {
	let c: f32 = cos(a);
	var s: f32 = sin(a);
	return mat2x2<f32>(c, -s, s, c);
} 

fn hash12(p: vec2<f32>) -> f32 {
	var p3: vec3<f32> = fract(vec3<f32>(p.xyx) * 0.1031);
	p3 = p3 + (dot(p3, p3.yzx + 33.33));
	return fract((p3.x + p3.y) * p3.z);
} 

fn sdBox(p: vec3<f32>, b: vec3<f32>) -> f32 {
	var q: vec3<f32> = abs(p) - b;
	return length(max(q, vec3<f32>(0.))) + min(max(q.x, max(q.y, q.z)), 0.);
} 

fn opSmoothUnion(d1: f32, d2: f32, k: f32) -> f32 {
	var h: f32 = clamp(0.5 + 0.5 * (d2 - d1) / k, 0., 1.);
	return mix(d2, d1, h) - k * h * (1. - h);
} 

fn opSmoothSubtraction(d1: f32, d2: f32, k: f32) -> f32 {
	var h: f32 = clamp(0.5 - 0.5 * (d2 + d1) / k, 0., 1.);
	return mix(d2, -d1, h) + k * h * (1. - h);
} 

fn opSmoothIntersection(d1: f32, d2: f32, k: f32) -> f32 {
	let h: f32 = clamp(0.5 - 0.5 * (d2 - d1) / k, 0., 1.);
	return mix(d2, d1, h) + k * h * (1. - h);
} 

fn sdCappedTorus(p2: vec3<f32>, sc: vec2<f32>, ra: f32, rb: f32) -> f32 {
    var p = p2;
	p.x = abs(p.x);
	var k: f32 = 0.; 
    if (sc.y * p.x > sc.x * p.y) { 
        k = dot(p.xy, sc); }
    else { 
        k = length(p.xy); 
    };
	return sqrt(dot(p, p) + ra * ra - 2. * ra * k) - rb;
} 

fn sdVerticalCapsule(p2: vec3<f32>, h: f32, r: f32) -> f32 {
    var p = p2;
	p.y = p.y - (clamp(p.y, 0., h));
	return length(p) - r;
} 

fn sdCappedCone(p: vec3<f32>, a: vec3<f32>, b: vec3<f32>, ra: f32, rb: f32) -> f32 {
	let rba: f32 = rb - ra;
	let baba: f32 = dot(b - a, b - a);
	let papa: f32 = dot(p - a, p - a);
	let paba: f32 = dot(p - a, b - a) / baba;
	let x: f32 = sqrt(papa - paba * paba * baba);
    var rab: f32;
    if (paba < 0.5) { rab = ra; } else { rab = rb; }
	let cax: f32 = max(0., x - rab);
	var cay: f32 = abs(paba - 0.5) - 0.5;
	let k: f32 = rba * rba + baba;
	let f: f32 = clamp((rba * (x - ra) + paba * baba) / k, 0., 1.);
	var cbx: f32 = x - ra - f * rba;
	let cby: f32 = paba - f;
	var s: f32; 
    if (cbx < 0. && cay < 0.) { s = -1.; } else { s = 1.; };
	return s * sqrt(min(cax * cax + cay * cay * baba, cbx * cbx + cby * cby * baba));
} 

fn sdRoundedCylinder(p: vec3<f32>, ra: f32, rb: f32, h: f32) -> f32 {
	let d: vec2<f32> = vec2<f32>(length(p.xz) - 2. * ra + rb, abs(p.y) - h);
	return min(max(d.x, d.y), 0.) + length(max(d, vec2<f32>(0.))) - rb;
} 

fn sdRoundBox(p: vec3<f32>, b: vec3<f32>, r: f32) -> f32 {
	let q: vec3<f32> = abs(p) - b;
	return length(max(q, vec3<f32>(0.))) + min(max(q.x, max(q.y, q.z)), 0.) - r;
} 

var<private> ao_pass: bool = false;
fn map2(pos_in: vec3<f32>) -> Volume {
    var pos = pos_in;
	var shape: f32 = 100.;
	var poszy = pos.zy;
	poszy = pos.zy * (rot(sin(pos.y * 0.2 + uni.iTime) * 0.1 + 0.2));
	pos.z = poszy.x;
	pos.y = poszy.y;
	var posyx = pos.yx;
	posyx = pos.yx * (rot(0.1 * sin(pos.y * 0.3 + uni.iTime)));
	pos.y = posyx.x;
	pos.x = posyx.y;
	var p: vec3<f32> = pos;

	var ghost: Volume;
	ghost.mate = 0;
	ghost.density = 0.05;
	ghost.space = 0.12;
    
	var opaque: Volume;
	opaque.mate = 0;
	opaque.density = 1.;
	opaque.space = 0.;

	var hair: Volume;
	hair.mate = mat_eyebrows;
	hair.density = 0.2;
	hair.space = 0.1;

	var glass: Volume;
	glass.mate = mat_glass;
	glass.density = 0.15;
	glass.space = 0.1;
    glass.dist = 0.;

	ghost.dist = length(p * vec3<f32>(1., 0.9, 1.)) - 1.;
	ghost.dist = opSmoothUnion(ghost.dist, length(p - vec3<f32>(0., 1.2, 0.)) - 0.55, 0.35);

	p.z = p.z + (1.3);
	var pyz = p.yz;
	pyz = p.yz * (rot(p.z * 0.5 + 0.1 * sin(uni.iTime + p.z * 4.)));
	p.y = pyz.x;
	p.z = pyz.y;
	shape = sdBox(p, vec3<f32>(1., 0.01, 1.));
	shape = max(shape, -length(pos.xz) + 0.99);
	ghost.dist = opSmoothSubtraction(shape, ghost.dist, 0.1);
	p = pos - vec3<f32>(0., 1.6, 0.);
	shape = sdRoundedCylinder(p + sin(p.z * 4.) * 0.03, 0.4, 0.01, 0.01);
	shape = min(shape, sdCappedCone(p + 0.05 * sin(p.z * 8.), vec3<f32>(0., 0.5, 0.), vec3<f32>(0.), 0.3, 0.445));
	ghost.dist = min(ghost.dist, shape);
	p = pos - vec3<f32>(0., 1., -0.55);
	let s: f32 = sign(p.x);

	var pxz = p.xz;
	pxz = p.xz * (rot(-pos.x * 1.));
	p.x = pxz.x;
	p.z = pxz.y;

	p.x = abs(p.x) - 0.15;

	opaque.dist = max(length(p * vec3<f32>(1., 1., 1.3)) - 0.18, -ghost.dist);
	opaque.mate = mat_eye_globe;

	p = p - (vec3<f32>(0.05, 0.3, -0.03));
	p.y = p.y - (0.01 * sin(uni.iTime * 3.));

	var pxy = p.xy;
	pxy = p.xy * (rot(0.2 + sin(pos.x * 2. + uni.iTime) * 0.5));
	p.x = pxy.x;
	p.y = pxy.y;

	shape = sdBox(p, vec3<f32>(0.15, 0.02 - p.x * 0.1, 0.03));
	hair.dist = shape;
	p = pos;
	ghost.dist = opSmoothUnion(ghost.dist, length(p + vec3<f32>(0., 1.8, 0.)) - 0.5, 0.6);
	p.x = abs(p.x) - 0.2;
	p.z = p.z + (0.1 * sin(p.x * 4. + uni.iTime));
	ghost.dist = opSmoothUnion(ghost.dist, sdVerticalCapsule(p + vec3<f32>(0., 2.8, 0.), 0.6, 0.01 + max(0., p.y + 3.) * 0.3), 0.2);
	p = pos;
	p.x = abs(p.x) - 0.4;

	var pxy = p.xy;
	pxy = p.xy * (rot(3.14 / 2.));
	p.x = pxy.x;
	p.y = pxy.y;

	p.x = p.x + (pos.x * 0.2 * sin(pos.x + uni.iTime));
	ghost.dist = opSmoothUnion(ghost.dist, sdVerticalCapsule(p + vec3<f32>(-1.5, 0., 0.), 0.6, 0.2), 0.2);
	
    let vvv = select2(ghost, opaque);
    var volume: Volume = select2(vvv, hair);
	if (!ao_pass) {
		p = pos - vec3<f32>(0., 1., -0.65);
		p.x = abs(p.x) - 0.18;
		glass.dist = sdRoundBox(p + vec3<f32>(-0.1, 0., 0.1), vec3<f32>(0.2 + p.y * 0.1, 0.15 + p.x * 0.05, 0.001), 0.05);
		glass.dist = max(glass.dist, -sdRoundBox(p + vec3<f32>(-0.1, 0., 0.1), vec3<f32>(0.18 + p.y * 0.1, 0.14 + p.x * 0.05, 0.1), 0.05));
		glass.dist = max(glass.dist, abs(p.z) - 0.1);
		volume = select2(volume, glass);
	}
	return volume;
} 

fn getNormal(p: vec3<f32>) -> vec3<f32> {
	let off: vec2<f32> = vec2<f32>(0.001, 0.);
	return normalize(map2(p).dist - vec3<f32>(map2(p - off.xyy).dist, map2(p - off.yxy).dist, map2(p - off.yyx).dist));
} 

fn getAO(pos: vec3<f32>, nor: vec3<f32>) -> f32 {
	var occ: f32 = 0.;
	var sca: f32 = 1.;

	for (var i: i32 = 0; i < 5; i = i + 1) {
		let h: f32 = 0.01 + 0.12 * f32(i) / 4.;
		var volume: Volume = map2(pos + h * nor);
		let d: f32 = volume.dist;
		occ = occ + ((h - d) * sca);
		sca = sca * (0.95);
		if (occ > 0.35) { break; }
	}

	return clamp(1. - 3. * occ, 0., 1.) * (0.5 + 0.5 * nor.y);
} 


// @compute @workgroup_size(8, 8, 1)
// fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

//     var O: vec4<f32> =  textureLoad(buffer_a, location);
//     textureStore(texture, location, O);
// }

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
	var color: vec4<f32>;
	var coordinate = vec2<f32>(f32(location.x), f32(location.y) );

	color = vec4<f32>(0., 0., 0., 0.);
	let uv: vec2<f32> = coordinate / uni.iResolution.xy;
	let p: vec2<f32> = 2. * (coordinate - 0.5 * uni.iResolution.xy) / uni.iResolution.y;
	var pos: vec3<f32> = vec3<f32>(-5., 0., -8.);
	var z: vec3<f32> = normalize(vec3<f32>(0., -0.3, 0.) - pos);
	var x: vec3<f32> = normalize(cross(z, vec3<f32>(0., 1., 0.)));
	var y: vec3<f32> = normalize(cross(x, z));
	let ray: vec3<f32> = normalize(z * 3. + x * p.x + y * p.y);
	var colorrgb = color.rgb;
	colorrgb = color.rgb + (vec3<f32>(0.2235, 0.3804, 0.5882) * uv.y);
	color.r = colorrgb.x;
	color.g = colorrgb.y;
	color.b = colorrgb.z;
    color.a = 1.;
	var shade: f32 = 0.;
	var normal: vec3<f32> = vec3<f32>(0., 1., 0.);
	var ao: f32 = 1.;
	let rng: f32 = hash12(coordinate + uni.iTime);
	var count: i32 = 30;

	for (var index: i32 = 0; index < count; index += 1) {
		var volume: Volume = map2(pos);
		if (volume.dist < 0.01) {
        
			if (shade < 0.001) {
				ao_pass = true;
				ao = getAO(pos, normal);
				ao_pass = false;
			}
			shade = shade + (volume.density);
			normal = getNormal(pos);
			let fresnel: f32 = pow(dot(ray, normal) * 0.5 + 0.5, 1.2);
			volume.dist = volume.space * fresnel;
			var col: vec3<f32> = vec3<f32>(0.);
			if (volume.mate == mat_eye_globe) {

                let globe: f32 = dot(normal, vec3<f32>(0., 1., 0.)) * 0.5 + 0.5;
                var look: vec3<f32> = vec3<f32>(0., 0., -1.);
                var lookxz = look.xz;
                lookxz = look.xz * (rot(sin(uni.iTime) * 0.2 - 0.2));
                look.x = lookxz.x;
                look.z = lookxz.y;
                var lookyz = look.yz;
                lookyz = look.yz * (rot(sin(uni.iTime * 2.) * 0.1 + 0.5));
                look.y = lookyz.x;
                look.z = lookyz.y;
                let pupils: f32 = smoothstep(0.01, 0., dot(normal, look) - 0.95);
                col = col + (vec3<f32>(1.) * globe * pupils);
                // break;
            }
            else if (volume.mate == mat_eyebrows) {
                col = col + (vec3<f32>(0.3451, 0.2314, 0.5255));
                // break;
            }
            else if (volume.mate == mat_glass) {
                col = col + (vec3<f32>(0.2));
                // break;
            }
            else {
                let leftlight: vec3<f32> = normalize(vec3<f32>(6., -5., 1.));
                let rightlight: vec3<f32> = normalize(vec3<f32>(-3., 1., 1.));
                let frontlight: vec3<f32> = normalize(vec3<f32>(-1., 1., -2.));
                let blue: vec3<f32> = vec3<f32>(0., 0., 1.) * pow(dot(normal, leftlight) * 0.5 + 0.5, 0.2);
                let green: vec3<f32> = vec3<f32>(0., 1., 0.) * pow(dot(normal, frontlight) * 0.5 + 0.5, 2.);
                let red: vec3<f32> = vec3<f32>(0.8941, 0.2039, 0.0824) * pow(dot(normal, rightlight) * 0.5 + 0.5, 0.5);
                col = col + (blue + green + red);
                col = col * (ao * 0.5 + 0.3);
                // break;
            }
        
            var colorrgb = color.rgb;
            colorrgb = color.rgb + (col * volume.density);
            color.r = colorrgb.x;
            color.g = colorrgb.y;
            color.b = colorrgb.z;

            // color = vec4<f32>(1.0, 0.0, 0.0, 1.0);
            
        }
		if (shade >= 1.) {
			break;
		}
        
		volume.dist = volume.dist * (0.9 + 0.1 * rng);
		pos = pos + (ray * volume.dist);
	}


    // color = vec4<f32>(1.0, 0.0, 0.0, 1.0);
    // color.a = 1.0;
    textureStore(texture, y_inverted_location, color);

} 


