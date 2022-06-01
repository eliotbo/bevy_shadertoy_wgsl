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

[[stage(compute), workgroup_size(8, 8, 1)]]
fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

    let color = vec4<f32>(0.0);


    textureStore(buffer_a, location, color);
}

// https://www.shadertoy.com/view/7t3SDf

fn t(i: vec2<i32>, location: vec2<i32>) -> vec4<f32> {
    let O: vec4<f32> =  textureLoad(buffer_a, i + location );
    return O;
}

[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    var location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    // location = location + vec2<i32>(10);
    

    var r: vec4<f32> = vec4<f32>(0.);

	for (var i: vec2<i32> = vec2<i32>(-7); i.x < 7; i.x = i.x + 1  ) {	

        for (i.y = -7; i.y  < 7; i.y = i.y + 1  ) {
            
            let ii = i + 1;
            let a = 0;

            let v: vec2<f32> = t(ii , location + a ).xy;
            let what = t(ii, location + a).z ;
            let fi = vec2<f32>(ii);
            
            r = r + ( what 
                * exp(-dot(v+fi, v+fi)) / 3.14
                * vec4<f32>(mix(v+v+fi , v, t(ii, location + a ).z), 1., 1.)  );
        }	
    }	

    r.x = r.x / (r.z+0.000001);
    r.y = r.y / (r.z+0.000001);

	if (i32(uni.iFrame) % 500 == 1) {
            let u = vec2<f32>(location +0) ;
			let m: vec2<f32> = 4.*u/vec2<f32>(uni.iResolution.xy) - 2.;
			r = r + (vec4<f32>(m, 1., 0.)*exp(-dot(m, m)));
		
	}

    textureStore(buffer_a, location , r);
}

