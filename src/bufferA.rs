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
// use std::borrow::Cow;
// use bytemuck::bytes_of;
use rand::*;
use std::{borrow::Cow, cmp::Ordering, num::NonZeroU64, ops::Deref, ops::Range};

use crate::{GameOfLifeState, NUM_PARTICLES, SIZE, WORKGROUP_SIZE};

// const SIZE: (u32, u32) = (1280, 720);
// const WORKGROUP_SIZE: u32 = 8;
// const NUM_PARTICLES: u32 = 256;

struct ParticleBindGroup(BindGroup);

pub struct GameOfLifePipeline2 {
    particle_bind_group_layout2: BindGroupLayout,
    particle_pipeline2: CachedComputePipelineId,
}

impl FromWorld for GameOfLifePipeline2 {
    fn from_world(world: &mut World) -> Self {
        let particle_bind_group_layout2 = world
            .resource::<RenderDevice>()
            .create_bind_group_layout(&BindGroupLayoutDescriptor {
                entries: &[BindGroupLayoutEntry {
                    binding: 0,
                    visibility: ShaderStages::COMPUTE,
                    ty: BindingType::Buffer {
                        ty: BufferBindingType::Storage { read_only: false },
                        has_dynamic_offset: false,
                        min_binding_size: BufferSize::new(
                            Particle::std430_size_static() as u64 * NUM_PARTICLES as u64,
                        ),
                    },
                    count: None,
                }],
                label: Some("particles_update_particles_buffer_layout"),
            });

        let shader = world.resource::<AssetServer>().load("shaders/image2.wgsl");
        let mut pipeline_cache = world.resource_mut::<PipelineCache>();

        let particle_pipeline2 = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: None,
            layout: Some(vec![particle_bind_group_layout2.clone()]),
            shader,
            shader_defs: vec![],
            entry_point: Cow::from("update"),
        });

        GameOfLifePipeline2 {
            particle_bind_group_layout2,
            particle_pipeline2,
        }
    }
}

#[derive(Component, Clone)]
pub struct ParticleVec {
    pub particles: Vec<Particle>,
}

#[repr(C)]
#[derive(Debug, Copy, Clone, Pod, Zeroable, AsStd430)]
pub struct Particle {
    pub position: [f32; 3],
    pub age: f32,
}

impl Particle {
    pub fn random() -> Self {
        let mut rng = rand::thread_rng();
        Particle {
            position: rng.gen(),
            age: rng.gen::<f32>() * 1.0,
        }
    }
}

pub fn extract_game_of_life_image2(mut commands: Commands, particles: Res<ParticleVec>) {
    commands.insert_resource(particles.clone());
}

pub fn queue_bind_group2(
    mut commands: Commands,
    // pipeline: Res<GameOfLifePipeline>,
    // gpu_images: Res<RenderAssets<Image>>,
    // game_of_life_image: Res<GameOfLifeImage>,
    pipeline2: Res<GameOfLifePipeline2>,
    render_device: Res<RenderDevice>,
    particles: Res<ParticleVec>,
) {
    let particle_capacity_bytes: u64 = Particle::std430_size_static() as u64 * NUM_PARTICLES as u64;

    let particles_bytes: Vec<u8> = particles
        .particles
        .iter()
        .flat_map(|&p| {
            let what = p.as_std430();
            let w: Vec<u8> = what.as_bytes().into();
            w
        })
        .collect();

    // println!("dsfs : {:?}", particles_bytes.len());

    let mut buffer_content = [0u8; 4096];

    for (i, pb) in particles_bytes.iter().enumerate() {
        buffer_content[i] = *pb;
    }

    let buffer = render_device.create_buffer_with_data(&BufferInitDescriptor {
        label: Some("particle_buffer"),
        contents: &buffer_content,
        usage: BufferUsages::COPY_DST | BufferUsages::STORAGE,
    });

    let particle_bind_group = render_device.create_bind_group(&BindGroupDescriptor {
        label: Some("particle_bind_group"),
        layout: &pipeline2.particle_bind_group_layout2,
        entries: &[BindGroupEntry {
            binding: 0,
            resource: BindingResource::Buffer(BufferBinding {
                buffer: &buffer,
                offset: 0,
                size: BufferSize::new(particle_capacity_bytes),
            }),
        }],
    });

    commands.insert_resource(ParticleBindGroup(particle_bind_group));
}

pub struct GameOfLifeNode2 {
    pub state: GameOfLifeState,
}

impl Default for GameOfLifeNode2 {
    fn default() -> Self {
        Self {
            state: GameOfLifeState::Loading,
        }
    }
}

impl render_graph::Node for GameOfLifeNode2 {
    fn update(&mut self, world: &mut World) {
        let pipeline = world.resource::<GameOfLifePipeline2>();
        // let pipeline2 = world.resource::<GameOfLifePipeline2>();
        let pipeline_cache = world.resource::<PipelineCache>();

        // if the corresponding pipeline has loaded, transition to the next stage
        match self.state {
            GameOfLifeState::Loading => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(pipeline.particle_pipeline2)
                {
                    self.state = GameOfLifeState::Init
                }
            }
            GameOfLifeState::Init => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(pipeline.particle_pipeline2)
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
        // let texture_bind_group = &world.resource::<GameOfLifeImageBindGroup>().0;
        let particle_bind_group = &world.resource::<ParticleBindGroup>().0;
        let pipeline_cache = world.resource::<PipelineCache>();
        let pipeline = world.resource::<GameOfLifePipeline2>();

        let mut pass = render_context
            .command_encoder
            .begin_compute_pass(&ComputePassDescriptor::default());

        // pass.set_bind_group(0, texture_bind_group, &[]);
        pass.set_bind_group(0, particle_bind_group, &[]);

        // let update_pipeline = pipeline_cache
        //     .get_compute_pipeline(pipeline.update_pipeline)
        //     .unwrap();

        // println!("pipeline_cache : {:?}", pipeline_cache.pipelines);

        match self.state {
            GameOfLifeState::Update => {
                let particle_pipeline2 = pipeline_cache
                    .get_compute_pipeline(pipeline.particle_pipeline2)
                    .unwrap();

                pass.set_pipeline(particle_pipeline2);
                pass.dispatch(32, 1, 1);
            }
            _ => {}
        }

        Ok(())
    }
}
