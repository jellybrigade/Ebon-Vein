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
local sanityDistortion = 0
local hallucinations = {}

-- Set the pulse effect level for walls
function Renderer.setPulseEffect(factor)
    pulseEffect = factor
end

-- Set the distortion effect time
function Renderer.setDistortionEffect(time)
    distortionTime = time
end

-- Set sanity-based visual effects
function Renderer.setSanityEffect(amount, activeHallucinations)
    sanityDistortion = amount
    hallucinations = activeHallucinations or {}
end

-- Draw the map with visibility
function Renderer.drawMap(map, visibilityMap, gamePhase)
    -- Apply sanity distortion to map rendering if active
    local xOffset, yOffset = 0, 0
    if sanityDistortion > 0 then
        -- Random subtle distortion for map tiles
        xOffset = math.sin(love.timer.getTime() * 2) * sanityDistortion * 3
        yOffset = math.cos(love.timer.getTime() * 1.5) * sanityDistortion * 3
    end
    
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
                    
                    -- Apply wall shifting hallucination if active
                    for _, hallucination in ipairs(hallucinations) do
                        if hallucination.type == 3 then -- WALL_SHIFT
                            -- Make walls "breathe" by adjusting their color
                            local breatheFactor = math.sin(love.timer.getTime() * 2 + (x+y)/5) * hallucination.intensity
                            baseColor = {
                                baseColor[1] * (1 + breatheFactor),
                                baseColor[2] * (1 + breatheFactor * 0.5),
                                baseColor[3] * (1 + breatheFactor * 0.5)
                            }
                        end
                    end
                elseif tile == "X" then
                    baseColor = COLORS.exit
                elseif tile == "~" then
                    baseColor = COLORS.flesh
                    
                    -- Make flesh tiles pulsate
                    local pulseFactor = 0.1 + math.sin(love.timer.getTime() * 1.5 + (x*y)/10) * 0.1
                    baseColor = {
                        baseColor[1] * (1 + pulseFactor),
                        baseColor[2] * (1 - pulseFactor * 0.5),
                        baseColor[3] * (1 - pulseFactor * 0.5)
                    }
                elseif tile == "," then
                    baseColor = COLORS.blood
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
                
                -- Apply sanity distortion to visible tiles
                local drawX = GRID_OFFSET_X + (x - 1) * TILE_WIDTH
                local drawY = GRID_OFFSET_Y + (y - 1) * TILE_HEIGHT
                
                if visState == Visibility.VISIBLE and sanityDistortion > 0 then
                    -- Apply subtle positional distortion based on sanity
                    drawX = drawX + xOffset * math.sin((x+y) * 0.3 + love.timer.getTime())
                    drawY = drawY + yOffset * math.cos((x-y) * 0.2 + love.timer.getTime())
                end
                
                -- Draw the tile
                love.graphics.print(
                    tile,                
                    drawX,
                    drawY
                )
            end
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Draw a hallucination
function Renderer.drawHallucination(hallucination, type)
    if not hallucination.x or not hallucination.y then return end
    
    if type == "enemy" then
        -- Draw a hallucinated enemy
        love.graphics.setColor(0.5, 0.2, 0.7, 0.8) -- Purple-ish color for hallucination
        love.graphics.print(
            "?",
            GRID_OFFSET_X + (hallucination.x - 1) * TILE_WIDTH,
            GRID_OFFSET_Y + (hallucination.y - 1) * TILE_HEIGHT
        )
    elseif type == "exit" then
        -- Draw a false exit
        love.graphics.setColor(0.9, 0.8, 0.1, 0.7) -- Transparent gold
        love.graphics.print(
            "X",
            GRID_OFFSET_X + (hallucination.x - 1) * TILE_WIDTH,
            GRID_OFFSET_Y + (hallucination.y - 1) * TILE_HEIGHT
        )
    elseif type == "doppelganger" then
        -- Draw a copy of the player character
        love.graphics.setColor(0.7, 0.7, 0.9, 0.8)
        love.graphics.print(
            "@",
            GRID_OFFSET_X + (hallucination.x - 1) * TILE_WIDTH,
            GRID_OFFSET_Y + (hallucination.y - 1) * TILE_HEIGHT
        )
    elseif type == "shadow" then
        -- Draw a moving shadow
        love.graphics.setColor(0.1, 0.1, 0.2, 0.6)
        love.graphics.print(
            "*",
            GRID_OFFSET_X + (hallucination.x - 1) * TILE_WIDTH,
            GRID_OFFSET_Y + (hallucination.y - 1) * TILE_HEIGHT
        )
    end
    
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

-- Draw entity tooltip (for mouse hover)
function Renderer.drawEntityTooltip(entity, x, y)
    if not entity then return end
    
    -- Set background color
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    
    -- Set text color
    love.graphics.setColor(1, 1, 1)
    
    -- Add hazard-specific tooltip content
    if entity.type and (
        entity.type == "acid" or 
        entity.type == "gas" or 
        entity.type == "spikes" or
        entity.type == "fire" or
        entity.type == "crumbling") then
        
        -- Determine description based on hazard type
        local description = ""
        if entity.type == "acid" then
            description = "Acid Pool: Burns anything that touches it."
        elseif entity.type == "gas" then
            description = "Gas Vent: Periodically releases disorienting gas."
        elseif entity.type == "spikes" then
            description = "Spike Trap: Damages the first creature to step on it."
        elseif entity.type == "fire" then
            description = "Fire: Burns creatures and can spread to nearby tiles."
        elseif entity.type == "crumbling" then
            description = "Crumbling Floor: Will collapse if stepped on again."
        end
        
        love.graphics.print(description, x, y)
        return
    end
    
    -- For non-hazard entities, display basic info
    local name = entity.name or "Unknown"
    local description = entity.description or ""
    
    love.graphics.print(name, x, y)
    if description ~= "" then
        love.graphics.print(description, x, y + 20)
    end
    
    love.graphics.setColor(1, 1, 1)
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
    local width = love.graphics.getWidth() - x - 100
    
    for i, msg in ipairs(messages) do
        -- Use printf instead of print to make text wrap properly
        love.graphics.printf(
            msg, 
            x, 
            y - ((#messages - i) * 25), -- Increased spacing from 20 to 25
            width,
            "left"
        )
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
        love.graphics.printf(
            "Your pack is empty. The Abyss has little to offer.",
            150, 200, 500, "left"
        )
    else
        for i, item in ipairs(inventory) do
            local y = 160 + (i * 35)  -- Increased spacing from 30 to 35
            
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
            local descWidth = 300  -- Width for description text wrapping
            love.graphics.printf(item.description, 380, y, descWidth, "left")
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
