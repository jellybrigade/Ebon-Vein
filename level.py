# ...existing code...

def generate_level(level_num):
    # Calculate increasing map size based on level
    base_width = 30
    base_height = 20
    width_increase = level_num * 3
    height_increase = level_num * 2
    map_width = base_width + width_increase
    map_height = base_height + height_increase
    
    # Create a new game map with the calculated dimensions
    game_map = GameMap(map_width, map_height)
    # ...existing code...
    
    # Calculate enemy count - fewer enemies, increasing gradually
    # Start with just 2-3 enemies at level 1, then add 1-2 per level
    enemy_count = 2 + level_num
    if enemy_count > 12:  # Cap maximum enemies at 12
        enemy_count = 12
    
    # Generate enemies
    for _ in range(enemy_count):
        # ...existing code for enemy placement...
    
    # ...existing code...
    return game_map, player, enemies
# ...existing code...
