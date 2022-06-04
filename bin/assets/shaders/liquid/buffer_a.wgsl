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

struct Particle {
    position: vec2<f32>;
    velocity: vec2<f32>;
    mass: vec2<f32>;
};

[[group(0), binding(0)]]
var<uniform> uni: CommonUniform;

[[group(0), binding(1)]]
var buffer_a: texture_storage_2d<rgba8unorm, read_write>;

let fluid_rho: f32 = 0.5;
let dt: f32 = 1.5;
let border_h = 5.0;
let h: f32 = 1.;

fn Pf(rho: vec2<f32>) -> f32
{
    //return 0.2*rho.x; //gas
    let GF: f32 = 1.;//smoothstep(0.49, 0.5, 1. - rho.y);
    return mix(0.5*rho.x, 0.04*rho.x*(rho.x/fluid_rho - 1.), GF); //water pressure
}

fn Rot(ang: f32) -> mat2x2<f32>
{
    return mat2x2<f32>(cos(ang), -sin(ang), sin(ang), cos(ang)); 
}

fn Dir(ang: f32) -> vec2<f32>
{
    return vec2<f32>(cos(ang), sin(ang));
}

fn sdBox(p: vec2<f32>, b: vec2<f32>) -> f32 {
  let d = (abs(p) - b) ;
  return length(max(d, vec2<f32>(0.))) + min(max(d.x, d.y), 0.);
}

fn border(p: vec2<f32>, uni: CommonUniform) -> f32
{
    let R: vec2<f32> = uni.iResolution;
    
    let bound: f32 = -sdBox(p - R*0.5, R*vec2<f32>(0.5, 0.5)); 
    let box: f32 = sdBox(Rot(0.*uni.iTime)*(p - R*vec2<f32>(0.5, 0.6)) , R*vec2<f32>(0.05, 0.01));
    let drain: f32 = -sdBox(p - R*vec2<f32>(0.5, 0.7), R*vec2<f32>(1.5, 0.5));
    return max(drain,min(bound, box));
}


fn bN( p: vec2<f32>, uni: CommonUniform ) -> vec3<f32>
{
    let dx: vec3<f32> = vec3<f32>(-h, 0.0 , h);

    let idx: vec4<f32> = vec4<f32>(-1./h, 0., 1./h, 0.25);
    let r: vec3<f32> = idx.zyw*border(p + dx.zy, uni)
           + idx.xyw*border(p + dx.xy, uni)
           + idx.yzw*border(p + dx.yz, uni)
           + idx.yxw*border(p + dx.yx, uni);

    return vec3<f32>(normalize(r.xy), r.z + 1e-4);

}


fn pack(x: vec2<f32>) -> u32 
{
    var q: vec2<f32>;
    q.x = 65534.0*clamp(0.5*x.x+0.5, 0., 1.);
    q.y = 65534.0*clamp(0.5*x.y+0.5, 0., 1.);
    return u32(round(q.x)) + 65535u*u32(round(q.y));
}

fn unpack(a: u32) -> vec2<f32>
{
    let q = vec2<u32>(a % 65535u, a / 65535u);
    let p = vec2<f32>(
        clamp(f32(q.x) / 65534.0, 0.,1.)*2.0 - 1.0,
        clamp(f32(q.y) / 65534.0, 0.,1.)*2.0 - 1.0
    );
    return p;
}

fn decode(x: f32) -> vec2<f32>
{
    let X: u32 = bitcast<u32>(x);
    return unpack(X); 
}

fn encode(x: vec2<f32>) -> f32
{
    let X: u32 = pack(x);
    let casted: f32 = bitcast<f32>(X);
    return casted;
}

fn getParticle(data: vec4<f32>, pos: vec2<f32>) -> Particle
{
    var P: Particle;
    P.position = decode(data.x) + pos;
    P.velocity = decode(data.y);
    P.mass = data.zw;
    return P;
}


fn saveParticle(in_p: Particle, pos: vec2<f32>) -> vec4<f32>
{
    var P: Particle = in_p;
    // P.position = clamp(P.position - pos, vec2<f32>(-0.5), vec2<f32>(0.5));
    P.position.x = clamp(P.position.x - pos.x, -0.5, 0.5);
    P.position.y = clamp(P.position.y - pos.y, -0.5, 0.5);
    return vec4<f32>(encode(P.position), encode(P.velocity), P.mass.x, P.mass.y);
}

fn hash32(p: vec2<f32>) -> vec3<f32>
{
	var p3: vec3<f32> = fract(vec3<f32>(p.xyx) * vec3<f32>(.1031, .1030, .0973));
    p3 = p3 + dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

fn G(x: vec2<f32>) -> f32
{
    return exp(-dot(x,x));
}

fn G0(x: vec2<f32>) -> f32
{
    return exp(-length(x));
}

fn distribution(x: vec2<f32>,  p: vec2<f32>, K: f32) -> vec3<f32>
{
    let omin: vec2<f32> = clamp(x - K*0.5, p - 0.5, p + 0.5);
    let omax: vec2<f32> = clamp(x + K*0.5, p - 0.5, p + 0.5); 
    return vec3<f32>(0.5*(omin + omax), (omax.x - omin.x)*(omax.y - omin.y)/(K*K));
}


//diffusion and advection basically
fn Reintegration(buffer: texture_storage_2d<rgba8unorm, read_write>, P: Particle, pos: vec2<f32>) -> Particle
{
    var particle: Particle = P;


    
    //basically integral over all updated neighbor distributions
    //that fall inside of this pixel
    //this makes the tracking conservative
    var i: i32 = -2;
    loop  {
        if (i > 2) { break; }

        var j: i32 = -2;
        loop {
            if (j > 2) { break; }

            let tpos: vec2<f32> = pos + vec2<f32>(f32(i),f32(j));

            let data: vec4<f32> = textureLoad(buffer, vec2<i32>(tpos));
        
            var P0: Particle = getParticle(data, tpos);
        
            P0.position = P0.position + P0.velocity*dt; //integrate position

            let difR: f32 = 0.9 + 0.21*smoothStep(fluid_rho*0., fluid_rho*0.333, P0.mass.x);
            let D: vec3<f32> = distribution(P0.position, pos, difR);
            //the deposited mass into this cell
            let m: f32 = P0.mass.x*D.z;
            
            //add weighted by mass
            particle.position = particle.position + D.xy*m;
            particle.velocity =  particle.velocity + P0.velocity*m;
            particle.mass.y = particle.mass.y  +  P0.mass.y*m;
            
            //add mass
            particle.mass.x = particle.mass.x + m;

        }
    }
    // range(i, -2, 2) range(j, -2, 2)

    //normalization
    if(particle.mass.x != 0.)
    {
        particle.position = particle.position / particle.mass.x;
        particle.velocity= particle.velocity / particle.mass.x;
        particle.mass.y = particle.mass.y / particle.mass.x;
    }

    return particle;
}

//force calculation and integration
fn Simulation(
    buffer: texture_storage_2d<rgba8unorm, read_write>,   
    P: Particle,  
    pos: vec2<f32>, 
    Mouse: vec4<f32>,
    uni: CommonUniform
    ) -> Particle
{
    var particle: Particle = P;
    
    
    //Compute the SPH force
    var F: vec2<f32> = vec2<f32>(0.);
    var  avgV: vec3<f32> = vec3<f32>(0.);

    var i: i32 = -2;
    loop  {
        if (i > 2) { break; }

        var j: i32 = -2;
        loop {
            if (j > 2) { break; }

            let tpos: vec2<f32> = pos + vec2<f32>(f32(i), f32(j));
            // let  data: vec4<f32> = texel(ch, tpos);
            let data: vec4<f32> = textureLoad(buffer, vec2<i32>(tpos));

            let  P0: Particle = getParticle(data, tpos);
            let  dx: vec2<f32> = P0.position - particle.position;
            let  avgP: f32 = 0.5*P0.mass.x*(Pf(particle.mass) + Pf(P0.mass)); 
            F = F - 0.5*G(1.*dx)*avgP*dx;
            avgV = avgV + P0.mass.x*G(1.*dx)*vec3<f32>(P0.velocity,1.);
        }
    }

    avgV.x = avgV.x / avgV.z;
    avgV.y = avgV.y / avgV.z;

    //viscosity
    F = F + 0.*particle.mass.x*(avgV.xy - particle.velocity);
    
    //gravity
    F = F + particle.mass.x*vec2<f32>(0., -0.0004);

    if(Mouse.z > 0.)
    {
        let dm: vec2<f32> =(Mouse.xy - Mouse.zw)/10.; 
        let d: f32 = distance(Mouse.xy, particle.position)/20.;
        F = F + 0.001*dm*exp(-d*d);
       // particle.mass.y += 0.1*exp(-40.*d*d);
    }
    
    //integrate
    particle.velocity = particle.velocity + F*dt/particle.mass.x;

    //border 
    let N: vec3<f32> = bN(particle.position, uni);
    let vdotN : f32 = step(N.z, border_h) * dot(-N.xy, particle.velocity);
    particle.velocity = particle.velocity + 0.5*(N.xy*vdotN + N.xy*abs(vdotN));
    particle.velocity = particle.velocity + 0.*particle.mass.x*N.xy*step(abs(N.z), border_h)*exp(-N.z);
    
    if (N.z < 0.) { particle.velocity = vec2<f32>(0.); }
    
    
    //velocity limit
    let v: f32 = length(particle.velocity);
    if (v > 1.0) { 
        particle.velocity = particle.velocity / v; 
    } 

    // particle.velocity = particle.velocity / (v > 1.) ? v : 1.;

    return particle;
}


// // /*
// // vec3 distribution(vec2 x, vec2 p, float K)
// // {
// //     vec4 aabb0 = vec4(p - 0.5, p + 0.5);
// //     vec4 aabb1 = vec4(x - K*0.5, x + K*0.5);
// //     vec4 aabbX = vec4(max(aabb0.xy, aabb1.xy), min(aabb0.zw, aabb1.zw));
// //     vec2 center = 0.5*(aabbX.xy + aabbX.zw); //center of mass
// //     vec2 size = max(aabbX.zw - aabbX.xy, 0.); //only positive
// //     float m = size.x*size.y/(K*K); //relative amount
// //     //if any of the dimensions are 0 then the mass is 0
// //     return vec3(center, m);
// // }*/

[[stage(compute), workgroup_size(8, 8, 1)]]
fn init([[builtin(global_invocation_id)]] invocation_id: vec3<u32>, [[builtin(num_workgroups)]] num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let location_f32 = vec2<f32>(f32(invocation_id.x), f32(invocation_id.y));

    let color = vec4<f32>(0.0);

    textureStore(buffer_a, location, color);
}


[[stage(compute), workgroup_size(8, 8, 1)]]
fn update([[builtin(global_invocation_id)]] invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    // textureStore(buffer_a, location, vec4<f32>(0.094));

    if (uni.iTime > 1.0) {
        textureStore(buffer_a, location, vec4<f32>(0.95));
    }
}

