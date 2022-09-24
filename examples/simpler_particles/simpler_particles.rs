// https://www.shadertoy.com/view/Ms2SD1
// by TDM
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

use bevy::{
    diagnostic::{FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin},
    prelude::*,
};

use bevy_shadertoy_wgsl::*;

mod fps;

fn main() {
    let mut app = App::new();

    app.insert_resource(ClearColor(Color::GRAY))
        .insert_resource(WindowDescriptor {
            // width: 960.,
            // height: 600.,
            width: 1200.,
            height: 800.,
            cursor_visible: true,
            present_mode: bevy::window::PresentMode::Immediate, // uncomment for unthrottled FPS
            ..default()
        })
        .insert_resource(ShadertoyCanvas {
            // width: 960. as u32,
            // height: 600.0 as u32,
            width: 1200,
            height: 800,
            borders: 0.02,
            position: Vec3::new(0.0, 0.0, 0.0),
        })
        .add_plugin(fps::FPSPlugin)
        .add_plugins(DefaultPlugins)
        .add_plugin(ShadertoyPlugin)
        .add_plugin(FrameTimeDiagnosticsPlugin::default())
        .add_plugin(LogDiagnosticsPlugin::default())
        .add_startup_system(setup)
        .run();
}

fn setup(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    mut st_res: ResMut<ShadertoyResources>,
) {
    let example = "simpler_particles";
    st_res.include_debugger = false;

    let all_shader_handles: ShaderHandles =
        make_and_load_shaders2(example, &asset_server, st_res.include_debugger);

    commands.insert_resource(all_shader_handles);
}
