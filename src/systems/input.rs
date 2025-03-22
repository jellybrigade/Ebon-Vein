// ...existing code...
pub fn handle_input(
    keyboard: Res<Input<KeyCode>>,
    mut player_query: Query<(&mut Player, &mut Health, &Transform, &mut PlayerAttackTimer)>,
    // ...existing code...
) {
    // ...existing code...
    if let Ok((mut player, _, player_transform, _)) = player_query.get_single_mut() {
        // ...existing code...
        
        // Toggle debug immortality mode with F1 key
        if keyboard.just_pressed(KeyCode::F1) {
            player.toggle_debug_immortal();
            println!("Debug Immortality: {}", if player.is_debug_immortal() { "ON" } else { "OFF" });
        }
        
        // ...existing code...
    }
    // ...existing code...
}
