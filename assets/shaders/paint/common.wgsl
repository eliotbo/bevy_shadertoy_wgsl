// unused

#define_import_path bevy_shadertoy_wgsl::assets::shaders::common

struct CommonUniform {
    iTime: f32;
    iTimeDelta: f32;
    iFrame: f32;
    iSampleRate: f32;

    iResolution: vec2<f32>;
    iMouse: vec2<f32>;

    iChannelTime: vec4<f32>;
    iChannelResolution: vec4<f32>;
    iDate: vec4<i32>;
};
