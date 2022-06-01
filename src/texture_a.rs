use bevy::{
    prelude::*,
    render::{
        render_asset::RenderAssets,
        render_graph::{self},
        render_resource::{std140::AsStd140, *},
        renderer::{RenderContext, RenderDevice},
    },
};

use std::borrow::Cow;

use crate::{
    CommonUniform, CommonUniformMeta, ShaderHandles, ShadertoyState, SIZE, WORKGROUP_SIZE,
};

struct TextureABindGroup {
    // texture_b_bind_group: BindGroup,
    texture_a_bind_group: BindGroup,
    // common_uniform_bind_group: BindGroup,
    init_pipeline: CachedComputePipelineId,
    update_pipeline: CachedComputePipelineId,
}

// pub struct CommonUniformMetaA {
//     // buffer: UniformVec<CommonUniform>,
//     pub buffer: Buffer,
//     // bind_group: Option<BindGroup>,
// }

#[derive(Deref)]
pub struct TextureA(pub Handle<Image>);

pub struct TextureAPipeline {
    texture_a_bind_group_layout: BindGroupLayout,
}

impl FromWorld for TextureAPipeline {
    fn from_world(world: &mut World) -> Self {
        let texture_a_bind_group_layout = world
            .resource::<RenderDevice>()
            .create_bind_group_layout(&BindGroupLayoutDescriptor {
                label: Some("layout_a"),
                entries: &[
                    BindGroupLayoutEntry {
                        binding: 0,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::Buffer {
                            ty: BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: BufferSize::new(
                                CommonUniform::std140_size_static() as u64
                            ),
                        },
                        count: None,
                    },
                    BindGroupLayoutEntry {
                        binding: 1,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::StorageTexture {
                            access: StorageTextureAccess::ReadWrite,
                            format: TextureFormat::Rgba8Unorm,
                            view_dimension: TextureViewDimension::D2,
                        },
                        count: None,
                    },
                ],
            });

        TextureAPipeline {
            texture_a_bind_group_layout,
        }
    }
}

pub fn extract_texture_a(mut commands: Commands, image: Res<TextureA>) {
    commands.insert_resource(TextureA(image.clone()));
}

pub fn queue_bind_group_a(
    mut commands: Commands,
    pipeline: Res<TextureAPipeline>,
    gpu_images: Res<RenderAssets<Image>>,
    // texture_b: Res<TextureA>,
    texture_a: Res<TextureA>,
    render_device: Res<RenderDevice>,
    mut pipeline_cache: ResMut<PipelineCache>,
    all_shader_handles: Res<ShaderHandles>,
    common_uniform_meta: ResMut<CommonUniformMeta>,
) {
    let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: None,
        layout: Some(vec![pipeline.texture_a_bind_group_layout.clone()]),
        shader: all_shader_handles.texture_a_shader.clone(),
        shader_defs: vec!["INIT".to_string()],
        entry_point: Cow::from("update"),
    });

    let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
        label: None,
        layout: Some(vec![pipeline.texture_a_bind_group_layout.clone()]),
        shader: all_shader_handles.texture_a_shader.clone(),
        shader_defs: vec![],
        entry_point: Cow::from("update"),
    });

    let texture_a_view = &gpu_images[&texture_a.0];

    let texture_a_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: Some("texture_a_bind_group"),
        layout: &pipeline.texture_a_bind_group_layout,
        entries: &[
            BindGroupEntry {
                binding: 0,
                resource: common_uniform_meta.buffer.as_entire_binding(),
            },
            BindGroupEntry {
                binding: 1,
                resource: BindingResource::TextureView(&texture_a_view.texture_view),
            },
        ],
    });

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
        let bind_group = world.resource::<TextureABindGroup>();

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
        let bind_group = world.resource::<TextureABindGroup>();

        // let texture_b_bind_group = &bind_group.texture_b_bind_group;
        let texture_a_bind_group = &bind_group.texture_a_bind_group;

        // let common_uni_bind_group = bind_group.common_uniform_bind_group.clone();

        let init_pipeline_cache = bind_group.init_pipeline;
        let update_pipeline_cache = bind_group.update_pipeline;

        let pipeline_cache = world.resource::<PipelineCache>();

        let mut pass = render_context
            .command_encoder
            .begin_compute_pass(&ComputePassDescriptor::default());

        // pass.set_bind_group(0, &common_uni_bind_group, &[]);
        pass.set_bind_group(0, texture_a_bind_group, &[]);

        // pass.set_bind_group(1, texture_b_bind_group, &[]);

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
