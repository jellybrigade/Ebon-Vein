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
        const rightTile = Math.floor((this.x + this.width) / tileSize);
        const topTile = Math.floor(this.y / tileSize);
        const bottomTile = Math.floor((this.y + this.height) / tileSize);
        
        // Check for collisions with map boundaries
        if (this.x < 0 || this.x + this.width > currentMap.width * tileSize || 





























}    }        console.log(`Debug immortal mode: ${this.debugImmortal ? 'ON' : 'OFF'}`);        this.debugImmortal = !this.debugImmortal;    toggleDebugImmortal() {        }        // ...existing code...                }            }                }                    break;                    this.y = prevY;                    this.x = prevX;                if (currentMap.getTile(x, y) === 1) { // Assuming 1 is an obstacle            for (let x = leftTile; x <= rightTile; x++) {        for (let y = topTile; y <= bottomTile; y++) {        // Check for collisions with obstacles                }            this.y = prevY; // Revert to previous Y position            topTile < 0 || bottomTile >= currentMap.height) {        if (this.y < 0 || this.y + this.height > currentMap.height * tileSize ||                 }            this.x = prevX; // Revert to previous X position            leftTile < 0 || rightTile >= currentMap.width) {    isDebugImmortal() {
        return this.debugImmortal;
    }
    
    takeDamage(amount) {
        if (this.debugImmortal) return;
        // ...existing damage handling code...
    }
    
    // ...existing code...
}

// ...existing code...
