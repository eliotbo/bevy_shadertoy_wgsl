use bevy::{
    app::ScheduleRunnerSettings,
    diagnostic::{FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin},
    prelude::*,
    utils::Duration,
    window::PresentMode,
};

use bevy_shadertoy_wgsl::*;

fn main() {
    let mut app = App::new();

    app.insert_resource(ScheduleRunnerSettings::run_loop(Duration::from_secs_f64(
        1.0 / 120.0,
    )))
    .insert_resource(ClearColor(Color::GRAY))
    .insert_resource(WindowDescriptor {
        width: 960.,
        height: 600.,
        cursor_visible: true,
        present_mode: PresentMode::Immediate, // uncomment for unthrottled FPS
        ..default()
    })
    .insert_resource(ShadertoyCanvas {
        width: 960. as u32,
        height: 600.0 as u32,
        borders: 0.0,
        position: Vec3::new(0.0, 0.0, 0.0),
    })
    .add_plugins(DefaultPlugins)
    .add_system(bevy::input::system::exit_on_esc_system)
    .add_plugin(ShadertoyPlugin)
    .add_plugin(FrameTimeDiagnosticsPlugin::default())
    .add_plugin(LogDiagnosticsPlugin::default())
    .add_startup_system(setup)
    .add_system(match_window_size)
    .add_system(limit_fps)
    .run();
}

fn setup(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    mut st_res: ResMut<ShadertoyResources>,
) {
    let example = "paint_streams";
    st_res.include_debugger = true;

    let all_shader_handles: ShaderHandles =
        make_and_load_shaders2(example, &asset_server, st_res.include_debugger);

    commands.insert_resource(all_shader_handles);
}

fn match_window_size(windows: Res<Windows>, mut canvas: ResMut<ShadertoyCanvas>) {
    let window = windows.get_primary().unwrap();
    canvas.width = window.width() as u32;
    canvas.height = window.height() as u32;
}

use std::{thread, time};

fn limit_fps() {
    thread::sleep(time::Duration::from_millis(5));
}
