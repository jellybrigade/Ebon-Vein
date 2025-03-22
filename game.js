// ...existing code...

class Camera {
    constructor(width, height) {
        this.x = 0;
        this.y = 0;
        this.width = width;
        this.height = height;
        this.zoomFactor = 1.5; // Higher zoom factor = more zoomed in
    }

    follow(entity) {
        // Make sure we have valid dimensions, use defaults if not provided
        const entityWidth = entity.width || tileSize;
        const entityHeight = entity.height || tileSize;
        
        // Center the camera on the player
        const targetX = entity.x - (this.width / this.zoomFactor - entityWidth) / 2;
        const targetY = entity.y - (this.height / this.zoomFactor - entityHeight) / 2;
        
        // Apply immediate positioning instead of smooth follow for debugging
        // Remove this line and uncomment the next two lines for smooth following
        this.x = targetX; this.y = targetY;
        
        // Smooth follow (uncomment for smooth movement)
        // this.x = this.x + (targetX - this.x) * 0.1;
        // this.y = this.y + (targetY - this.y) * 0.1;
        
        // Prevent camera from showing outside the map
        const maxX = currentMap.width * tileSize - this.width / this.zoomFactor;
        const maxY = currentMap.height * tileSize - this.height / this.zoomFactor;
        
        this.x = Math.max(0, Math.min(this.x, maxX));
        this.y = Math.max(0, Math.min(this.y, maxY));
    }
    
    // Convert world coordinates to screen coordinates
    worldToScreen(x, y) {
        return {
            x: (x - this.x) * this.zoomFactor,
            y: (y - this.y) * this.zoomFactor
        };
    }
    
    // Convert screen coordinates to world coordinates
    screenToWorld(x, y) {
        return {
            x: x / this.zoomFactor + this.x,
            y: y / this.zoomFactor + this.y
        };
    }
}

// Initialize the camera with the canvas dimensions
const camera = new Camera(canvas.width, canvas.height);

// ...existing code...

function update() {
    // ...existing code...
    
    // Make sure this call exists and is working
    camera.follow(player);
    
    // ...existing code...
}

function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Apply zoom transformation
    ctx.save();
    ctx.scale(camera.zoomFactor, camera.zoomFactor);
    
    // Draw map with camera offset
    for (let y = 0; y < currentMap.height; y++) {
        for (let x = 0; x < currentMap.width; x++) {
            const tile = currentMap.getTile(x, y);
            if (tile === 0) continue; // Skip empty tiles
            
            // Calculate screen position with camera offset
            const screenX = x * tileSize - camera.x;
            const screenY = y * tileSize - camera.y;
            
            // Only draw tiles that are visible on zoomed screen
            if (screenX < -tileSize || screenY < -tileSize || 
                screenX > canvas.width / camera.zoomFactor || 
                screenY > canvas.height / camera.zoomFactor) {
                continue;
            }
            
            drawTile(tile, screenX, screenY);
        }
    }
    
    // Draw enemies with camera offset
    currentMap.enemies.forEach(enemy => {
        ctx.fillStyle = enemy.color;
        ctx.fillRect(enemy.x - camera.x, enemy.y - camera.y, enemy.width, enemy.height);
    });
    
    // Draw player with camera offset
    ctx.fillStyle = player.color;
    ctx.fillRect(player.x - camera.x, player.y - camera.y, player.width, player.height);
    
    // IMPORTANT: Restore the context after all map drawing
    ctx.restore();
    
    // Draw UI elements normally (not affected by camera zoom)
    if (player.isDebugImmortal()) {
        ctx.fillStyle = "rgba(255, 0, 0, 0.5)";
        ctx.font = "16px Arial";
        ctx.fillText("DEBUG MODE: IMMORTAL", canvas.width - 180, 20);
    }
    
    // Draw debug info if needed
    if (player.debugMode) {
        ctx.fillStyle = "white";
        ctx.font = "12px Arial";
        ctx.fillText(`Camera: ${Math.round(camera.x)},${Math.round(camera.y)}`, 10, 20);
        ctx.fillText(`Player: ${player.x},${player.y}`, 10, 40);
        ctx.fillText(`Zoom: ${camera.zoomFactor}`, 10, 60);
    }
    
    // ...existing code...
}

function drawTile(tileIndex, x, y) {
    // Draw the tile at the specified position
    // Note: x and y already have camera offset applied
    ctx.fillStyle = tileColors[tileIndex];
    ctx.fillRect(x, y, tileSize, tileSize);
    // ...existing code...
}

// ...existing code...

// Setup key handlers
window.addEventListener('keydown', (e) => {
    // ...existing code...
    
    // Toggle debug immortal mode with F1 key
    if (e.key === 'F1') {
        player.toggleDebugImmortal();
        e.preventDefault();
    }
    
    // Toggle debug mode with F2 key
    if (e.key === 'F2') {
        toggleDebug();
        e.preventDefault();
    }
    
    // Adjust zoom with + and - keys
    if (e.key === '+' || e.key === '=') {
        camera.zoomFactor += 0.1;
        e.preventDefault();
    }
    
    if (e.key === '-' || e.key === '_') {
        camera.zoomFactor = Math.max(0.5, camera.zoomFactor - 0.1);
        e.preventDefault();
    }
    
    // Reset zoom with 0 key
    if (e.key === '0') {
        camera.zoomFactor = 1.5;
        e.preventDefault();
    }
    
    // ...existing code...
});
