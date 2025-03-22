import pygame

class Camera:
    def __init__(self, map_width, map_height, screen_width, screen_height):
        self.camera = pygame.Rect(0, 0, map_width, map_height)
        self.width = map_width
        self.height = map_height
        self.screen_width = screen_width
        self.screen_height = screen_height
    
    def apply(self, entity):
        """Offset entity rect by camera position"""
        return entity.rect.move(self.camera.topleft)
    
    def apply_rect(self, rect):
        """Offset a rectangle by camera position"""
        return rect.move(self.camera.topleft)
    
    def update(self, target):
        """Update camera position based on target (usually the player)"""
        # Calculate camera position to center on the target
        x = -target.rect.centerx + int(self.screen_width / 2)
        y = -target.rect.centery + int(self.screen_height / 2)
        
        # Limit scrolling to map edges
        x = min(0, x)  # left boundary
        y = min(0, y)  # top boundary
        x = max(-(self.width - self.screen_width), x)  # right boundary
        y = max(-(self.height - self.screen_height), y)  # bottom boundary
        
        self.camera = pygame.Rect(x, y, self.width, self.height)
