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

[[group(0), binding(5)]]
var texture: texture_storage_2d<rgba32float, read_write>;

// [[group(0), binding(6)]]
// var font_texture: texture_storage_2d<rgba32float, read_write>;

[[group(0), binding(6)]]
var font_texture: texture_2d<f32>;

[[group(0), binding(7)]]
var font_texture_sampler: sampler;

[[group(0), binding(8)]]
var rgba_noise_256_texture: texture_2d<f32>;

[[group(0), binding(9)]]
var rgba_noise_256_texture_sampler: sampler;

// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
//     let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

//     let color = vec4<f32>(f32(0));
//     textureStore(texture, location, color);
// }

// Why are the characters so pixelated? 
// One possible reason is that we are in a compute shader and the textures are not
// filtered.

let backColorDebug: vec3<f32> = vec3<f32>(0.2, 0.2, 0.2);


var<private> uv_debug: vec2<f32> ;
var<private> tp_debug: vec2<f32> ;
var<private> align_debug: vec4<f32>; // north, east, south, west
var<private> font_size_debug: f32;
var<private> dotColor_debug: vec3<f32> = vec3<f32>(0.5, 0.5, 0.);
var<private> drawColorDebug: vec3<f32> = vec3<f32>(1., 1., 0.);
var<private> vColor: vec3<f32> = backColorDebug;
var<private> aspect_debug: f32 = 1.;
var<private> pixelPosDebug: vec2<f32> = vec2<f32>(0., 0.);

let FONT_SPACE_DEBUG: f32 = 0.5;
let headColorDebug: vec3<f32> = vec3<f32>(0.9, 0.6, 0.2);
let mpColorDebug: vec3<f32> = vec3<f32>(0.99, 0.99, 0.);
let mxColorDebug: vec3<f32> = vec3<f32>(1., 0., 0.);
let myColorDebug: vec3<f32> = vec3<f32>(0., 1., 0.);
let font_png_size_debug: vec2<f32> = vec2<f32>(1023.0, 1023.0);

fn char(ch: i32) -> f32 {

    let fr = fract(floor(vec2<f32>(f32(ch), 15.999 - f32(ch) / 16.)) / 16.);
	let q = clamp(tp_debug, vec2<f32>(0.), vec2<f32>(1.)) / 16. + fr ;
	let inverted_q = vec2<f32>(q.x, 1. - q.y);

	// // There is aliasing on the characters
	// let f = textureSampleGrad(font_texture,
    //                  font_texture_sampler,
    //                  inverted_q,
    //                   vec2<f32>(1.0, 0.0),
    //                  vec2<f32>(0.0, 1.0));

	// using textureLoad without sampler
    let q1 = vec2<i32>(font_png_size_debug  * q );
	let y_inverted_q1 = vec2<i32>(q1.x, i32(font_png_size_debug.y) - q1.y);

	var f: vec4<f32> = textureLoad(font_texture, y_inverted_q1 , 0);

	// smoothing out the aliasing
	let dx = vec2<i32>(1, 0);
	let dy = vec2<i32>(0, 1);

	let fx1: vec4<f32> = textureLoad(font_texture, y_inverted_q1 + dx, 0);
	let fx2: vec4<f32> = textureLoad(font_texture, y_inverted_q1 - dx, 0);
	let fy1: vec4<f32> = textureLoad(font_texture, y_inverted_q1 + dy, 0);
	let fy2: vec4<f32> = textureLoad(font_texture, y_inverted_q1 - dy, 0);

	let rp = 0.25;
	f = f * rp + (1.0 - rp) * (fx1 + fx2 + fy1 + fy2) / 4.0 ;

	return f.x * (f.y + 0.3) * (f.z + 0.3) * 2.;
} 

fn SetTextPosition(x: f32, y: f32)  {
	tp_debug =  10. * uv_debug;
	tp_debug.x = tp_debug.x + 17. - x;
	tp_debug.y = tp_debug.y - 9.4 + y;
} 

fn SetTextPositionAbs(x: f32, y: f32)  {
	tp_debug.x = 10. * uv_debug.x - x;
	tp_debug.y = 10. * uv_debug.y - y;
} 

fn drawFract(value: ptr<function, f32>, digits:  ptr<function, i32>) -> f32 {
	var c: f32 = 0.;
	*value = fract(*value) * 10.;

	for (var ni: i32 = 1; ni < 60; ni = ni + 1) {
		c = c + (char(48 + i32(*value)));
		tp_debug.x = tp_debug.x - (0.5);
		*digits = *digits - (1);
		*value = fract(*value) * 10.;

		if (*digits <= 0 || *value == 0.) {		
            break;
        }
	}

	tp_debug.x = tp_debug.x - (0.5 * f32(*digits));
	return c;
} 

fn maxInt(a: i32, b: i32) -> i32 {
    var ret: i32;
    if (a > b) { ret = a; } else { ret = b; };
	return ret;
} 

fn drawInt(value: ptr<function, i32>,  minDigits: ptr<function, i32>) -> f32 {
	var c: f32 = 0.;
	if (*value < 0) {
		*value = -*value;
		if (*minDigits < 1) {		
			*minDigits = 1;
		} else { 
			*minDigits = *minDigits - 1;
		}
		c = c + (char(45));
		tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);

	}
	var fn2: i32 = *value;
	var digits: i32 = 1;

	for (var ni: i32 = 0; ni < 10; ni = ni + 1) {
		fn2 = fn2 / (10);
		if (fn2 == 0) {		break; }
		digits = digits + 1;
	}

	digits = maxInt(*minDigits, digits);
	tp_debug.x = tp_debug.x - (0.5 * f32(digits));

	for (var ni: i32 = 1; ni < 11; ni = ni + 1) {
		tp_debug.x = tp_debug.x + (0.5);
		c = c + (char(48 + *value % 10));
		*value = *value / (10);
		if (ni >= digits) {		break; }
	}

	tp_debug.x = tp_debug.x - (0.5 * f32(digits));
	return c;
} 

fn drawIntBackwards(value: ptr<function, i32>,  minDigits: ptr<function, i32>) -> f32 {
	var c: f32 = 0.;
	let original_value: i32 = *value;

	if (*value < 0) {
		*value = -*value;
		if (*minDigits < 1) {		
			*minDigits = 1;
		} else { 
			*minDigits = *minDigits - 1;
		}
		// tp_debug.x = tp_debug.x + (FONT_SPACE_DEBUG);
		// c = c + (char(45));
		

	}
	var fn2: i32 = *value;
	var digits: i32 = 1;

	for (var ni: i32 = 0; ni < 10; ni = ni + 1) {
		fn2 = fn2 / (10);
		if (fn2 == 0) {		break; }
		digits = digits + 1;
	}

	digits = maxInt(*minDigits, digits);
	// tp_debug.x = tp_debug.x - (0.5 * f32(digits));

	for (var ni: i32 = digits - 1; ni < 11; ni = ni - 1) {
		tp_debug.x = tp_debug.x + (0.5);
		c = c + (char(48 + *value % 10));
		*value = *value / (10);
		if (ni == 0) {		break; }
	}

	if (original_value < 0) {
		tp_debug.x = tp_debug.x + (FONT_SPACE_DEBUG);
		c = c + (char(45));
	}

	// tp_debug.x = tp_debug.x + (0.5 * f32(digits));
	return c;
} 

// fn drawFloat(value: ptr<function, f32>, prec: ptr<function, i32>, maxDigits: i32) -> f32 {
fn drawFloat(val: f32, prec: ptr<function, i32>, maxDigits: i32) -> f32 {
	// in case of 0.099999..., round up to 0.1000000
	var value = round(val * pow(10., f32(maxDigits))) / pow(10., f32(maxDigits));

	let tp_debugx: f32 = tp_debug.x - 0.5 * f32(maxDigits);
	var c: f32 = 0.;
	if (value < 0.) {
		c = char(45);
		value = -value;
	}
	tp_debug.x = tp_debug.x - (0.5);
    var ival = i32(value);

    var one: i32 = 1;

	c = c + (drawInt(&ival, &one));
	c = c + (char(46));
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);

    var frac_val = fract(value);
	c = c + (drawFract(&frac_val, prec));
	tp_debug.x = min(tp_debug.x, tp_debugx);

	return c;
}

fn drawFloat_f32(value:  f32) -> f32 {
    var two: i32 = 2;
	return drawFloat(value, &two, 5);
} 

fn drawFloat_f32_prec(value: f32, prec: ptr<function, i32>) -> f32 {
	return drawFloat(value, prec, 2);
} 

fn drawInt_i32_back(value: ptr<function, i32>) -> f32 {
    var one: i32 = 1;
	return drawIntBackwards(value, &one);
} 

fn drawInt_i32(value: ptr<function, i32>) -> f32 {
    var one: i32 = 1;
	return drawInt(value, &one);
} 





fn SetColor(red: f32, green: f32, blue: f32)  {
	drawColorDebug = vec3<f32>(red, green, blue);
} 

fn WriteFloat(fValue: f32, maxDigits: i32, decimalPlaces: ptr<function, i32>)  {

	// vColor = mix(vColor, drawColorDebug, drawFloat_f32_prec(fValue, decimalPlaces));
	vColor = mix(vColor, drawColorDebug, drawFloat(fValue, decimalPlaces, maxDigits));
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
;
} 

fn WriteFloatBox(
	fValue: f32, 
	maxDigits: i32, 
	decimalPlaces: i32, 
	alpha: f32
)  {
	var decs = decimalPlaces;
	vColor = mix(vColor, drawColorDebug, drawFloat(fValue, &decs, maxDigits) * alpha);
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
;
} 

fn WriteInteger(iValue: ptr<function, i32>)  {
	vColor = mix(vColor, drawColorDebug, drawInt_i32(iValue));
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);

} 

fn WriteIntegerBack(iValue: ptr<function, i32>)  {
	vColor = mix(vColor, drawColorDebug, drawInt_i32_back(iValue));
	tp_debug.x = tp_debug.x + (FONT_SPACE_DEBUG);

} 



fn WriteFPS()  {
	var fps: f32 = f32(uni.iSampleRate);
	SetColor(0.8, 0.6, 0.3);
	var max_digits_one = 1;
	WriteFloat(fps, 5, &max_digits_one);
	var c: f32 = 0.;
	c = c + (char(102));
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);

	c = c + (char(112));
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);

	c = c + (char(115));
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	// let c2 = smoothStep(0.0, 1.0, c );

	vColor = mix(vColor, drawColorDebug, c);
} 

fn WriteMousePos(mPos: vec2<f32>, y_pos: f32)  {
	let digits: i32 = 3;
	let radius: f32 =  uni.iResolution.x / 400.;
	if (uni.iMouse.z > 0.) { dotColor_debug = mpColorDebug; }
	let r: f32 = length(abs(mPos.xy) - pixelPosDebug) - radius;
	// vColor = vColor + (mix(vec3<f32>(0.), dotColor_debug, 1. - clamp(r, 0., 1.)));

	var max_digits_three: i32 = 3;
	var mposxi: i32 = i32(mPos.x);
	var mposyi: i32 = i32(mPos.y);

	var mposx: f32 = (mPos.x);
	var mposy: f32 = (mPos.y);


	let x_pos = align_debug.y - 1. * FONT_SPACE_DEBUG;
		
	SetTextPositionAbs(
		 x_pos,
		 y_pos,
	);

	drawColorDebug = myColorDebug;
	WriteIntegerBack(&mposyi);

	SetTextPositionAbs(
		 x_pos - 7. *  FONT_SPACE_DEBUG,
		 y_pos,
	);

	drawColorDebug = mxColorDebug;

	WriteIntegerBack(&mposxi);

} 


fn sdRoundedBox(p: vec2<f32>, b: vec2<f32>, r: vec4<f32>) -> f32 {
  var x = r.x;
  var y = r.y;
  x = select(r.z, r.x, p.x > 0.);
  y = select(r.w, r.y, p.x > 0.);
  x  = select(y, x, p.y > 0.);
  let q = abs(p) - b + x;
  return min(max(q.x, q.y), 0.) + length(max(q, vec2<f32>(0.))) - x;
}



fn WriteRGBAValues(
	location: vec2<i32>, 
	value: vec4<f32>, 
	screen_poz: vec2<f32>,
	alpha: f32,
 )  {
	let poz = screen_poz / uni.iResolution * 20. * vec2<f32>(aspect_debug, 1.0);
	let window_ajusted = uni.iResolution / vec2<f32>(960., 600.);

	let box_pos = vec2<f32>(align_debug.w, align_debug.x - FONT_SPACE_DEBUG ) / 10.;
	// let box_pos = mp;

	// // box location follows mouse position
	// let box_location = vec2<f32>(
	// 	uni.iMouse.x + 100. * window_ajusted.x /  ( aspect_debug / 1.6 ) , 
	// 	uni.iMouse.y - 48. * window_ajusted.y
	// );


	let box_location  = vec2<f32>(
		100. * window_ajusted.x /  ( aspect_debug / 1.6 ) , 
		uni.iResolution.y - 60. * window_ajusted.y,
	);
	
	let inverted_screen_poz = vec2<f32>(screen_poz.x,  -screen_poz.y) ; // / vec2<f32>(aspect_debug, 1.) ;

	let d_box = sdRoundedBox(
		 vec2<f32>(location) - box_location - inverted_screen_poz, 
		 vec2<f32>(73. /  ( aspect_debug / 1.6 ), 75.) * window_ajusted, 
		vec4<f32>(5.,5.,5.,5.)  * 5.0 
	);

	// let alpha = 0.225;
	let decimal_places = 3;
	SetColor(1., 1., 1.);
	var c: f32 = 0.;
	let lspace = 0.8;

	let bg_color = vec3<f32>(.8, .7, .9);
	vColor = mix( vColor, bg_color,  (1.0 -  step(0.0, d_box)) * alpha ); 

	// red
	SetTextPosition(
		10. *  (box_pos.x +1. + lspace) + poz.x, 
		10. * (-box_pos.y +1.) - 0.0 + poz.y
	) ;
	c = c + (char(114)); // r
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	c = c + (char(58)); // colon
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	WriteFloatBox(value.r, 3, decimal_places, alpha );

	// green
	SetTextPosition(
		10. *  ((box_pos.x +1. + lspace)) + poz.x, 
		10. * (-box_pos.y +1. ) + 1.0 + poz.y,
	) ;
	c = c + (char(103)); // g
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	c = c + (char(58)); // colon
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	WriteFloatBox(value.g, 3, decimal_places, alpha );

	// blue
	SetTextPosition(
		10. *  (box_pos.x +1. + lspace) + poz.x, 
		10. * (-box_pos.y +1. ) + 2.0 + poz.y,
		) ;
	c = c + (char(98)); // b
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	c = c + (char(58)); // colon
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	WriteFloatBox(value.b, 4, decimal_places, alpha );

	// alpha
	SetTextPosition(
		10. *  (box_pos.x +1. + lspace) + poz.x, 
		10. * (-box_pos.y +1. ) + 3.0 + poz.y,
	) ;
	c = c + (char(97)); // a
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	c = c + (char(58)); // colon
	tp_debug.x = tp_debug.x - (FONT_SPACE_DEBUG);
	WriteFloatBox(value.a, 4, decimal_places, alpha );

	vColor = mix(vColor, drawColorDebug, c * alpha);
}

fn sdSegment(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>) -> f32 {
    let pa = p - a;
    let ba = b - a;
    let h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    return length(pa - ba * h);
}

fn ring(pos: vec2<f32>, radius: f32, thick: f32) -> f32 {
	return mix(1., 0., smoothStep(thick, thick + 0.01, abs(length(uv_debug - pos) - radius)));
} 

fn sdCircle(p: vec2<f32>, c: vec2<f32>, r: f32) -> f32 {
    let d = length(p - c);
    return d - r;
}

fn draw_ring(location: vec2<i32>) {
	let mouse_click_poz = vec2<f32>(abs(uni.iMouse.z) , abs(uni.iMouse.w));

	let alpha = 0.75;
	let ring_dist = sdCircle(vec2<f32>(location) , mouse_click_poz, 2.3);
	let d = smoothStep(0.5, 1.5, abs(ring_dist - 1.));
	vColor = mix(vColor, headColorDebug,   (1. - d) * alpha );
}

fn draw_crossair(location: vec2<i32>)  {

	let start = 5.0;
	let end = 20.;
	let segment1 = sdSegment(
		vec2<f32>(location) - uni.iMouse.xy, 
		vec2<f32>(start, 0.), 
		vec2<f32>(end, 0.)
	);

	let segment2 = sdSegment(
		vec2<f32>(location) - uni.iMouse.xy, 
		vec2<f32>(-start, 0.), 
		vec2<f32>(-end, 0.)
	);

	let segment3 = sdSegment(
		vec2<f32>(location) - uni.iMouse.xy, 
		vec2<f32>(0., start), 
		vec2<f32>(0., end)
	);

	let segment4 = sdSegment(
		vec2<f32>(location) - uni.iMouse.xy, 
		vec2<f32>(0., -start), 
		vec2<f32>(0., -end)
	);

	var alpha = 0.75;
	if (uni.iMouse.z > 0.) {
		alpha = 1.0;
	}

	let d = smoothStep(0.5, 1.5, segment1);
	vColor = mix(vColor, headColorDebug, (1.0 -  d) * alpha );

	let d = smoothStep(0.5, 1.5, segment2);
	vColor = mix(vColor, headColorDebug, (1.0 -  d) * alpha );

	let d = smoothStep(0.5, 1.5, segment3);
	vColor = mix(vColor, headColorDebug, (1.0 -  d) * alpha );

	let d = smoothStep(0.5, 1.5, segment4);
	vColor = mix(vColor, headColorDebug, (1.0 -  d) * alpha );
}

fn show_debug_info(location: vec2<i32>, color: vec3<f32>) -> vec4<f32> {    
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );
    vColor = color;


	aspect_debug =  uni.iResolution.x /  uni.iResolution.y;

	let ratio: vec2<f32> = vec2<f32>(aspect_debug, 1.);
	pixelPosDebug = fragCoord.xy;
	// mousePosDebug = uni.iMouse.xy;
	uv_debug = (2. * fragCoord.xy /  uni.iResolution.xy - 1.) * ratio;

	align_debug = 10. * vec4<f32>(
		1.,      // North
		aspect_debug,  // East
		-1.,     // South
		-aspect_debug, // West
	);


	WriteMousePos(uni.iMouse.zw, align_debug.z + 2.0 * FONT_SPACE_DEBUG); // Click position
	WriteMousePos(uni.iMouse.xy, align_debug.z + 0.2 * FONT_SPACE_DEBUG); // Current mouse position

	var c: f32 = 0.;

	SetTextPositionAbs(
		 align_debug.y -      FONT_SPACE_DEBUG,
		 align_debug.x - 2. * FONT_SPACE_DEBUG,
	);

	SetColor(0.8, 0.8, 0.8);
	var resx = i32(uni.iResolution.x);
	var resy = i32(uni.iResolution.y);


	WriteIntegerBack(&resx);
	c = c + (char(28));
	tp_debug.x = tp_debug.x + 0. * (FONT_SPACE_DEBUG);
	WriteIntegerBack(&resy);


	SetTextPositionAbs(
		 align_debug.w - 1. * FONT_SPACE_DEBUG,
		 align_debug.z - 0. * FONT_SPACE_DEBUG,
	);

	WriteFPS();
	SetColor(0.9, 0.7, 0.8);

	let fragColor = vec4<f32>(vColor, 1.);

	let poz = vec2<f32>(0., uni.iResolution.y / 2.);
	
	// // RGBA probe labels follow mouse
	// let poz = vec2<f32>(uni.iMouse.x , uni.iResolution.y - uni.iMouse.y);
	
	let inverted_y_mouse_location = vec2<i32>(vec2<f32>(uni.iMouse.x, uni.iResolution.y - uni.iMouse.y));
	let value: vec4<f32> = textureLoad(texture, inverted_y_mouse_location);
	WriteRGBAValues(location, value, poz, 0.85);

	let inverted_y_mouseclick_location = vec2<i32>(vec2<f32>(abs(uni.iMouse.z), uni.iResolution.y - abs(uni.iMouse.w)));
	let value2: vec4<f32> = textureLoad(texture, inverted_y_mouseclick_location);
	WriteRGBAValues(location, value2, vec2<f32>(0.), 0.65);

	draw_crossair(location);

	draw_ring(location);

	let fragColor = vec4<f32>(vColor, 1.);

	

	return fragColor;
} 




// https://www.shadertoy.com/view/XsXSWS
// no licence

fn hash(p: vec2<f32>) -> vec2<f32> {
	var p_var = p;
	p_var = vec2<f32>(dot(p_var, vec2<f32>(127.1, 311.7)), dot(p_var, vec2<f32>(269.5, 183.3)));
	return -1. + 2. * fract(sin(p_var) * 43758.547);
} 

fn noise(p: vec2<f32>) -> f32 {
	let K1: f32 = 0.36602542;
	let K2: f32 = 0.21132487;
	let i: vec2<f32> = floor(p + (p.x + p.y) * K1);
	var a: vec2<f32> = p - i + (i.x + i.y) * K2;
	var o: vec2<f32>; 
    if (a.x > a.y) { o = vec2<f32>(1., 0.); } else { o = vec2<f32>(0., 1.); };
	let b: vec2<f32> = a - o + K2;
	var c: vec2<f32> = a - 1. + 2. * K2;
	let h: vec3<f32> = max(0.5 - vec3<f32>(dot(a, a), dot(b, b), dot(c, c)), vec3<f32>(0.));
	var n: vec3<f32> = h * h * h * h * vec3<f32>(dot(a, hash(i + 0.)), dot(b, hash(i + o)), dot(c, hash(i + 1.)));
	return dot(n, vec3<f32>(70.));
} 

fn fbm(uv_in: vec2<f32>) -> f32 {
	var f: f32;
    var uv = uv_in;
	let m: mat2x2<f32> = mat2x2<f32>(1.6, 1.2, -1.2, 1.6);
	f = 0.5 * noise(uv);
	uv = m * uv;
	f = f + (0.25 * noise(uv));
	uv = m * uv;
	f = f + (0.125 * noise(uv));
	uv = m * uv;
	f = f + (0.0625 * noise(uv));
	uv = m * uv;
	f = 0.5 + 0.5 * f;
	return f;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );
	let uv: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
	var q: vec2<f32> = uv;
	q.x = q.x * (5.);
	q.y = q.y * (2.);
	let strength: f32 = floor(q.x + 1.);
	let T3: f32 = max(3., 1.25 * strength) * uni.iTime;
	q.x = (q.x % 1.) - 0.5;
	q.y = q.y - (0.25);
	let n: f32 = fbm(strength * q - vec2<f32>(0., T3));
	let c: f32 = 1. - 16. * pow(max(0., length(q * vec2<f32>(1.8 + q.y * 1.5, 0.75)) - n * max(0., q.y + 0.25)), 1.2);
	var c1: f32 = n * c * (1.5 - pow(2.5 * uv.y, 4.));
	c1 = clamp(c1, 0., 1.);
	let col: vec3<f32> = vec3<f32>(1.5 * c1, 1.5 * c1 * c1 * c1, c1 * c1 * c1 * c1 * c1 * c1);
	let a: f32 = c * (1. - pow(uv.y, 3.));
	fragColor = vec4<f32>(mix(vec3<f32>(0.), col, a), 1.);

    textureStore(texture, y_inverted_location, fragColor);
} 



