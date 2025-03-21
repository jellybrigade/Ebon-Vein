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

-- Draw the map
function Renderer.drawMap(map, visibilityMap)
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
                local baseColor = (tile == ".") and COLORS.floor or COLORS.wall
                
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

-- Draw the messages log
function Renderer.drawMessages(messages, x, y)
    love.graphics.setColor(COLORS.message)
    for i, msg in ipairs(messages) do
        love.graphics.print(msg, x, y - ((#messages - i) * 20))
    end
    love.graphics.setColor(1, 1, 1)
end

-- Draw UI elements like controls help
function Renderer.drawUI(gameState)
    love.graphics.setColor(COLORS.ui)
    
    -- Controls help - updated to include inventory controls
    local controlsText = "Move: Arrow keys | I: Inventory | R: New map | Q/ESC: Quit"
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

-- Draw the inventory screen
function Renderer.drawInventory(inventory, selectedItem)
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 100, 100, 600, 400)
    
    love.graphics.setColor(COLORS.inventory)
    love.graphics.print("INVENTORY", 350, 110)
    love.graphics.print("Use: Enter | Close: I or Escape", 260, 130)
    
    if #inventory == 0 then
        love.graphics.print("Your inventory is empty.", 300, 200)
    else
        for i, item in ipairs(inventory) do
            local y = 160 + (i * 25)
            
            -- Highlight selected item
            if selectedItem == i then
                love.graphics.setColor(0.8, 0.8, 0.5)
                love.graphics.rectangle("fill", 150, y - 5, 500, 25)
            end
            
            -- Draw item with its original color
            love.graphics.setColor(item.color)
            love.graphics.print(item.symbol .. " " .. item.name, 200, y)
            
            -- Draw description
            love.graphics.setColor(COLORS.inventory)
            love.graphics.print(item.description, 400, y)
        end
    end
    
    love.graphics.setColor(1, 1, 1)
end

return Renderer
