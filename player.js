// ...existing code...

class Player {
    constructor() {
        // ...existing code...
        this.debugImmortal = false;
        // ...existing code...
    }
    
    // ...existing code...
    
    handleInput() {
        // Store previous position
        const prevX = this.x;
        const prevY = this.y;
        
        // ...existing movement code...
        
        // Check for collision with map boundaries and obstacles
        const leftTile = Math.floor(this.x / tileSize);
        const rightTile = Math.floor((this.x + this.width - 1) / tileSize);
        const topTile = Math.floor(this.y / tileSize);
        const bottomTile = Math.floor((this.y + this.height - 1) / tileSize);
        
        // Check for collisions with map boundaries
        if (this.x < 0 || this.x + this.width > currentMap.width * tileSize || 
            leftTile < 0 || rightTile >= currentMap.width) {
            this.x = prevX; // Revert to previous X position
        }
        
        if (this.y < 0 || this.y + this.height > currentMap.height * tileSize || 
            topTile < 0 || bottomTile >= currentMap.height) {
            this.y = prevY; // Revert to previous Y position
        }
        
        // Check for collisions with obstacles - separate X and Y checks for better sliding
        // First check X movement
        let collisionX = false;
        const newLeftTile = Math.floor(this.x / tileSize);
        const newRightTile = Math.floor((this.x + this.width - 1) / tileSize);
        
        for (let y = topTile; y <= bottomTile; y++) {
            for (let x = newLeftTile; x <= newRightTile; x++) {
                if (x >= 0 && x < currentMap.width && y >= 0 && y < currentMap.height && 
                    currentMap.getTile(x, y) === 1) {
                    collisionX = true;
                    break;
                }
            }
            if (collisionX) break;
        }
        
        if (collisionX) {
            this.x = prevX;
        }
        
        // Then check Y movement separately
        let collisionY = false;
        const newTopTile = Math.floor(this.y / tileSize);
        const newBottomTile = Math.floor((this.y + this.height - 1) / tileSize);
        
        for (let y = newTopTile; y <= newBottomTile; y++) {
            for (let x = leftTile; x <= rightTile; x++) {
                if (x >= 0 && x < currentMap.width && y >= 0 && y < currentMap.height && 
                    currentMap.getTile(x, y) === 1) {
                    collisionY = true;
                    break;
                }
            }
            if (collisionY) break;
        }
        
        if (collisionY) {
            this.y = prevY;
        }
        
        // ...existing code...
    }
    
    isDebugImmortal() {
        return this.debugImmortal;
    }
    
    takeDamage(amount) {
        if (this.debugImmortal) return;
        // ...existing damage handling code...
    }
    
    toggleDebugImmortal() {
        console.log(`Debug immortal mode: ${this.debugImmortal ? 'ON' : 'OFF'}`);
        this.debugImmortal = !this.debugImmortal;
    }
    
    // ...existing code...
}

// ...existing code...
