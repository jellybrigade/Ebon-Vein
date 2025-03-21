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
    player = {1, 1, 1}
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

return Renderer
