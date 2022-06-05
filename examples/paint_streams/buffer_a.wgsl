
// don't forget to use a return value when using Reintegration
fn Reintegration(ch: texture_storage_2d<rgba8unorm, read_write>, pos: vec2<f32>, R2: vec2<f32>) -> particle {
	
    //basically integral over all updated neighbor distributions
    //that fall inside of this pixel
    //this makes the tracking conservative
    for (var i: i32 = -2; i <= 2; i = i + 1) {	
        for (var j: i32 = -2; j <= 2; j = j + 1) {
            let tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(j));

            // let data: vec4<f32> = texel(ch, tpos);
            // let data: vec4<f32> = texelFetch(ch, ivec2(tpos), 0);
            let data: vec4<f32> =  textureLoad(ch, vec2<i32>(tpos));

            var P0: particle = getParticle(data, tpos);

            P0.X = P0.X + (P0.V * dt);//integrate position

            let difR: f32 = 0.9 + 0.21 * smoothStep(fluid_rho * 0., fluid_rho * 0.333, P0.M.x);
            let D: vec3<f32> = distribution(P0.X, pos / R2 , difR);

            //the deposited mass into this cell
            let m: f32 = P0.M.x * D.z;

            var P1: particle;
            // TODO: change the input particle directly using (*P).X = ...
            //add weighted by mass
            P1.X = P1.X + (D.xy * m);
            P1.V = P1.V + (P0.V * m);
            P1.M.y = P1.M.y + (P0.M.y * m);

            //add mass
            P1.M.x = P1.M.x + (m);
	
        }	
    }

    //normalization
    if (P1.M.x != 0.) {
		P1.X = P1.X / (P1.M.x);
		P1.V = P1.V / (P1.M.x);
		P1.M.y = P1.M.y / (P1.M.x);
	}

    return P1;
} 


[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {

	let R2 = uni.iResolution.xy;
    let location = vec2<i32>(i32(invocation_id.x), i32(R2.y)  - i32(invocation_id.y));

    let pos: vec2<f32> = vec2<f32>(location)  ;

	var P: particle;
		
	#ifdef INIT
		let rand: vec3<f32> = hash32(pos);
		// let rand = vec3<f32>(0.2, -0.2, -0.2);
		if (rand.z < 0.) {
			P.X = pos;
			P.V = 0.5 * (rand.xy - 0.5) + vec2<f32>(0., 0.);
			P.M = vec2<f32>(mass, 0.);
		
		} else {
			P.X = pos;
			P.V = vec2<f32>(0.);
			P.M = vec2<f32>(0.000001);
		
		}
	#else
		P = Reintegration(buffer_b, pos, R2);
	#endif

    textureStore(buffer_a, location, saveParticle(P, pos));
} 

