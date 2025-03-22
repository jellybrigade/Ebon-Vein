// ...existing code...

class Map {
    constructor(width, height) {
        this.width = width;
        this.height = height;
        this.tiles = Array(width * height).fill(0);
        this.enemies = [];
        // ...existing code...
    }
    
    // ...existing code...
}

// Create larger maps for better exploration
function createTestMap() {
    const map = new Map(30, 30); // Larger map dimensions
    
    // Create some borders and obstacles
    for (let x = 0; x < map.width; x++) {
        map.setTile(x, 0, 1); // Top border
        map.setTile(x, map.height - 1, 1); // Bottom border
    }
    
    for (let y = 0; y < map.height; y++) {
        map.setTile(0, y, 1); // Left border
        map.setTile(map.width - 1, y, 1); // Right border
    }
    
    // Add some random obstacles
    for (let i = 0; i < 50; i++) {
        const x = Math.floor(Math.random() * (map.width - 2)) + 1;
        const y = Math.floor(Math.random() * (map.height - 2)) + 1;
        map.setTile(x, y, 1);
    }
    
    // Add enemies
    for (let i = 0; i < 5; i++) {
        let x, y;
        do {
            x = Math.floor(Math.random() * (map.width - 2) + 1) * tileSize;
            y = Math.floor(Math.random() * (map.height - 2) + 1) * tileSize;
        } while (map.getTileAtPixel(x, y) !== 0);
        
        map.enemies.push(new Enemy(x, y));
    }
    
    return map;
}

// ...existing code...
