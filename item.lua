-- Item module for handling in-game collectible items

local Item = {}

-- Item types with their properties
local ITEM_TYPES = {
    {
        id = "health_potion",
        name = "Health Potion",
        symbol = "H",
        color = {0.7, 0.1, 0.7},
        description = "Restores 5 health points",
        use = function(player) 
            local healAmount = 5
            local oldHealth = player.health
            player.health = math.min(player.health + healAmount, player.maxHealth)
            return "You drink the potion and restore " .. (player.health - oldHealth) .. " health."
        end
    },
    {
        id = "sword",
        name = "Iron Sword",
        symbol = "W",
        color = {0.7, 0.7, 0.9},
        description = "+2 damage",
        use = function(player)
            player.damage = player.damage + 2
            return "You equip the sword, increasing your damage."
        end
    },
    {
        id = "shield",
        name = "Wooden Shield", 
        symbol = "S",
        color = {0.6, 0.4, 0.2},
        description = "+1 defense",
        use = function(player)
            player.defense = player.defense + 1
            return "You equip the shield, increasing your defense."
        end
    },
    {
        id = "shard_of_light",
        name = "Shard of Light",
        symbol = "L",
        color = {0.9, 0.9, 0.6},
        description = "A fragment of forgotten sunlight. Restores sanity.",
        use = function(player)
            return "The shard dissolves into motes of light that seep into your mind.", 20, 0
        end
    },
    {
        id = "memory_crystal",
        name = "Memory Crystal",
        symbol = "M",
        color = {0.4, 0.6, 0.8},
        description = "Contains memories of the world above. Restores sanity but is physically draining.",
        use = function(player)
            return "Memories of the surface world flood your consciousness.", 30, -2
        end
    },
    {
        id = "resonance_stone",
        name = "Resonance Stone",
        symbol = "R",
        color = {0.5, 0.5, 0.5},
        description = "Vibrates at a frequency that stabilizes your thoughts.",
        use = function(player)
            return "The stone emits a calming resonance that clears your thoughts.", 15, 0
        end
    },
    {
        id = "black_salt",
        name = "Black Salt",
        symbol = "B",
        color = {0.2, 0.2, 0.3},
        description = "Ancient salt that wards against abyssal influence. Restores sanity but causes pain.",
        use = function(player)
            return "The bitter salt burns your tongue but clears your mind.", 25, -3
        end
    }
}

-- Create a new item
function Item.create(x, y, itemType)
    local itemTypeId = itemType or math.random(#ITEM_TYPES)
    local template = ITEM_TYPES[itemTypeId]
    
    local item = {
        x = x,
        y = y,
        id = template.id,
        name = template.name,
        symbol = template.symbol,
        color = template.color,
        description = template.description,
        use = template.use
    }
    
    return item
end

-- Create a meditation altar
function Item.createMeditationAltar(x, y)
    local altar = {
        x = x,
        y = y,
        id = "meditation_altar",
        name = "Cursed Altar",
        symbol = "A",
        color = {0.6, 0.2, 0.6},
        description = "A strange altar that seems to resonate with your thoughts. Meditating here may restore sanity... or worse.",
        isMeditationAltar = true  -- Special flag for altars
    }
    
    return altar
end

-- Spawn items in the dungeon
function Item.spawnItems(map, count, level)
    local items = {}
    
    -- Ensure we have some sanity restoration items
    local sanityItemCount = math.max(1, math.floor(count * 0.3))  -- 30% of items are sanity items
    
    -- First place sanity restoration items
    for i = 1, sanityItemCount do
        local x, y = Item.findValidItemPosition(map)
        if x and y then
            -- Create a sanity restoration item
            local sanityItemTypes = {4, 5, 6, 7}  -- Indices of sanity items
            local itemType = sanityItemTypes[math.random(#sanityItemTypes)]
            local item = Item.create(x, y, itemType)
            table.insert(items, item)
        end
    end
    
    -- Then place regular items
    for i = 1, count - sanityItemCount do
        local x, y = Item.findValidItemPosition(map)
        if x and y then
            -- Create regular items (weapons, potions, etc.)
            local regularItemTypes = {1, 2, 3}  -- Indices of regular items
            local itemType = regularItemTypes[math.random(#regularItemTypes)]
            local item = Item.create(x, y, itemType)
            table.insert(items, item)
        end
    end
    
    -- Place meditation altars based on level
    local altarCount = math.min(2, math.floor(level / 2))
    for i = 1, altarCount do
        local x, y = Item.findValidAltarPosition(map, items)
        if x and y then
            local altar = Item.createMeditationAltar(x, y)
            table.insert(items, altar)
        end
    end
    
    return items
end

-- Find a valid position for an altar (in rooms, away from other items)
function Item.findValidAltarPosition(map, existingItems)
    -- Prefer to place altars in rooms rather than corridors
    if #map.rooms <= 1 then
        return Item.findValidItemPosition(map) -- Fallback if no rooms
    end
    
    -- Try each room except the first one (where player starts)
    for roomIdx = 2, #map.rooms do
        local room = map.rooms[roomIdx]
        local roomCenterX = math.floor(room.x + room.width / 2)
        local roomCenterY = math.floor(room.y + room.height / 2)
        
        -- Check if center is free
        local isFree = true
        for _, item in ipairs(existingItems) do
            if item.x == roomCenterX and item.y == roomCenterY then
                isFree = false
                break
            end
        end
        
        if isFree and map.tiles[roomCenterY][roomCenterX] == "." then
            return roomCenterX, roomCenterY
        end
        
        -- Try a few positions within the room
        local attempts = 0
        while attempts < 10 do
            local x = math.floor(room.x + math.random(1, room.width - 2))
            local y = math.floor(room.y + math.random(1, room.height - 2))
            
            if map.tiles[y][x] == "." then
                local occupied = false
                for _, item in ipairs(existingItems) do
                    if item.x == x and item.y == y then
                        occupied = true
                        break
                    end
                end
                
                if not occupied then
                    return x, y
                end
            end
            
            attempts = attempts + 1
        end
    end
    
    -- Fallback to regular item placement
    return Item.findValidItemPosition(map)
end

-- Find a valid position for an item (on a floor tile, not in the first room)
function Item.findValidItemPosition(map)
    local attempts = 0
    local maxAttempts = 100
    
    while attempts < maxAttempts do
        local x, y = math.random(1, map.width), math.random(1, map.height)
        
        -- Check if position is a floor and not in the first room
        if map.tiles[y][x] == "." and not Item.isInFirstRoom(x, y, map) then
            return x, y
        end
        
        attempts = attempts + 1
    end
    
    return nil, nil -- Couldn't find a valid position
end

-- Check if a position is in the first room (same as in Enemy)
function Item.isInFirstRoom(x, y, map)
    if #map.rooms == 0 then
        return false
    end
    
    local firstRoom = map.rooms[1]
    return x >= firstRoom.x and x < firstRoom.x + firstRoom.width and
           y >= firstRoom.y and y < firstRoom.y + firstRoom.height
end

-- Find an item at specific coordinates
function Item.findItemAt(items, x, y)
    for i, item in ipairs(items) do
        if item.x == x and item.y == y then
            return i -- Return the index of the item
        end
    end
    return nil
end

return Item
