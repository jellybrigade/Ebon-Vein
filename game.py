# ...existing code...
from camera import Camera
from enemy import Enemy, FleeingShadow, Mimic, CorruptedThief, BloodboundSpawn

# ...existing code...

class Game:
    def __init__(self):
        # ...existing code...
        self.enemies = []
        self.enemy_spawn_timer = 0
        self.enemy_corpses = []  # Track dead enemies for bloodbound spawn logic
        
    # ...existing code...
    
    def spawn_enemies(self):
        # Reduce the total number of enemies
        if len(self.enemies) >= MAX_ENEMIES:
            return
            
        if self.enemy_spawn_timer <= 0 and len(self.enemies) < MAX_ENEMIES:
            # Choose a spawn point away from the player
            valid_spawn = False
            attempts = 0
            
            while not valid_spawn and attempts < 10:
                # Random position in the map
                x = random.randint(TILE_SIZE * 2, (MAP_WIDTH - 2) * TILE_SIZE)
                y = random.randint(TILE_SIZE * 2, (MAP_HEIGHT - 2) * TILE_SIZE)
                
                # Check distance from player
                distance = ((x - self.player.x) ** 2 + (y - self.player.y) ** 2) ** 0.5
                if distance > 300:  # Must be at least 300 pixels away
                    # Check if position is valid (not on a wall)
                    enemy_rect = pygame.Rect(x, y, TILE_SIZE - 10, TILE_SIZE - 10)
                    valid_spawn = True
                    for wall in self.walls:
                        if enemy_rect.colliderect(wall.rect):
                            valid_spawn = False
                            break
                            
                attempts += 1
            
            if valid_spawn:
                # Spawn different types of enemies with varying probabilities
                enemy_type = random.choices(
                    ["regular", "fleeing_shadow", "mimic", "corrupted_thief", "bloodbound_spawn"],
                    weights=[0.5, 0.15, 0.1, 0.15, 0.1],
                    k=1
                )[0]
                
                if enemy_type == "regular":
                    enemy = Enemy(x, y, 
                                 speed=random.uniform(1.0, 2.0),
                                 health=random.randint(80, 120),
                                 damage=random.randint(8, 15))
                elif enemy_type == "fleeing_shadow":
                    enemy = FleeingShadow(x, y)
                elif enemy_type == "mimic":
                    enemy = Mimic(x, y)
                elif enemy_type == "corrupted_thief":
                    enemy = CorruptedThief(x, y)
                else:  # bloodbound_spawn
                    enemy = BloodboundSpawn(x, y)
                    
                self.enemies.append(enemy)
                self.enemy_spawn_timer = random.randint(60, 180)  # 1-3 seconds
        else:
            self.enemy_spawn_timer -= 1
            
    def update_enemies(self):
        for enemy in self.enemies[:]:
            if not enemy.active:
                # Add to corpses list for bloodbound spawn logic
                self.enemy_corpses.append((enemy.x, enemy.y, 300))  # Position and countdown timer
                self.enemies.remove(enemy)
                continue
                
            enemy.update(self.player, self.walls, self.enemies)
            
        # Update corpse timers and remove old ones
        for i, (x, y, timer) in enumerate(self.enemy_corpses[:]):
            self.enemy_corpses[i] = (x, y, timer - 1)
            if timer <= 0:
                self.enemy_corpses.remove((x, y, timer))
    
    def draw_enemies(self):
        # Draw corpses first (under enemies)
        for x, y, timer in self.enemy_corpses:
            fade = min(255, timer)
            pygame.draw.circle(
                self.screen, 
                (100, 0, 0, fade), 
                (x - self.camera_offset[0], y - self.camera_offset[1]), 
                10
            )
            
        # Then draw active enemies
        for enemy in self.enemies:
            enemy.draw(self.screen, self.camera_offset)
            
    # ...existing code...

def run_game():
    # ...existing code...
    
    # Game loop
    while running:
        # ...existing code...
        
        # Generate level if needed
        if current_level != previous_level:
            game_map, player, enemies = generate_level(current_level)
            
            # Create camera with the map size
            tile_size = 32  # Adjust based on your actual tile size
            map_pixel_width = game_map.width * tile_size
            map_pixel_height = game_map.height * tile_size
            camera = Camera(map_pixel_width, map_pixel_height, SCREEN_WIDTH, SCREEN_HEIGHT)
            
            previous_level = current_level
        
        # Update camera to follow player
        camera.update(player)
        
        # Clear screen
        screen.fill(BLACK)
        
        # Draw map with camera offset
        for y in range(game_map.height):
            for x in range(game_map.width):
                tile = game_map.get_tile(x, y)
                if tile:
                    tile_rect = pygame.Rect(x * tile_size, y * tile_size, tile_size, tile_size)
                    screen.blit(tile.image, camera.apply_rect(tile_rect))
        
        # Draw entities with camera offset
        for enemy in enemies:
            screen.blit(enemy.image, camera.apply(enemy))
        
        # Draw player with camera offset
        screen.blit(player.image, camera.apply(player))
        
        # Draw UI elements (these usually don't need camera offset)
        # ...existing UI rendering code...
        
        # ...existing code...
# ...existing code...
