-- Map module for handling the dungeon grid

local Map = {}

-- Tile types
local FLOOR = "."
local WALL = "#"

-- Create a new map grid
function Map.create(width, height)
    local map = {
        width = width,
        height = height,
        tiles = {}
    }
    
    -- Initialize with walls
    for y = 1, height do
        map.tiles[y] = {}
        for x = 1, width do
            map.tiles[y][x] = WALL
        end
    end
    
    -- Create a simple room in the center (will replace with proper generation later)
    local roomWidth = math.floor(width * 0.6)
    local roomHeight = math.floor(height * 0.6)
    local roomX = math.floor((width - roomWidth) / 2)
    local roomY = math.floor((height - roomHeight) / 2)
    
    for y = roomY, roomY + roomHeight - 1 do
        for x = roomX, roomX + roomWidth - 1 do
            map.tiles[y][x] = FLOOR
        end
    end
    
    return map
end

-- Get the tile at a specific position
function Map.getTile(map, x, y)
    if x < 1 or y < 1 or x > map.width or y > map.height then
        return nil -- Out of bounds
    end
    return map.tiles[y][x]
end

-- Find a random floor tile position
function Map.findRandomFloor(map)
    local floorPositions = {}
    
    for y = 1, map.height do
        for x = 1, map.width do
            if map.tiles[y][x] == FLOOR then
                table.insert(floorPositions, {x = x, y = y})
            end
        end
    end
    
    if #floorPositions > 0 then
        local pos = floorPositions[math.random(#floorPositions)]
        return pos.x, pos.y
    end
    
    return 1, 1 -- Fallback position
end

return Map
