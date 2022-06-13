

fn mixN(a: vec3<f32>, b: vec3<f32>, k: f32) -> vec3<f32> {
    return sqrt(mix(a * a, b * b, clamp(k, 0., 1.)));
} 

fn V(p: vec2<f32>) -> vec4<f32> {
	// return pixel(ch1, p);
    return textureLoad(buffer_c, vec2<i32>(p));
} 

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    R = uni.iResolution.xy;
    time = uni.iTime;
    Mouse = uni.iMouse;

    let y_inverted_location = vec2<i32>(i32(invocation_id.x), i32(R.y) - i32(invocation_id.y));
	

//     var O: vec4<f32> =  textureLoad(buffer_a, location);
//     textureStore(texture, location, O);
// }

// fn mainImage( col: vec4<f32>,  pos: vec2<f32>) -> () {


    

	// let p: vec2<i32> = vec2<i32>(pos);
	// let data: vec4<f32> = texel(ch0, pos);

    let p: vec2<i32> = location;

    let data: vec4<f32> = textureLoad(buffer_a, location);

    let pos = vec2<f32>(location);

    var P: particle = getParticle(data, pos);

    let Nb: vec3<f32> = bN(P.X);
    let bord: f32 = smoothStep(2. * border_h, border_h * 0.5, border(pos));
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
    // var col: vec4<f32>;

    var col: vec3<f32> = vec3<f32>(3.);
    col = mixN(col.xyz, fcol.xyz * (1.5 * b + specular * 5.), a);


    col = mixN(col, 0. * vec3<f32>(0.5, 0.5, 1.), bord);
    col = tanh(col);
    let col4 = vec4<f32>(col, 3.0);

    textureStore(texture, y_inverted_location, col4);
} 
