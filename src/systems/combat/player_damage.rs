// ...existing code...

pub fn player_damage(
    commands: Commands,
    mut state: ResMut<State<crate::GameState>>,
    assets: Res<crate::GameAssets>,
    damage_event_reader: EventReader<PlayerDamageEvent>,
    mut player_query: Query<(&mut Player, &mut Health, &mut TextureAtlasSprite)>,
) {
    // ...existing code...
    
    if let Ok((player, mut health, mut sprite)) = player_query.get_single_mut() {
        for damage_event in damage_event_reader.iter() {
            // Skip damage if player is in debug immortality mode
            if player.is_debug_immortal() {
                continue;
            }
            
            // ...existing code...
        }
    }
    
    // ...existing code...
}
