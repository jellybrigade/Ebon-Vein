-- Enemy module for handling enemy entities and AI

local Enemy = {}

-- Enemy types with their properties
local ENEMY_TYPES = {
    {symbol = "g", name = "Goblin", health = 3, damage = 1, color = {0.5, 0.8, 0.3}},
    {symbol = "o", name = "Orc", health = 5, damage = 2, color = {0.2, 0.6, 0.1}},
    {symbol = "s", name = "Shade", health = 2, damage = 1, color = {0.5, 0.5, 0.8}}
}

-- Create a new enemy
function Enemy.create(x, y, type)
    local enemyType = type or math.random(#ENEMY_TYPES)
    local template = ENEMY_TYPES[enemyType]
    
    local enemy = {
        x = x,
        y = y,
        symbol = template.symbol,
        name = template.name,
        health = template.health,
        maxHealth = template.health,
        damage = template.damage,
        color = template.color,
        sightRange = 5 -- How far the enemy can "see" the player
    }
    
    return enemy
end

-- Spawn multiple enemies in the dungeon
function Enemy.spawnEnemies(map, count)
    local enemies = {}
    
    -- Try to place the requested number of enemies
    for i = 1, count do
        local x, y = Enemy.findValidEnemyPosition(map)
        if x and y then
            local enemy = Enemy.create(x, y)
            table.insert(enemies, enemy)
        end
    end
    
    return enemies
end

-- Find a valid position for an enemy (on a floor tile)
function Enemy.findValidEnemyPosition(map)
    local attempts = 0
    local maxAttempts = 100
    
    while attempts < maxAttempts do
        local x, y = math.random(1, map.width), math.random(1, map.height)
        
        -- Check if position is a floor and not in the first room (to avoid spawning near the player)
        if map.tiles[y][x] == "." and not Enemy.isInFirstRoom(x, y, map) then
            return x, y
        end
        
        attempts = attempts + 1
    end
    
    return nil, nil -- Couldn't find a valid position
end

-- Check if a position is in the first room (to avoid spawning near player start)
function Enemy.isInFirstRoom(x, y, map)
    if #map.rooms == 0 then
        return false
    end
    
    local firstRoom = map.rooms[1]
    return x >= firstRoom.x and x < firstRoom.x + firstRoom.width and
           y >= firstRoom.y and y < firstRoom.y + firstRoom.height
end

-- Update an enemy (decide and perform its action)
function Enemy.update(enemy, gameState)
    -- Calculate distance to player
    local dx = gameState.player.x - enemy.x
    local dy = gameState.player.y - enemy.y
    local distToPlayer = math.sqrt(dx * dx + dy * dy)
    
    -- If player is within sight range, move toward them
    if distToPlayer <= enemy.sightRange then
        Enemy.moveTowardPlayer(enemy, gameState)
    else
        -- Otherwise move randomly
        Enemy.moveRandomly(enemy, gameState)
    end
end

-- Move enemy toward the player
function Enemy.moveTowardPlayer(enemy, gameState)
    local dx = 0
    local dy = 0
    
    -- Determine direction toward player
    if enemy.x < gameState.player.x then dx = 1
    elseif enemy.x > gameState.player.x then dx = -1 end
    
    if enemy.y < gameState.player.y then dy = 1
    elseif enemy.y > gameState.player.y then dy = -1 end
    
    -- Try to move (only in one direction at a time for simplicity)
    if dx ~= 0 and dy ~= 0 then
        -- Choose randomly between horizontal and vertical movement
        if math.random() < 0.5 then
            Enemy.tryMove(enemy, dx, 0, gameState)
        else
            Enemy.tryMove(enemy, 0, dy, gameState)
        end
    else
        -- Move in the non-zero direction
        Enemy.tryMove(enemy, dx, dy, gameState)
    end
end

-- Move enemy in a random direction
function Enemy.moveRandomly(enemy, gameState)
    local directions = {
        {0, -1},  -- Up
        {1, 0},   -- Right
        {0, 1},   -- Down
        {-1, 0}   -- Left
    }
    
    local dir = directions[math.random(#directions)]
    Enemy.tryMove(enemy, dir[1], dir[2], gameState)
end

-- Try to move the enemy in the specified direction
function Enemy.tryMove(enemy, dx, dy, gameState)
    local newX = enemy.x + dx
    local newY = enemy.y + dy
    
    -- Don't move into walls
    local tile = gameState.map.tiles[newY] and gameState.map.tiles[newY][newX]
    if not tile or tile ~= "." then
        return false
    end
    
    -- Don't move into player
    if newX == gameState.player.x and newY == gameState.player.y then
        -- In the future, this could trigger combat
        return false
    end
    
    -- Don't move into another enemy
    for _, otherEnemy in ipairs(gameState.enemies) do
        if otherEnemy ~= enemy and otherEnemy.x == newX and otherEnemy.y == newY then
            return false
        end
    end
    
    -- All checks passed, update position
    enemy.x = newX
    enemy.y = newY
    return true
end

return Enemy
