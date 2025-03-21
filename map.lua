-- Map module for handling the dungeon grid

local Map = {}

-- Tile types
local FLOOR = "."
local WALL = "#"

-- Room parameters
local MIN_ROOM_SIZE = 4
local MAX_ROOM_SIZE = 8
local MAX_ROOMS = 15

-- Create a new map grid
function Map.create(width, height)
    local map = {
        width = width,
        height = height,
        tiles = {},
        rooms = {} -- Store rooms for later use
    }
    
    -- Initialize with walls
    for y = 1, height do
        map.tiles[y] = {}
        for x = 1, width do
            map.tiles[y][x] = WALL
        end
    end
    
    -- Generate rooms and corridors
    Map.generateDungeon(map)
    
    return map
end

-- Generate a random dungeon with rooms and corridors
function Map.generateDungeon(map)
    -- Try to place rooms
    for i = 1, MAX_ROOMS do
        -- Random room dimensions
        local roomW = math.random(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
        local roomH = math.random(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
        
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
                Map.createCorridor(map, newRoom.center, prevRoom.center)
            end
            
            -- Store the room
            table.insert(map.rooms, newRoom)
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
function Map.createCorridor(map, from, to)
    -- Horizontal corridor
    local x1, x2 = from.x, to.x
    if x1 > x2 then x1, x2 = x2, x1 end
    for x = x1, x2 do
        if x > 0 and x <= map.width and from.y > 0 and from.y <= map.height then
            map.tiles[from.y][x] = FLOOR
        end
    end
    
    -- Vertical corridor
    local y1, y2 = from.y, to.y
    if y1 > y2 then y1, y2 = y2, y1 end
    for y = y1, y2 do
        if y > 0 and y <= map.height and to.x > 0 and to.x <= map.width then
            map.tiles[y][to.x] = FLOOR
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
