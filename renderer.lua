-- Renderer module for displaying the game

local Renderer = {}

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
    ui = {0.6, 0.6, 0.8}
}

-- Draw the map
function Renderer.drawMap(map)
    for y = 1, map.height do
        for x = 1, map.width do
            local tile = map.tiles[y][x]
            
            -- Choose color based on tile type
            if tile == "." then -- Floor
                love.graphics.setColor(COLORS.floor)
            else -- Wall or anything else
                love.graphics.setColor(COLORS.wall)
            end
            
            -- Draw the tile
            love.graphics.print(
                tile,
                GRID_OFFSET_X + (x - 1) * TILE_WIDTH,
                GRID_OFFSET_Y + (y - 1) * TILE_HEIGHT
            )
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Draw an entity (player, enemy, item, etc.)
function Renderer.drawEntity(entity)
    if entity.symbol then
        love.graphics.setColor(COLORS.player)
        love.graphics.print(
            entity.symbol,
            GRID_OFFSET_X + (entity.x - 1) * TILE_WIDTH,
            GRID_OFFSET_Y + (entity.y - 1) * TILE_HEIGHT
        )
        love.graphics.setColor(1, 1, 1)
    end
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
    
    -- Controls help - updated for classic roguelike keybindings
    local controlsText = "Move: Arrow keys | R: New map | Q/ESC: Quit"
    love.graphics.print(controlsText, 10, 30)
    
    -- Player position (for debugging)
    local posText = string.format("Position: %d, %d", gameState.player.x, gameState.player.y)
    love.graphics.print(posText, 600, 10)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

return Renderer
