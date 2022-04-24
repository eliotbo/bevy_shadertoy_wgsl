use bevy::{
    core::{cast_slice, FloatOrd, Pod, Time, Zeroable},
    core_pipeline::node::MAIN_PASS_DEPENDENCIES,
    prelude::*,
    render::{
        render_asset::RenderAssets,
        render_graph::{self, RenderGraph},
        // render_resource::*,
        render_resource::{
            std140::AsStd140,
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

use crate::{
    CommonUniformMeta, MainImagePipeline, ShaderHandles, ShadertoyState, SIZE, WORKGROUP_SIZE,
};

struct TextureABindGroup {
    texture_a_bind_group: BindGroup,
    init_pipeline: CachedComputePipelineId,
    update_pipeline: CachedComputePipelineId,
}

#[derive(Deref)]
pub struct TextureA(pub Handle<Image>);

pub fn extract_texture_a(mut commands: Commands, image: Res<TextureA>) {
    commands.insert_resource(TextureA(image.clone()));
}

pub fn queue_bind_group_a(
    mut commands: Commands,
    // pipeline: Res<TextureAPipeline>,
    main_pipeline: Res<MainImagePipeline>,
    gpu_images: Res<RenderAssets<Image>>,
    texture_a: Res<TextureA>,
    render_device: Res<RenderDevice>,
    mut pipeline_cache: ResMut<PipelineCache>,
    all_shader_handles: Res<ShaderHandles>,
    // mut common_uniform_meta: ResMut<CommonUniformMeta>,
) {
    let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: Some(Cow::from("texture_a_init")),
        layout: Some(vec![
            main_pipeline.texture_a_bind_group_layout.clone(),
            // main_pipeline.common_uniform_layout.clone(),
        ]),
        shader: all_shader_handles.texture_a_shader.clone(),
        shader_defs: vec![],
        entry_point: Cow::from("init"),
    });

    let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: Some(Cow::from("texture_a_update")),
        layout: Some(vec![
            main_pipeline.texture_a_bind_group_layout.clone(),
            // main_pipeline.common_uniform_layout.clone(),
        ]),
        shader: all_shader_handles.texture_a_shader.clone(),
        shader_defs: vec![],
        entry_point: Cow::from("update"),
    });

    let view = &gpu_images[&texture_a.0];

    let texture_a_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: None,
        layout: &main_pipeline.texture_a_bind_group_layout,
        entries: &[BindGroupEntry {
            binding: 0,
            resource: BindingResource::TextureView(&view.texture_view),
        }],
    });

    // // Common uniform
    // //
    // //
    // let common_uniform_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
    //     label: None,
    //     layout: &main_pipeline.common_uniform_layout,
    //     entries: &[BindGroupEntry {
    //         binding: 0,
    //         resource: common_uniform_meta.buffer.as_entire_binding(),
    //     }],
    // });
    // common_uniform_meta.bind_group = Some(common_uniform_bind_group);

    commands.insert_resource(TextureABindGroup {
        texture_a_bind_group,
        init_pipeline,
        update_pipeline,
    });
}

pub struct TextureANode {
    pub state: ShadertoyState,
}

impl Default for TextureANode {
    fn default() -> Self {
        Self {
            state: ShadertoyState::Loading,
        }
    }
}

impl render_graph::Node for TextureANode {
    fn update(&mut self, world: &mut World) {
        let pipeline_cache = world.resource::<PipelineCache>();

        let bind_group = world.resource::<TextureABindGroup>();

        let init_pipeline = bind_group.init_pipeline;
        let update_pipeline = bind_group.update_pipeline;

        // if the corresponding pipeline has loaded, transition to the next stage
        match self.state {
            ShadertoyState::Loading => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(init_pipeline)
                {
                    self.state = ShadertoyState::Init
                }
            }
            ShadertoyState::Init => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(update_pipeline)
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
        let bind_group = world.resource::<TextureABindGroup>();

        let common_uniform_meta = world.resource::<CommonUniformMeta>();
        let common_uni_bind_group = &common_uniform_meta.bind_group.clone().unwrap();

        let texture_a_bind_group = &bind_group.texture_a_bind_group;

        let init_pipeline_cache = bind_group.init_pipeline;
        let update_pipeline_cache = bind_group.update_pipeline;

        let pipeline_cache = world.resource::<PipelineCache>();

        let mut pass = render_context
            .command_encoder
            .begin_compute_pass(&ComputePassDescriptor::default());

        pass.set_bind_group(0, texture_a_bind_group, &[]);
        // pass.set_bind_group(1, common_uni_bind_group, &[]);

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
