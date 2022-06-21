

fn mixN(a: vec3<f32>, b: vec3<f32>, k: f32) -> vec3<f32> {
    return sqrt(mix(a * a, b * b, clamp(k, 0., 1.)));
} 

fn V(p: vec2<f32>) -> vec4<f32> {
    let data: vec4<f32> = textureLoad(buffer_c, vec2<i32>(p));
    return data;
} 



fn border(p: vec2<f32>, R2: vec2<f32>) -> f32 {
    let bound: f32 = -sdBox(p - R2 * 0.5, R2 * vec2<f32>(0.5, 0.5));
    let box: f32 = sdBox(Rot(0. * time) * (p - R2 * vec2<f32>(0.5, 0.6)), R2 * vec2<f32>(0.05, 0.01));
    let drain: f32 = -sdBox(p - R2 * vec2<f32>(0.5, 0.7), R2 * vec2<f32>(1.5, 0.5));
    return max(drain, min(bound, box));
} 



fn bN(p: vec2<f32>, R2: vec2<f32>) -> vec3<f32> {
    let dx: vec3<f32> = vec3<f32>(-h, 0., h);
    let idx: vec4<f32> = vec4<f32>(-1. / h, 0., 1. / h, 0.25);
    let r: vec3<f32> = idx.zyw * border(p + dx.zy, R2) + idx.xyw * border(p + dx.xy, R2) + idx.yzw * border(p + dx.yz, R2) + idx.yxw * border(p + dx.yx, R2);
    return vec3<f32>(normalize(r.xy), r.z + 1.0e-4);
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    R = uni.iResolution.xy;
    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var col: vec4<f32>;
    var pos = vec2<f32>(f32(location.x), f32(location.y)) ;

    // let Mouse = uni.iMouse;
    time = uni.iTime;

    let p: vec2<i32> = vec2<i32>(pos);

    let data: vec4<f32> = textureLoad(buffer_a, location);

    var P: particle = getParticle(data, pos);
    let Nb: vec3<f32> = bN(P.X, R);
    let bord: f32 = smoothStep(2. * border_h, border_h * 0.5, border(pos, R));
    let rho: vec4<f32> = V(pos);
    let dx: vec3<f32> = vec3<f32>(-2., 0., 2.);
    let grad: vec4<f32> = -0.5 * vec4<f32>(V(pos + dx.zy).zw - V(pos + dx.xy).zw, V(pos + dx.yz).zw - V(pos + dx.yx).zw);
    let N: vec2<f32> = pow(length(grad.xz), 0.2) * normalize(grad.xz + 0.00001);
    let specular: f32 = pow(max(dot(N, Dir(1.4)), 0.), 3.5);

    let specularb: f32 = G(0.4 * (Nb.zz - border_h)) * pow(max(dot(Nb.xy, Dir(1.4)), 0.), 3.);

    let a: f32 = pow(smoothStep(fluid_rho * 0., fluid_rho * 2., rho.z), 0.1);
    let b: f32 = exp(-1.7 * smoothStep(fluid_rho * 1., fluid_rho * 7.5, rho.z));
    let col0: vec3<f32> = vec3<f32>(1., 0.5, 0.);
    let col1: vec3<f32> = vec3<f32>(0.1, 0.4, 1.);
    let fcol: vec3<f32> = mixN(col0, col1, tanh(3. * (rho.w - 0.7)) * 0.5 + 0.5);
    col = vec4<f32>(3.);
    var colxyz = col.xyz;

    colxyz = mixN(col.xyz, fcol.xyz * (1.5 * b + specular * 5.), a);
    col.x = colxyz.x;
    col.y = colxyz.y;
    col.z = colxyz.z;

    var colxyz = col.xyz;
    colxyz = mixN(col.xyz, 0. * vec3<f32>(0.5, 0.5, 1.), bord);
    col.x = colxyz.x;
    col.y = colxyz.y;
    col.z = colxyz.z;

    var colxyz = col.xyz;
    colxyz = tanh(col.xyz);
    col.x = colxyz.x;
    col.y = colxyz.y;
    col.z = colxyz.z;

    // let bufa: vec4<f32> = textureLoad(buffer_a, location);

    // var col2 = vec4<f32>(0.2, 0.6, 0.9, 1.0);
    // var col2 = vec4<f32>(0.3, 0.5, 0.29, 1.0);
    // if (y_inverted_location.x > i32(R.x / 2.0)) {

    //     let v = vec2<f32>(0.3, 0.5) * 2.0;

    //     let u = f32(encodeVec2To1u(v));

    //     let back = decode1uToVec2(u) / 2.0;

    //     col2 = vec4<f32>(back.x, back.y, 0.29, 1.0);
    // }

    // let data2: vec4<f32> = (textureLoad(buffer_a, location)  ) ;
    // var pb: particle = getParticle(data2, pos);
    // let v2 = (pb.X - pos + 1.0) / 2.;
    // let v2 = (pb.M ) / 1.;

    // let debug = vec4<f32>(v2.x, 0.0, 0.0, 1.0);

    // if (Mouse.z > 0.5) {
    //     col = debug;
    // }


    let col_debug_info = show_debug_info(location, col.xyz);
    
    // textureStore(texture, y_inverted_location, toLinear(debug));
    // textureStore(texture, y_inverted_location, toLinear(col));
    textureStore(texture, y_inverted_location, toLinear(col_debug_info));
} 
