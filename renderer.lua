-- Renderer module for displaying the game

local Renderer = {}
local Visibility = require("visibility")  -- Import visibility module

-- Configuration
local TILE_WIDTH = 16
local TILE_HEIGHT = 16
local GRID_OFFSET_X = 50
local GRID_OFFSET_Y = 50

-- Colors
local COLORS = {
    floor = {0.2, 0.2, 0.3},
    wall = {0.5, 0.5, 0.6},
    exit = {0.9, 0.8, 0.1},  -- Bright gold color for exit
    player = {1, 1, 1},
    message = {0.8, 0.8, 0.6},
    title = {0.7, 0.2, 0.2},
    ui = {0.6, 0.6, 0.8},
    health = {0.8, 0.2, 0.2},
    inventory = {0.9, 0.9, 0.7},
    rangedAttack = {0.9, 0.5, 0.1},
    
    -- Add colors for different visibility states
    unseen = {0, 0, 0},      -- Black for unseen
    seen = {0.15, 0.15, 0.2}, -- Dark gray for previously seen
    visible = {1, 1, 1},      -- Full brightness for visible
    
    -- Add colors for special tile types
    flesh = {0.6, 0.2, 0.2}, -- Red-ish for flesh tiles
    blood = {0.5, 0.1, 0.1}  -- Darker red for blood tiles
}   

-- Variables for special effects
local pulseEffect = 0
local distortionTime = 0

-- Set the pulse effect level for walls
function Renderer.setPulseEffect(factor)
    pulseEffect = factor
end

-- Set the distortion effect time
function Renderer.setDistortionEffect(time)
    distortionTime = time
end

-- Draw the map with visibility
function Renderer.drawMap(map, visibilityMap, gamePhase)
    for y = 1, map.height do
        for x = 1, map.width do
            local tile = map.tiles[y][x]
            local visState = visibilityMap[y][x]
            
            -- Skip drawing completely unseen tiles
            if visState == Visibility.UNSEEN then
                love.graphics.setColor(COLORS.unseen)
                love.graphics.print(
                    " ",  -- Empty space for unseen tiles
                    GRID_OFFSET_X + (x - 1) * TILE_WIDTH,
                    GRID_OFFSET_Y + (y - 1) * TILE_HEIGHT
                )
            else
                -- Choose color based on tile type and visibility state
                local baseColor
                if tile == "." then
                    baseColor = COLORS.floor
                elseif tile == "#" then
                    baseColor = COLORS.wall
                elseif tile == "X" then
                    baseColor = COLORS.exit
                elseif tile == "~" then
                    baseColor = COLORS.flesh -- Use flesh color for ~ tiles
                elseif tile == "," then
                    baseColor = COLORS.blood -- Use blood color for , tiles
                else
                    baseColor = COLORS.floor -- Fallback color for any other tile types
                end
                
                if visState == Visibility.VISIBLE then
                    -- Fully visible
                    love.graphics.setColor(baseColor)
                else
                    -- Seen but not currently visible (dimmed)
                    love.graphics.setColor(baseColor[1] * 0.5, baseColor[2] * 0.5, baseColor[3] * 0.5)
                end
                
                -- Draw the tile
                love.graphics.print(
                    tile,                
                    GRID_OFFSET_X + (x - 1) * TILE_WIDTH,
                    GRID_OFFSET_Y + (y - 1) * TILE_HEIGHT
                )
            end
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Draw an entity (player, enemy, item, etc.)
function Renderer.drawEntity(entity)
    if entity.symbol then
        -- Use entity's color if available, otherwise use player color
        if entity.color then
            love.graphics.setColor(entity.color)
        else
            love.graphics.setColor(COLORS.player)
        end
        
        love.graphics.print(
            entity.symbol,
            GRID_OFFSET_X + (entity.x - 1) * TILE_WIDTH,
            GRID_OFFSET_Y + (entity.y - 1) * TILE_HEIGHT
        )
        love.graphics.setColor(1, 1, 1)
    end
end

-- Draw a ranged attack animation (line from attacker to target)
function Renderer.drawRangedAttack(from, to)
    love.graphics.setColor(COLORS.rangedAttack)
    love.graphics.line(
        GRID_OFFSET_X + (from.x - 0.5) * TILE_WIDTH,
        GRID_OFFSET_Y + (from.y - 0.5) * TILE_HEIGHT,
        GRID_OFFSET_X + (to.x - 0.5) * TILE_WIDTH,
        GRID_OFFSET_Y + (to.y - 0.5) * TILE_HEIGHT
    )
    love.graphics.setColor(1, 1, 1)
end

-- Draw the messages log (legacy method, UI module handles this in new code)
function Renderer.drawMessages(messages, x, y)
    love.graphics.setColor(COLORS.message)
    for i, msg in ipairs(messages) do
        love.graphics.print(msg, x, y - ((#messages - i) * 20))
    end
    love.graphics.setColor(1, 1, 1)
end

-- Draw UI elements (legacy method, UI module handles this in new code)
function Renderer.drawUI(gameState)
    love.graphics.setColor(COLORS.ui)
    
    -- Controls help - updated to include inventory controls
    local controlsText = "Move: Arrow keys | I: Inventory | H: Help | R: New map | Q/ESC: Quit"
    love.graphics.print(controlsText, 10, 30)
    
    -- Player health and position
    local healthText = string.format("Health: %d/%d", 
                                    gameState.player.health, 
                                    gameState.player.maxHealth)
    love.graphics.setColor(COLORS.health)
    love.graphics.print(healthText, 500, 30)
    
    love.graphics.setColor(COLORS.ui)
    local posText = string.format("Position: %d, %d | Enemies: %d", 
                                 gameState.player.x, gameState.player.y, 
                                 #gameState.enemies)
    love.graphics.print(posText, 500, 10)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Draw the inventory screen (legacy version)
function Renderer.drawInventory(inventory, selectedItem)
    -- Draw semi-transparent background with a thematic border
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)  -- Darker background
    love.graphics.rectangle("fill", 100, 100, 600, 400)
    
    -- Add decorative border
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("line", 100, 100, 600, 400)
    love.graphics.rectangle("line", 105, 105, 590, 390)
    
    -- Title with thematic styling
    love.graphics.setColor(0.7, 0.6, 0.2)  -- Gold-ish title
    love.graphics.print("INVENTORY", 350, 110)
    
    -- Add some flavor text
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.print("The few possessions you carry in the darkness...", 260, 130)
    
    -- Controls instructions
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("Use: Enter | Navigate: ↑↓ | Close: I or Escape", 270, 470)
    
    if #inventory == 0 then
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.print("Your pack is empty. The Abyss has little to offer.", 270, 200)
    else
        for i, item in ipairs(inventory) do
            local y = 160 + (i * 30)
            
            -- Highlight selected item with a subtle glow effect
            if selectedItem == i then
                -- Darker background for selection
                love.graphics.setColor(0.2, 0.2, 0.25, 0.8)
                love.graphics.rectangle("fill", 150, y - 5, 500, 30)
                
                -- Subtle highlight border
                love.graphics.setColor(0.5, 0.4, 0.2)
                love.graphics.rectangle("line", 150, y - 5, 500, 30)
            end
            
            -- Draw item symbol with its color
            love.graphics.setColor(item.color)
            love.graphics.print(item.symbol, 170, y)
            
            -- Draw item name
            if selectedItem == i then
                love.graphics.setColor(0.8, 0.7, 0.5)  -- Brighter for selected        
            else
                love.graphics.setColor(0.7, 0.7, 0.8)
            end
            love.graphics.print(item.name, 200, y)
            
            -- Draw description with a muted color
            love.graphics.setColor(0.5, 0.5, 0.6)
            love.graphics.print(" - " .. item.description, 380, y)
        end
    end
    
    love.graphics.setColor(1, 1, 1)
end

-- Draw the game over screen with a more thematic design
function Renderer.drawGameOver(message, isVictory)
    -- Create a vignette effect with gradual darkening
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Add some atmosphere with subtle "rays of light" or "darkness tendrils"
    if isVictory then
        -- Gold rays for victory
        for i = 1, 12 do
            local angle = (i / 12) * math.pi * 2
            love.graphics.setColor(0.7, 0.6, 0.2, 0.2)
            love.graphics.line(
                love.graphics.getWidth() / 2,
                love.graphics.getHeight() / 2,
                love.graphics.getWidth() / 2 + math.cos(angle) * 400,
                love.graphics.getHeight() / 2 + math.sin(angle) * 400
            )
        end
    else
        -- Dark tendrils for defeat
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2
            love.graphics.setColor(0.2, 0.1, 0.3, 0.3)
            love.graphics.line(
                love.graphics.getWidth() / 2,
                love.graphics.getHeight() / 2,
                love.graphics.getWidth() / 2 + math.cos(angle) * 300,
                love.graphics.getHeight() / 2 + math.sin(angle) * 300
            )
        end
    end
    
    -- Central panel
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", 
        love.graphics.getWidth() / 2 - 250,
        love.graphics.getHeight() / 2 - 100,
        500, 200, 
        10, 10)
    
    -- Panel border
    if isVictory then
        love.graphics.setColor(0.7, 0.6, 0.2) -- Gold for victory
    else
        love.graphics.setColor(0.5, 0.2, 0.2) -- Red for defeat
    end
    
    love.graphics.rectangle("line", 
        love.graphics.getWidth() / 2 - 250, 
        love.graphics.getHeight() / 2 - 100, 
        500, 200, 
        10, 10)
    
    -- Title text with glow effect
    if isVictory then
        -- Victory title
        love.graphics.setColor(0.2, 0.2, 0.3, 0.5) -- Shadow
        love.graphics.print(
            "VICTORY", 
            love.graphics.getWidth() / 2 - 42, 
            love.graphics.getHeight() / 2 - 70 + 2
        )
        love.graphics.setColor(0.9, 0.8, 0.3) -- Gold text
        love.graphics.print(
            "VICTORY", 
            love.graphics.getWidth() / 2 - 44, 
            love.graphics.getHeight() / 2 - 72
        )
    else
        -- Defeat title
        love.graphics.setColor(0.3, 0.1, 0.1, 0.5) -- Shadow
        love.graphics.print(
            "DARKNESS CLAIMS YOU", 
            love.graphics.getWidth() / 2 - 110, 
            love.graphics.getHeight() / 2 - 70 + 2
        )
        love.graphics.setColor(0.8, 0.3, 0.3) -- Red text
        love.graphics.print(
            "DARKNESS CLAIMS YOU", 
            love.graphics.getWidth() / 2 - 112, 
            love.graphics.getHeight() / 2 - 72
        )
    end
    
    -- Message with atmospheric styling
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf(
        message,
        love.graphics.getWidth() / 2 - 200,
        love.graphics.getHeight() / 2 - 30,
        400,
        "center"
    )
    
    -- Instructions to restart
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.print(
        "Press SPACE to venture forth again",
        love.graphics.getWidth() / 2 - 120,
        love.graphics.getHeight() / 2 + 50
    )
    
    love.graphics.setColor(1, 1, 1)
end

return Renderer
