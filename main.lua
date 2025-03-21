-- Ebon Vein - A roguelike game
-- The world is dying. The sun has dimmed, the air is cold, and the lands are ruled by chaos.
-- You descend into the Abyss seeking the Black Heart artifact.

-- Load required modules
local Map = require("map")
local Renderer = require("renderer")

-- Game state
local gameState = {
    running = true,
    map = nil,
    player = {
        x = 5,
        y = 5,
        symbol = "@"
    }
}

-- Initialize the game
function love.load()
    -- Set up the font (using a monospaced font is important for ASCII display)
    local font = love.graphics.newFont("fonts/DejaVuSansMono.ttf", 16)
    love.graphics.setFont(font)
    
    -- Initialize the map
    gameState.map = Map.create(40, 25) -- Create a 40x25 grid map
    
    -- Place player in a valid floor position
    gameState.player.x, gameState.player.y = Map.findRandomFloor(gameState.map)
end

-- Update game logic (turn-based)
function love.update(dt)
    -- Turn-based games typically don't need continuous updates
    -- Logic will be handled in keypressed events
end

-- Process player input
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    -- Movement will be added later
    
    -- For testing: regenerate the map with 'r'
    if key == "r" then
        gameState.map = Map.create(40, 25)
        gameState.player.x, gameState.player.y = Map.findRandomFloor(gameState.map)
    end
end

-- Draw the game
function love.draw()
    -- Clear the screen
    love.graphics.clear(0, 0, 0)
    
    -- Render the map and entities
    Renderer.drawMap(gameState.map)
    Renderer.drawEntity(gameState.player)
    
    -- Display game title
    love.graphics.setColor(0.7, 0.2, 0.2)
    love.graphics.print("EBON VEIN", 10, 10)
    love.graphics.setColor(1, 1, 1)
end
