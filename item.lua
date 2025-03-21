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

-- Spawn items in the dungeon
function Item.spawnItems(map, count)
    local items = {}
    
    for i = 1, count do
        local x, y = Item.findValidItemPosition(map)
        if x and y then
            local item = Item.create(x, y)
            table.insert(items, item)
        end
    end
    
    return items
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
