//! Notes:
//! wglsl error messages do not display the correct line numbers when comparing to the
//! buffer and image scripts because the shader that is read by the GPU includes
//! the uniform and the bindings, which add about 50 lines of code

use bevy::{
    core_pipeline::node::MAIN_PASS_DEPENDENCIES,
    diagnostic::{Diagnostics, FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin},
    prelude::*,
    reflect::TypeUuid,
    render::{
        render_asset::RenderAssets,
        render_graph::{self, NodeLabel, RenderGraph},
        // render_resource::*,
        render_resource::{std140::AsStd140, *},
        renderer::{RenderContext, RenderDevice, RenderQueue},
        RenderApp,
        RenderStage,
    },
    window::{PresentMode, WindowResized},
};

use std::borrow::Cow;
use std::fs; // not compatible with WASM -->

mod texture_a;
use texture_a::*;

mod texture_b;
use texture_b::*;

mod texture_c;
use texture_c::*;

mod texture_d;
use texture_d::*;

pub const WORKGROUP_SIZE: u32 = 8;
pub const NUM_PARTICLES: u32 = 256;
pub const BORDERS: f32 = 1.0;

#[derive(Clone, Debug)]
pub struct CanvasSize {
    pub width: u32,
    pub height: u32,
}

#[derive(Clone)]
pub struct ShadertoyTextures {
    font_texture_handle: Handle<Image>,
    rgba_noise_256_handle: Handle<Image>,
}

pub struct ShadertoyResources {
    number_of_frames: u32,
    time_since_reset: f32,
    pub include_debugger: bool,
}

fn main() {
    let mut app = App::new();
    // app.insert_resource(wgpu_options)
    app.insert_resource(ClearColor(Color::GRAY))
        .insert_resource(WindowDescriptor {
            width: 960.,
            height: 600.,
            cursor_visible: false,
            // present_mode: PresentMode::Immediate, // uncomment for unthrottled FPS
            ..default()
        })
        .insert_resource(CanvasSize {
            width: (960.0_f32 * BORDERS).floor() as u32,
            height: (600.0_f32 * BORDERS).floor() as u32,
        })
        .insert_resource(ShadertoyResources {
            number_of_frames: 0,
            time_since_reset: 0.0,
            include_debugger: false,
        })
        .add_plugins(DefaultPlugins)
        .add_system(bevy::input::system::exit_on_esc_system)
        .add_plugin(ShadertoyPlugin)
        .add_plugin(FrameTimeDiagnosticsPlugin::default())
        .add_plugin(LogDiagnosticsPlugin::default())
        .add_startup_system(setup)
        .add_system(update_common_uniform)
        .run();
}

// #[derive(Component)]
// struct ComponentA(f32);

// #[derive(Bundle)]
// struct MyBundle {
//     a: ComponentA,
// }

fn setup(
    mut commands: Commands,
    mut images: ResMut<Assets<Image>>,
    canvas_size: Res<CanvasSize>,
    // mut shaders: ResMut<Assets<Shader>>,
    asset_server: Res<AssetServer>,
    windows: Res<Windows>,
    st_res: Res<ShadertoyResources>,
    // mut custom_materials: ResMut<Assets<CustomMaterial>>,
) {
    commands.spawn_bundle(OrthographicCameraBundle::new_2d());

    let mut image = Image::new_fill(
        Extent3d {
            width: canvas_size.width,
            height: canvas_size.height,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        &[0, 0, 0, 0],
        TextureFormat::Rgba32Float,
    );
    image.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;

    let image = images.add(image);

    commands.insert_resource(MainImage(image.clone()));

    commands.spawn_bundle(SpriteBundle {
        sprite: Sprite {
            custom_size: Some(Vec2::new(
                canvas_size.width as f32,
                canvas_size.height as f32,
            )),
            ..default()
        },
        texture: image.clone(),
        // // the y axis of a bevy window is flipped compared to shadertoy. We fix it
        // // by rotating the sprite 180 degrees, but this comes at the cost of a mirrored
        // // image in the x axis.
        // transform: Transform::from_rotation(bevy::math::Quat::from_rotation_z(
        //     core::f32::consts::PI,
        // )),
        transform: Transform::from_translation(Vec3::new(0.0, 0.0, 0.0)),
        ..default()
    });

    let font_texture_handle: Handle<Image> = asset_server.load("textures/font.png");
    let rgba_noise_256_handle: Handle<Image> = asset_server.load("textures/rgba_noise_256.png");
    commands.insert_resource(ShadertoyTextures {
        font_texture_handle,
        rgba_noise_256_handle,
    });

    let window = windows.primary();
    let mut common_uniform = CommonUniform::default();

    common_uniform.i_resolution.x = window.width();
    common_uniform.i_resolution.y = window.height();
    commands.insert_resource(common_uniform);

    //
    //
    //
    // Texture A: equivalent of Buffer A in Shadertoy
    let mut texture_a = Image::new_fill(
        Extent3d {
            width: canvas_size.width,
            height: canvas_size.height,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        // &[255, 255, 255, 255],
        &[0, 0, 0, 0],
        TextureFormat::Rgba32Float,
    );
    texture_a.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;

    let texture_a = images.add(texture_a);

    commands.insert_resource(TextureA(texture_a));

    //
    //
    //
    // Texture B: equivalent of Buffer B in Shadertoy
    let mut texture_b = Image::new_fill(
        Extent3d {
            width: canvas_size.width,
            height: canvas_size.height,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        // &[255, 255, 255, 255],
        &[0, 0, 0, 0],
        TextureFormat::Rgba32Float,
    );
    texture_b.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;

    let texture_b = images.add(texture_b);

    commands.insert_resource(TextureB(texture_b));

    //
    //
    //
    // Texture C: equivalent of Buffer C in Shadertoy
    let mut texture_c = Image::new_fill(
        Extent3d {
            width: canvas_size.width,
            height: canvas_size.height,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        // &[255, 255, 255, 255],
        &[0, 0, 0, 0],
        TextureFormat::Rgba32Float,
    );
    texture_c.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;

    let texture_c = images.add(texture_c);

    commands.insert_resource(TextureC(texture_c));

    //
    //
    //
    // Texture D: equivalent of Buffer D in Shadertoy
    let mut texture_d = Image::new_fill(
        Extent3d {
            width: canvas_size.width,
            height: canvas_size.height,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        // &[255, 255, 255, 255],
        &[0, 0, 0, 0],
        TextureFormat::Rgba32Float,
    );
    texture_d.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;

    let texture_d = images.add(texture_d);

    commands.insert_resource(TextureD(texture_d));

    // TODO
    // rain: https://www.shadertoy.com/view/wdGSzw
    // fix clouds

    // // let example = "clouds";
    // // let example = "minimal";
    // // let example = "paint";
    // // let example = "paint_streams2";
    // // let example = "seascape";
    // // let example = "sunset";
    // let example = "fluid";
    // // let example = "dry_ice";
    // // let example = "protean_clouds";

    // // let example = "fire2";
    // // let example = "fire";
    // // let example = "debugger";
    // // let example = "molecular_dynamics";
    // // let example = "love_and_domination";
    // // let example = "dancing_tree";

    // let all_shader_handles: ShaderHandles =
    //     make_and_load_shaders2(example, &asset_server, st_res.include_debugger);

    // commands.insert_resource(all_shader_handles);
}

pub fn make_and_load_shaders(example: &str, asset_server: &Res<AssetServer>) -> ShaderHandles {
    let image_shader_handle = asset_server.load(&format!("./shaders/{}/image.wgsl", example));
    let texture_a_shader = asset_server.load(&format!("./shaders/{}/buffer_a.wgsl", example));
    let texture_b_shader = asset_server.load(&format!("./shaders/{}/buffer_b.wgsl", example));
    let texture_c_shader = asset_server.load(&format!("./shaders/{}/buffer_c.wgsl", example));
    let texture_d_shader = asset_server.load(&format!("./shaders/{}/buffer_d.wgsl", example));

    ShaderHandles {
        image_shader: image_shader_handle,
        texture_a_shader,
        texture_b_shader,
        texture_c_shader,
        texture_d_shader,
    }
}

pub fn make_and_load_shaders2(
    example: &str,
    asset_server: &Res<AssetServer>,
    include_debugger: bool,
) -> ShaderHandles {
    // let image_shader_handle = asset_server.load(&format!("shaders/{}/image.wgsl", example));
    // let example_string = example.to_string();
    //

    format_and_save_shader(example, "image", include_debugger);
    format_and_save_shader(example, "buffer_a", false);
    format_and_save_shader(example, "buffer_b", false);
    format_and_save_shader(example, "buffer_c", false);
    format_and_save_shader(example, "buffer_d", false);

    let image_shader_handle = asset_server.load(&format!("./shaders/{}/image.wgsl", example));
    let texture_a_shader = asset_server.load(&format!("./shaders/{}/buffer_a.wgsl", example));
    let texture_b_shader = asset_server.load(&format!("./shaders/{}/buffer_b.wgsl", example));
    let texture_c_shader = asset_server.load(&format!("./shaders/{}/buffer_c.wgsl", example));
    let texture_d_shader = asset_server.load(&format!("./shaders/{}/buffer_d.wgsl", example));

    ShaderHandles {
        image_shader: image_shader_handle,
        texture_a_shader,
        texture_b_shader,
        texture_c_shader,
        texture_d_shader,
    }
}

// This function uses the std library and isn't compatible with wasm
fn format_and_save_shader(example: &str, buffer_type: &str, include_debugger: bool) {
    let common_prelude = include_str!("./templates/common_prelude.wgsl");

    let template = match buffer_type {
        "image" => include_str!("./templates/image_template.wgsl"),
        "buffer_a" => include_str!("./templates/buffer_a_template.wgsl"),
        "buffer_b" => include_str!("./templates/buffer_b_template.wgsl"),
        "buffer_c" => include_str!("./templates/buffer_c_template.wgsl"),
        "buffer_d" => include_str!("./templates/buffer_d_template.wgsl"),
        _ => include_str!("./templates/buffer_d_template.wgsl"),
    };

    let mut shader_content = template.replace("{{COMMON_PRELUDE}}", common_prelude);

    if include_debugger {
        let debbuger_str = include_str!("./templates/debugger.wgsl");
        shader_content = shader_content.replace("{{DEBUGGER}}", debbuger_str);
    } else {
        shader_content = shader_content.replace("{{DEBUGGER}}", "");
    }

    let path_to_code_block = format!("./examples/{}/{}.wgsl", example, buffer_type);
    let path_to_common = format!("./examples/{}/common.wgsl", example);
    println!("common: {}", path_to_common);

    let common = fs::read_to_string(path_to_common).expect("could not read file.");
    let image_main = fs::read_to_string(path_to_code_block).expect("could not read file.");

    let mut shader_content = shader_content.replace("{{COMMON}}", &common);
    shader_content = shader_content.replace("{{CODE_BLOCK}}", &image_main);
    let folder = format!("./assets/shaders/{}", example);
    let path = format!("{}/{}.wgsl", folder, buffer_type);
    println!("{}", path);
    let _ = fs::create_dir(folder);
    fs::write(path, shader_content).expect("Unable to write file");
}

// fn import_shader(
//     shader_skeleton: &str,
//     shader_handle_untyped: HandleUntyped,
//     shaders: &mut Assets<Shader>,
//     shader_core_script: &str,
//     signature: &str,
// ) -> Handle<Shader> {
//     //
//     // insert common code in every shader
//     let shader_prelude =
//     let mut image_source = shader_skeleton.replace("{{COMMON}}", &COMMON);
//     image_source = image_source.replace(signature, shader_core_script);

//     let image_shader = Shader::from_wgsl(Cow::from(image_source));
//     shaders.set_untracked(shader_handle_untyped.clone(), image_shader.clone());
//     shader_handle_untyped.typed()
// }

// Copied from Shadertoy.com :
// uniform vec3      iResolution;           // viewport resolution (in pixels)
// uniform float     iTime;                 // shader playback time (in seconds)
// uniform float     iTimeDelta;            // render time (in seconds)
// uniform int       iFrame;                // shader playback frame
// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
// uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
// uniform vec4      iDate;                 // (year, month, day, time in seconds)
// uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

#[derive(Component, Default, Clone, AsStd140)]
pub struct CommonUniform {
    pub i_time: f32,
    pub i_time_delta: f32,
    pub i_frame: f32,
    pub i_sample_rate: f32, // sound sample rate

    pub i_mouse: Vec4,
    pub i_resolution: Vec2,

    pub i_channel_time: Vec4,
    pub i_channel_resolution: Vec4,
    pub i_date: [i32; 4],

    pub changed_window_size: f32,
}

pub struct CommonUniformMeta {
    buffer: Buffer,
}

fn make_new_texture(
    // old_buffer_length: i32,
    canvas_size: &CanvasSize,
    image_handle: &Handle<Image>,
    images: &mut ResMut<Assets<Image>>,
) {
    if let Some(image) = images.get_mut(image_handle) {
        // There is no easy way to get the data from the gpu to the cpu, so when we
        // resize the image, we lose all the data. There might be a way to get the
        // data soon though.

        image.resize(Extent3d {
            width: canvas_size.width,
            height: canvas_size.height,
            depth_or_array_layers: 1,
        });
    }
}

// also updates the size of the buffers and main texture accordign to the window size
// TODO: update date, channel time, channe l_resolution, sample_rate
fn update_common_uniform(
    mut common_uniform: ResMut<CommonUniform>,
    mut window_resize_event: EventReader<WindowResized>,
    mut query: Query<(&mut Sprite, &Transform, &Handle<Image>)>,
    mut images: ResMut<Assets<Image>>,
    windows: Res<Windows>,
    time: Res<Time>,
    mouse_button_input: Res<Input<MouseButton>>,
    mut canvas_size: ResMut<CanvasSize>,
    texture_a: Res<TextureA>,
    texture_b: Res<TextureB>,
    texture_c: Res<TextureC>,
    texture_d: Res<TextureD>,
    mut frames_accum: ResMut<ShadertoyResources>,
) {
    // update resolution
    for window_resize in window_resize_event.iter() {
        common_uniform.i_resolution.x = (window_resize.width * BORDERS).floor();
        common_uniform.i_resolution.y = (window_resize.height * BORDERS).floor();

        canvas_size.width = common_uniform.i_resolution.x as u32;
        canvas_size.height = common_uniform.i_resolution.y as u32;
        for (mut sprite, _, image_handle) in query.iter_mut() {
            sprite.custom_size = Some(common_uniform.i_resolution);

            make_new_texture(&canvas_size, image_handle, &mut images);
            make_new_texture(&canvas_size, &texture_a.0, &mut images);
            make_new_texture(&canvas_size, &texture_b.0, &mut images);
            make_new_texture(&canvas_size, &texture_c.0, &mut images);
            make_new_texture(&canvas_size, &texture_d.0, &mut images);
        }
    }

    // update mouse position
    let window = windows.primary();
    if let Some(mouse_pos) = window.cursor_position() {
        let mp = mouse_pos;
        // println!("{:?}", mp);

        for (_, transform, _) in query.iter() {
            let pos = transform.translation.truncate();
            let window_size = Vec2::new(window.width(), window.height());
            let top_left = pos + (window_size - common_uniform.i_resolution) / 2.0;

            common_uniform.i_mouse.x = mp.x - top_left.x;

            common_uniform.i_mouse.y = mp.y - top_left.y;

            if mouse_button_input.just_pressed(MouseButton::Left) {
                common_uniform.i_mouse.z = common_uniform.i_mouse.x;
                common_uniform.i_mouse.w = common_uniform.i_mouse.y;
            }

            if mouse_button_input.pressed(MouseButton::Left) {
                common_uniform.i_mouse.z = common_uniform.i_mouse.z.abs();
                common_uniform.i_mouse.w = common_uniform.i_mouse.w.abs();
            } else {
                common_uniform.i_mouse.z = -common_uniform.i_mouse.z.abs();
                common_uniform.i_mouse.w = -common_uniform.i_mouse.w.abs();
            }
        }
    }

    // update time
    common_uniform.i_time = time.seconds_since_startup() as f32;
    common_uniform.i_time_delta = time.delta_seconds() as f32;
    frames_accum.time_since_reset += time.delta_seconds();
    frames_accum.number_of_frames += 1;
    let fps_refresh_time = 0.5; // seconds

    if frames_accum.time_since_reset > fps_refresh_time {
        common_uniform.i_sample_rate =
            frames_accum.number_of_frames as f32 / frames_accum.time_since_reset;
        frames_accum.time_since_reset = 0.0;
        frames_accum.number_of_frames = 0;
    }

    common_uniform.i_frame += 1.0;
}

pub struct ShadertoyPlugin;

#[derive(Clone)]
pub struct ShaderHandles {
    pub image_shader: Handle<Shader>,
    pub texture_a_shader: Handle<Shader>,
    pub texture_b_shader: Handle<Shader>,
    pub texture_c_shader: Handle<Shader>,
    pub texture_d_shader: Handle<Shader>,
}

impl Plugin for ShadertoyPlugin {
    fn build(&self, app: &mut App) {
        // let mut common_uniform = app.world.resource_mut::<CommonUniform>();
        // common_uniform.i_frame += 1.0;

        app.add_startup_system(setup)
            .add_system(update_common_uniform)
            .insert_resource(ShadertoyResources {
                number_of_frames: 0,
                time_since_reset: 0.0,
                include_debugger: false,
            });

        let render_app = app.sub_app_mut(RenderApp);

        let render_device = render_app.world.resource::<RenderDevice>();

        let buffer = render_device.create_buffer(&BufferDescriptor {
            label: Some("common uniform buffer"),
            size: CommonUniform::std140_size_static() as u64,
            usage: BufferUsages::UNIFORM | BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });

        render_app
            .insert_resource(CommonUniformMeta {
                buffer: buffer.clone(),
            })
            .add_system_to_stage(RenderStage::Prepare, prepare_common_uniform)
            .init_resource::<ShadertoyPipelines>()
            .add_system_to_stage(RenderStage::Extract, extract_main_image)
            .add_system_to_stage(RenderStage::Queue, queue_bind_group)
            // .init_resource::<TextureAPipeline>()
            .add_system_to_stage(RenderStage::Extract, extract_texture_a)
            .add_system_to_stage(RenderStage::Queue, queue_bind_group_a)
            // .init_resource::<TextureBPipeline>()
            .add_system_to_stage(RenderStage::Extract, extract_texture_b)
            .add_system_to_stage(RenderStage::Queue, queue_bind_group_b)
            // .init_resource::<TextureCPipeline>()
            .add_system_to_stage(RenderStage::Extract, extract_texture_c)
            .add_system_to_stage(RenderStage::Queue, queue_bind_group_c)
            // .init_resource::<TextureDPipeline>()
            .add_system_to_stage(RenderStage::Extract, extract_texture_d)
            .add_system_to_stage(RenderStage::Queue, queue_bind_group_d);

        let mut render_graph = render_app.world.resource_mut::<RenderGraph>();

        render_graph.add_node("main_image", MainNode::default());
        render_graph.add_node("texture_a", TextureANode::default());
        render_graph.add_node("texture_b", TextureBNode::default());
        render_graph.add_node("texture_c", TextureCNode::default());
        render_graph.add_node("texture_d", TextureDNode::default());

        render_graph
            .add_node_edge("texture_a", "texture_b")
            .unwrap();

        render_graph
            .add_node_edge("texture_b", "texture_c")
            .unwrap();

        render_graph
            .add_node_edge("texture_c", "texture_d")
            .unwrap();

        render_graph
            .add_node_edge("texture_d", "main_image")
            .unwrap();

        render_graph
            .add_node_edge("main_image", MAIN_PASS_DEPENDENCIES)
            .unwrap();
    }
}

// pub struct ShadertoyPipelines {
//     main_image_group_layout: BindGroupLayout,
// }

pub struct ShadertoyPipelines {
    pub main_image_group_layout: BindGroupLayout,
    pub abcd_group_layout: BindGroupLayout,
}

impl ShadertoyPipelines {
    pub fn make_texture_layout(binding: u32) -> BindGroupLayoutEntry {
        BindGroupLayoutEntry {
            binding,
            visibility: ShaderStages::COMPUTE,
            ty: BindingType::StorageTexture {
                access: StorageTextureAccess::ReadWrite,
                format: TextureFormat::Rgba32Float,
                view_dimension: TextureViewDimension::D2,
            },
            count: None,
        }
    }

    pub fn new(render_device: &RenderDevice) -> Self {
        let uniform_descriptor = BindGroupLayoutEntry {
            binding: 0,
            visibility: ShaderStages::COMPUTE,
            ty: BindingType::Buffer {
                ty: BufferBindingType::Uniform,
                has_dynamic_offset: false,
                min_binding_size: BufferSize::new(CommonUniform::std140_size_static() as u64),
            },
            count: None,
        };

        let abcd_group_layout =
            render_device.create_bind_group_layout(&BindGroupLayoutDescriptor {
                label: Some("abcd_layout"),
                entries: &[
                    uniform_descriptor,
                    ShadertoyPipelines::make_texture_layout(1),
                    ShadertoyPipelines::make_texture_layout(2),
                    ShadertoyPipelines::make_texture_layout(3),
                    ShadertoyPipelines::make_texture_layout(4),
                ],
            });

        let main_image_group_layout =
            render_device.create_bind_group_layout(&BindGroupLayoutDescriptor {
                label: Some("main_layout"),
                entries: &[
                    uniform_descriptor,
                    ShadertoyPipelines::make_texture_layout(1),
                    ShadertoyPipelines::make_texture_layout(2),
                    ShadertoyPipelines::make_texture_layout(3),
                    ShadertoyPipelines::make_texture_layout(4),
                    BindGroupLayoutEntry {
                        binding: 5,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::StorageTexture {
                            access: StorageTextureAccess::ReadWrite,
                            format: TextureFormat::Rgba32Float,
                            view_dimension: TextureViewDimension::D2,
                        },
                        count: None,
                    },
                    // font texture
                    BindGroupLayoutEntry {
                        binding: 6,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::Texture {
                            sample_type: TextureSampleType::Float { filterable: true },
                            view_dimension: TextureViewDimension::D2,
                            multisampled: false,
                        },
                        count: None,
                    },
                    BindGroupLayoutEntry {
                        binding: 7,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::Sampler(SamplerBindingType::Filtering),
                        count: None,
                    },
                    // noise texture
                    BindGroupLayoutEntry {
                        binding: 8,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::Texture {
                            sample_type: TextureSampleType::Float { filterable: true },
                            view_dimension: TextureViewDimension::D2,
                            multisampled: false,
                        },
                        count: None,
                    },
                    BindGroupLayoutEntry {
                        binding: 9,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::Sampler(SamplerBindingType::Filtering),
                        count: None,
                    },
                ],
            });

        ShadertoyPipelines {
            main_image_group_layout,
            abcd_group_layout,
        }
    }
}

impl FromWorld for ShadertoyPipelines {
    fn from_world(world: &mut World) -> Self {
        let common_uni = world.get_resource_mut::<CommonUniform>();

        let mut buffer_min_binding_size = (900 * 600 * 4 * 4) as u64;

        if let Some(uniform) = common_uni {
            buffer_min_binding_size =
                uniform.i_resolution.x as u64 * uniform.i_resolution.y as u64 * 4 * 4;
        }

        let render_device = world.resource::<RenderDevice>();

        ShadertoyPipelines::new(render_device)
    }
}

// impl FromWorld for ShadertoyPipelines {
//     fn from_world(world: &mut World) -> Self {
//         let main_image_group_layout =
//             world
//                 .resource::<RenderDevice>()
//                 .create_bind_group_layout(&BindGroupLayoutDescriptor {
//                     label: Some("main_layout"),
//                     entries: &[
//                         BindGroupLayoutEntry {
//                             binding: 0,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::Buffer {
//                                 ty: BufferBindingType::Uniform,
//                                 has_dynamic_offset: false,
//                                 min_binding_size: BufferSize::new(
//                                     CommonUniform::std140_size_static() as u64,
//                                 ),
//                             },
//                             count: None,
//                         },
//                         BindGroupLayoutEntry {
//                             binding: 1,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::StorageTexture {
//                                 access: StorageTextureAccess::ReadWrite,
//                                 format: TextureFormat::Rgba32Float,
//                                 view_dimension: TextureViewDimension::D2,
//                             },
//                             count: None,
//                         },
//                         BindGroupLayoutEntry {
//                             binding: 2,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::StorageTexture {
//                                 access: StorageTextureAccess::ReadWrite,
//                                 format: TextureFormat::Rgba32Float,
//                                 view_dimension: TextureViewDimension::D2,
//                             },
//                             count: None,
//                         },
//                         BindGroupLayoutEntry {
//                             binding: 3,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::StorageTexture {
//                                 access: StorageTextureAccess::ReadWrite,
//                                 format: TextureFormat::Rgba32Float,
//                                 view_dimension: TextureViewDimension::D2,
//                             },
//                             count: None,
//                         },
//                         BindGroupLayoutEntry {
//                             binding: 4,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::StorageTexture {
//                                 access: StorageTextureAccess::ReadWrite,
//                                 format: TextureFormat::Rgba32Float,
//                                 view_dimension: TextureViewDimension::D2,
//                             },
//                             count: None,
//                         },
//                         BindGroupLayoutEntry {
//                             binding: 5,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::StorageTexture {
//                                 access: StorageTextureAccess::ReadWrite,
//                                 format: TextureFormat::Rgba32Float,
//                                 view_dimension: TextureViewDimension::D2,
//                             },
//                             count: None,
//                         },
//                         // BindGroupLayoutEntry {
//                         //     binding: 6,
//                         //     visibility: ShaderStages::COMPUTE,
//                         //     ty: BindingType::StorageTexture {
//                         //         access: StorageTextureAccess::ReadWrite,
//                         //         format: TextureFormat::Rgba32Float,
//                         //         view_dimension: TextureViewDimension::D2,
//                         //     },
//                         //     count: None,
//                         // },
//                         BindGroupLayoutEntry {
//                             binding: 6,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::Texture {
//                                 sample_type: TextureSampleType::Float { filterable: true },
//                                 view_dimension: TextureViewDimension::D2,
//                                 multisampled: false,
//                             },
//                             count: None,
//                         },
//                         BindGroupLayoutEntry {
//                             binding: 7,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::Sampler(SamplerBindingType::Filtering),
//                             count: None,
//                         },
//                         BindGroupLayoutEntry {
//                             binding: 8,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::Texture {
//                                 sample_type: TextureSampleType::Float { filterable: true },
//                                 view_dimension: TextureViewDimension::D2,
//                                 multisampled: false,
//                             },
//                             count: None,
//                         },
//                         BindGroupLayoutEntry {
//                             binding: 9,
//                             visibility: ShaderStages::COMPUTE,
//                             ty: BindingType::Sampler(SamplerBindingType::Filtering),
//                             count: None,
//                         },
//                     ],
//                 });

//         ShadertoyPipelines {
//             main_image_group_layout,
//         }
//     }
// }

#[derive(Deref)]
struct MainImage(Handle<Image>);

struct MainImageBindGroup {
    main_image_bind_group: BindGroup,
    init_pipeline: CachedComputePipelineId,
    update_pipeline: CachedComputePipelineId,
}

// write the extracted common uniform into the corresponding uniform buffer
pub fn prepare_common_uniform(
    common_uniform_meta: ResMut<CommonUniformMeta>,
    render_queue: Res<RenderQueue>,
    mut common_uniform: ResMut<CommonUniform>,
    render_device: Res<RenderDevice>,
    mut pipelines: ResMut<ShadertoyPipelines>,
) {
    use bevy::render::render_resource::std140::Std140;
    let std140_common_uniform = common_uniform.as_std140();
    let bytes = std140_common_uniform.as_bytes();

    render_queue.write_buffer(
        &common_uniform_meta.buffer,
        0,
        bevy::core::cast_slice(&bytes),
    );

    // modify the pipelines according to the new window size if applicable
    if common_uniform.changed_window_size > 0.5 {
        *pipelines = ShadertoyPipelines::new(&render_device);
        common_uniform.changed_window_size = 0.0;
    }
}

pub struct ChangedWindowSize(pub bool);

fn extract_main_image(
    mut commands: Commands,
    image: Res<MainImage>,
    font_image: ResMut<ShadertoyTextures>,
    common_uniform: Res<CommonUniform>,
    all_shader_handles: Res<ShaderHandles>,
    canvas_size: Res<CanvasSize>,
    mut window_resize_event: EventReader<WindowResized>,
) {
    // insert common uniform only once
    commands.insert_resource(common_uniform.clone());

    commands.insert_resource(MainImage(image.clone()));

    commands.insert_resource(font_image.clone());

    commands.insert_resource(all_shader_handles.clone());

    let mut changed_window_size = false;
    commands.insert_resource(canvas_size.clone());

    for _ in window_resize_event.iter() {
        changed_window_size = true;
    }

    commands.insert_resource(ChangedWindowSize(changed_window_size));
}

fn queue_bind_group(
    mut commands: Commands,
    pipeline: Res<ShadertoyPipelines>,

    gpu_images: Res<RenderAssets<Image>>,
    shadertoy_textures: Res<ShadertoyTextures>,
    main_image: Res<MainImage>,
    texture_a_image: Res<TextureA>,
    texture_b_image: Res<TextureB>,
    texture_c_image: Res<TextureC>,
    texture_d_image: Res<TextureD>,
    render_device: Res<RenderDevice>,
    mut pipeline_cache: ResMut<PipelineCache>,
    all_shader_handles: Res<ShaderHandles>,
    common_uniform_meta: ResMut<CommonUniformMeta>,
    mut changed_size_res: ResMut<ChangedWindowSize>,
    mut render_graph: ResMut<RenderGraph>,
) {
    if changed_size_res.0 {
        changed_size_res.0 = false;

        let main_node: &mut MainNode = render_graph
            .get_node_mut(NodeLabel::Name(Cow::from("main_image")))
            .unwrap();
        main_node.state = ShadertoyState::Loading;

        let texture_a_node: &mut TextureANode = render_graph
            .get_node_mut(NodeLabel::Name(Cow::from("texture_a")))
            .unwrap();
        texture_a_node.state = ShadertoyState::Loading;

        let texture_b_node: &mut TextureBNode = render_graph
            .get_node_mut(NodeLabel::Name(Cow::from("texture_b")))
            .unwrap();
        texture_b_node.state = ShadertoyState::Loading;

        let texture_c_node: &mut TextureCNode = render_graph
            .get_node_mut(NodeLabel::Name(Cow::from("texture_c")))
            .unwrap();
        texture_c_node.state = ShadertoyState::Loading;

        let texture_d_node: &mut TextureDNode = render_graph
            .get_node_mut(NodeLabel::Name(Cow::from("texture_d")))
            .unwrap();
        texture_d_node.state = ShadertoyState::Loading;
    }

    let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: None,
        layout: Some(vec![pipeline.main_image_group_layout.clone()]),
        shader: all_shader_handles.image_shader.clone(),
        shader_defs: vec!["INIT".to_string()],
        entry_point: Cow::from("update"),
    });

    let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: None,
        layout: Some(vec![pipeline.main_image_group_layout.clone()]),
        shader: all_shader_handles.image_shader.clone(),
        shader_defs: vec![],
        entry_point: Cow::from("update"),
    });

    let main_view = &gpu_images[&main_image.0];
    let font_view = &gpu_images[&shadertoy_textures.font_texture_handle];
    let rgba_noise_256_view = &gpu_images[&shadertoy_textures.rgba_noise_256_handle];

    let texture_a_view = &gpu_images[&texture_a_image.0];
    let texture_b_view = &gpu_images[&texture_b_image.0];
    let texture_c_view = &gpu_images[&texture_c_image.0];
    let texture_d_view = &gpu_images[&texture_d_image.0];

    let main_image_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: Some("main_bind_group"),
        layout: &pipeline.main_image_group_layout,
        entries: &[
            BindGroupEntry {
                binding: 0,
                resource: common_uniform_meta.buffer.as_entire_binding(),
            },
            BindGroupEntry {
                binding: 1,
                resource: BindingResource::TextureView(&texture_a_view.texture_view),
            },
            BindGroupEntry {
                binding: 2,
                resource: BindingResource::TextureView(&texture_b_view.texture_view),
            },
            BindGroupEntry {
                binding: 3,
                resource: BindingResource::TextureView(&texture_c_view.texture_view),
            },
            BindGroupEntry {
                binding: 4,
                resource: BindingResource::TextureView(&texture_d_view.texture_view),
            },
            BindGroupEntry {
                binding: 5,
                resource: BindingResource::TextureView(&main_view.texture_view),
            },
            BindGroupEntry {
                binding: 6,
                resource: BindingResource::TextureView(&font_view.texture_view),
            },
            BindGroupEntry {
                binding: 7,
                resource: BindingResource::Sampler(&font_view.sampler),
            },
            BindGroupEntry {
                binding: 8,
                resource: BindingResource::TextureView(&rgba_noise_256_view.texture_view),
            },
            BindGroupEntry {
                binding: 9,
                resource: BindingResource::Sampler(&rgba_noise_256_view.sampler),
            },
        ],
    });

    commands.insert_resource(MainImageBindGroup {
        main_image_bind_group,
        init_pipeline: init_pipeline.clone(),
        update_pipeline: update_pipeline.clone(),
    });
}

pub enum ShadertoyState {
    Loading,
    Init,
    Update,
}

pub struct MainNode {
    pub state: ShadertoyState,
}

impl Default for MainNode {
    fn default() -> Self {
        Self {
            state: ShadertoyState::Loading,
        }
    }
}

impl render_graph::Node for MainNode {
    fn update(&mut self, world: &mut World) {
        let pipeline_cache = world.resource::<PipelineCache>();

        let bind_group = world.resource::<MainImageBindGroup>();

        let init_pipeline_cache = bind_group.init_pipeline;
        let update_pipeline_cache = bind_group.update_pipeline;

        match self.state {
            ShadertoyState::Loading => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(init_pipeline_cache)
                {
                    self.state = ShadertoyState::Init
                }
            }
            ShadertoyState::Init => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(update_pipeline_cache)
                {
                    self.state = ShadertoyState::Update
                }
            }
            ShadertoyState::Update => {}
        }
    }

    fn run(
        &self,
        _graph: &mut render_graph::RenderGraphContext,
        render_context: &mut RenderContext,
        world: &World,
    ) -> Result<(), render_graph::NodeRunError> {
        let bind_group = world.resource::<MainImageBindGroup>();
        let canvas_size = world.resource::<CanvasSize>();

        let init_pipeline_cache = bind_group.init_pipeline;
        let update_pipeline_cache = bind_group.update_pipeline;

        let pipeline_cache = world.resource::<PipelineCache>();

        let mut pass = render_context
            .command_encoder
            .begin_compute_pass(&ComputePassDescriptor {
                label: Some("main_compute_pass"),
            });

        pass.set_bind_group(0, &bind_group.main_image_bind_group, &[]);

        // select the pipeline based on the current state
        match self.state {
            ShadertoyState::Loading => {}

            ShadertoyState::Init => {
                let init_pipeline = pipeline_cache
                    .get_compute_pipeline(init_pipeline_cache)
                    .unwrap();
                pass.set_pipeline(init_pipeline);
                pass.dispatch(
                    canvas_size.width / WORKGROUP_SIZE,
                    canvas_size.height / WORKGROUP_SIZE,
                    1,
                );
            }

            ShadertoyState::Update => {
                let update_pipeline = pipeline_cache
                    .get_compute_pipeline(update_pipeline_cache)
                    .unwrap();
                pass.set_pipeline(update_pipeline);
                pass.dispatch(
                    canvas_size.width / WORKGROUP_SIZE,
                    canvas_size.height / WORKGROUP_SIZE,
                    1,
                );
            }
        }

        Ok(())
    }
}
