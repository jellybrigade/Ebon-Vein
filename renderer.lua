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
    visible = {1, 1, 1}      -- Full brightness for visible
}   
    -- Add missing colors for special tile types (the likely cause of the error)
-- Variables for special effects6, 0.2, 0.2}, -- Red-ish for flesh tiles
local pulseEffect = 0r blood tiles
local distortionTime = 0

-- Set the pulse effect level for walls
function Renderer.setPulseEffect(factor)mePhase)
    pulseEffect = factor1, map.height do
        for x = 1, map.width do
            local tile = map.tiles[y][x]
            local visState = visibilityMap[y][x]
            t(time)
            -- Skip drawing completely unseen tiles
            if visState == Visibility.UNSEEN then
                love.graphics.setColor(COLORS.unseen)
                love.graphics.print(
                    " ",  -- Empty space for unseen tilesr.drawMap(map, visibilityMap)
    for y = 1, map.height do
        for x = 1, map.width do_Y + (y - 1) * TILE_HEIGHT
            local tile = map.tiles[y][x]
            local visState = visibilityMap[y][x]
            n tile type and visibility state
            -- Skip drawing completely unseen tiles
            if visState == Visibility.UNSEEN then
                love.graphics.setColor(COLORS.unseen)r
                love.graphics.print(eif tile == "#" then
                    " ",  -- Empty space for unseen tiles    baseColor = COLORS.wall
                    GRID_OFFSET_X + (x - 1) * TILE_WIDTH,
                    GRID_OFFSET_Y + (y - 1) * TILE_HEIGHTRS.exit
                )
            elsebaseColor = COLORS.flesh -- Use flesh color for ~ tiles
                -- Choose color based on tile type and visibility state
                local baseColor
                if tile == "." thene
                    baseColor = COLORS.floor    -- Fallback color for any other tile types
                elseif tile == "#" thenCOLORS.floor
                    baseColor = COLORS.wall
                elseif tile == "X" then
                    baseColor = COLORS.exit
                end
                    love.graphics.setColor(baseColor)
                else if visState == Visibility.VISIBLE then
                    -- Seen but not currently visible (dimmed)         -- Fully visible
                    love.graphics.setColor(baseColor[1] * 0.5, baseColor[2] * 0.5, baseColor[3] * 0.5)             love.graphics.setColor(baseColor)
                end            else
                  -- Seen but not currently visible (dimmed)
                -- Draw the tileetColor(baseColor[1] * 0.5, baseColor[2] * 0.5, baseColor[3] * 0.5)
                love.graphics.print(             end
                    tile,                
                    GRID_OFFSET_X + (x - 1) * TILE_WIDTH,
                    GRID_OFFSET_Y + (y - 1) * TILE_HEIGHT
                )
            end
        endSET_Y + (y - 1) * TILE_HEIGHT
    end
    end
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Draw an entity (player, enemy, item, etc.)(1, 1, 1)
function Renderer.drawEntity(entity)
    if entity.symbol then
        -- Use entity's color if available, otherwise use player colorn entity (player, enemy, item, etc.)
        if entity.color then
            love.graphics.setColor(entity.color)entity.symbol then
        else     -- Use entity's color if available, otherwise use player color
            love.graphics.setColor(COLORS.player)        if entity.color then
        end
        
        love.graphics.print(r)
            entity.symbol,
            GRID_OFFSET_X + (entity.x - 1) * TILE_WIDTH,
            GRID_OFFSET_Y + (entity.y - 1) * TILE_HEIGHT
        )
        love.graphics.setColor(1, 1, 1)WIDTH,
    end       GRID_OFFSET_Y + (entity.y - 1) * TILE_HEIGHT
end
     love.graphics.setColor(1, 1, 1)
-- Draw a ranged attack animation (line from attacker to target)    end
function Renderer.drawRangedAttack(from, to)
    love.graphics.setColor(COLORS.rangedAttack)
    love.graphics.line(om attacker to target)
        GRID_OFFSET_X + (from.x - 0.5) * TILE_WIDTH,om, to)
        GRID_OFFSET_Y + (from.y - 0.5) * TILE_HEIGHT,
        GRID_OFFSET_X + (to.x - 0.5) * TILE_WIDTH,e.graphics.line(
        GRID_OFFSET_Y + (to.y - 0.5) * TILE_HEIGHT.5) * TILE_WIDTH,
    )     GRID_OFFSET_Y + (from.y - 0.5) * TILE_HEIGHT,
    love.graphics.setColor(1, 1, 1)        GRID_OFFSET_X + (to.x - 0.5) * TILE_WIDTH,
end

-- Draw the messages log (legacy method, UI module handles this in new code)
function Renderer.drawMessages(messages, x, y)
    love.graphics.setColor(COLORS.message)
    for i, msg in ipairs(messages) do
        love.graphics.print(msg, x, y - ((#messages - i) * 20)))
    endlove.graphics.setColor(COLORS.message)
    love.graphics.setColor(1, 1, 1)) do
endi) * 20))

-- Draw UI elements (legacy method, UI module handles this in new code)
function Renderer.drawUI(gameState)
    love.graphics.setColor(COLORS.ui)
    raw UI elements (legacy method, UI module handles this in new code)
    -- Controls help - updated to include inventory controls
    local controlsText = "Move: Arrow keys | I: Inventory | H: Help | R: New map | Q/ESC: Quit"
    love.graphics.print(controlsText, 10, 30)
    controls
    -- Player health and positions | I: Inventory | H: Help | R: New map | Q/ESC: Quit"
    local healthText = string.format("Health: %d/%d", love.graphics.print(controlsText, 10, 30)
                                    gameState.player.health, 
                                    gameState.player.maxHealth)
    love.graphics.setColor(COLORS.health) local healthText = string.format("Health: %d/%d", 
    love.graphics.print(healthText, 500, 30)                                    gameState.player.health, 
    .player.maxHealth)
    love.graphics.setColor(COLORS.ui)
    local posText = string.format("Position: %d, %d | Enemies: %d", 
                                 gameState.player.x, gameState.player.y, 
                                 #gameState.enemies)
    love.graphics.print(posText, 500, 10)local posText = string.format("Position: %d, %d | Enemies: %d", 
         gameState.player.x, gameState.player.y, 
    -- Reset colorte.enemies)
    love.graphics.setColor(1, 1, 1)
end
-- Reset color
-- Draw the inventory screen (legacy version))
function Renderer.drawInventory(inventory, selectedItem)
    -- Draw semi-transparent background with a thematic border
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)  -- Darker backgroundraw the inventory screen (legacy version)
    love.graphics.rectangle("fill", 100, 100, 600, 400)tory(inventory, selectedItem)
    ith a thematic border
    -- Add decorative border
    love.graphics.setColor(0.3, 0.3, 0.4)love.graphics.rectangle("fill", 100, 100, 600, 400)
    love.graphics.rectangle("line", 100, 100, 600, 400)
    love.graphics.rectangle("line", 105, 105, 590, 390)
    
    -- Title with thematic stylinglove.graphics.rectangle("line", 100, 100, 600, 400)
    love.graphics.setColor(0.7, 0.6, 0.2)  -- Gold-ish title("line", 105, 105, 590, 390)
    love.graphics.print("INVENTORY", 350, 110)
    
    -- Add some flavor text.graphics.setColor(0.7, 0.6, 0.2)  -- Gold-ish title
    love.graphics.setColor(0.6, 0.6, 0.7)10)
    love.graphics.print("The few possessions you carry in the darkness...", 260, 130)
    ome flavor text
    -- Controls instructions
    love.graphics.setColor(0.5, 0.5, 0.6)essions you carry in the darkness...", 260, 130)
    love.graphics.print("Use: Enter | Navigate: ↑↓ | Close: I or Escape", 270, 470)
    
    if #inventory == 0 then
        love.graphics.setColor(0.5, 0.5, 0.6)s.print("Use: Enter | Navigate: ↑↓ | Close: I or Escape", 270, 470)
        love.graphics.print("Your pack is empty. The Abyss has little to offer.", 270, 200)
    else
        for i, item in ipairs(inventory) do
            local y = 160 + (i * 30)aphics.print("Your pack is empty. The Abyss has little to offer.", 270, 200)
            
            -- Highlight selected item with a subtle glow effect
            if selectedItem == i then
                -- Darker background for selection
                love.graphics.setColor(0.2, 0.2, 0.25, 0.8)-- Highlight selected item with a subtle glow effect
                love.graphics.rectangle("fill", 150, y - 5, 500, 30)= i then
                for selection
                -- Subtle highlight border
                love.graphics.setColor(0.5, 0.4, 0.2)love.graphics.rectangle("fill", 150, y - 5, 500, 30)
                love.graphics.rectangle("line", 150, y - 5, 500, 30)
            end -- Subtle highlight border
            .2)
            -- Draw item symbol with its color    love.graphics.rectangle("line", 150, y - 5, 500, 30)
            love.graphics.setColor(item.color)
            love.graphics.print(item.symbol, 170, y)
            
            -- Draw item name love.graphics.setColor(item.color)
            if selectedItem == i then     love.graphics.print(item.symbol, 170, y)
                love.graphics.setColor(0.8, 0.7, 0.5)  -- Brighter for selected        
            else
                love.graphics.setColor(0.7, 0.7, 0.8)         if selectedItem == i then
            end                love.graphics.setColor(0.8, 0.7, 0.5)  -- Brighter for selected
            love.graphics.print(item.name, 200, y)
            .8)
            -- Draw description with a muted color
            love.graphics.setColor(0.5, 0.5, 0.6)e, 200, y)
            love.graphics.print(" - " .. item.description, 380, y)
        end        -- Draw description with a muted color
    end
    hics.print(" - " .. item.description, 380, y)
    love.graphics.setColor(1, 1, 1)
end

-- Draw the game over screen with a more thematic design
function Renderer.drawGameOver(message, isVictory)
    -- Create a vignette effect with gradual darkening
    love.graphics.setColor(0, 0, 0, 0.7)tic design
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Add some atmosphere with subtle "rays of light" or "darkness tendrils"hics.setColor(0, 0, 0, 0.7)
    if isVictory thenaphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        -- Gold rays for victory
        for i = 1, 12 dotle "rays of light" or "darkness tendrils"
            local angle = (i / 12) * math.pi * 2
            love.graphics.setColor(0.7, 0.6, 0.2, 0.2)
            love.graphics.line(
                love.graphics.getWidth() / 2,12) * math.pi * 2
                love.graphics.getHeight() / 2,0.2, 0.2)
                love.graphics.getWidth() / 2 + math.cos(angle) * 400,
                love.graphics.getHeight() / 2 + math.sin(angle) * 400
            )
        end   love.graphics.getWidth() / 2 + math.cos(angle) * 400,
    else     love.graphics.getHeight() / 2 + math.sin(angle) * 400
        -- Dark tendrils for defeat     )
        for i = 1, 8 do    end
            local angle = (i / 8) * math.pi * 2
            love.graphics.setColor(0.2, 0.1, 0.3, 0.3)
            love.graphics.line(
                love.graphics.getWidth() / 2,* 2
                love.graphics.getHeight() / 2,0.3, 0.3)
                love.graphics.getWidth() / 2 + math.cos(angle) * 300,raphics.line(
                love.graphics.getHeight() / 2 + math.sin(angle) * 300 love.graphics.getWidth() / 2,
            )            love.graphics.getHeight() / 2,
        ende.graphics.getWidth() / 2 + math.cos(angle) * 300,
    endgraphics.getHeight() / 2 + math.sin(angle) * 300
    
    -- Central panelend
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", 
        love.graphics.getWidth() / 2 - 250, -- Central panel
        love.graphics.getHeight() / 2 - 100,  0.15, 0.9)
        500, 200, 
        10, 10)
    ics.getHeight() / 2 - 100, 
    -- Panel border0, 
    if isVictory then    10, 10)
        love.graphics.setColor(0.7, 0.6, 0.2) -- Gold for victory
    else
        love.graphics.setColor(0.5, 0.2, 0.2) -- Red for defeat
    endctory
    
    love.graphics.rectangle("line", etColor(0.5, 0.2, 0.2) -- Red for defeat
        love.graphics.getWidth() / 2 - 250, 
        love.graphics.getHeight() / 2 - 100, 
        500, 200, graphics.rectangle("line", 
        10, 10)
    ght() / 2 - 100, 
    -- Title text with glow effect
    if isVictory then
        -- Victory title
        love.graphics.setColor(0.2, 0.2, 0.3, 0.5) -- Shadowtle text with glow effect
        love.graphics.print(sVictory then
            "VICTORY", e
            love.graphics.getWidth() / 2 - 42, 
            love.graphics.getHeight() / 2 - 70 + 2
        )
        love.graphics.setColor(0.9, 0.8, 0.3) -- Gold text
        love.graphics.print(
            "VICTORY", 
            love.graphics.getWidth() / 2 - 44, t
            love.graphics.getHeight() / 2 - 72
        )
    else
        -- Defeat title
        love.graphics.setColor(0.3, 0.1, 0.1, 0.5) -- Shadow
        love.graphics.print(e
            "DARKNESS CLAIMS YOU",     -- Defeat title
            love.graphics.getWidth() / 2 - 110, , 0.1, 0.5) -- Shadow
            love.graphics.getHeight() / 2 - 70 + 2
        )IMS YOU", 
        love.graphics.setColor(0.8, 0.3, 0.3) -- Red text.graphics.getWidth() / 2 - 110, 
        love.graphics.print( 70 + 2
            "DARKNESS CLAIMS YOU", 
            love.graphics.getWidth() / 2 - 112, .graphics.setColor(0.8, 0.3, 0.3) -- Red text
            love.graphics.getHeight() / 2 - 72phics.print(
        )       "DARKNESS CLAIMS YOU", 
    end        love.graphics.getWidth() / 2 - 112, 
    eight() / 2 - 72
    -- Message with atmospheric styling
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf(
        message,
        love.graphics.getWidth() / 2 - 200,
        love.graphics.getHeight() / 2 - 30,ove.graphics.printf(
        400,    message,
        "center"2 - 200,
    )     love.graphics.getHeight() / 2 - 30,
            400,
    -- Instructions to restart"
    love.graphics.setColor(0.6, 0.6, 0.7)    )











return Rendererend    love.graphics.setColor(1, 1, 1)        )        love.graphics.getHeight() / 2 + 50        love.graphics.getWidth() / 2 - 120,        "Press SPACE to venture forth again",    love.graphics.print(    
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
