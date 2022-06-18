type ivec2 = vec2<i32>;
type v2 = vec2<f32>;
let FONT_SPACE: f32 = 0.5;
var<private> uv: vec2<f32> ;
var<private> tp: vec2<f32> ;
var<private> R: vec2<f32>;
let font_texture_size: vec2<f32> = vec2<f32>(1024.0, 1024.0);

fn char(ch: i32) -> f32 {

    let fr = fract(floor(vec2<f32>(f32(ch), 15.999 - f32(ch) / 16.)) / 16.);
    let q = ivec2(font_texture_size * 1. * (clamp(tp, v2(0.), v2(1.)) / 16. + fr ));
	let y_inverted_q = ivec2(q.x, i32(font_texture_size.y) - q.y);
	let f: vec4<f32> = textureLoad(font_texture, y_inverted_q , 0);

	return f.x * (f.y + 0.3) * (f.z + 0.3) * 2.;
} 

fn SetTextPosition(x: f32, y: f32)  {
	tp = 10. * uv;
	tp.x = tp.x + 17. - x;
	tp.y = tp.y - 9.4 + y;
} 

fn drawFract(value: ptr<function, f32>, digits:  ptr<function, i32>) -> f32 {
	var c: f32 = 0.;
	*value = fract(*value) * 10.;

	for (var ni: i32 = 1; ni < 60; ni = ni + 1) {
		c = c + (char(48 + i32(*value)));
		tp.x = tp.x - (0.5);
		*digits = *digits - (1);
		*value = fract(*value) * 10.;

		if (*digits <= 0 || *value == 0.) {		
            break;
        }
	}

	tp.x = tp.x - (0.5 * f32(*digits));
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
		if (*minDigits < 1) {		*minDigits = 1;
		} else { 
		*minDigits = *minDigits - 1;
		}
		c = c + (char(45));
		tp.x = tp.x - (FONT_SPACE);

	}
	var fn2: i32 = *value;
	var digits: i32 = 1;

	for (var ni: i32 = 0; ni < 10; ni = ni + 1) {
		fn2 = fn2 / (10);
		if (fn2 == 0) {		break; }
		digits = digits + 1;
	}

	digits = maxInt(*minDigits, digits);
	tp.x = tp.x - (0.5 * f32(digits));

	for (var ni: i32 = 1; ni < 11; ni = ni + 1) {
		tp.x = tp.x + (0.5);
		c = c + (char(48 + *value % 10));
		*value = *value / (10);
		if (ni >= digits) {		break; }
	}

	tp.x = tp.x - (0.5 * f32(digits));
	return c;
} 

// fn drawFloat(value: ptr<function, f32>, prec: ptr<function, i32>, maxDigits: i32) -> f32 {
fn drawFloat(value: ptr<function, f32>, prec: ptr<function, i32>, maxDigits: i32) -> f32 {
	let tpx: f32 = tp.x - 0.5 * f32(maxDigits);
	var c: f32 = 0.;
	if (*value < 0.) {
		c = char(45);
		*value = -*value;
	}
	tp.x = tp.x - (0.5);
    var ival = i32(*value);

    var one: i32 = 1;

	c = c + (drawInt(&ival, &one));
	c = c + (char(46));
	tp.x = tp.x - (FONT_SPACE);

    var frac_val = fract(*value);
	c = c + (drawFract(&frac_val, prec));
	tp.x = min(tp.x, tpx);
	return c;
}

fn drawFloat_f32(value: ptr<function, f32>) -> f32 {
    var two: i32 = 2;
	return drawFloat(value, &two, 5);
} 

fn drawFloat_f32_prec(value: ptr<function, f32>, prec: ptr<function, i32>) -> f32 {
	return drawFloat(value, prec, 2);
} 

fn drawInt_i32(value: ptr<function, i32>) -> f32 {
    var one: i32 = 1;
	return drawInt(value, &one);
} 

fn drawLineSegment(A: vec2<f32>, B: vec2<f32>, r: f32) -> f32 {
	let g: vec2<f32> = B - A;
	let h: vec2<f32> = uv - A;
	let d: f32 = length(h - g * clamp(dot(g, h) / dot(g, g), 0., 1.));
	return smoothStep(r, 0.5 * r, d);
} 

fn circle(pos: vec2<f32>, radius: f32, halo: f32) -> f32 {
	return clamp(halo * (radius - length(uv - pos)), 0., 1.);
} 

let headColor: vec3<f32> = vec3<f32>(0.9, 0.6, 0.2);
let backColor: vec3<f32> = vec3<f32>(0.15, 0.1, 0.1);
let mpColor: vec3<f32> = vec3<f32>(0.99, 0.99, 0.);
let mxColor: vec3<f32> = vec3<f32>(1., 0., 0.);
let myColor: vec3<f32> = vec3<f32>(0., 1., 0.);
var<private> dotColor: vec3<f32> = vec3<f32>(0.5, 0.5, 0.);
var<private> drawColor: vec3<f32> = vec3<f32>(1., 1., 0.);
var<private> vColor: vec3<f32> = backColor;
var<private> aspect: f32 = 1.;
var<private> pixelPos: vec2<f32> = vec2<f32>(0., 0.);
var<private> mousePos: vec2<f32> = vec2<f32>(200., 200.);
var<private> lp: vec2<f32> = vec2<f32>(0.5, 0.5);
var<private> mp: vec2<f32> = vec2<f32>(0.5, 0.5);
var<private> resolution: vec2<f32>;

fn SetColor(red: f32, green: f32, blue: f32)  {
	drawColor = vec3<f32>(red, green, blue);
} 

fn WriteFloat(fValue: ptr<function, f32>, maxDigits: i32, decimalPlaces: ptr<function, i32>)  {
	vColor = mix(vColor, drawColor, drawFloat_f32_prec(fValue, decimalPlaces));
	tp.x = tp.x - (FONT_SPACE);
;
} 

fn WriteInteger(iValue: ptr<function, i32>)  {
	vColor = mix(vColor, drawColor, drawInt_i32(iValue));
	tp.x = tp.x - (FONT_SPACE);

} 

// TODO: implement date in common uniform
fn WriteDate()  {
	// var c: f32 = 0.;
    // var datex:  i32 = i32(uni.iDate.x);
	// c = c + (drawInt_i32(&datex));
	// c = c + (char(45));
	// tp.x = tp.x - (FONT_SPACE);

    // var datey: i32 = i32(uni.iDate.y + 1.);
	// c = c + (drawInt_i32(&datey));
	// c = c + (char(45));
	// tp.x = tp.x - (FONT_SPACE);

    // var datez: i32 = i32(uni.iDate.z);
	// c = c + (drawInt_i32(&datez));
	// tp.x = tp.x - (FONT_SPACE);
	// vColor = mix(vColor, drawColor, c);
} 

// TODO: implement date in common uniform
fn WriteTime()  {
// 	var c: f32 = 0.;
// 	c = c + (drawInt(i32(mod(uni.iDate.w / 3600., 24.))));
// 	c = c + (char(58));
// 	tp.x = tp.x - (FONT_SPACE);
// ;
// 	c = c + (drawInt(i32(mod(uni.iDate.w / 60., 60.)), 2));
// 	c = c + (char(58));
// 	tp.x = tp.x - (FONT_SPACE);
// ;
// 	c = c + (drawInt(i32(mod(uni.iDate.w, 60.)), 2));
// 	tp.x = tp.x - (FONT_SPACE);
// 	vColor = mix(vColor, drawColor, c);
} 

fn WriteFPS()  {
	var fps: f32 = f32(uni.iSampleRate);
	SetColor(0.8, 0.6, 0.3);
	var max_digits_one = 1;
	WriteFloat(&fps, 6, &max_digits_one);
	var c: f32 = 0.;
	c = c + (char(102));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(112));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(115));
	tp.x = tp.x - (FONT_SPACE);

	vColor = mix(vColor, drawColor, c);
} 

fn WriteMousePos(ytext: f32, mPos: vec2<f32>)  {
	let digits: i32 = 3;
	let radius: f32 = resolution.x / 200.;
	if (uni.iMouse.z > 0.) { dotColor = mpColor; }
	let r: f32 = length(abs(mPos.xy) - pixelPos) - radius;
	vColor = vColor + (mix(vec3<f32>(0.), dotColor, 1. - clamp(r, 0., 1.)));
	SetTextPosition(1., ytext);
	var max_digits_three: i32 = 3;
	var mposxi: i32 = i32(mPos.x);
	var mposyi: i32 = i32(mPos.y);

	var mposx: f32 = (mPos.x);
	var mposy: f32 = (mPos.y);
	if (ytext == 7.) {
		drawColor = mxColor;
		
		WriteFloat(&mposx, 6, &max_digits_three);
		tp.x = tp.x - (FONT_SPACE);

		drawColor = myColor;
		WriteFloat(&mposy, 6, &max_digits_three);
	} else { 

		drawColor = mxColor;
		
		WriteInteger(&mposxi);
		tp.x = tp.x - (FONT_SPACE);
		
		
		drawColor = myColor;
		WriteInteger(&mposyi);
	}
} 

fn WriteText1()  {
	SetTextPosition(1., 1.);
	var c: f32 = 0.;
	c = c + (char(28));
	tp.x = tp.x - (FONT_SPACE);

	tp.x = tp.x - (FONT_SPACE);
	c = c + (char(68));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(97));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(116));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(97));
	tp.x = tp.x - (FONT_SPACE);

	tp.x = tp.x - (FONT_SPACE);
	c = c + (char(50));
	tp.x = tp.x - (FONT_SPACE);

	tp.x = tp.x - (FONT_SPACE);
	tp.x = tp.x - (FONT_SPACE);
	c = c + (char(118));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(49));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(46));
	tp.x = tp.x - (FONT_SPACE);

	vColor = vColor + (c * headColor);
} 

fn WriteWebGL()  {
	SetTextPosition(1., 3.);
	var c: f32 = 0.;
	c = c + (char(87));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(101));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(98));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(71));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(76));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(50));
	tp.x = tp.x - (FONT_SPACE);

	vColor = vColor + (c * headColor);
} 

fn WriteTestValues()  {
	var c: f32 = 0.;
	SetTextPosition(1., 12.);

	var t1: i32 = 123;
	var d1: i32 = 8;
	c = c + (drawInt(&t1, &d1));
	tp.x = tp.x - (FONT_SPACE);

	var t2: i32 = -1234567890;
	c = c + (drawInt_i32(&t2));
	tp.x = tp.x - (FONT_SPACE);

	var t3: i32 = 0;
	c = c + (drawInt_i32(&t3));
	tp.x = tp.x - (FONT_SPACE);

	var t4: i32 = -1;
	c = c + (drawInt_i32(&t4));
	tp.x = tp.x - (FONT_SPACE);

	var f1: f32 = -123.456;
	var p1: i32 = 3;
	c = c + (drawFloat_f32_prec(&f1, &p1));
	SetTextPosition(1., 13.);

	var t1: i32 = -123;
	var d1: i32 = 8;
	c = c + (drawInt(&t1, &d1));
	tp.x = tp.x - (FONT_SPACE);

	var t1: i32 = 1234567890;
	var d1: i32 = 11;
	c = c + (drawInt(&t1, &d1));

	var f1: f32 = -123.456;
	var p1: i32 = 3;
	var d1: i32 = 0;
	c = c + (drawFloat(&f1, &p1, 0));
	tp.x = tp.x - (FONT_SPACE);

	// c = c + (drawFloat(1., 0, 0));
	// tp.x = tp.x - (FONT_SPACE);

	// c = c + (drawFloat_f32_prec(654.321, 3));
	// tp.x = tp.x - (FONT_SPACE);

	// c = c + (drawFloat_f32_prec(999.9, 1));
	// tp.x = tp.x - (FONT_SPACE);

	// c = c + (drawFloat_f32_prec(pow(10., 3.), 1));

	// c = c + (drawFloat_f32_prec(pow(10., 6.), 1));

	SetTextPosition(1., 14.);

	var f1: f32 = exp2(-126.);
	var p1: i32 = 60;
	c = c + (drawFloat_f32_prec(&f1, &p1));
	vColor = vColor + (c * headColor);
} 

fn ring(pos: vec2<f32>, radius: f32, thick: f32) -> f32 {
	return mix(1., 0., smoothStep(thick, thick + 0.01, abs(length(uv - pos) - radius)));
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
    // // let uv =  vec2<f32> (location) / R;
    // // let color = textureSample(font_texture, font_texture_sampler, uv);
    // var color = textureLoad(font_texture, location, 0);
    // // color.x = 0.;
    // color.y = color.x;
    // color.z = color.x;

    // textureStore(texture, location, color);

	// var fragColor: vec4<f32>;
	var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );

	resolution = uni.iResolution.xy;
	aspect = resolution.x / resolution.y;
	let ratio: vec2<f32> = vec2<f32>(aspect, 1.);
	pixelPos = fragCoord.xy;
	mousePos = uni.iMouse.xy;
	uv = (2. * fragCoord.xy / resolution.xy - 1.) * ratio;
	mp = (2. * abs(uni.iMouse.xy) / resolution.xy - 1.) * ratio;
	lp = (2. * abs(uni.iMouse.zw) / resolution.xy - 1.) * ratio;
	vColor = mix(vColor, vec3<f32>(0.2), drawLineSegment(vec2<f32>(-99., 0.), vec2<f32>(99., 0.), 0.01));
	vColor = mix(vColor, vec3<f32>(0.2), drawLineSegment(vec2<f32>(0., -99.), vec2<f32>(0., 99.), 0.01));
	WriteText1();
	WriteWebGL();
	WriteTestValues();
	WriteMousePos(5., uni.iMouse.zw);
	WriteMousePos(6., uni.iMouse.xy);
	var radius: f32 = length(mp - lp);
	SetColor(0.9, 0.9, 0.2);
	var c: f32 = 0.;
	tp.x = tp.x - (FONT_SPACE);
	c = c + (char(114));
	tp.x = tp.x - (FONT_SPACE);

	c = c + (char(61));
	tp.x = tp.x - (FONT_SPACE);

	vColor = vColor + (c * drawColor);

	var max_digits_two: i32 = 2;
	WriteFloat(&radius, 6, &max_digits_two);

	if (uni.iMouse.z > 0.) {
		let intensity: f32 = ring(lp, radius, 0.01);
		drawColor = vec3<f32>(1.5, 0.4, 0.5);
		vColor = mix(vColor, drawColor, intensity * 0.2);
	}
	SetTextPosition(27., 1.);
	SetColor(0.8, 0.8, 0.8);
	var resx = i32(uni.iResolution.x);
	var resy = i32(uni.iResolution.y);
	WriteInteger(&resx);
	c = c + (char(28));
	tp.x = tp.x - (FONT_SPACE);
;
	WriteInteger(&resy);
	SetTextPosition(1., 16.);
	SetColor(0.9, 0.7, 0.8);

	// // TODO: keyboard
	// for (var ci: i32 = 0; ci < 256; ci = ci + 1) {	
	// 	if (textureLoad(BUFFER_iChannel3, vec2<i32>(vec2<i32>(ci, 0))).x > 0.) { 
	// 		WriteInteger(&ci); 
	// 	}
	// }

	SetTextPosition(1., 19.);
	SetColor(0.9, 0.9, 0.4);
	WriteDate();
	tp.x = tp.x - (FONT_SPACE);
	SetColor(1., 0., 1.);
	WriteTime();
	tp.x = tp.x - (FONT_SPACE);
	SetColor(0.4, 0.7, 0.4);
	var iframe: i32 = i32(uni.iFrame);
	WriteInteger(&iframe);
	tp.x = tp.x - (FONT_SPACE);
	SetColor(0., 1., 1.);
	var itime = uni.iTime;
	WriteFloat(&itime, 6, &max_digits_two);
	tp.x = tp.x - (FONT_SPACE);
	WriteFPS();
	let fragColor = vec4<f32>(vColor, 1.);

	textureStore(texture, y_inverted_location, fragColor);

} 
