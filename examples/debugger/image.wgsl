// Why are the charaacters so pixelated? 
// One possible reason is that we are in a compute shader and the textures are not
// filtered.

// type ivec2 = vec2<i32>;
// type v2 = vec2<f32>;

// let backColor: vec3<f32> = vec3<f32>(0.2, 0.2, 0.2);

// var<private> R: vec2<f32>;
// var<private> uv: vec2<f32> ;
// var<private> tp: vec2<f32> ;
// var<private> alignment: vec4<f32>; // north, east, south, west
// var<private> font_size: f32;
// var<private> dotColor: vec3<f32> = vec3<f32>(0.5, 0.5, 0.);
// var<private> drawColor: vec3<f32> = vec3<f32>(1., 1., 0.);
// var<private> vColor: vec3<f32> = backColor;
// var<private> aspect: f32 = 1.;
// var<private> pixelPos: vec2<f32> = vec2<f32>(0., 0.);
// var<private> mousePos: vec2<f32> = vec2<f32>(200., 200.);
// var<private> lp: vec2<f32> = vec2<f32>(0.5, 0.5);
// var<private> mp: vec2<f32> = vec2<f32>(0.5, 0.5);
// var<private> resolution: vec2<f32>;


// let FONT_SPACE: f32 = 0.5;
// let headColor: vec3<f32> = vec3<f32>(0.9, 0.6, 0.2);
// let mpColor: vec3<f32> = vec3<f32>(0.99, 0.99, 0.);
// let mxColor: vec3<f32> = vec3<f32>(1., 0., 0.);
// let myColor: vec3<f32> = vec3<f32>(0., 1., 0.);
// let font_png_size: vec2<f32> = vec2<f32>(1023.0, 1023.0);


// fn chara(ch: i32) -> f32 {

//     let fr = fract(floor(vec2<f32>(f32(ch), 15.999 - f32(ch) / 16.)) / 16.);
// 	let q = clamp(tp, v2(0.), v2(1.)) / 16. + fr ;
// 	let inverted_q = v2(q.x, 1. - q.y);

// 	// // There is aliasing on the charaacters
// 	// let f = textureSampleGrad(font_texture,
//     //                  font_texture_sampler,
//     //                  inverted_q,
//     //                   vec2<f32>(1.0, 0.0),
//     //                  vec2<f32>(0.0, 1.0));

// 	// using textureLoad without sampler
//     let q1 = ivec2(font_png_size  * q );
// 	let y_inverted_q1 = ivec2(q1.x, i32(font_png_size.y) - q1.y);

// 	var f: vec4<f32> = textureLoad(font_texture, y_inverted_q1 , 0);

// 	// smoothing out the aliasing
// 	let dx = vec2<i32>(1, 0);
// 	let dy = vec2<i32>(0, 1);

// 	let fx1: vec4<f32> = textureLoad(font_texture, y_inverted_q1 + dx, 0);
// 	let fx2: vec4<f32> = textureLoad(font_texture, y_inverted_q1 - dx, 0);
// 	let fy1: vec4<f32> = textureLoad(font_texture, y_inverted_q1 + dy, 0);
// 	let fy2: vec4<f32> = textureLoad(font_texture, y_inverted_q1 - dy, 0);

// 	let rp = 0.25;
// 	f = f * rp + (1.0 - rp) * (fx1 + fx2 + fy1 + fy2) / 4.0 ;

// 	return f.x * (f.y + 0.3) * (f.z + 0.3) * 2.;
// } 

// fn SetTextPosition(x: f32, y: f32)  {
// 	tp =  10. * uv;
// 	tp.x = tp.x + 17. - x;
// 	tp.y = tp.y - 9.4 + y;
// } 

// fn SetTextPositionAbs(x: f32, y: f32)  {
// 	tp.x = 10. * uv.x - x;
// 	tp.y = 10. * uv.y - y;
// } 

// fn drawFract(value: ptr<function, f32>, digits:  ptr<function, i32>) -> f32 {
// 	var c: f32 = 0.;
// 	*value = fract(*value) * 10.;

// 	for (var ni: i32 = 1; ni < 60; ni = ni + 1) {
// 		c = c + (chara(48 + i32(*value)));
// 		tp.x = tp.x - (0.5);
// 		*digits = *digits - (1);
// 		*value = fract(*value) * 10.;

// 		if (*digits <= 0 || *value == 0.) {		
//             break;
//         }
// 	}

// 	tp.x = tp.x - (0.5 * f32(*digits));
// 	return c;
// } 

// fn maxInt(a: i32, b: i32) -> i32 {
//     var ret: i32;
//     if (a > b) { ret = a; } else { ret = b; };
// 	return ret;
// } 

// fn drawInt(value: ptr<function, i32>,  minDigits: ptr<function, i32>) -> f32 {
// 	var c: f32 = 0.;
// 	if (*value < 0) {
// 		*value = -*value;
// 		if (*minDigits < 1) {		
// 			*minDigits = 1;
// 		} else { 
// 			*minDigits = *minDigits - 1;
// 		}
// 		c = c + (chara(45));
// 		tp.x = tp.x - (FONT_SPACE);

// 	}
// 	var fn2: i32 = *value;
// 	var digits: i32 = 1;

// 	for (var ni: i32 = 0; ni < 10; ni = ni + 1) {
// 		fn2 = fn2 / (10);
// 		if (fn2 == 0) {		break; }
// 		digits = digits + 1;
// 	}

// 	digits = maxInt(*minDigits, digits);
// 	tp.x = tp.x - (0.5 * f32(digits));

// 	for (var ni: i32 = 1; ni < 11; ni = ni + 1) {
// 		tp.x = tp.x + (0.5);
// 		c = c + (chara(48 + *value % 10));
// 		*value = *value / (10);
// 		if (ni >= digits) {		break; }
// 	}

// 	tp.x = tp.x - (0.5 * f32(digits));
// 	return c;
// } 

// fn drawIntBackwards(value: ptr<function, i32>,  minDigits: ptr<function, i32>) -> f32 {
// 	var c: f32 = 0.;
// 	let original_value: i32 = *value;

// 	if (*value < 0) {
// 		*value = -*value;
// 		if (*minDigits < 1) {		
// 			*minDigits = 1;
// 		} else { 
// 			*minDigits = *minDigits - 1;
// 		}
// 		// tp.x = tp.x + (FONT_SPACE);
// 		// c = c + (chara(45));
		

// 	}
// 	var fn2: i32 = *value;
// 	var digits: i32 = 1;

// 	for (var ni: i32 = 0; ni < 10; ni = ni + 1) {
// 		fn2 = fn2 / (10);
// 		if (fn2 == 0) {		break; }
// 		digits = digits + 1;
// 	}

// 	digits = maxInt(*minDigits, digits);
// 	// tp.x = tp.x - (0.5 * f32(digits));

// 	for (var ni: i32 = digits - 1; ni < 11; ni = ni - 1) {
// 		tp.x = tp.x + (0.5);
// 		c = c + (chara(48 + *value % 10));
// 		*value = *value / (10);
// 		if (ni == 0) {		break; }
// 	}

// 	if (original_value < 0) {
// 		tp.x = tp.x + (FONT_SPACE);
// 		c = c + (chara(45));
// 	}

// 	// tp.x = tp.x + (0.5 * f32(digits));
// 	return c;
// } 

// // fn drawFloat(value: ptr<function, f32>, prec: ptr<function, i32>, maxDigits: i32) -> f32 {
// fn drawFloat(val: f32, prec: ptr<function, i32>, maxDigits: i32) -> f32 {
// 	// in case of 0.099999..., round up to 0.1000000
// 	var value = round(val * pow(10., f32(maxDigits))) / pow(10., f32(maxDigits));

// 	let tpx: f32 = tp.x - 0.5 * f32(maxDigits);
// 	var c: f32 = 0.;
// 	if (value < 0.) {
// 		c = chara(45);
// 		value = -value;
// 	}
// 	tp.x = tp.x - (0.5);
//     var ival = i32(value);

//     var one: i32 = 1;

// 	c = c + (drawInt(&ival, &one));
// 	c = c + (chara(46));
// 	tp.x = tp.x - (FONT_SPACE);

//     var frac_val = fract(value);
// 	c = c + (drawFract(&frac_val, prec));
// 	tp.x = min(tp.x, tpx);

// 	return c;
// }

// fn drawFloat_f32(value:  f32) -> f32 {
//     var two: i32 = 2;
// 	return drawFloat(value, &two, 5);
// } 

// fn drawFloat_f32_prec(value: f32, prec: ptr<function, i32>) -> f32 {
// 	return drawFloat(value, prec, 2);
// } 

// fn drawInt_i32_back(value: ptr<function, i32>) -> f32 {
//     var one: i32 = 1;
// 	return drawIntBackwards(value, &one);
// } 

// fn drawInt_i32(value: ptr<function, i32>) -> f32 {
//     var one: i32 = 1;
// 	return drawInt(value, &one);
// } 





// fn SetColor(red: f32, green: f32, blue: f32)  {
// 	drawColor = vec3<f32>(red, green, blue);
// } 

// fn WriteFloat(fValue: f32, maxDigits: i32, decimalPlaces: ptr<function, i32>)  {

// 	// vColor = mix(vColor, drawColor, drawFloat_f32_prec(fValue, decimalPlaces));
// 	vColor = mix(vColor, drawColor, drawFloat(fValue, decimalPlaces, maxDigits));
// 	tp.x = tp.x - (FONT_SPACE);
// ;
// } 

// fn WriteFloatBox(
// 	fValue: f32, 
// 	maxDigits: i32, 
// 	decimalPlaces: i32, 
// 	alpha: f32
// )  {
// 	var decs = decimalPlaces;
// 	vColor = mix(vColor, drawColor, drawFloat(fValue, &decs, maxDigits) * alpha);
// 	tp.x = tp.x - (FONT_SPACE);
// ;
// } 

// fn WriteInteger(iValue: ptr<function, i32>)  {
// 	vColor = mix(vColor, drawColor, drawInt_i32(iValue));
// 	tp.x = tp.x - (FONT_SPACE);

// } 

// fn WriteIntegerBack(iValue: ptr<function, i32>)  {
// 	vColor = mix(vColor, drawColor, drawInt_i32_back(iValue));
// 	tp.x = tp.x + (FONT_SPACE);

// } 



// fn WriteFPS()  {
// 	var fps: f32 = f32(uni.iSampleRate);
// 	SetColor(0.8, 0.6, 0.3);
// 	var max_digits_one = 1;
// 	WriteFloat(fps, 5, &max_digits_one);
// 	var c: f32 = 0.;
// 	c = c + (chara(102));
// 	tp.x = tp.x - (FONT_SPACE);

// 	c = c + (chara(112));
// 	tp.x = tp.x - (FONT_SPACE);

// 	c = c + (chara(115));
// 	tp.x = tp.x - (FONT_SPACE);
// 	// let c2 = smoothstep(0.0, 1.0, c );

// 	vColor = mix(vColor, drawColor, c);
// } 

// fn WriteMousePos(mPos: vec2<f32>, y_pos: f32)  {
// 	let digits: i32 = 3;
// 	let radius: f32 = resolution.x / 400.;
// 	if (uni.iMouse.z > 0.) { dotColor = mpColor; }
// 	let r: f32 = length(abs(mPos.xy) - pixelPos) - radius;
// 	// vColor = vColor + (mix(vec3<f32>(0.), dotColor, 1. - clamp(r, 0., 1.)));

// 	var max_digits_three: i32 = 3;
// 	var mposxi: i32 = i32(mPos.x);
// 	var mposyi: i32 = i32(mPos.y);

// 	var mposx: f32 = (mPos.x);
// 	var mposy: f32 = (mPos.y);


// 	let x_pos = alignment.y - 1. * FONT_SPACE;
		
// 	SetTextPositionAbs(
// 		 x_pos,
// 		 y_pos,
// 	);

// 	drawColor = myColor;
// 	WriteIntegerBack(&mposyi);

// 	SetTextPositionAbs(
// 		 x_pos - 7. *  FONT_SPACE,
// 		 y_pos,
// 	);

// 	drawColor = mxColor;

// 	WriteIntegerBack(&mposxi);

// } 


// fn sdRoundedBox(p: vec2<f32>, b: vec2<f32>, r: vec4<f32>) -> f32 {
//   var x = r.x;
//   var y = r.y;
//   x = select(r.z, r.x, p.x > 0.);
//   y = select(r.w, r.y, p.x > 0.);
//   x  = select(y, x, p.y > 0.);
//   let q = abs(p) - b + x;
//   return min(max(q.x, q.y), 0.) + length(max(q, vec2<f32>(0.))) - x;
// }



// fn WriteRGBAValues(
// 	location: vec2<i32>, 
// 	value: vec4<f32>, 
// 	screen_poz: vec2<f32>,
// 	alpha: f32,
//  )  {
// 	let poz = screen_poz / uni.iResolution * 20. * vec2<f32>(aspect, 1.0);
// 	let window_ajusted = uni.iResolution / v2(960., 600.);

// 	let box_pos = vec2<f32>(alignment.w, alignment.x - FONT_SPACE ) / 10.;
// 	// let box_pos = mp;

// 	// // box location follows mouse position
// 	// let box_location = v2(
// 	// 	uni.iMouse.x + 100. * window_ajusted.x /  ( aspect / 1.6 ) , 
// 	// 	uni.iMouse.y - 48. * window_ajusted.y
// 	// );


// 	let box_location  = v2(
// 		100. * window_ajusted.x /  ( aspect / 1.6 ) , 
// 		uni.iResolution.y - 60. * window_ajusted.y,
// 	);
	
// 	let inverted_screen_poz = vec2<f32>(screen_poz.x,  -screen_poz.y) ; // / vec2<f32>(aspect, 1.) ;

// 	let d_box = sdRoundedBox(
// 		 vec2<f32>(location) - box_location - inverted_screen_poz, 
// 		 vec2<f32>(73. /  ( aspect / 1.6 ), 75.) * window_ajusted, 
// 		vec4<f32>(5.,5.,5.,5.)  * 5.0 
// 	);

// 	// let alpha = 0.225;
// 	let decimal_places = 3;
// 	SetColor(1., 1., 1.);
// 	var c: f32 = 0.;
// 	let lspace = 0.8;

// 	let bg_color = vec3<f32>(.8, .7, .9);
// 	vColor = mix( vColor, bg_color,  (1.0 -  step(0.0, d_box)) * alpha ); 

// 	// red
// 	SetTextPosition(
// 		10. *  (box_pos.x +1. + lspace) + poz.x, 
// 		10. * (-box_pos.y +1.) - 0.0 + poz.y
// 	) ;
// 	c = c + (chara(114)); // r
// 	tp.x = tp.x - (FONT_SPACE);
// 	c = c + (chara(58)); // colon
// 	tp.x = tp.x - (FONT_SPACE);
// 	WriteFloatBox(value.r, 3, decimal_places, alpha );

// 	// green
// 	SetTextPosition(
// 		10. *  ((box_pos.x +1. + lspace)) + poz.x, 
// 		10. * (-box_pos.y +1. ) + 1.0 + poz.y,
// 	) ;
// 	c = c + (chara(103)); // g
// 	tp.x = tp.x - (FONT_SPACE);
// 	c = c + (chara(58)); // colon
// 	tp.x = tp.x - (FONT_SPACE);
// 	WriteFloatBox(value.g, 3, decimal_places, alpha );

// 	// blue
// 	SetTextPosition(
// 		10. *  (box_pos.x +1. + lspace) + poz.x, 
// 		10. * (-box_pos.y +1. ) + 2.0 + poz.y,
// 		) ;
// 	c = c + (chara(98)); // b
// 	tp.x = tp.x - (FONT_SPACE);
// 	c = c + (chara(58)); // colon
// 	tp.x = tp.x - (FONT_SPACE);
// 	WriteFloatBox(value.b, 4, decimal_places, alpha );

// 	// alpha
// 	SetTextPosition(
// 		10. *  (box_pos.x +1. + lspace) + poz.x, 
// 		10. * (-box_pos.y +1. ) + 3.0 + poz.y,
// 	) ;
// 	c = c + (chara(97)); // a
// 	tp.x = tp.x - (FONT_SPACE);
// 	c = c + (chara(58)); // colon
// 	tp.x = tp.x - (FONT_SPACE);
// 	WriteFloatBox(value.a, 4, decimal_places, alpha );

// 	vColor = mix(vColor, drawColor, c * alpha);
// }

// fn sdSegment(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>) -> f32 {
//     let pa = p - a;
//     let ba = b - a;
//     let h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
//     return length(pa - ba * h);
// }

// fn ring(pos: vec2<f32>, radius: f32, thick: f32) -> f32 {
// 	return mix(1., 0., smoothstep(thick, thick + 0.01, abs(length(uv - pos) - radius)));
// } 

// fn sdCircle(p: vec2<f32>, c: vec2<f32>, r: f32) -> f32 {
//     let d = length(p - c);
//     return d - r;
// }

// fn draw_ring(location: vec2<i32>) {
// 	let mouse_click_poz = vec2<f32>(abs(uni.iMouse.z) , abs(uni.iMouse.w));

// 	let alpha = 0.75;
// 	let ring_dist = sdCircle(vec2<f32>(location) , mouse_click_poz, 2.3);
// 	let d = smoothstep(0.5, 1.5, abs(ring_dist - 1.));
// 	vColor = mix(vColor, headColor,   (1. - d) * alpha );
// }

// fn draw_crossair(location: vec2<i32>)  {

// 	let start = 5.0;
// 	let end = 20.;
// 	let segment1 = sdSegment(
// 		vec2<f32>(location) - uni.iMouse.xy, 
// 		vec2<f32>(start, 0.), 
// 		vec2<f32>(end, 0.)
// 	);

// 	let segment2 = sdSegment(
// 		vec2<f32>(location) - uni.iMouse.xy, 
// 		vec2<f32>(-start, 0.), 
// 		vec2<f32>(-end, 0.)
// 	);

// 	let segment3 = sdSegment(
// 		vec2<f32>(location) - uni.iMouse.xy, 
// 		vec2<f32>(0., start), 
// 		vec2<f32>(0., end)
// 	);

// 	let segment4 = sdSegment(
// 		vec2<f32>(location) - uni.iMouse.xy, 
// 		vec2<f32>(0., -start), 
// 		vec2<f32>(0., -end)
// 	);

// 	var alpha = 0.75;
// 	if (uni.iMouse.z > 0.) {
// 		alpha = 1.0;
// 	}

// 	let d = smoothstep(0.5, 1.5, segment1);
// 	vColor = mix(vColor, headColor, (1.0 -  d) * alpha );

// 	let d = smoothstep(0.5, 1.5, segment2);
// 	vColor = mix(vColor, headColor, (1.0 -  d) * alpha );

// 	let d = smoothstep(0.5, 1.5, segment3);
// 	vColor = mix(vColor, headColor, (1.0 -  d) * alpha );

// 	let d = smoothstep(0.5, 1.5, segment4);
// 	vColor = mix(vColor, headColor, (1.0 -  d) * alpha );
// }

// fn show_debug_info(location: vec2<i32>) -> vec4<f32> {    


// 	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

// 	resolution = uni.iResolution.xy;
// 	aspect = resolution.x / resolution.y;

// 	let ratio: vec2<f32> = vec2<f32>(aspect, 1.);
// 	pixelPos = fragCoord.xy;
// 	mousePos = uni.iMouse.xy;
// 	uv = (2. * fragCoord.xy / resolution.xy - 1.) * ratio;

// 	alignment = 10. * vec4<f32>(
// 		1.,      // North
// 		aspect,  // East
// 		-1.,     // South
// 		-aspect, // West
// 	);

// 	mp = (2. * abs(uni.iMouse.xy) / resolution.xy - 1.) * ratio; // Mouse position in uv coordinates

// 	WriteMousePos(uni.iMouse.zw, alignment.z + 2.0 * FONT_SPACE); // Click position
// 	WriteMousePos(uni.iMouse.xy, alignment.z + 0.2 * FONT_SPACE); // Current mouse position

// 	var c: f32 = 0.;

// 	SetTextPositionAbs(
// 		 alignment.y -      FONT_SPACE,
// 		 alignment.x - 2. * FONT_SPACE,
// 	);

// 	SetColor(0.8, 0.8, 0.8);
// 	var resx = i32(uni.iResolution.x);
// 	var resy = i32(uni.iResolution.y);


// 	WriteIntegerBack(&resx);
// 	c = c + (chara(28));
// 	tp.x = tp.x + 0. * (FONT_SPACE);
// 	WriteIntegerBack(&resy);


// 	SetTextPositionAbs(
// 		 alignment.w - 1. * FONT_SPACE,
// 		 alignment.z - 0. * FONT_SPACE,
// 	);

// 	WriteFPS();
// 	SetColor(0.9, 0.7, 0.8);

// 	let fragColor = vec4<f32>(vColor, 1.);

// 	let poz = vec2<f32>(0., uni.iResolution.y / 2.);
	
// 	// // RGBA probe labels follow mouse
// 	// let poz = vec2<f32>(uni.iMouse.x , uni.iResolution.y - uni.iMouse.y);
	
// 	let inverted_y_mouse_location = vec2<i32>(v2(uni.iMouse.x, uni.iResolution.y - uni.iMouse.y));
// 	let value: vec4<f32> = textureLoad(texture, inverted_y_mouse_location);
// 	WriteRGBAValues(location, value, poz, 0.5);

// 	let inverted_y_mouseclick_location = vec2<i32>(v2(abs(uni.iMouse.z), uni.iResolution.y - abs(uni.iMouse.w)));
// 	let value2: vec4<f32> = textureLoad(texture, inverted_y_mouseclick_location);
// 	WriteRGBAValues(location, value2, vec2<f32>(0.), 0.25);

// 	draw_crossair(location);

// 	draw_ring(location);

// 	let fragColor = vec4<f32>(vColor, 1.);

// 	return fragColor;
// } 

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
	
	let y_inverted_location = vec2<i32>((location.x), i32(uni.iResolution.y) - (location.y));


	let fragColor = show_debug_info(location, vec3<f32>(0.5, 0.2, 0.1));
	textureStore(texture, y_inverted_location, toLinear(fragColor));
}

