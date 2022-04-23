
#version 450

layout(location = 0) in vec4 v_Position;
layout(location = 0) out vec4 o_Target;

layout(location = 0) out vec4 o_Target;

layout(set = 2, binding = 0) uniform texture2DArray MyArrayTexture_texture;
layout(set = 2, binding = 1) uniform sampler MyArrayTexture_texture_sampler;

layout(set = 1, binding = 0) uniform CustomMaterial {
    vec4 Color;
};

void main() {
    // o_Target = Color;

    vec2 ss = v_Position.xy / v_Position.w;

    o_Target = texture(
        sampler2DArray(MyArrayTexture_texture, MyArrayTexture_texture_sampler), vec3(uv, layer)
    );
}
