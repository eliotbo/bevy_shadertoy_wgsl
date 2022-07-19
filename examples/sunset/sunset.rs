// MIT License
// Copyright (c) 2019 Dimas Leenman

use bevy::{
    diagnostic::{FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin},
    prelude::*,
};

use bevy_shadertoy_wgsl::*;

fn main() {
    let mut app = App::new();

    app.insert_resource(ClearColor(Color::GRAY))
        .insert_resource(WindowDescriptor {
            width: 960.,
            height: 600.,
            cursor_visible: true,
            // present_mode: PresentMode::Immediate, // uncomment for unthrottled FPS
            ..default()
        })
        .insert_resource(CanvasSize {
            width: (960.0_f32 * BORDERS).floor() as u32,
            height: (600.0_f32 * BORDERS).floor() as u32,
        })
        .add_plugins(DefaultPlugins)
        .add_plugin(ShadertoyPlugin)
        .add_plugin(FrameTimeDiagnosticsPlugin::default())
        .add_plugin(LogDiagnosticsPlugin::default())
        .add_startup_system(setup)
        // .add_system(update_common_uniform)
        .run();
}

fn setup(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    mut st_res: ResMut<ShadertoyResources>,
) {
    let example = "sunset";
    st_res.include_debugger = false;

    let all_shader_handles: ShaderHandles =
        make_and_load_shaders2(example, &asset_server, st_res.include_debugger);

    commands.insert_resource(all_shader_handles);
}

//  ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4
//  ffmpeg -ss 2 -t 27 -i output.mp4 -vf "fps=20,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 showcase.gif
