let uv: vec2<f32> = vec2<f32>(0.);
let tp: vec2<f32> = vec2<f32>(0.);

fn char(ch: i32) -> f32 {
	let f: vec4<f32> = textureLoad_CONVERT_TO_i32(BUFFER_iChannel2, 
        
        vec2<i32>(clamp(tp, 0., 1.) / 16. + fract(floor(vec2<f32>(ch, 15.999 - f32(ch) / 16.)) / 16.)));
	return f.x * (f.y + 0.3) * (f.z + 0.3) * 2.;
} 

fn SetTextPosition(x: f32, y: f32)  {
	tp = 10. * uv;
	tp.x = tp.x + 17. - x;
	tp.y = tp.y - 9.4 + y;
} 

fn drawFract(value: f32, digits: i32) -> f32 {
	var c: f32 = 0.;
	value = fract(value) * 10.;

	for (var ni: i32 = 1; ni < 60; ni = ni + 1) {
		c = c + (char(48 + i32(value)));
		tp.x = tp.x - (0.5);
		digits = digits - (1);
		value = fract(value) * 10.;
		if (digits <= 0 || value == 0.) {		break;
 }
	}

	tp.x = tp.x - (0.5 * f32(digits));
	return c;
} 

fn maxInt(a: i32, b: i32) -> i32 {
	return if (a > b) { a; } else { b; };
} 

fn drawInt(value: i32, minDigits: i32) -> f32 {
	var c: f32 = 0.;
	if (value < 0) {
		value = -value;
		if (minDigits < 1) {		minDigits = 1;
		} else { 
		minDigits = minDigits - 1;
		}
		c = c + (char(45));
		tp.x = tp.x - (FONT_SPACE);
;
	}
	var fn: i32 = value;
	var digits: i32 = 1;

	for (var ni: i32 = 0; ni < 10; ni = ni + 1) {
		fn = fn / (10);
		if (fn == 0) {		break;
 }
		digits = digits + 1;
	}

	digits = maxInt(minDigits, digits);
	tp.x = tp.x - (0.5 * f32(digits));

	for (var ni: i32 = 1; ni < 11; ni = ni + 1) {
		tp.x = tp.x + (0.5);
		c = c + (char(48 + value % 10));
		value = value / (10);
		if (ni >= digits) {		break;
 }
	}

	tp.x = tp.x - (0.5 * f32(digits));
	return c;
} 

fn drawFloat(value: f32, prec: i32, maxDigits: i32) -> f32 {
	let tpx: f32 = tp.x - 0.5 * f32(maxDigits);
	var c: f32 = 0.;
	if (value < 0.) {
		c = char(45);
		value = -value;
	}
	tp.x = tp.x - (0.5);
	c = c + (drawInt(i32(value), 1));
	c = c + (char(46));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (drawFract(fract(value), prec));
	tp.x = min(tp.x, tpx);
	return c;
} 

fn drawFloat(value: f32) -> f32 {
	return drawFloat(value, 2, 5);
} 

fn drawFloat(value: f32, prec: i32) -> f32 {
	return drawFloat(value, prec, 2);
} 

fn drawInt(value: i32) -> f32 {
	return drawInt(value, 1);
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

const headColor: vec3<f32> = vec3<f32>(0.9, 0.6, 0.2);
const backColor: vec3<f32> = vec3<f32>(0.15, 0.1, 0.1);
const mpColor: vec3<f32> = vec3<f32>(0.99, 0.99, 0.);
const mxColor: vec3<f32> = vec3<f32>(1., 0., 0.);
const myColor: vec3<f32> = vec3<f32>(0., 1., 0.);
var dotColor: vec3<f32> = vec3<f32>(0.5, 0.5, 0.);
var drawColor: vec3<f32> = vec3<f32>(1., 1., 0.);
var vColor: vec3<f32> = backColor;
var aspect: f32 = 1.;
let pixelPos: vec2<f32> = vec2<f32>(0.);
var mousePos: vec2<f32> = vec2<f32>(200.);
var lp: vec2<f32> = vec2<f32>(0.5);
var mp: vec2<f32> = vec2<f32>(0.5);
let resolution: vec2<f32> = vec2<f32>(0.);
fn SetColor(red: f32, green: f32, blue: f32)  {
	drawColor = vec3<f32>(red, green, blue);
} 

fn WriteFloat(const fValue: f32, const maxDigits: i32, const decimalPlaces: i32)  {
	vColor = mix(vColor, drawColor, drawFloat(fValue, decimalPlaces));
	tp.x = tp.x - (FONT_SPACE);
;
} 

fn WriteInteger(const iValue: i32)  {
	vColor = mix(vColor, drawColor, drawInt(iValue));
	tp.x = tp.x - (FONT_SPACE);
;
} 

fn WriteDate()  {
	var c: f32 = 0.;
	c = c + (drawInt(i32(uni.iDate.x)));
	c = c + (char(45));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (drawInt(i32(uni.iDate.y + 1.)));
	c = c + (char(45));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (drawInt(i32(uni.iDate.z)));
	tp.x = tp.x - (FONT_SPACE);
	vColor = mix(vColor, drawColor, c);
} 

fn WriteTime()  {
	var c: f32 = 0.;
	c = c + (drawInt(i32(mod(uni.iDate.w / 3600., 24.))));
	c = c + (char(58));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (drawInt(i32(mod(uni.iDate.w / 60., 60.)), 2));
	c = c + (char(58));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (drawInt(i32(mod(uni.iDate.w, 60.)), 2));
	tp.x = tp.x - (FONT_SPACE);
	vColor = mix(vColor, drawColor, c);
} 

fn WriteFPS()  {
	let fps: f32 = uni.iFrameRate;
	SetColor(0.8, 0.6, 0.3);
	WriteFloat(fps, 6, 1);
	var c: f32 = 0.;
	c = c + (char(102));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(112));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(115));
	tp.x = tp.x - (FONT_SPACE);
;
	vColor = mix(vColor, drawColor, c);
} 

fn WriteMousePos(ytext: f32, mPos: vec2<f32>)  {
	let digits: i32 = 3;
	let radius: f32 = resolution.x / 200.;
	if (uni.iMouse.z > 0.) { dotColor = mpColor; }
	let r: f32 = length(abs(mPos.xy) - pixelPos) - radius;
	vColor = vColor + (mix(vec3<f32>(0.), dotColor, 1. - clamp(r, 0., 1.)));
	SetTextPosition(1., ytext);
	if (ytext == 7.) {
		drawColor = mxColor;
		WriteFloat(mPos.x, 6, 3);
		tp.x = tp.x - (FONT_SPACE);
;
		drawColor = myColor;
		WriteFloat(mPos.y, 6, 3);
	} else { 

		drawColor = mxColor;
		WriteInteger(i32(mPos.x));
		tp.x = tp.x - (FONT_SPACE);
;
		drawColor = myColor;
		WriteInteger(i32(mPos.y));
	}
} 

fn WriteText1()  {
	SetTextPosition(1., 1.);
	var c: f32 = 0.;
	c = c + (char(28));
	tp.x = tp.x - (FONT_SPACE);
;
	tp.x = tp.x - (FONT_SPACE);
	c = c + (char(68));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(97));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(116));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(97));
	tp.x = tp.x - (FONT_SPACE);
;
	tp.x = tp.x - (FONT_SPACE);
	c = c + (char(50));
	tp.x = tp.x - (FONT_SPACE);
;
	tp.x = tp.x - (FONT_SPACE);
	tp.x = tp.x - (FONT_SPACE);
	c = c + (char(118));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(49));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(46));
	tp.x = tp.x - (FONT_SPACE);
;
	vColor = vColor + (c * headColor);
} 

fn WriteWebGL()  {
	SetTextPosition(1., 3.);
	var c: f32 = 0.;
	c = c + (char(87));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(101));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(98));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(71));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(76));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(50));
	tp.x = tp.x - (FONT_SPACE);
;
	vColor = vColor + (c * headColor);
} 

fn WriteTestValues()  {
	var c: f32 = 0.;
	SetTextPosition(1., 12.);
	c = c + (drawInt(123, 8));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawInt(-1234567890));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawInt(0));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawInt(-1));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawFloat(-123.456, 3));
	SetTextPosition(1., 13.);
	c = c + (drawInt(-123, 8));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawInt(1234567890, 11));
	c = c + (drawFloat(0., 0, 0));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawFloat(1., 0, 0));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawFloat(654.321, 3));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawFloat(999.9, 1));
	tp.x = tp.x - (FONT_SPACE);
	c = c + (drawFloat(pow(10., 3.), 1));
	c = c + (drawFloat(pow(10., 6.), 1));
	SetTextPosition(1., 14.);
	c = c + (drawFloat(exp2(-126.), 60));
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
    
	var fragColor: vec4<f32>;
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
	let radius: f32 = length(mp - lp);
	SetColor(0.9, 0.9, 0.2);
	var c: f32 = 0.;
	tp.x = tp.x - (FONT_SPACE);
	c = c + (char(114));
	tp.x = tp.x - (FONT_SPACE);
;
	c = c + (char(61));
	tp.x = tp.x - (FONT_SPACE);
;
	vColor = vColor + (c * drawColor);
	WriteFloat(radius, 6, 2);
	if (uni.iMouse.z > 0.) {
		let intensity: f32 = ring(lp, radius, 0.01);
		drawColor = vec3<f32>(1.5, 0.4, 0.5);
		vColor = mix(vColor, drawColor, intensity * 0.2);
	}
	SetTextPosition(27., 1.);
	SetColor(0.8, 0.8, 0.8);
	WriteInteger(i32(uni.iResolution.x));
	c = c + (char(28));
	tp.x = tp.x - (FONT_SPACE);
;
	WriteInteger(i32(uni.iResolution.y));
	SetTextPosition(1., 16.);
	SetColor(0.9, 0.7, 0.8);

	for (var ci: i32 = 0; ci < 256; ci = ci + 1) {	if (textureLoad(BUFFER_iChannel3, vec2<i32>(vec2<i32>(ci, 0))).x > 0.) { WriteInteger(ci); }
	}

	SetTextPosition(1., 19.);
	SetColor(0.9, 0.9, 0.4);
	WriteDate();
	tp.x = tp.x - (FONT_SPACE);
	SetColor(1., 0., 1.);
	WriteTime();
	tp.x = tp.x - (FONT_SPACE);
	SetColor(0.4, 0.7, 0.4);
	WriteInteger(uni.iFrame);
	tp.x = tp.x - (FONT_SPACE);
	SetColor(0., 1., 1.);
	WriteFloat(uni.iTime, 6, 2);
	tp.x = tp.x - (FONT_SPACE);
	WriteFPS();
	fragColor = vec4<f32>(vColor, 1.);
} 

