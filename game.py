import pygame
import random
from camera import Camera
from enemy import Enemy, FleeingShadow, Mimic, CorruptedThief, BloodboundSpawn

class Game:
    def __init__(self):
        self.enemies = []
        self.enemy_spawn_timer = 0
        self.enemy_corpses = []
        
        # Legend panel for descriptions
        self.legend_panel = LegendPanel(SCREEN_WIDTH - 240, 10, 230, SCREEN_HEIGHT - 20)
        
    def spawn_enemies(self):
        level = self.level
        if level == 1:
            num_enemies = random.randint(2, 4)  # Level 1: 2-4 enemies
        elif level == 2:
            num_enemies = random.randint(3, 5)  # Level 2: 3-5 enemies
        elif level == 3:
            num_enemies = random.randint(4, 6)  # Level 3: 4-6 enemies
        elif level == 4:
            num_enemies = random.randint(5, 7)  # Level 4: 5-7 enemies
        else:
            num_enemies = random.randint(6, 8)  # Level 5: 6-8 enemies

        if len(self.enemies) >= num_enemies:
            return
            
        if self.enemy_spawn_timer <= 0 and len(self.enemies) < num_enemies:
            valid_spawn = False
            attempts = 0
            
            while not valid_spawn and attempts < 10:
                x = random.randint(TILE_SIZE * 2, (MAP_WIDTH - 2) * TILE_SIZE)
                y = random.randint(TILE_SIZE * 2, (MAP_HEIGHT - 2) * TILE_SIZE)
                
                distance = ((x - self.player.x) ** 2 + (y - self.player.y) ** 2) ** 0.5
                if distance > 300:
                    enemy_rect = pygame.Rect(x, y, TILE_SIZE - 10, TILE_SIZE - 10)
                    valid_spawn = True
                    for wall in self.walls:
                        if enemy_rect.colliderect(wall.rect):
                            valid_spawn = False
                            break
                            
                attempts += 1
            
            if valid_spawn:
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
                else:
                    enemy = BloodboundSpawn(x, y)
                    
                self.enemies.append(enemy)
                self.enemy_spawn_timer = random.randint(60, 180)
        else:
            self.enemy_spawn_timer -= 1
            
    def update_enemies(self):
        for enemy in self.enemies[:]:
            if not enemy.active:
                self.enemy_corpses.append((enemy.x, enemy.y, 300))
                self.enemies.remove(enemy)
                continue
                
            enemy.update(self.player, self.walls, self.enemies)
            
        for i, (x, y, timer) in enumerate(self.enemy_corpses[:]):
            self.enemy_corpses[i] = (x, y, timer - 1)
            if timer <= 0:
                self.enemy_corpses.remove((x, y, timer))
    
    def draw_enemies(self):
        for x, y, timer in self.enemy_corpses:
            fade = min(255, timer)
            pygame.draw.circle(
                self.screen, 
                (100, 0, 0, fade), 
                (x - self.camera_offset[0], y - self.camera_offset[1]), 
                10
            )
            
        for enemy in self.enemies:
            enemy.draw(self.screen, self.camera_offset)
            
    def draw(self):
        self.draw_enemies()
        
        # Draw the legend panel on the right side
        self.legend_panel.draw(self.screen)

class LegendPanel:
    def __init__(self, x, y, width, height):
        self.rect = pygame.Rect(x, y, width, height)
        self.color = (30, 30, 30)
        self.border_color = (100, 100, 100)
        self.text_color = (220, 220, 220)
        self.title_color = (255, 255, 255)
        self.font = pygame.font.Font(None, 22)
        self.title_font = pygame.font.Font(None, 26)
        
        self.sections = {
            "ENEMIES": [
                {"color": (255, 0, 0), "name": "Regular Enemy", "desc": "Basic hostile creature"},
                {"color": (100, 0, 100), "name": "Fleeing Shadow", "desc": "Teleports when injured"},
                {"color": (139, 69, 19), "name": "Mimic", "desc": "Disguised as treasure"},
                {"color": (0, 100, 100), "name": "Corrupted Thief", "desc": "Steals sanity on touch"},
                {"color": (150, 0, 0), "name": "Bloodbound Spawn", "desc": "Gains strength near corpses"}
            ],
            "ITEMS": [
                {"color": (255, 255, 0), "name": "Health Potion", "desc": "Restores health points"},
                {"color": (0, 255, 255), "name": "Sanity Elixir", "desc": "Restores lost sanity"},
                {"color": (255, 165, 0), "name": "Key", "desc": "Unlocks special doors"}
            ],
            "TERRAIN": [
                {"color": (50, 50, 50), "name": "Wall", "desc": "Impassable barrier"},
                {"color": (100, 50, 0), "name": "Door", "desc": "Access to new areas"},
                {"color": (0, 0, 100), "name": "Water", "desc": "Slows movement, cannot be crossed"}
            ]
        }
        
    def draw(self, screen):
        pygame.draw.rect(screen, self.color, self.rect)
        pygame.draw.rect(screen, self.border_color, self.rect, 2)
        
        title = self.title_font.render("LEGEND", True, self.title_color)
        screen.blit(title, (self.rect.x + (self.rect.width - title.get_width()) // 2, self.rect.y + 10))
        
        y_offset = 45
        
        for section_title, items in self.sections.items():
            section_text = self.title_font.render(section_title, True, self.title_color)
            screen.blit(section_text, (self.rect.x + 10, self.rect.y + y_offset))
            y_offset += 30
            
            for item in items:
                color_box = pygame.Rect(self.rect.x + 15, self.rect.y + y_offset, 15, 15)
                pygame.draw.rect(screen, item["color"], color_box)
                pygame.draw.rect(screen, self.border_color, color_box, 1)
                
                name_text = self.font.render(item["name"], True, self.text_color)
                screen.blit(name_text, (self.rect.x + 40, self.rect.y + y_offset - 2))
                
                desc_words = item["desc"].split()
                desc_line = ""
                for word in desc_words:
                    test_line = desc_line + word + " "
                    if self.font.size(test_line)[0] < self.rect.width - 50:
                        desc_line = test_line
                    else:
                        desc_text = self.font.render(desc_line, True, (180, 180, 180))
                        screen.blit(desc_text, (self.rect.x + 40, self.rect.y + y_offset + 18))
                        y_offset += 18
                        desc_line = word + " "
                
                if desc_line:
                    desc_text = self.font.render(desc_line, True, (180, 180, 180))
                    screen.blit(desc_text, (self.rect.x + 40, self.rect.y + y_offset + 18))
                
                y_offset += 38

def run_game():
    while running:
        if current_level != previous_level:
            game_map, player, enemies = generate_level(current_level)
            
            tile_size = 32
            map_pixel_width = game_map.width * tile_size
            map_pixel_height = game_map.height * tile_size
            camera = Camera(map_pixel_width, map_pixel_height, SCREEN_WIDTH, SCREEN_HEIGHT)
            
            previous_level = current_level
        
        camera.update(player)
        
        screen.fill(BLACK)
        
        for y in range(game_map.height):
            for x in range(game_map.width):
                tile = game_map.get_tile(x, y)
                if tile:
                    tile_rect = pygame.Rect(x * tile_size, y * tile_size, tile_size, tile_size)
                    screen.blit(tile.image, camera.apply_rect(tile_rect))
        
        for enemy in enemies:
            screen.blit(enemy.image, camera.apply(enemy))
        
        screen.blit(player.image, camera.apply(player))
        
        game.draw()
