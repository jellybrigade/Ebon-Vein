// ...existing code...

pub fn update_ui(
    mut commands: Commands,
    player_query: Query<(&Player, &Health), With<Player>>,
    // ...existing code...
) {
    // ...existing code...
    
    if let Ok((player, health)) = player_query.get_single() {
        // ...existing code...
        
        // Add debug mode indicator if active
        if player.is_debug_immortal() {
            commands.spawn(NodeBundle {
                style: Style {
                    position_type: PositionType::Absolute,
                    right: Val::Px(10.0),
                    top: Val::Px(10.0),
                    // ...
                    ..Default::default()
                },
                background_color: Color::rgba(0.8, 0.0, 0.0, 0.5).into(),
                ..Default::default()
            })
            .with_children(|parent| {
                parent.spawn(TextBundle::from_section(
                    "DEBUG MODE: IMMORTAL",
                    TextStyle {
                        font_size: 16.0,
                        color: Color::WHITE,
                        // ...
                        ..Default::default()
                    },
                ));
            })
            .insert(UiCleanup);
        }
        
        // ...existing code...
    }
}
