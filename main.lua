-- Ebon Vein - A roguelike game
-- The world is dying. The sun has dimmed, the air is cold, and the lands are ruled by chaos.
-- You descend into the Abyss seeking the Black Heart artifact.

-- Load required modules
local Map = require("map")
local Renderer = require("renderer")
local Enemy = require("enemy")  -- Add enemy module

-- Game state
local gameState = {
    running = true,
    map = nil,
    player = {
        x = 5,
        y = 5,
        symbol = "@",
        health = 10,
        maxHealth = 10
    },
    enemies = {},  -- Add enemies list
    messages = {} -- For displaying game messages
}

-- Initialize the game
function love.load()
    -- Set up the font (using a monospaced font is important for ASCII display)
    local font = love.graphics.newFont("fonts/DejaVuSansMono.ttf", 16)
    love.graphics.setFont(font)
    
    -- Initialize the map
    gameState.map = Map.create(40, 25) -- Create a 40x25 grid map
    
    -- Place player in the center of the first room
    gameState.player.x, gameState.player.y = Map.getFirstRoomCenter(gameState.map)
    
    -- Spawn enemies
    gameState.enemies = Enemy.spawnEnemies(gameState.map, 8)
    
    -- Add initial message
    addMessage("You enter the Abyss, seeking the Black Heart...")
    addMessage("Beware the shadows that lurk within...")
end

-- Add a message to the game log
function addMessage(text)
    table.insert(gameState.messages, text)
    -- Keep only the most recent messages
    if #gameState.messages > 5 then
        table.remove(gameState.messages, 1)
    end
end

-- Attempt to move the player
function movePlayer(dx, dy)
    local newX = gameState.player.x + dx
    local newY = gameState.player.y + dy
    
    -- Check if the new position is valid (not a wall)
    local tile = Map.getTile(gameState.map, newX, newY)
    if tile == "." then -- Floor tile
        -- Check for enemies at the destination
        for _, enemy in ipairs(gameState.enemies) do
            if enemy.x == newX and enemy.y == newY then
                -- In the future this will handle combat
                addMessage("You bump into a " .. enemy.name .. "!")
                return true -- Return true because the player's turn was used
            end
        end
        
        -- No collision, move the player
        gameState.player.x = newX
        gameState.player.y = newY
        return true
    end
    
    return false
end

-- Update enemies (process their turns)
function updateEnemies()
    for _, enemy in ipairs(gameState.enemies) do
        Enemy.update(enemy, gameState)
    end
end

-- Update game logic (turn-based)
function love.update(dt)
    -- Turn-based games typically don't need continuous updates
    -- Logic will be handled in keypressed events
end

-- Process player input
function love.keypressed(key)
    if key == "escape" or key == "q" then
        love.event.quit()
        return
    end
    
    -- Movement controls - classic roguelike uses arrow keys
    local moved = false
    
    -- Arrow keys
    if key == "up" then
        moved = movePlayer(0, -1)
    elseif key == "down" then
        moved = movePlayer(0, 1)
    elseif key == "left" then
        moved = movePlayer(-1, 0)
    elseif key == "right" then
        moved = movePlayer(1, 0)
    end
    
    -- For testing: regenerate the map with 'r'
    if key == "r" then
        gameState.map = Map.create(40, 25)
        gameState.player.x, gameState.player.y = Map.getFirstRoomCenter(gameState.map)
        gameState.enemies = Enemy.spawnEnemies(gameState.map, 8)
        addMessage("A new area of the Abyss forms around you...")
    end
    
    -- If the player moved, update enemies (their turn)
    if moved then
        updateEnemies()
    end
end

-- Draw the game
function love.draw()
    -- Clear the screen
    love.graphics.clear(0, 0, 0)
    
    -- Render the map and entities
    Renderer.drawMap(gameState.map)
    
    -- Draw enemies before player (so player is on top)
    for _, enemy in ipairs(gameState.enemies) do
        Renderer.drawEntity(enemy)
    end
    
    Renderer.drawEntity(gameState.player)
    
    -- Display game title
    love.graphics.setColor(0.7, 0.2, 0.2)
    love.graphics.print("EBON VEIN", 10, 10)
    love.graphics.setColor(1, 1, 1)
    
    -- Draw messages log
    Renderer.drawMessages(gameState.messages, 10, 550)
    
    -- Draw UI elements
    Renderer.drawUI(gameState)
end
