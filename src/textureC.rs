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

use crate::textureB::TextureB;
use crate::{ShaderHandles, ShadertoyState, SIZE, WORKGROUP_SIZE};

struct TextureCBindGroup {
    texture_b_bind_group: BindGroup,
    texture_a_bind_group: BindGroup,
    texture_c_bind_group: BindGroup,
    init_pipeline: CachedComputePipelineId,
    update_pipeline: CachedComputePipelineId,
}

#[derive(Deref)]
pub struct TextureC(pub Handle<Image>);

pub struct TextureCPipeline {
    texture_a_bind_group_layout: BindGroupLayout,
    texture_b_bind_group_layout: BindGroupLayout,
    texture_c_bind_group_layout: BindGroupLayout,
}

impl FromWorld for TextureCPipeline {
    fn from_world(world: &mut World) -> Self {
        let texture_c_bind_group_layout = world
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

        // let shader = world
        //     .resource::<AssetServer>()
        //     .load("shaders/texture_b.wgsl");

        TextureCPipeline {
            texture_c_bind_group_layout,
            texture_b_bind_group_layout,
            texture_a_bind_group_layout,
        }
    }
}

pub fn extract_texture_c(mut commands: Commands, image: Res<TextureC>) {
    commands.insert_resource(TextureC(image.clone()));
}

pub fn queue_bind_group_c(
    mut commands: Commands,
    pipeline: Res<TextureCPipeline>,
    gpu_images: Res<RenderAssets<Image>>,
    texture_c: Res<TextureC>,
    texture_b: Res<TextureB>,
    texture_a: Res<TextureA>,
    render_device: Res<RenderDevice>,
    mut pipeline_cache: ResMut<PipelineCache>,
    all_shader_handles: Res<ShaderHandles>,
) {
    let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: None,
        layout: Some(vec![
            // pipeline.texture_c_bind_group_layout.clone(),
            // pipeline.texture_b_bind_group_layout.clone(),
            // pipeline.texture_a_bind_group_layout.clone(),
            pipeline.texture_a_bind_group_layout.clone(),
            pipeline.texture_b_bind_group_layout.clone(),
            pipeline.texture_c_bind_group_layout.clone(),
        ]),
        shader: all_shader_handles.texture_c_shader.clone(),
        shader_defs: vec![],
        entry_point: Cow::from("init"),
    });

    let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: None,
        layout: Some(vec![
            pipeline.texture_a_bind_group_layout.clone(),
            pipeline.texture_b_bind_group_layout.clone(),
            pipeline.texture_c_bind_group_layout.clone(),
        ]),
        shader: all_shader_handles.texture_c_shader.clone(),
        shader_defs: vec![],
        entry_point: Cow::from("update"),
    });

    let view = &gpu_images[&texture_c.0];

    let texture_c_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: None,
        layout: &pipeline.texture_c_bind_group_layout,
        entries: &[BindGroupEntry {
            binding: 0,
            resource: BindingResource::TextureView(&view.texture_view),
        }],
    });

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

    commands.insert_resource(TextureCBindGroup {
        texture_c_bind_group,
        texture_b_bind_group,
        texture_a_bind_group,
        init_pipeline,
        update_pipeline,
    });
}

pub struct TextureCNode {
    pub state: ShadertoyState,
}

impl Default for TextureCNode {
    fn default() -> Self {
        Self {
            state: ShadertoyState::Loading,
        }
    }
}

impl render_graph::Node for TextureCNode {
    fn update(&mut self, world: &mut World) {
        let bind_group = world.resource::<TextureCBindGroup>();

        let pipeline_cache = world.resource::<PipelineCache>();

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
        let bind_group = world.resource::<TextureCBindGroup>();

        let texture_c_bind_group = &bind_group.texture_c_bind_group;
        let texture_b_bind_group = &bind_group.texture_b_bind_group;
        let texture_a_bind_group = &bind_group.texture_a_bind_group;

        let init_pipeline_cache = bind_group.init_pipeline;
        let update_pipeline_cache = bind_group.update_pipeline;

        let pipeline_cache = world.resource::<PipelineCache>();

        let mut pass = render_context
            .command_encoder
            .begin_compute_pass(&ComputePassDescriptor::default());

        pass.set_bind_group(2, texture_c_bind_group, &[]);
        pass.set_bind_group(1, texture_b_bind_group, &[]);
        pass.set_bind_group(0, texture_a_bind_group, &[]);

        // select the pipeline based on the current state
        match self.state {
            ShadertoyState::Loading => {}

            ShadertoyState::Init => {
                let init_pipeline = pipeline_cache
                    .get_compute_pipeline(init_pipeline_cache)
                    .unwrap();
                pass.set_pipeline(init_pipeline);
                pass.dispatch(SIZE.0 / WORKGROUP_SIZE, SIZE.1 / WORKGROUP_SIZE, 1);
            }

            ShadertoyState::Update => {
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
