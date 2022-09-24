use bevy::{
    diagnostic::{Diagnostics, FrameTimeDiagnosticsPlugin},
    prelude::*,
    time::FixedTimestep,
};

const TIMESTEP_4_PER_SECOND: f64 = 20.0 / 60.0;

pub struct FPSPlugin;

impl Plugin for FPSPlugin {
    fn build(&self, app: &mut App) {
        // app.add_plugin(FrameTimeDiagnosticsPlugin::default())
        //     .add_startup_system(spawn_text)
        //     .add_system(update)
        app.add_plugin(FrameTimeDiagnosticsPlugin::default())
            .add_startup_system(setup)
            .add_system_set(
                SystemSet::new()
                    .with_run_criteria(FixedTimestep::step(TIMESTEP_4_PER_SECOND))
                    .with_system(text_update_system),
            )
            .add_system(text_color_system);
    }
}

// fn main() {
//     App::new()
//         .add_plugins(DefaultPlugins)
//         .add_plugin(FrameTimeDiagnosticsPlugin::default())
//         .add_startup_system(setup)
//         .add_system(text_update_system)
//         .add_system(text_color_system)
//         .run();
// }

// A unit struct to help identify the FPS UI component, since there may be many Text components
#[derive(Component)]
struct FpsText;

// A unit struct to help identify the color-changing Text component
#[derive(Component)]
struct ColorText;

fn setup(mut commands: Commands, asset_server: Res<AssetServer>) {
    // // UI camera
    // commands.spawn_bundle(Camera2dBundle::default());
    // Text with one section

    // Text with multiple sections
    commands
        .spawn_bundle(
            // Create a TextBundle that has a Text with a list of sections.
            TextBundle::from_sections([
                TextSection::new(
                    "FPS: ",
                    TextStyle {
                        font: asset_server.load("fonts/poly.ttf"),
                        font_size: 60.0,
                        color: Color::BLACK,
                    },
                ),
                TextSection::from_style(TextStyle {
                    font: asset_server.load("fonts/poly.ttf"),
                    font_size: 60.0,
                    color: Color::BLACK,
                }),
            ])
            .with_style(Style {
                align_self: AlignSelf::FlexEnd,
                ..default()
            }),
        )
        .insert(FpsText);
}

fn text_color_system(time: Res<Time>, mut query: Query<&mut Text, With<ColorText>>) {
    for mut text in &mut query {
        let seconds = time.seconds_since_startup() as f32;

        // Update the color of the first and only section.
        text.sections[0].style.color = Color::Rgba {
            red: (1.25 * seconds).sin() / 2.0 + 0.5,
            green: (0.75 * seconds).sin() / 2.0 + 0.5,
            blue: (0.50 * seconds).sin() / 2.0 + 0.5,
            alpha: 1.0,
        };
    }
}

fn text_update_system(diagnostics: Res<Diagnostics>, mut query: Query<&mut Text, With<FpsText>>) {
    for mut text in &mut query {
        if let Some(fps) = diagnostics.get(FrameTimeDiagnosticsPlugin::FPS) {
            if let Some(average) = fps.average() {
                // Update the value of the second section
                text.sections[1].value = format!("{average:.2}");
            }
        }
    }
}
