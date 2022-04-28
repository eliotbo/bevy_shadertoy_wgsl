
struct CommonUniform {
    iTime: f32;
    iTimeDelta: f32;
    iFrame: i32;
    iSampleRate: i32;

    iChannelTime: vec4<f32>;
    iChannelResolution: vec4<f32>;
    iDate: vec4<i32>;
    
    iResolution: vec2<f32>;
    iMouse: vec2<f32>;
};

[[group(0), binding(0)]]
var<uniform> uni: CommonUniform;

[[group(0), binding(1)]]
var buffer_a: texture_storage_2d<rgba8unorm, read_write>;

[[group(0), binding(2)]]
var buffer_b: texture_storage_2d<rgba8unorm, read_write>;


{{COMMON}}

{{TEXTURE_B}}

