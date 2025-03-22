-- Map module for handling the dungeon grid

local Map = {}

-- Tile types
local FLOOR = "."
local WALL = "#"
local EXIT = "X"  -- Add exit tile type
local FLESH = "~"  -- Organic tile for later levels
local BLOOD = ","  -- Blood splatter

-- Make tile types accessible from outside
Map.FLOOR = FLOOR
Map.WALL = WALL
Map.EXIT = EXIT  -- Export the EXIT constant
Map.FLESH = FLESH
Map.BLOOD = BLOOD

-- Base map parameters
local BASE_WIDTH = 80
local BASE_HEIGHT = 50
local SIZE_MULTIPLIER = 1.3  -- Each level gets this much bigger than the previous

-- Room parameters
local MIN_ROOM_SIZE = 4
local MAX_ROOM_SIZE = 12  -- Increased from 8 for larger rooms
local BASE_MAX_ROOMS = 20  -- Increased from 15 for more rooms

-- Create a new map grid
function Map.create(width, height, level)
    level = level or 1
    
    -- Calculate size based on level
    local sizeMultiplier = math.pow(SIZE_MULTIPLIER, level - 1)
    local actualWidth = width or math.floor(BASE_WIDTH * sizeMultiplier)
    local actualHeight = height or math.floor(BASE_HEIGHT * sizeMultiplier)
    
    local map = {
        width = actualWidth,
        height = actualHeight,
        tiles = {},
        rooms = {}, -- Store rooms for later use
        level = level, -- Store the level number
        features = {} -- Special map features
    }
    
    -- Initialize with walls
    for y = 1, actualHeight do
        map.tiles[y] = {}
        for x = 1, actualWidth do
            map.tiles[y][x] = WALL
        end
    end
    
    -- Generate rooms and corridors based on level
    if level == 5 then -- Final level
        Map.generateFinalLevel(map)
    else
        Map.generateDungeon(map, level)
    end
    
    -- Add level-specific details
    Map.addLevelDetails(map, level)
    
    return map
end

-- Generate a random dungeon with rooms and corridors
function Map.generateDungeon(map, level)
    -- Adjust parameters based on level and map size
    local mapSizeFactor = (map.width * map.height) / (BASE_WIDTH * BASE_HEIGHT)
    local maxRooms = math.floor(BASE_MAX_ROOMS * mapSizeFactor) + (level * 3) -- More rooms in deeper levels
    local minSize = math.max(4, MIN_ROOM_SIZE - (level - 1)) -- Smaller rooms in deeper levels
    local maxSize = math.min(MAX_ROOM_SIZE, math.floor(MAX_ROOM_SIZE * (0.8 + (level * 0.05)))) -- Larger max size in deeper levels
    
    -- Try to place rooms
    for i = 1, maxRooms do
        -- Random room dimensions
        local roomW = math.random(minSize, maxSize)
        local roomH = math.random(minSize, maxSize)
        
        -- Random room position
        local roomX = math.random(2, map.width - roomW - 1)
        local roomY = math.random(2, map.height - roomH - 1)
        
        local newRoom = {
            x = roomX,
            y = roomY,
            width = roomW,
            height = roomH,
            center = {
                x = math.floor(roomX + roomW / 2),
                y = math.floor(roomY + roomH / 2)
            }
        }
        
        -- Check if this room overlaps with existing rooms
        local failed = false
        for _, otherRoom in ipairs(map.rooms) do
            if Map.roomsIntersect(newRoom, otherRoom) then
                failed = true
                break
            end
        end
        
        if not failed then
            -- Add room to the map
            Map.createRoom(map, newRoom.x, newRoom.y, newRoom.width, newRoom.height)
            
            -- Connect to previous room except for the first room
            if #map.rooms > 0 then
                local prevRoom = map.rooms[#map.rooms]
                -- Create corridor between rooms
                -- Level 2+ can have more chaotic, winding corridors
                if level >= 2 then
                    Map.createWindingCorridor(map, newRoom.center, prevRoom.center, level)
                else
                    Map.createCorridor(map, newRoom.center, prevRoom.center)
                end
            end
            
            -- Store the room
            table.insert(map.rooms, newRoom)
        end
    end
    
    -- Place an exit in the last room
    if #map.rooms > 0 then
        local lastRoom = map.rooms[#map.rooms]
        map.exitX = lastRoom.center.x
        map.exitY = lastRoom.center.y
        map.tiles[map.exitY][map.exitX] = EXIT
    end
end

-- Generate the final level (living flesh chamber)
function Map.generateFinalLevel(map)
    -- Create a large central chamber
    local centerX = math.floor(map.width / 2)
    local centerY = math.floor(map.height / 2)
    local chamberRadius = math.min(math.floor(map.width / 3), math.floor(map.height / 3))
    
    -- Create circular chamber
    for y = 1, map.height do
        for x = 1, map.width do
            local dx = x - centerX
            local dy = y - centerY
            local distance = math.sqrt(dx*dx + dy*dy)
            
            if distance < chamberRadius then
                map.tiles[y][x] = FLESH
            elseif distance < chamberRadius + 1.5 then
                map.tiles[y][x] = WALL
            end
        end
    end
    
    -- Create entrance corridors - more for larger maps
    local entranceCount = math.random(4, math.min(8, math.floor(map.width / 15)))
    local angleStep = (2 * math.pi) / entranceCount
    
    for i = 1, entranceCount do
        local angle = i * angleStep
        local corridorLength = math.random(15, math.min(30, math.floor(map.width / 4)))
        
        local startX = centerX + math.cos(angle) * chamberRadius
        local startY = centerY + math.sin(angle) * chamberRadius
        local endX = centerX + math.cos(angle) * (chamberRadius + corridorLength)
        local endY = centerY + math.sin(angle) * (chamberRadius + corridorLength)
        
        -- Ensure endpoints are within bounds
        endX = math.max(2, math.min(map.width - 1, math.floor(endX)))
        endY = math.max(2, math.min(map.height - 1, math.floor(endY)))
        startX = math.max(2, math.min(map.width - 1, math.floor(startX)))
        startY = math.max(2, math.min(map.height - 1, math.floor(startY)))
        
        -- Create a winding corridor
        Map.createWindingCorridor(map, {x = startX, y = startY}, {x = endX, y = endY}, 3)
        
        -- Create a room at the end of the corridor
        local roomSize = math.random(5, 10)
        local roomX = endX - math.floor(roomSize/2)
        local roomY = endY - math.floor(roomSize/2)
        
        -- Ensure room is within bounds
        roomX = math.max(2, math.min(map.width - roomSize - 1, roomX))
        roomY = math.max(2, math.min(map.height - roomSize - 1, roomY))
        
        Map.createRoom(map, roomX, roomY, roomSize, roomSize)
        
        -- Add the room to the rooms list
        table.insert(map.rooms, {
            x = roomX,
            y = roomY,
            width = roomSize,
            height = roomSize,
            center = {x = endX, y = endY}
        })
    end
    
    -- Place exit in the center of the chamber
    map.exitX = centerX
    map.exitY = centerY
    map.tiles[centerY][centerX] = EXIT
end

-- Create a flesh-based room
function Map.createFleshRoom(map, x, y, width, height)
    for roomY = y - height/2, y + height/2 do
        for roomX = x - width/2, x + width/2 do
            if roomX > 0 and roomX <= map.width and 
               roomY > 0 and roomY <= map.height then
                
                -- Irregular edges for organic feel
                local distToEdge = math.min(
                    roomX - (x - width/2),
                    (x + width/2) - roomX,
                    roomY - (y - height/2),
                    (y + height/2) - roomY
                )
                
                if distToEdge < 1 then
                    if math.random() > 0.4 then
                        map.tiles[math.floor(roomY)][math.floor(roomX)] = WALL
                    else
                        map.tiles[math.floor(roomY)][math.floor(roomX)] = FLESH
                    end
                else
                    map.tiles[math.floor(roomY)][math.floor(roomX)] = FLESH
                end
            end
        end
    end
end

-- Create an organic tendril corridor
function Map.createTentacleCorridor(map, x1, y1, x2, y2)
    local points = {}
    local segments = math.random(4, 8)
    
    -- Generate waypoints with some randomness
    for i = 0, segments do
        local t = i / segments
        local midX = x1 + (x2 - x1) * t
        local midY = y1 + (y2 - y1) * t
        
        -- Add randomness to middle points
        if i > 0 and i < segments then
            midX = midX + math.random(-3, 3)
            midY = midY + math.random(-3, 3)
        end
        
        table.insert(points, {x = midX, y = midY})
    end
    
    -- Connect the waypoints
    for i = 1, #points - 1 do
        Map.createCorridor(map, points[i], points[i+1], true)
    end
end

-- Create a small tendril
function Map.createTendril(map, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local steps = math.max(math.abs(dx), math.abs(dy))
    
    if steps == 0 then return end
    
    for i = 0, steps do
        local t = i / steps
        local x = math.floor(x1 + dx * t)
        local y = math.floor(y1 + dy * t)
        
        if x > 0 and x <= map.width and y > 0 and y <= map.height then
            map.tiles[y][x] = FLESH
        end
    end
end

-- Create a winding corridor with more randomness
function Map.createWindingCorridor(map, from, to, chaosLevel)
    -- Safety check for from and to parameters
    if not from or not from.x or not from.y or not to or not to.x or not to.y then
        print("Warning: createWindingCorridor called with invalid points")
        return
    end
    
    chaosLevel = chaosLevel or 2
    local points = {}
    local segments = 1 + math.floor(chaosLevel * 1.5)
    
    -- Generate intermediate points
    table.insert(points, {x = from.x, y = from.y})
    
    for i = 1, segments - 1 do
        local t = i / segments
        local midX = from.x + (to.x - from.x) * t
        local midY = from.y + (to.y - from.y) * t
        
        -- Add increasing randomness with level
        local randomFactor = chaosLevel * 2
        midX = midX + math.random(-randomFactor, randomFactor)
        midY = midY + math.random(-randomFactor, randomFactor)
        
        -- Ensure midpoints are valid and within map bounds
        midX = math.max(1, math.min(map.width, midX))
        midY = math.max(1, math.min(map.height, midY))
        
        table.insert(points, {x = midX, y = midY})
    end
    
    table.insert(points, {x = to.x, y = to.y})
    
    -- Connect the waypoints
    for i = 1, #points - 1 do
        -- Double-check that points are valid before passing them
        if points[i] and points[i].x and points[i].y and 
           points[i+1] and points[i+1].x and points[i+1].y then
            Map.createCorridor(map, points[i], points[i+1])
        end
    end
end

-- Add level-specific details to the map
function Map.addLevelDetails(map, level)
    -- Level 1: Blood and bones - remnants of failed adventurers
    if level == 1 then
        Map.addBloodStains(map, 0.03)
    
    -- Level 2: Shifting geometry - some walls may have strange patterns
    elseif level == 2 then
        Map.addStrangeWallPatterns(map, 0.05)
    
    -- Level 3: Fleshy growths - the walls begin to look organic
    elseif level == 3 then
        Map.addFleshyGrowths(map, 0.1)
        Map.addBloodStains(map, 0.05)
    
    -- Level 4: Reality distortion - patches of flesh and blood
    elseif level == 4 then
        Map.addFleshyGrowths(map, 0.15)
        Map.addBloodStains(map, 0.08)
        Map.addRealityDistortions(map, 0.1)
    
    -- Level 5: The heart chamber - mostly organic with flesh and blood
    elseif level == 5 then
        Map.addBloodStains(map, 0.12)
        -- Level 5 is already mostly organic from generateFinalLevel
    end
end

-- Add blood stains to the map
function Map.addBloodStains(map, density)
    for y = 1, map.height do
        for x = 1, map.width do
            if map.tiles[y][x] == FLOOR and math.random() < density then
                map.tiles[y][x] = BLOOD
            end
        end
    end
end

-- Add strange wall patterns (for level 2)
function Map.addStrangeWallPatterns(map, density)
    -- Store wall pattern locations
    map.features.wallPatterns = {}
    
    for y = 2, map.height-1 do
        for x = 2, map.width-1 do
            if map.tiles[y][x] == WALL and math.random() < density then
                -- Mark this wall as having a pattern
                table.insert(map.features.wallPatterns, {x = x, y = y})
            end
        end
    end
end

-- Add fleshy growths to walls
function Map.addFleshyGrowths(map, density)
    -- Store flesh growth locations
    map.features.fleshGrowths = {}
    
    for y = 1, map.height do
        for x = 1, map.width do
            -- Add flesh to some walls adjacent to floor
            if map.tiles[y][x] == WALL and math.random() < density then
                -- Check if adjacent to floor
                local adjacentToFloor = false
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        local nx, ny = x + dx, y + dy
                        if nx > 0 and nx <= map.width and ny > 0 and ny <= map.height then
                            if map.tiles[ny][nx] == FLOOR or map.tiles[ny][nx] == BLOOD then
                                adjacentToFloor = true
                                break
                            end
                        end
                    end
                    if adjacentToFloor then break end
                end
                
                if adjacentToFloor then
                    map.tiles[y][x] = FLESH
                    table.insert(map.features.fleshGrowths, {x = x, y = y})
                end
            end
        end
    end
end

-- Add reality distortions (for level 4)
function Map.addRealityDistortions(map, density)
    -- Store distortion locations
    map.features.distortions = {}
    
    for y = 2, map.height-1 do
        for x = 2, map.width-1 do
            if math.random() < density then
                -- Create a small patch of distortion
                table.insert(map.features.distortions, {
                    x = x, 
                    y = y, 
                    radius = math.random(1, 3)
                })
            end
        end
    end
end

-- Check if two rooms intersect (including a buffer zone)
function Map.roomsIntersect(room1, room2)
    local buffer = 1 -- Buffer zone around rooms
    return not (
        room1.x + room1.width + buffer < room2.x or
        room2.x + room2.width + buffer < room1.x or
        room1.y + room1.height + buffer < room2.y or
        room2.y + room2.height + buffer < room1.y
    )
end

-- Create a rectangular room
function Map.createRoom(map, x, y, width, height)
    for roomY = y, y + height - 1 do
        for roomX = x, x + width - 1 do
            if roomX > 0 and roomX <= map.width and 
               roomY > 0 and roomY <= map.height then
                map.tiles[roomY][roomX] = FLOOR
            end
        end
    end
end

-- Create a corridor between two points
function Map.createCorridor(map, from, to, useFleshy)
    -- Safety check to prevent nil indexing
    if not from or not from.x or not from.y or not to or not to.x or not to.y then
        print("Warning: Attempted to create corridor with invalid points")
        return
    end
    
    local tile = useFleshy and FLESH or FLOOR
    
    -- Horizontal corridor
    local x1, x2 = from.x, to.x
    if x1 > x2 then x1, x2 = x2, x1 end
    for x = x1, x2 do
        if x > 0 and x <= map.width and from.y > 0 and from.y <= map.height then
            map.tiles[from.y][x] = tile
        end
    end
    
    -- Vertical corridor
    local y1, y2 = from.y, to.y
    if y1 > y2 then y1, y2 = y2, y1 end
    for y = y1, y2 do
        if y > 0 and y <= map.height and to.x > 0 and to.x <= map.width then
            map.tiles[y][to.x] = tile
        end
    end
end

-- Create a winding corridor with more randomness
function Map.createWindingCorridor(map, from, to, chaosLevel)
    -- Safety check for from and to parameters
    if not from or not from.x or not from.y or not to or not to.x or not to.y then
        print("Warning: createWindingCorridor called with invalid points")
        return
    end
    
    chaosLevel = chaosLevel or 2
    local points = {}
    local segments = 1 + math.floor(chaosLevel * 1.5)
    
    -- Generate intermediate points
    table.insert(points, {x = from.x, y = from.y})
    
    for i = 1, segments - 1 do
        local t = i / segments
        local midX = from.x + (to.x - from.x) * t
        local midY = from.y + (to.y - from.y) * t
        
        -- Add increasing randomness with level
        local randomFactor = chaosLevel * 2
        midX = midX + math.random(-randomFactor, randomFactor)
        midY = midY + math.random(-randomFactor, randomFactor)
        
        -- Ensure midpoints are valid and within map bounds
        midX = math.max(1, math.min(map.width, midX))
        midY = math.max(1, math.min(map.height, midY))
        
        table.insert(points, {x = midX, y = midY})
    end
    
    table.insert(points, {x = to.x, y = to.y})
    
    -- Connect the waypoints
    for i = 1, #points - 1 do
        -- Double-check that points are valid before passing them
        if points[i] and points[i].x and points[i].y and 
           points[i+1] and points[i+1].x and points[i+1].y then
            Map.createCorridor(map, points[i], points[i+1])
        end
    end
end

-- Get the tile at a specific position
function Map.getTile(map, x, y)
    if x < 1 or y < 1 or x > map.width or y > map.height then
        return nil -- Out of bounds
    end
    return map.tiles[y][x]
end

-- Get the tile at a position (safely)
function Map.getTile(map, x, y)
    if x < 1 or y < 1 or x > map.width or y > map.height then
        return WALL  -- Out of bounds is treated as wall
    end
    return map.tiles[y][x]
end

-- Check if a position is a valid floor space (including special tiles like blood)
function Map.isWalkable(map, x, y)
    local tile = Map.getTile(map, x, y)
    return tile == FLOOR or tile == BLOOD or tile == FLESH or tile == EXIT
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

-- Get the center of the first room (for player placement)
function Map.getFirstRoomCenter(map)
    if #map.rooms > 0 then
        local firstRoom = map.rooms[1]
        return firstRoom.center.x, firstRoom.center.y
    end
    
    -- Fallback to a random floor tile if no rooms
    return Map.findRandomFloor(map)
end

return Map
