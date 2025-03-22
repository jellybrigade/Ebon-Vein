import random
import pygame
from constants import *

class Enemy:
    def __init__(self, x, y, speed, health, damage, enemy_type="regular"):
        self.x = x
        self.y = y
        self.speed = speed
        self.health = health
        self.max_health = health
        self.damage = damage
        self.enemy_type = enemy_type
        self.size = TILE_SIZE - 10
        self.rect = pygame.Rect(x, y, self.size, self.size)
        self.color = (255, 0, 0)  # Default color
        self.target = None
        self.active = True
        self.teleport_cooldown = 0
        self.is_disguised = False
        self.stolen_sanity = 0
        
    def move(self, player, walls, enemies):
        # Base movement logic
        # ...existing code...
        
        # Special type-specific behaviors
        if self.enemy_type == "fleeing_shadow" and self.teleport_cooldown <= 0:
            # Fleeing shadows might teleport when health is low
            if self.health <= self.max_health * 0.4 and random.random() < 0.03:
                self.teleport(walls)
                
        elif self.enemy_type == "corrupted_thief" and self.rect.colliderect(player.rect):
            # Corrupted thieves steal sanity on contact
            stolen = min(2, player.sanity)
            player.sanity -= stolen
            self.stolen_sanity += stolen
            
        elif self.enemy_type == "bloodbound_spawn":
            # Check for nearby corpses to gain strength
            nearby_corpses = 0
            for enemy in enemies:
                if not enemy.active and self.distance_to((enemy.x, enemy.y)) < 100:
                    nearby_corpses += 1
            # Temporarily boost damage based on corpses
            self.damage = self.damage_base * (1 + (nearby_corpses * 0.2))

    def update(self, player, walls, enemies):
        if not self.active:
            return
        
        if self.enemy_type == "mimic" and not self.is_triggered:
            # Mimics don't move until triggered
            if self.distance_to((player.x, player.y)) < 60:
                self.is_disguised = False
                self.is_triggered = True
        else:
            self.move(player, walls, enemies)
            
        # Update teleport cooldown
        if self.teleport_cooldown > 0:
            self.teleport_cooldown -= 1
            
    def draw(self, screen, camera_offset):
        if not self.active:
            return
            
        x, y = self.x - camera_offset[0], self.y - camera_offset[1]
        
        if self.enemy_type == "mimic" and self.is_disguised:
            # Draw as a treasure chest
            pygame.draw.rect(screen, (139, 69, 19), (x, y, self.size, self.size))
            pygame.draw.rect(screen, (255, 215, 0), (x + 5, y + 5, self.size - 10, self.size - 10))
        else:
            # Draw based on enemy type
            if self.enemy_type == "fleeing_shadow":
                color = (100, 0, 100)  # Purple for shadows
            elif self.enemy_type == "corrupted_thief": 
                color = (0, 100, 100)  # Teal for thieves
            elif self.enemy_type == "bloodbound_spawn":
                color = (150, 0, 0)  # Dark red for bloodbound
            else:
                color = self.color
                
            pygame.draw.rect(screen, color, (x, y, self.size, self.size))
            
            # Health bar
            health_ratio = self.health / self.max_health
            pygame.draw.rect(screen, (255, 0, 0), (x, y - 10, self.size, 5))
            pygame.draw.rect(screen, (0, 255, 0), (x, y - 10, self.size * health_ratio, 5))
    
    def take_damage(self, damage):
        self.health -= damage
        if self.health <= 0:
            self.active = False
            return True
        return False
        
    def distance_to(self, point):
        return ((self.x - point[0]) ** 2 + (self.y - point[1]) ** 2) ** 0.5
        
    def teleport(self, walls):
        # Find a new location for fleeing shadows
        attempts = 0
        while attempts < 50:
            new_x = random.randint(100, MAP_WIDTH * TILE_SIZE - 100)
            new_y = random.randint(100, MAP_HEIGHT * TILE_SIZE - 100)
            new_rect = pygame.Rect(new_x, new_y, self.size, self.size)
            
            # Check if new location is valid
            valid = True
            for wall in walls:
                if new_rect.colliderect(wall.rect):
                    valid = False
                    break
                    
            if valid:
                self.x = new_x
                self.y = new_y
                self.rect.x = new_x
                self.rect.y = new_y
                self.teleport_cooldown = 180  # 3 seconds cooldown
                return
                
            attempts += 1


class FleeingShadow(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y, speed=2.5, health=70, damage=10, enemy_type="fleeing_shadow")
        self.color = (100, 0, 100)  # Purple


class Mimic(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y, speed=1.0, health=120, damage=20, enemy_type="mimic")
        self.is_disguised = True
        self.is_triggered = False
        # When triggered, speed increases
        self.triggered_speed = 3.0


class CorruptedThief(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y, speed=3.5, health=60, damage=5, enemy_type="corrupted_thief")
        self.color = (0, 100, 100)  # Teal
        self.stolen_sanity = 0


class BloodboundSpawn(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y, speed=1.8, health=100, damage=12, enemy_type="bloodbound_spawn")
        self.color = (150, 0, 0)  # Dark red
        self.damage_base = 12  # Store base damage for calculations
