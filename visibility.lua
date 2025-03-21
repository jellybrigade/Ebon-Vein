-- Visibility module for field of vision calculations

local Visibility = {}

-- Visibility states
local UNSEEN = 0
local SEEN = 1
local VISIBLE = 2

-- Create a new visibility map filled with unseen tiles
function Visibility.createMap(width, height)
    local visMap = {}
    for y = 1, height do
        visMap[y] = {}
        for x = 1, width do
            visMap[y][x] = UNSEEN
        end
    end
    return visMap
end

-- Check if a position is within map bounds
function Visibility.isInBounds(map, x, y)
    return x >= 1 and y >= 1 and x <= map.width and y <= map.height
end

-- Calculate field of vision using a simple raycasting method
function Visibility.updateFOV(map, visMap, centerX, centerY, radius)
    -- First, mark currently visible tiles as "seen"
    for y = 1, #visMap do
        for x = 1, #visMap[y] do
            if visMap[y][x] == VISIBLE then
                visMap[y][x] = SEEN
            end
        end
    end
    
    -- The center is always visible
    visMap[centerY][centerX] = VISIBLE
    
    -- Cast rays in all directions (full 360 degrees)
    local rayCount = 120  -- Number of rays to cast
    for i = 1, rayCount do
        local angle = (i / rayCount) * math.pi * 2
        Visibility.castRay(map, visMap, centerX, centerY, math.cos(angle), math.sin(angle), radius)
    end
    
    return visMap
end

-- Cast a single ray and mark tiles as visible
function Visibility.castRay(map, visMap, startX, startY, dirX, dirY, maxDistance)
    local x, y = startX, startY
    local distance = 0
    
    while distance < maxDistance do
        -- Move a small step along the ray
        x = x + dirX * 0.3
        y = y + dirY * 0.3
        distance = distance + 0.3
        
        -- Convert to grid coordinates
        local gridX, gridY = math.floor(x + 0.5), math.floor(y + 0.5)
        
        -- Stop if out of bounds
        if not Visibility.isInBounds(map, gridX, gridY) then
            break
        end
        
        -- Mark as visible
        visMap[gridY][gridX] = VISIBLE
        
        -- Stop at walls
        if map.tiles[gridY][gridX] == "#" then
            break
        end
    end
end

-- Check if a tile is currently visible
function Visibility.isVisible(visMap, x, y)
    return visMap[y] and visMap[y][x] == VISIBLE
end

-- Check if a tile has been seen before
function Visibility.isSeen(visMap, x, y)
    return visMap[y] and visMap[y][x] >= SEEN
end

-- Export visibility states for use in other modules
Visibility.UNSEEN = UNSEEN
Visibility.SEEN = SEEN
Visibility.VISIBLE = VISIBLE

return Visibility
