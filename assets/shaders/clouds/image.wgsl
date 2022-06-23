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




// Sample Pinning
// https://www.shadertoy.com/view/XdfXzn
// MIT License

var<private> STRUCTURED: bool;
var<private> sundir: vec3<f32>;
fn noise(x: vec3<f32>) -> f32 {
	var p: vec3<f32> = floor(x);
	var f: vec3<f32> = fract(x);
	f = f * f * (3. - 2. * f);
	let uv: vec2<f32> = p.xy + vec2<f32>(37., 17.) * p.z + f.xy;
	// let rg: vec2<f32> = textureLod(iChannel0, (uv + 0.5) / 256., 0.).yx;
    // let rg: vec2<f32> = textureLoad(rgba_noise_256_texture, vec2<i32>((uv + 0.5) ), 0).yx;

    let rg: vec2<f32> = textureSampleLevel(
        rgba_noise_256_texture,
        rgba_noise_256_texture_sampler,
        (uv + 0.5) / 256.,
        0.
    ).yx ;

	return mix(rg.x, rg.y, f.z);
} 

fn map(p: vec3<f32>) -> vec4<f32> {
	var d: f32 = 0.1 + 0.8 * sin(0.6 * p.z) * sin(0.5 * p.x) - p.y;
	var q: vec3<f32> = p;
	var f: f32;
	f = 0.5 * noise(q);
	q = q * 2.02;
	f = f + (0.25 * noise(q));
	q = q * 2.03;
	f = f + (0.125 * noise(q));
	q = q * 2.01;
	f = f + (0.0625 * noise(q));
	d = d + (2.75 * f);
	d = clamp(d, 0., 1.);
	var res: vec4<f32> = vec4<f32>(d);
	var col: vec3<f32> = 1.15 * vec3<f32>(1., 0.95, 0.8);
	col = col + (vec3<f32>(1., 0., 0.) * exp2(res.x * 10. - 10.));
	var resxyz = res.xyz;
	resxyz = mix(col, vec3<f32>(0.7, 0.7, 0.7), res.x);
	res.x = resxyz.x;
	res.y = resxyz.y;
	res.z = resxyz.z;
	return res;
} 

fn mysign(x: f32) -> f32 {

	if (x < 0.) { return -1.; } else { return 1.; };
} 

fn mysign2(x: vec2<f32>) -> vec2<f32> {
    var x2: vec2<f32>;
    if (x.x < 0.) { x2.x = -1.; } else { x2.x =1.; };
    if (x.y < 0.) { x2.y = -1.; } else { x2.y = 1.; }
	return x2;
} 

fn SetupSampling(t: ptr<function, vec2<f32>>, dt: ptr<function, vec2<f32>>, wt: ptr<function, vec2<f32>>, ro: vec3<f32>, rd: vec3<f32>)  {
	var rd_var = rd;
	if (!STRUCTURED) {
		(*dt) = vec2<f32>(1., 1.);
		(*t) = (*dt);
		(*wt) = vec2<f32>(0.5, 0.5);
		return ;
	}
	var n0: vec3<f32>; 
    if (abs(rd_var.x) > abs(rd_var.z)) { n0 = vec3<f32>(1., 0., 0.); } else { n0 = vec3<f32>(0., 0., 1.); };

	var n1: vec3<f32> = vec3<f32>(mysign(rd_var.x * rd_var.z), 0., 1.);
	let ln: vec2<f32> = vec2<f32>(length(n0), length(n1));
	n0 = n0 / (ln.x);
	n1 = n1 / (ln.y);
	let ndotro: vec2<f32> = vec2<f32>(dot(ro, n0), dot(ro, n1));
	var ndotrd: vec2<f32> = vec2<f32>(dot(rd_var, n0), dot(rd_var, n1));
	let period: vec2<f32> = ln * 1.;
	(*dt) = period / abs(ndotrd);
	let dist: vec2<f32> = abs(ndotro / ndotrd);
	(*t) = -mysign2(ndotrd) * (ndotro % period) / abs(ndotrd);

	if (ndotrd.x > 0.) { (*t).x = (*t).x + ((*dt).x); }
	if (ndotrd.y > 0.) { (*t).y = (*t).y + ((*dt).y); }
	let minperiod: f32 = 1.;
	let maxperiod: f32 = sqrt(2.) * 1.;
	(*wt) = smoothStep(vec2<f32>(maxperiod), vec2<f32>(minperiod), (*dt) / ln);
	(*wt) = (*wt) / ((*wt).x + (*wt).y);
} 

fn raymarch(ro: vec3<f32>, rd: vec3<f32>) -> vec4<f32> {
	var sum: vec4<f32> = vec4<f32>(0., 0., 0., 0.);
	var t: vec2<f32>;
	var dt: vec2<f32>;
	var wt: vec2<f32>;
	SetupSampling(&t, &dt, &wt, ro, rd);
	let f: f32 = 0.6;
	let endFade: f32 = f * f32(40.) * 1.;
	let startFade: f32 = 0.8 * endFade;

	for (var i: i32 = 0; i < 40; i = i + 1) {
		if (sum.a > 0.99) {		continue;
 }
		var data: vec4<f32>;
        if (t.x < t.y) { data = vec4<f32>(t.x, wt.x, dt.x, 0.); } else { data = vec4<f32>(t.y, wt.y, 0., dt.y); };

		let pos: vec3<f32> = ro + data.x * rd;
		var w: f32 = data.y;
		t = t + (data.zw);
		w = w * (smoothStep(endFade, startFade, data.x));
		var col: vec4<f32> = map(pos);
		let dif: f32 = clamp((col.w - map(pos + 0.6 * sundir).w) / 0.6, 0., 1.);
		let lin: vec3<f32> = vec3<f32>(0.51, 0.53, 0.63) * 1.35 + 0.55 * vec3<f32>(0.85, 0.57, 0.3) * dif;
		var colxyz = col.xyz;
	colxyz = col.xyz * (lin);
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;
		var colxyz = col.xyz;
	colxyz = col.xyz * (col.xyz);
	col.x = colxyz.x;
	col.y = colxyz.y;
	col.z = colxyz.z;
		col.a = col.a * (0.75);
		var colrgb = col.rgb;
	colrgb = col.rgb * (col.a);
	col.r = colrgb.r;
	col.g = colrgb.g;
	col.b = colrgb.b;
		sum = sum + (col * (1. - sum.a) * w);
	}

	var sumxyz = sum.xyz;
	sumxyz = sum.xyz / (0.001 + sum.w);
	sum.x = sumxyz.x;
	sum.y = sumxyz.y;
	sum.z = sumxyz.z;
	return clamp(sum, vec4<f32>(0.), vec4<f32>(1.));
} 

fn sky(rd: vec3<f32>) -> vec3<f32> {
	var col: vec3<f32> = vec3<f32>(0.);
	let hort: f32 = 1. - clamp(abs(rd.y), 0., 1.);
	col = col + (0.5 * vec3<f32>(0.99, 0.5, 0.) * exp2(hort * 8. - 8.));
	col = col + (0.1 * vec3<f32>(0.5, 0.9, 1.) * exp2(hort * 3. - 3.));
	col = col + (0.55 * vec3<f32>(0.6, 0.6, 0.9));
	let sun: f32 = clamp(dot(sundir, rd), 0., 1.);
	col = col + (0.2 * vec3<f32>(1., 0.3, 0.2) * pow(sun, 2.));
	col = col + (0.5 * vec3<f32>(1., 0.9, 0.9) * exp2(sun * 650. - 650.));
	col = col + (0.1 * vec3<f32>(1., 1., 0.1) * exp2(sun * 100. - 100.));
	col = col + (0.3 * vec3<f32>(1., 0.7, 0.) * exp2(sun * 50. - 50.));
	col = col + (0.5 * vec3<f32>(1., 0.3, 0.05) * exp2(sun * 10. - 10.));
	let ax: f32 = atan2(rd.y, length(rd.xz)) / 1.;
	let ay: f32 = atan2(rd.z, rd.x) / 2.;
    
	var st: f32 = textureLoad(rgba_noise_256_texture, vec2<i32>(vec2<f32>(ax, ay) * 255.), 0 ).x;

	let st2: f32 = textureLoad(rgba_noise_256_texture, vec2<i32>(0.25 * vec2<f32>(ax, ay) * 255.), 0 ).x;
	st = st * (st2);
	st = smoothStep(0.65, 0.9, st);
	col = mix(col, col + 1.8 * st, clamp(1. - 1.1 * length(col), 0., 1.));
	return col;
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

	var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	STRUCTURED = uni.iMouse.z <= 0.;
	sundir = normalize(vec3<f32>(-1., 0., -1.));
	let q: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
	var p: vec2<f32> = -1. + 2. * q;
	p.x = p.x * (uni.iResolution.x / uni.iResolution.y);
	let mo: vec2<f32> = -1. + 2. * uni.iMouse.xy / uni.iResolution.xy;
	let lookDir: vec3<f32> = vec3<f32>(cos(0.53 * uni.iTime), 0., sin(uni.iTime));
	let camVel: vec3<f32> = vec3<f32>(-20., 0., 0.);
	let ro: vec3<f32> = vec3<f32>(0., 1.5, 0.) + uni.iTime * camVel;
	let ta: vec3<f32> = ro + lookDir;
	let ww: vec3<f32> = normalize(ta - ro);
	let uu: vec3<f32> = normalize(cross(vec3<f32>(0., 1., 0.), ww));
	let vv: vec3<f32> = normalize(cross(ww, uu));
	let fov: f32 = 1.;
	let rd: vec3<f32> = normalize(fov * p.x * uu + fov * 1.2 * p.y * vv + 1.5 * ww);
	var clouds: vec4<f32> = raymarch(ro, rd);
	var col: vec3<f32> = clouds.xyz;
	if (clouds.w <= 0.99) { col = mix(sky(rd), col, clouds.w); }
	col = clamp(col, vec3<f32>(0.), vec3<f32>(1.));
	col = smoothStep(vec3<f32>(0.), vec3<f32>(1.), col);
	col = col * (pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), 0.12));
	// (*fragColor) = vec4<f32>(col, 1.);
    textureStore(texture, y_inverted_location, vec4<f32>(col, 1.));

    let test: vec4<f32> = textureSampleLevel(
        rgba_noise_256_texture,
        rgba_noise_256_texture_sampler,
        vec2<f32>(location) / R * 2.0,
        0.
    ) ;

    // textureStore(texture, y_inverted_location, test);


} 




    



// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
//     let R: vec2<f32> = uni.iResolution.xy;
//     let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

// 	if (uni.iMouse.z > 0.) { useNewApproach = false; }
// 	let q: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
// 	var p: vec2<f32> = -1. + 2. * q;
// 	p.x = p.x * (uni.iResolution.x / uni.iResolution.y);
// 	let mo: vec2<f32> = -1. + 2. * uni.iMouse.xy / uni.iResolution.xy;
// 	let ro: vec3<f32> = vec3<f32>(0., 1.9, 0.) + uni.iTime * camVel;
// 	let ta: vec3<f32> = ro + lookDir;
// 	let ww: vec3<f32> = normalize(ta - ro);
// 	let uu: vec3<f32> = normalize(cross(vec3<f32>(0., 1., 0.), ww));
// 	let vv: vec3<f32> = normalize(cross(ww, uu));
// 	let rd: vec3<f32> = normalize(p.x * uu + 1.2 * p.y * vv + 1.5 * ww);
// 	var col: vec3<f32> = sky(rd);
// 	let rd_layout: vec3<f32> = rd / mix(dot(rd, ww), 1., samplesCurvature);
// 	let clouds: vec4<f32> = raymarch(ro, rd_layout);
// 	col = mix(col, clouds.xyz, clouds.w);
// 	col = clamp(col, 0., 1.);
// 	col = smoothStep(0., 1., col);
// 	col = col * (pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), 0.12));
// 	// (*fragColor) = vec4<f32>(col, 1.);
//     textureStore(texture, y_inverted_location, vec4<f32>(col, 1.));

    
// } 

