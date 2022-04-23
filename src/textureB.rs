use bevy::{
    core::{cast_slice, FloatOrd, Pod, Time, Zeroable},
    core_pipeline::node::MAIN_PASS_DEPENDENCIES,
    prelude::*,
    render::{
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

use crate::textureA::*;

// use std::borrow::Cow;
use bytemuck::bytes_of;
use rand::*;
use std::{borrow::Cow, cmp::Ordering, num::NonZeroU64, ops::Deref, ops::Range};

use crate::{GameOfLifeState, SIZE, WORKGROUP_SIZE};

struct TextureBBindGroup {
    texture_b_bind_group: BindGroup,
    texture_a_bind_group: BindGroup,
}

#[derive(Deref)]
pub struct TextureB(pub Handle<Image>);

pub fn extract_texture_b(mut commands: Commands, image: Res<TextureB>) {
    commands.insert_resource(TextureB(image.clone()));
}

pub fn queue_bind_group_b(
    mut commands: Commands,
    pipeline: Res<TextureBPipeline>,
    gpu_images: Res<RenderAssets<Image>>,
    texture_b: Res<TextureB>,
    texture_a: Res<TextureA>,
    render_device: Res<RenderDevice>,
) {
    let view = &gpu_images[&texture_b.0];

    let texture_b_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: None,
        layout: &pipeline.texture_b_bind_group_layout,
        entries: &[BindGroupEntry {
            binding: 0,
            resource: BindingResource::TextureView(&view.texture_view),
        }],
    });

    let view = &gpu_images[&texture_a.0];

    let texture_a_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: None,
        layout: &pipeline.texture_a_bind_group_layout,
        entries: &[BindGroupEntry {
            binding: 0,
            resource: BindingResource::TextureView(&view.texture_view),
        }],
    });

    commands.insert_resource(TextureBBindGroup {
        texture_b_bind_group,
        texture_a_bind_group,
    });
}

pub struct TextureBPipeline {
    texture_a_bind_group_layout: BindGroupLayout,
    texture_b_bind_group_layout: BindGroupLayout,
    init_pipeline: CachedComputePipelineId,
    update_pipeline: CachedComputePipelineId,
}

impl FromWorld for TextureBPipeline {
    fn from_world(world: &mut World) -> Self {
        let texture_b_bind_group_layout = world
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

        let texture_a_bind_group_layout = world
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

        let shader = world
            .resource::<AssetServer>()
            .load("shaders/texture_b.wgsl");
        let mut pipeline_cache = world.resource_mut::<PipelineCache>();

        let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: None,
            layout: Some(vec![texture_a_bind_group_layout.clone()]),
            shader: shader.clone(),
            shader_defs: vec![],
            entry_point: Cow::from("init"),
        });

        let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: None,
            layout: Some(vec![texture_a_bind_group_layout.clone()]),
            shader,
            shader_defs: vec![],
            entry_point: Cow::from("update"),
        });

        TextureBPipeline {
            texture_b_bind_group_layout,
            texture_a_bind_group_layout,

            init_pipeline,
            update_pipeline,
        }
    }
}

pub struct TextureBNode {
    pub state: GameOfLifeState,
}

impl Default for TextureBNode {
    fn default() -> Self {
        Self {
            state: GameOfLifeState::Loading,
        }
    }
}

impl render_graph::Node for TextureBNode {
    fn update(&mut self, world: &mut World) {
        let pipeline = world.resource::<TextureBPipeline>();
        // let pipeline2 = world.resource::<TextureBPipeline2>();
        let pipeline_cache = world.resource::<PipelineCache>();

        // if the corresponding pipeline has loaded, transition to the next stage
        match self.state {
            GameOfLifeState::Loading => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(pipeline.init_pipeline)
                {
                    self.state = GameOfLifeState::Init
                }
            }
            GameOfLifeState::Init => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(pipeline.update_pipeline)
                {
                    self.state = GameOfLifeState::Update
                }
            }
            GameOfLifeState::Update => {}
        }
    }

    fn run(
        &self,
        _graph: &mut render_graph::RenderGraphContext,
        render_context: &mut RenderContext,
        world: &World,
    ) -> Result<(), render_graph::NodeRunError> {
        let texture_b_bind_group = &world.resource::<TextureBBindGroup>().texture_b_bind_group;
        let texture_a_bind_group = &world.resource::<TextureBBindGroup>().texture_a_bind_group;

        // let particle_bind_group = &world.resource::<ParticleBindGroup>().0;

        let pipeline_cache = world.resource::<PipelineCache>();
        let pipeline = world.resource::<TextureBPipeline>();
        // let pipeline2 = world.resource::<TextureBPipeline>();

        let mut pass = render_context
            .command_encoder
            .begin_compute_pass(&ComputePassDescriptor::default());

        pass.set_bind_group(0, texture_b_bind_group, &[]);
        pass.set_bind_group(1, texture_a_bind_group, &[]);

        // select the pipeline based on the current state
        match self.state {
            GameOfLifeState::Loading => {}

            GameOfLifeState::Init => {
                let init_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline.init_pipeline)
                    .unwrap();
                pass.set_pipeline(init_pipeline);
                pass.dispatch(SIZE.0 / WORKGROUP_SIZE, SIZE.1 / WORKGROUP_SIZE, 1);
            }

            GameOfLifeState::Update => {
                let update_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline.update_pipeline)
                    .unwrap();
                pass.set_pipeline(update_pipeline);
                pass.dispatch(SIZE.0 / WORKGROUP_SIZE, SIZE.1 / WORKGROUP_SIZE, 1);
            }
        }

        Ok(())
    }
}
