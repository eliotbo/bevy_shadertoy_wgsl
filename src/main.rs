use bevy::{
    core::{cast_slice, FloatOrd, Pod, Time, Zeroable},
    core_pipeline::node::MAIN_PASS_DEPENDENCIES,
    pbr::{MeshPipeline, MeshPipelineKey, MeshUniform, SetMeshBindGroup, SetMeshViewBindGroup},
    prelude::*,
    reflect::TypeUuid,
    render::{
        mesh::{GpuBufferInfo, MeshVertexBufferLayout},
        render_asset::RenderAssets,
        render_graph::{self, RenderGraph},
        // render_resource::*,
        render_resource::{
            std430::{AsStd430, Std430},
            *,
        },
        renderer::{RenderContext, RenderDevice},
        RenderApp,
        RenderStage,
    },
    window::WindowDescriptor,
};
// use std::borrow::Cow;
use bytemuck::bytes_of;
use rand::*;
use std::{borrow::Cow, cmp::Ordering, num::NonZeroU64, ops::Deref, ops::Range};

// mod bufferA;
// use bufferA::*;

mod textureA;
use textureA::*;

mod textureB;
use textureB::*;

pub const SIZE: (u32, u32) = (1280, 720);
pub const WORKGROUP_SIZE: u32 = 8;
pub const NUM_PARTICLES: u32 = 256;

const COMMON: &'static str = include_str!("common.wgsl");

const IMAGE_SHADER: &'static str = include_str!("image.wgsl");
pub const IMAGE_SHADER_HANDLE: HandleUntyped = HandleUntyped::weak_from_u64(
    bevy::render::render_resource::Shader::TYPE_UUID,
    192598017680025719,
);

const TEXTURE_A_SHADER: &'static str = include_str!("texture_a.wgsl");
pub const TEXTURE_A_SHADER_HANDLE: HandleUntyped = HandleUntyped::weak_from_u64(
    bevy::render::render_resource::Shader::TYPE_UUID,
    986988749367675188,
);

const TEXTURE_B_SHADER: &'static str = include_str!("texture_b.wgsl");
pub const TEXTURE_B_SHADER_HANDLE: HandleUntyped = HandleUntyped::weak_from_u64(
    bevy::render::render_resource::Shader::TYPE_UUID,
    808999425257967014,
);

const TEXTURE_C_SHADER: &'static str = include_str!("texture_c.wgsl");
pub const TEXTURE_C_SHADER_HANDLE: HandleUntyped = HandleUntyped::weak_from_u64(
    bevy::render::render_resource::Shader::TYPE_UUID,
    819348234244712380,
);

const TEXTURE_D_SHADER: &'static str = include_str!("texture_d.wgsl");
pub const TEXTURE_D_SHADER_HANDLE: HandleUntyped = HandleUntyped::weak_from_u64(
    bevy::render::render_resource::Shader::TYPE_UUID,
    193535259211504032,
);

fn main() {
    App::new()
        .insert_resource(ClearColor(Color::BLACK))
        .insert_resource(WindowDescriptor {
            // uncomment for unthrottled FPS
            // vsync: false,
            ..default()
        })
        .add_plugins(DefaultPlugins)
        .add_plugin(GameOfLifeComputePlugin)
        .add_startup_system(setup)
        .run();
}

fn setup(mut commands: Commands, mut images: ResMut<Assets<Image>>) {
    commands.spawn_bundle(OrthographicCameraBundle::new_2d());

    let mut image = Image::new_fill(
        Extent3d {
            width: SIZE.0,
            height: SIZE.1,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        &[0, 0, 0, 0],
        TextureFormat::Rgba8Unorm,
    );
    image.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;

    let image = images.add(image);

    commands.insert_resource(MainImage(image.clone()));

    commands.spawn_bundle(SpriteBundle {
        sprite: Sprite {
            custom_size: Some(Vec2::new(SIZE.0 as f32, SIZE.1 as f32)),
            ..default()
        },
        texture: image.clone(),
        ..default()
    });

    //
    //
    //
    // Texture A: equivalent of Buffer A in Shadertoy
    let mut texture_a = Image::new_fill(
        Extent3d {
            width: SIZE.0,
            height: SIZE.1,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        // &[255, 255, 255, 255],
        &[0, 0, 0, 0],
        TextureFormat::Rgba8Unorm,
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
            width: SIZE.0,
            height: SIZE.1,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        // &[255, 255, 255, 255],
        &[0, 0, 0, 0],
        TextureFormat::Rgba8Unorm,
    );
    texture_b.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;

    let texture_b = images.add(texture_b);

    commands.insert_resource(TextureB(texture_b));
}

pub struct GameOfLifeComputePlugin;

pub struct ShaderHandles {
    pub image_shader: Handle<Shader>,
    pub texture_a_shader: Handle<Shader>,
    pub texture_b_shader: Handle<Shader>,
    pub texture_c_shader: Handle<Shader>,
    pub texture_d_shader: Handle<Shader>,
}

impl Plugin for GameOfLifeComputePlugin {
    fn build(&self, app: &mut App) {
        let render_app = app.sub_app_mut(RenderApp);
        render_app
            .init_resource::<MainImagePipeline>()
            .add_system_to_stage(RenderStage::Extract, extract_main_image)
            .add_system_to_stage(RenderStage::Queue, queue_bind_group)
            .init_resource::<TextureAPipeline>()
            .add_system_to_stage(RenderStage::Extract, extract_texture_a)
            .add_system_to_stage(RenderStage::Queue, queue_bind_group_a)
            .init_resource::<TextureBPipeline>()
            .add_system_to_stage(RenderStage::Extract, extract_texture_b)
            .add_system_to_stage(RenderStage::Queue, queue_bind_group_b);

        // .init_resource::<MainImagePipeline2>()
        // .add_system_to_stage(RenderStage::Extract, extract_main_image2)
        // .add_system_to_stage(RenderStage::Queue, queue_bind_group2);

        let mut render_graph = render_app.world.resource_mut::<RenderGraph>();

        render_graph.add_node("main_image", GameOfLifeNode::default());
        render_graph.add_node("texture_a", TextureANode::default());
        render_graph.add_node("texture_b", TextureBNode::default());

        render_graph
            .add_node_edge("texture_a", "texture_b")
            .unwrap();

        render_graph
            .add_node_edge("texture_b", "main_image")
            .unwrap();

        render_graph
            .add_node_edge("main_image", MAIN_PASS_DEPENDENCIES)
            .unwrap();
    }
}

#[derive(Deref)]
struct MainImage(Handle<Image>);

struct MainImageBindGroup {
    main_image_bind_group: BindGroup,
    texture_a_bind_group: BindGroup,
    texture_b_bind_group: BindGroup,
    init_pipeline: CachedComputePipelineId,
    update_pipeline: CachedComputePipelineId,
}

fn import_shader(
    shader_skeleton: &str,
    shader_handle_untyped: HandleUntyped,
    shaders: &mut Assets<Shader>,
) -> Handle<Shader> {
    //
    // insert common code in every shader
    let image_source = shader_skeleton.replace("{{COMMON}}", &COMMON);
    let image_shader = Shader::from_wgsl(Cow::from(image_source));
    shaders.set_untracked(shader_handle_untyped.clone(), image_shader.clone());
    shader_handle_untyped.typed()
}

fn extract_main_image(
    mut commands: Commands,
    image: Res<MainImage>,
    mut shaders: ResMut<Assets<Shader>>,
) {
    commands.insert_resource(MainImage(image.clone()));

    let image_shader_handle = import_shader(IMAGE_SHADER, IMAGE_SHADER_HANDLE, &mut shaders);

    let texture_a_shader_handle =
        import_shader(TEXTURE_A_SHADER, TEXTURE_A_SHADER_HANDLE, &mut shaders);

    let texture_b_shader_handle =
        import_shader(TEXTURE_B_SHADER, TEXTURE_B_SHADER_HANDLE, &mut shaders);

    let texture_c_shader_handle =
        import_shader(TEXTURE_C_SHADER, TEXTURE_C_SHADER_HANDLE, &mut shaders);

    let texture_d_shader_handle =
        import_shader(TEXTURE_D_SHADER, TEXTURE_D_SHADER_HANDLE, &mut shaders);

    let all_shader_handles = ShaderHandles {
        image_shader: image_shader_handle,
        texture_a_shader: texture_a_shader_handle,
        texture_b_shader: texture_b_shader_handle,
        texture_c_shader: texture_c_shader_handle,
        texture_d_shader: texture_d_shader_handle,
    };

    commands.insert_resource(all_shader_handles);
}

fn queue_bind_group(
    mut commands: Commands,
    pipeline: Res<MainImagePipeline>,

    gpu_images: Res<RenderAssets<Image>>,
    main_image: Res<MainImage>,
    texture_a_image: Res<TextureA>,
    texture_b_image: Res<TextureB>,
    render_device: Res<RenderDevice>,
    mut pipeline_cache: ResMut<PipelineCache>,
    main_image_pipeline: Res<MainImagePipeline>,
    all_shader_handles: Res<ShaderHandles>,
) {
    // let mut pipeline_cache = world.resource_mut::<PipelineCache>();

    let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: None,
        layout: Some(vec![
            main_image_pipeline.main_image_group_layout.clone(),
            main_image_pipeline.texture_a_group_layout.clone(),
            main_image_pipeline.texture_b_group_layout.clone(),
        ]),
        // shader: shader_typed_handle.clone(),
        shader: all_shader_handles.image_shader.clone(),
        // shader: Shader::default(),
        shader_defs: vec![],
        entry_point: Cow::from("init"),
    });

    let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: None,
        layout: Some(vec![
            main_image_pipeline.main_image_group_layout.clone(),
            main_image_pipeline.texture_a_group_layout.clone(),
            main_image_pipeline.texture_b_group_layout.clone(),
        ]), // add particles here
        // shader: shader_typed_handle,
        shader: all_shader_handles.image_shader.clone(),
        shader_defs: vec![],
        entry_point: Cow::from("update"),
    });

    let view = &gpu_images[&main_image.0];

    let main_image_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: None,
        layout: &pipeline.main_image_group_layout,
        entries: &[BindGroupEntry {
            binding: 0,
            resource: BindingResource::TextureView(&view.texture_view),
        }],
    });

    let view_a = &gpu_images[&texture_a_image.0];

    let texture_a_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: None,
        layout: &pipeline.texture_a_group_layout,
        entries: &[BindGroupEntry {
            binding: 0,
            resource: BindingResource::TextureView(&view_a.texture_view),
        }],
    });

    let view_b = &gpu_images[&texture_b_image.0];

    let texture_b_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: None,
        layout: &pipeline.texture_b_group_layout,
        entries: &[BindGroupEntry {
            binding: 0,
            resource: BindingResource::TextureView(&view_b.texture_view),
        }],
    });

    commands.insert_resource(MainImageBindGroup {
        main_image_bind_group,
        texture_a_bind_group,
        texture_b_bind_group,
        init_pipeline: init_pipeline.clone(),
        update_pipeline: update_pipeline.clone(),
    });
}

pub struct MainImagePipeline {
    main_image_group_layout: BindGroupLayout,
    texture_a_group_layout: BindGroupLayout,
    texture_b_group_layout: BindGroupLayout,
    // init_pipeline: CachedComputePipelineId,
    // update_pipeline: CachedComputePipelineId,
}

impl FromWorld for MainImagePipeline {
    fn from_world(world: &mut World) -> Self {
        let main_image_group_layout =
            world
                .resource::<RenderDevice>()
                .create_bind_group_layout(&BindGroupLayoutDescriptor {
                    label: None,
                    entries: &[BindGroupLayoutEntry {
                        binding: 0,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::StorageTexture {
                            access: StorageTextureAccess::ReadWrite,
                            format: TextureFormat::Rgba8Unorm,
                            view_dimension: TextureViewDimension::D2,
                        },
                        count: None,
                    }],
                });

        let texture_a_group_layout =
            world
                .resource::<RenderDevice>()
                .create_bind_group_layout(&BindGroupLayoutDescriptor {
                    label: None,
                    entries: &[BindGroupLayoutEntry {
                        binding: 0,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::StorageTexture {
                            access: StorageTextureAccess::ReadWrite,
                            format: TextureFormat::Rgba8Unorm,
                            view_dimension: TextureViewDimension::D2,
                        },
                        count: None,
                    }],
                });

        let texture_b_group_layout =
            world
                .resource::<RenderDevice>()
                .create_bind_group_layout(&BindGroupLayoutDescriptor {
                    label: None,
                    entries: &[BindGroupLayoutEntry {
                        binding: 0,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::StorageTexture {
                            access: StorageTextureAccess::ReadWrite,
                            format: TextureFormat::Rgba8Unorm,
                            view_dimension: TextureViewDimension::D2,
                        },
                        count: None,
                    }],
                });

        MainImagePipeline {
            main_image_group_layout,
            texture_a_group_layout,
            texture_b_group_layout,
        }
    }
}

#[derive(Clone, Hash, PartialEq, Eq)]
pub struct MainUpdatePipelineKey {
    common_code: String,
}

impl Default for MainUpdatePipelineKey {
    fn default() -> Self {
        MainUpdatePipelineKey {
            common_code: Default::default(),
        }
    }
}

pub enum GameOfLifeState {
    Loading,
    Init,
    Update,
}

pub struct GameOfLifeNode {
    pub state: GameOfLifeState,
}

impl Default for GameOfLifeNode {
    fn default() -> Self {
        Self {
            state: GameOfLifeState::Loading,
        }
    }
}

impl render_graph::Node for GameOfLifeNode {
    fn update(&mut self, world: &mut World) {
        let pipeline_cache = world.resource::<PipelineCache>();

        let main_imagine_bind_group = world.resource::<MainImageBindGroup>();

        let init_pipeline_cache = main_imagine_bind_group.init_pipeline;
        let update_pipeline_cache = main_imagine_bind_group.update_pipeline;

        match self.state {
            GameOfLifeState::Loading => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(init_pipeline_cache)
                {
                    self.state = GameOfLifeState::Init
                }
            }
            GameOfLifeState::Init => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(update_pipeline_cache)
                {
                    self.state = GameOfLifeState::Update
                }
            }
            GameOfLifeState::Update => {
                // pipeline_cache

                // println!("{:?}", update_shader);
            }
        }
    }

    fn run(
        &self,
        _graph: &mut render_graph::RenderGraphContext,
        render_context: &mut RenderContext,
        world: &World,
    ) -> Result<(), render_graph::NodeRunError> {
        let main_imagine_bind_group = world.resource::<MainImageBindGroup>();

        let main_image_bind_group = &main_imagine_bind_group.main_image_bind_group;
        let texture_a_bind_group = &main_imagine_bind_group.texture_a_bind_group;
        let texture_b_bind_group = &main_imagine_bind_group.texture_b_bind_group;
        let init_pipeline_cache = main_imagine_bind_group.init_pipeline;
        let update_pipeline_cache = main_imagine_bind_group.update_pipeline;

        // let particle_bind_group = &world.resource::<ParticleBindGroup>().0;

        let pipeline_cache = world.resource::<PipelineCache>();
        // let pipeline = world.resource::<MainImagePipeline>();
        // let pipeline2 = world.resource::<MainImagePipeline>();

        let mut pass = render_context
            .command_encoder
            .begin_compute_pass(&ComputePassDescriptor::default());

        pass.set_bind_group(0, main_image_bind_group, &[]);
        pass.set_bind_group(1, texture_a_bind_group, &[]);
        pass.set_bind_group(2, texture_b_bind_group, &[]);

        // select the pipeline based on the current state
        match self.state {
            GameOfLifeState::Loading => {}

            GameOfLifeState::Init => {
                let init_pipeline = pipeline_cache
                    .get_compute_pipeline(init_pipeline_cache)
                    .unwrap();
                pass.set_pipeline(init_pipeline);
                pass.dispatch(SIZE.0 / WORKGROUP_SIZE, SIZE.1 / WORKGROUP_SIZE, 1);
            }

            GameOfLifeState::Update => {
                let update_pipeline = pipeline_cache
                    .get_compute_pipeline(update_pipeline_cache)
                    .unwrap();
                pass.set_pipeline(update_pipeline);
                pass.dispatch(SIZE.0 / WORKGROUP_SIZE, SIZE.1 / WORKGROUP_SIZE, 1);
            }
        }

        Ok(())
    }
}
