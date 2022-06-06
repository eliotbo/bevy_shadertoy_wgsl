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




fn hue(v: f32) -> vec4<f32> { 
    return (vec4<f32>(.6) + vec4<f32>(.6) * cos( vec4<f32>(6.3 * v) + vec4<f32>(0.0,23.0,21.0,0.0 ) ));
}

fn smoothit(v: f32) -> f32{ 
    return smoothStep( 1.5, 0., v );
}

fn sdSegment(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>) -> f32 {
  let pa = p - a;
  let ba = b - a;
  let h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h);
}

fn sdRhombus(p: vec2<f32>, b: vec2<f32>) -> f32 {
  let q = abs(p);
  let qb = dot(q, vec2<f32>(b.x, -b.y));
  let bb = dot(b, vec2<f32>(b.x, -b.y));
  let h = clamp((-2. * qb + bb) / dot(b, b), -1., 1.);
  let d = length(q - 0.5 * b * vec2<f32>(1. - h, 1. + h));
  return d * sign(q.x * b.y + q.y * b.x - b.x * b.y);
}

fn sdTriangleIsosceles(p: vec2<f32>, c: vec2<f32>) -> f32 {
  let q = vec2<f32>(abs(p.x), p.y);
  let a = q - c * clamp(dot(q, c) / dot(c, c), 0., 1.);
  let b = q - c * vec2<f32>(clamp(q.x / c.x, 0., 1.), 1.);
  let s = -sign(c.y);
  let d = min(vec2<f32>(dot(a, a), s * (q.x * c.y - q.y * c.x)), vec2<f32>(dot(b, b), s * (q.y - c.y)));
  return -sqrt(d.x) * sign(d.y);
}

fn sdStar(p: vec2<f32>, r: f32, n: u32, m: f32) ->f32 {
  let an = 3.141593 / f32(n);
  let en = 3.141593 / m;
  let acs = vec2<f32>(cos(an), sin(an));
  let ecs = vec2<f32>(cos(en), sin(en));
  let bn = (atan2(abs(p.x), p.y) % (2. * an)) - an;
  var q: vec2<f32> = length(p) * vec2<f32>(cos(bn), abs(sin(bn)));
  q = q - r * acs;
  q = q + ecs * clamp(-dot(q, ecs), 0., r * acs.y / ecs.y);
  return length(q) * sign(q.x);
}

fn sdHeart(p: vec2<f32>) -> f32 {
  let q = vec2<f32>(abs(p.x), p.y);
  let w = q - vec2<f32>(0.25, 0.75);
  if (q.x + q.y > 1.0) { return sqrt(dot(w, w)) - sqrt(2.) / 4.; }
  let u = q - vec2<f32>(0., 1.0);
  let v = q - 0.5 * max(q.x + q.y, 0.);
  return sqrt(min(dot(u, u), dot(v, v))) * sign(q.x - q.y);
}

fn sdMoon(p: vec2<f32>, d: f32, ra: f32, rb: f32) -> f32 {
  let q = vec2<f32>(p.x, abs(p.y));
  let a = (ra * ra - rb * rb + d * d) / (2. * d);
  let b = sqrt(max(ra * ra - a * a, 0.));
  if (d * (q.x * b - q.y * a) > d * d * max(b - q.y, 0.)) { return length(q-vec2<f32>(a, b)); }
  return max((length(q) - ra), -(length(q - vec2<f32>(d, 0.)) - rb));
}

fn sdCross(p: vec2<f32>, b: vec2<f32>) -> f32 {
  var q: vec2<f32> = abs(p);
  q = select(q.xy, q.yx, q.y > q.x);
  let t = q - b;
  let k = max(t.y, t.x);
  let w = select(vec2<f32>(b.y - q.x, -k), t, k > 0.);
  return sign(k) * length(max(w, vec2<f32>(0.)));
}

fn sdRoundedX(p: vec2<f32>, w: f32, r: f32) -> f32 {
  let q = abs(p);
  return length(q - min(q.x + q.y, w) * 0.5) - r;
}

fn sdCircle(p: vec2<f32>, c: vec2<f32>, r: f32) -> f32 {
  let d = length(p - c);
  return d - r;
}

// [[stage(compute), workgroup_size(8, 8, 1)]]
// fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
//     let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
//     let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

//     # ifdef INIT
//         if (location.x == 0 && location.y == 0 )  {
//             textureStore(buffer_a, location, hue(4.0 / 8.0));
//         } else {
//             // set brush color to black
//             let black = vec4<f32>(0.0, 0.0, 0.0, 1.0);
//             textureStore(buffer_a, location, black);
//         }
//     # endif
// }

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let R: vec2<f32> = uni.iResolution.xy;
    // let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    // the first three frames are not directed inside the update function.
    // The first time this function is called is on frame 4.
    // if (i32(uni.iFrame) == 3) { 
    # ifdef INIT
        if (location.x == 0 && location.y == 0 )  {
            textureStore(buffer_a, location, hue(4.0 / 8.0));
        } else {
            // set brush color to black
            let black = vec4<f32>(0.0, 0.0, 0.0, 1.0);
            textureStore(buffer_a, location, black);
        }
    # endif
    // }

    
    let U: vec2<f32> = vec2<f32>(location) / R;
    let M: vec2<f32> = vec2<f32>(uni.iMouse.x, 1.0-uni.iMouse.y);

    var O: vec4<f32> =  textureLoad(buffer_a, location);

    if (location.x == 0 && location.y == 0 )  {
        if ( uni.iMouse.x < 0.1 && uni.iMouse.w == 1.0) { // just pressed left mouse button
            let y: f32 = floor(9.*M.y);
            O = hue( y/8. ); 
            textureStore(buffer_a, location, O);
        }
        return;
    }

    // display palette on left
    if ( U.x < 0.1  ) {  
        let y: f32 = floor(9.*U.y);
        O = hue( y/8. ); 
        O.w = 1.;
        textureStore(buffer_a, location, O);
        return;
    }

    // let brush_color = vec4<f32>(1., 0., 0., 1.);
    let brush_color = textureLoad(buffer_a, vec2<i32>(0,0));

    // apply paint
    if (uni.iMouse.z == 1.0) {
        let mouse_pix = vec2<f32>(uni.iMouse.x *  R.x, (1.0 - uni.iMouse.y) * R.y );

        let brush_sdf = sdCircle(vec2<f32>(location), mouse_pix, 10.0);
        let brush_d = smoothStep(0.0, 5.0, brush_sdf);
        O = mix(O, brush_color, (1.0-brush_d) * 0.01);
    }
    


    textureStore(buffer_a, location, O);

}