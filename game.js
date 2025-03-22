// ...existing code...

class Camera {
    constructor(width, height) {
        this.x = 0;
        this.y = 0;
        this.width = width;
        this.height = height;
    }

    follow(entity) {
        // Center the camera on the entity
        this.x = entity.x - this.width / 2 + entity.width / 2;
        this.y = entity.y - this.height / 2 + entity.height / 2;
        
        // Prevent camera from showing outside the map
        this.x = Math.max(0, Math.min(this.x, currentMap.width * tileSize - this.width));
        this.y = Math.max(0, Math.min(this.y, currentMap.height * tileSize - this.height));
    }
    
    centerOn(x, y) {
        // Center the camera on a position
        this.x = x - this.width / 2;
        this.y = y - this.height / 2;
        
        // Prevent camera from showing outside the map
        this.x = Math.max(0, Math.min(this.x, currentMap.width * tileSize - this.width));
        this.y = Math.max(0, Math.min(this.y, currentMap.height * tileSize - this.height));
    }
}

// ...existing code...
    camera.follow(player);
// Initialize the camera with the canvas dimensions
const camera = new Camera(canvas.width, canvas.height);
}
// ...existing code...
function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    // ...existing code...
    // Draw map with camera offset
    for (let y = 0; y < currentMap.height; y++) {
    camera.centerOn(player.x + player.width/2, player.y + player.height/2);
    
    // ...existing code...
}

function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Draw map with camera offset
    for (let y = 0; y < currentMap.height; y++) {
        for (let x = 0; x < currentMap.width; x++) {
            const tile = currentMap.getTile(x, y);
            if (tile === 0) continue; // Skip empty tiles
            
            // Calculate screen position with camera offset
            const screenX = x * tileSize - camera.x;
            const screenY = y * tileSize - camera.y;
            
            // Only draw tiles that are visible on screen
            if (screenX < -tileSize || screenY < -tileSize || 
                screenX > canvas.width || screenY > canvas.height) {
                continue;
            }
            
            drawTile(tile, screenX, screenY);
        }
    }
    
    // Draw entities with camera offsetr if active
    currentMap.enemies.forEach(enemy => {   if (player.isDebugImmortal()) {
        ctx.fillStyle = enemy.color;        ctx.fillStyle = "rgba(255, 0, 0, 0.5)";
        ctx.fillRect(enemy.x - camera.x, enemy.y - camera.y, enemy.width, enemy.height);
    });MORTAL", canvas.width - 180, 20);
    
    // Draw player with camera offset   
    ctx.fillStyle = player.color;    // ...existing code...
    ctx.fillRect(player.x - camera.x, player.y - camera.y, player.width, player.height);
    







// ...existing code...}    // ...existing code for drawing tiles with the new x,y coordinates that account for camera...







// ...existing code...}    // ...existing code for drawing tiles with the new x,y coordinates that account for camera...function drawTile(tileIndex, x, y) {// Update any other functions that draw to the screen to use camera offsets}    // ...existing code...

function drawTile(tileIndex, x, y) {// Update any other functions that draw to the screen to use camera offsets// Setup key handlers
window.addEventListener('keydown', (e) => {
    // ...existing code...
    
    // Toggle debug immortal mode with F1 key
    if (e.key === 'F1') {
        player.toggleDebugImmortal();
        e.preventDefault();
    }
    
    // ...existing code...
});
