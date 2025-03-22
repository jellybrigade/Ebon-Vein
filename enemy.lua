-- Enemy module for handling enemy entities and AI

local Enemy = {}
local Combat = require("combat")  -- Import combat for ranged attacks
local Visibility = require("visibility")  -- Import visibility module
local Hazard = require("hazard")  -- Import hazard module

-- Enemy types with their properties
local ENEMY_TYPES = {
    {
        symbol = "g", 
        name = "Goblin", 
        health = 3, 
        maxHealth = 3, 
        damage = 1, 
        defense = 0, 
        color = {0.5, 0.8, 0.3},
        behavior = "aggressive",  -- Aggressively follows player
        movementSpeed = 1
    },
    {
        symbol = "o", 
        name = "Orc", 
        health = 5, 
        maxHealth = 5, 
        damage = 2, 
        defense = 1, 
        color = {0.2, 0.6, 0.1},
        behavior = "defensive",   -- Only approaches if player is close
        movementSpeed = 1
    },
    {
        symbol = "s", 
        name = "Shade", 
        health = 2, 
        maxHealth = 2, 
        damage = 3, 
        defense = 0, 
        color = {0.5, 0.5, 0.8},
        behavior = "patrolling",  -- Patrols an area until it spots player
        movementSpeed = 1,
        patrolRadius = 4
    },
    {
        symbol = "a", 
        name = "Archer", 
        health = 2, 
        maxHealth = 2, 
        damage = 2, 
        defense = 0, 
        color = {0.8, 0.6, 0.2},
        behavior = "ranged",      -- Prefers to keep distance and attack from afar
        movementSpeed = 1,
        attackRange = 5
    },
    {
        symbol = "w", 
        name = "Wraith", 
        health = 4, 
        maxHealth = 4, 
        damage = 1, 
        defense = 1, 
        color = {0.4, 0.4, 0.7},
        behavior = "flanking",    -- Tries to approach player from the sides/back
        movementSpeed = 2         -- Faster movement
    }
}

-- Add humanoid enemy types
Enemy.TYPES = {}
Enemy.TYPES.HUMANOID = {
    SOLDIER = 'soldier',
    ARCHER = 'archer',
    KNIGHT = 'knight'
}

-- Humanoid enemy properties
local humanoidProperties = {
    [Enemy.TYPES.HUMANOID.SOLDIER] = {
        width = 16,
        height = 32,
        health = 30,
        damage = 10,
        speed = 40,
        attackRange = 20,
        attackCooldown = 1,
        texture = 'humanoid_soldier'
    },
    [Enemy.TYPES.HUMANOID.ARCHER] = {
        width = 16,
        height = 32,
        health = 20,
        damage = 15,
        speed = 30,
        attackRange = 100,
        attackCooldown = 2,
        texture = 'humanoid_archer'
    },
    [Enemy.TYPES.HUMANOID.KNIGHT] = {
        width = 16,
        height = 32,
        health = 50,
        damage = 20,
        speed = 25,
        attackRange = 25,
        attackCooldown = 1.5,
        texture = 'humanoid_knight'
    }
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
        maxHealth = template.maxHealth,
        damage = template.damage,
        defense = template.defense,
        color = template.color,
        sightRange = 8,                      -- How far the enemy can "see" the player
        behavior = template.behavior,        -- Behavior type
        movementSpeed = template.movementSpeed or 1,
        attackRange = template.attackRange or 1,
        patrolPoints = {},                   -- For patrolling enemies
        patrolIndex = 1,                     -- Current patrol point index
        patrolRadius = template.patrolRadius or 3,
        lastSeenPlayerX = nil,               -- Last known player position
        lastSeenPlayerY = nil,
        turnsSincePlayerSeen = 0,            -- Turns since player was last seen
        preferredDistance = template.behavior == "ranged" and 4 or 1 -- Ranged enemies prefer distance
    }
    
    -- Initialize patrol points for patrolling enemies
    if enemy.behavior == "patrolling" then
        Enemy.initPatrolPoints(enemy, x, y)
    end
    
    return enemy
end

-- Function to create a humanoid enemy
function Enemy:createHumanoid(type, x, y)
    local humanoid = self:create(x, y)
    
    -- Set humanoid-specific properties
    local props = humanoidProperties[type]
    humanoid.type = type
    humanoid.width = props.width
    humanoid.height = props.height
    humanoid.health = props.health
    humanoid.damage = props.damage
    humanoid.speed = props.speed
    humanoid.attackRange = props.attackRange
    humanoid.attackCooldown = props.attackCooldown
    humanoid.attackTimer = 0
    humanoid.texture = props.texture
    
    -- Humanoid-specific behavior and state
    humanoid.state = 'idle'  -- idle, walking, attacking
    humanoid.direction = 1   -- 1 for right, -1 for left
    
    -- Override update function for humanoid behavior
    local baseUpdate = humanoid.update
    humanoid.update = function(self, dt)
        -- Call base update function
        baseUpdate(self, dt)
        
        -- Update attack timer
        if self.attackTimer > 0 then
            self.attackTimer = self.attackTimer - dt
        end
        
        -- Humanoid AI logic
        local player = self.level.player
        local distToPlayer = math.sqrt((player.x - self.x)^2 + (player.y - self.y)^2)
        
        if distToPlayer <= self.attackRange then
            -- Attack player if in range and cooldown is ready
            if self.attackTimer <= 0 then
                self:attack(player)
                self.attackTimer = self.attackCooldown
                self.state = 'attacking'
            end
        else
            -- Move towards player
            self.state = 'walking'
            
            -- Update direction based on player position
            self.direction = player.x > self.x and 1 or -1
            
            -- Move towards player
            self.x = self.x + self.direction * self.speed * dt
        end
    end
    
    -- Humanoid attack function
    humanoid.attack = function(self, target)
        -- Different attack logic based on humanoid type
        if self.type == Enemy.TYPES.HUMANOID.ARCHER then
            -- Archers shoot projectiles
            self:shootArrow(target)
        else
            -- Melee attackers damage directly if close enough
            target:takeDamage(self.damage)
        end
    end
    
    -- Archer-specific function to shoot arrows
    if type == Enemy.TYPES.HUMANOID.ARCHER then
        humanoid.shootArrow = function(self, target)
            -- Create an arrow projectile aimed at the target
            local dx = target.x - self.x
            local dy = target.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            local arrow = {
                x = self.x,
                y = self.y + self.height / 2,
                width = 8,
                height = 2,
                damage = self.damage,
                speed = 200,
                dx = dx / dist,
                dy = dy / dist
            }
            
            arrow.update = function(self, dt)
                self.x = self.x + self.dx * self.speed * dt
                self.y = self.y + self.dy * self.speed * dt
                
                -- Check collision with player
                if self:checkCollision(self.level.player) then
                    self.level.player:takeDamage(self.damage)
                    -- Remove arrow
                    for i, proj in ipairs(self.level.projectiles) do
                        if proj == self then
                            table.remove(self.level.projectiles, i)
                            break
                        end
                    end
                end
            end
            
            arrow.render = function(self)
                love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
            end
            
            arrow.checkCollision = function(self, entity)
                return not (self.x > entity.x + entity.width or
                           entity.x > self.x + self.width or
                           self.y > entity.y + entity.height or
                           entity.y > self.y + self.height)
            end
            
            -- Add to projectiles list
            table.insert(self.level.projectiles, arrow)
        end
    end
    
    -- Override render function for humanoids
    humanoid.render = function(self)
        -- Set color based on type
        if self.type == Enemy.TYPES.HUMANOID.SOLDIER then
            love.graphics.setColor(0.8, 0.2, 0.2)
        elseif self.type == Enemy.TYPES.HUMANOID.ARCHER then
            love.graphics.setColor(0.2, 0.8, 0.2)
        elseif self.type == Enemy.TYPES.HUMANOID.KNIGHT then
            love.graphics.setColor(0.2, 0.2, 0.8)
        end
        
        -- Draw humanoid body
        love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1)
        
        -- Draw health bar
        local healthBarWidth = self.width
        local healthBarHeight = 4
        local healthPercentage = self.health / humanoidProperties[self.type].health
        
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle('fill', self.x, self.y - healthBarHeight - 2, 
                                healthBarWidth * healthPercentage, healthBarHeight)
        love.graphics.setColor(1, 1, 1)
    end
    
    return humanoid
end

-- Function to spawn a random humanoid enemy
function Enemy:spawnRandomHumanoid(x, y)
    local types = {
        Enemy.TYPES.HUMANOID.SOLDIER,
        Enemy.TYPES.HUMANOID.ARCHER,
        Enemy.TYPES.HUMANOID.KNIGHT
    }
    local randomType = types[math.random(#types)]
    return self:createHumanoid(randomType, x, y)
end

-- Initialize patrol points in a circular pattern around spawn point
function Enemy.initPatrolPoints(enemy, centerX, centerY)
    local points = {}
    local radius = enemy.patrolRadius
    
    -- Create a simple square patrol path
    table.insert(points, {x = centerX + radius, y = centerY})
    table.insert(points, {x = centerX + radius, y = centerY + radius})
    table.insert(points, {x = centerX, y = centerY + radius})
    table.insert(points, {x = centerX - radius, y = centerY + radius})
    table.insert(points, {x = centerX - radius, y = centerY})
    table.insert(points, {x = centerX - radius, y = centerY - radius})
    table.insert(points, {x = centerX, y = centerY - radius})
    table.insert(points, {x = centerX + radius, y = centerY - radius})
    
    enemy.patrolPoints = points
    enemy.patrolIndex = math.random(#points) -- Start at random point
end

-- Spawn multiple enemies in the dungeon
function Enemy.spawnEnemies(map, count, level)
    local enemies = {}
    
    -- Limit the number of enemies to between 1 and 4 regardless of level
    local actualCount = math.min(4, math.max(1, math.random(1, 4)))
    
    -- Try to place the requested number of enemies
    for i = 1, actualCount do
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
    -- Check if enemy is in player's field of view
    local isVisible = Visibility.isVisible(gameState.visibilityMap, enemy.x, enemy.y)
    
    -- Calculate distance to player
    local dx = gameState.player.x - enemy.x
    local dy = gameState.player.y - enemy.y
    local distToPlayer = math.sqrt(dx * dx + dy * dy)
    
    -- Check if player is visible
    local canSeePlayer = distToPlayer <= enemy.sightRange and 
                          Enemy.hasLineOfSight(enemy, gameState.player, gameState.map)
    
    -- Update last seen player position
    if canSeePlayer then
        enemy.lastSeenPlayerX = gameState.player.x
        enemy.lastSeenPlayerY = gameState.player.y
        enemy.turnsSincePlayerSeen = 0
    else
        enemy.turnsSincePlayerSeen = enemy.turnsSincePlayerSeen + 1
    end
    
    -- Ranged attack if applicable
    if canSeePlayer and enemy.behavior == "ranged" and distToPlayer <= enemy.attackRange then
        if Enemy.tryRangedAttack(enemy, gameState) then
            return -- Attack performed, end turn
        end
    end
    
    -- Choose behavior based on enemy type
    if canSeePlayer or (enemy.lastSeenPlayerX and enemy.turnsSincePlayerSeen < 5) then
        if enemy.behavior == "aggressive" then
            Enemy.behaveAggressive(enemy, gameState)
        elseif enemy.behavior == "defensive" then
            Enemy.behaveDefensive(enemy, gameState, distToPlayer)
        elseif enemy.behavior == "ranged" then
            Enemy.behaveRanged(enemy, gameState, distToPlayer)
        elseif enemy.behavior == "flanking" then
            Enemy.behaveFlanking(enemy, gameState)
        elseif enemy.behavior == "patrolling" then
            -- If patrolling enemy sees player, act aggressively
            Enemy.behaveAggressive(enemy, gameState)
        end
    else
        -- Default behavior when player is not visible
        if enemy.behavior == "patrolling" then
            Enemy.patrolArea(enemy, gameState)
        else
            Enemy.moveRandomly(enemy, gameState)
        end
    end
    
    -- If enemy moves into player's field of view for the first time, add a message
    if not isVisible and Visibility.isVisible(gameState.visibilityMap, enemy.x, enemy.y) then
        if gameState.addMessage then
            gameState.addMessage("You see a " .. enemy.name .. " lurking in the shadows!")
        end
    end
end

-- Check if enemy has line of sight to target
function Enemy.hasLineOfSight(enemy, target, map)
    local x0, y0 = enemy.x, enemy.y
    local x1, y1 = target.x, target.y
    
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy
    
    while x0 ~= x1 or y0 ~= y1 do
        if map.tiles[y0][x0] == "#" and (x0 ~= enemy.x or y0 ~= enemy.y) and (x0 ~= target.x or y0 ~= target.y) then
            return false -- Wall blocks line of sight
        end
        
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
    
    return true
end

-- Aggressive behavior - directly pursue player
function Enemy.behaveAggressive(enemy, gameState)
    local targetX = enemy.lastSeenPlayerX or gameState.player.x
    local targetY = enemy.lastSeenPlayerY or gameState.player.y
    
    Enemy.moveTowardTarget(enemy, targetX, targetY, gameState)
end

-- Defensive behavior - only approach if player is close
function Enemy.behaveDefensive(enemy, gameState, distToPlayer)
    local targetX = enemy.lastSeenPlayerX or gameState.player.x
    local targetY = enemy.lastSeenPlayerY or gameState.player.y
    
    if distToPlayer and distToPlayer < 5 then
        -- Close enough to be aggressive
        Enemy.moveTowardTarget(enemy, targetX, targetY, gameState)
    else
        -- Too far, move randomly
        Enemy.moveRandomly(enemy, gameState)
    end
end

-- Ranged behavior - keep distance while attacking
function Enemy.behaveRanged(enemy, gameState, distToPlayer)
    local targetX = enemy.lastSeenPlayerX or gameState.player.x
    local targetY = enemy.lastSeenPlayerY or gameState.player.y
    
    -- Try to maintain ideal distance
    if distToPlayer < enemy.preferredDistance then
        -- Too close, back away
        Enemy.moveAwayFromTarget(enemy, targetX, targetY, gameState)
    elseif distToPlayer > enemy.preferredDistance + 2 then
        -- Too far, move closer
        Enemy.moveTowardTarget(enemy, targetX, targetY, gameState)
    else
        -- At good range, hold position or make minor adjustments
        Enemy.adjustPosition(enemy, gameState)
    end
end

-- Flanking behavior - try to approach from sides
function Enemy.behaveFlanking(enemy, gameState)
    local player = gameState.player
    
    -- Calculate potential flanking positions
    local positions = {
        {x = player.x + 1, y = player.y + 1}, -- Diagonal
        {x = player.x - 1, y = player.y + 1}, -- Diagonal
        {x = player.x + 1, y = player.y - 1}, -- Diagonal
        {x = player.x - 1, y = player.y - 1}  -- Diagonal
    }
    
    -- Find best flanking position (closest valid one)
    local bestPos = nil
    local minDist = math.huge
    
    for _, pos in ipairs(positions) do
        local dist = math.abs(pos.x - enemy.x) + math.abs(pos.y - enemy.y)
        if Enemy.isValidPosition(pos.x, pos.y, gameState) and dist < minDist then
            bestPos = pos
            minDist = dist
        end
    end
    
    -- Move toward best position or directly toward player if no valid flanking position
    if bestPos then
        Enemy.moveTowardTarget(enemy, bestPos.x, bestPos.y, gameState)
    else
        Enemy.moveTowardTarget(enemy, player.x, player.y, gameState)
    end
end

-- Patrol behavior - follow patrol path
function Enemy.patrolArea(enemy, gameState)
    if #enemy.patrolPoints == 0 then
        Enemy.moveRandomly(enemy, gameState)
        return
    end
    
    -- Get current patrol target
    local target = enemy.patrolPoints[enemy.patrolIndex]
    
    -- If reached target, move to next patrol point
    if enemy.x == target.x and enemy.y == target.y then
        enemy.patrolIndex = enemy.patrolIndex % #enemy.patrolPoints + 1
        target = enemy.patrolPoints[enemy.patrolIndex]
    end
    
    -- Move toward patrol point
    Enemy.moveTowardTarget(enemy, target.x, target.y, gameState)
end

-- Check if a position is valid for movement
function Enemy.isValidPosition(x, y, gameState)
    -- Check map boundaries
    if x < 1 or y < 1 or x > gameState.map.width or y > gameState.map.height then
        return false
    end
    
    -- Check for walls
    if gameState.map.tiles[y][x] ~= "." and 
       gameState.map.tiles[y][x] ~= "," and 
       gameState.map.tiles[y][x] ~= "~" then
        return false
    end
    
    -- Check for other enemies
    for _, enemy in ipairs(gameState.enemies) do
        if enemy.x == x and enemy.y == y then
            return false
        end
    end
    
    -- Check for player
    if gameState.player.x == x and gameState.player.y == y then
        return false
    end
    
    -- Check for inactive hazards (collapsed floors)
    if gameState.hazards then
        for _, hazard in ipairs(gameState.hazards) do
            if hazard.x == x and hazard.y == y and not hazard.active then
                return false
            end
        end
    end
    
    return true
end

-- Try to perform a ranged attack
function Enemy.tryRangedAttack(enemy, gameState)
    local dx = gameState.player.x - enemy.x
    local dy = gameState.player.y - enemy.y
    local distToPlayer = math.sqrt(dx * dx + dy * dy)
    
    if distToPlayer <= enemy.attackRange and distToPlayer > 1 and Enemy.hasLineOfSight(enemy, gameState.player, gameState.map) then
        -- Perform ranged attack
        local damage = Combat.calculateDamage(enemy, gameState.player) - 1 -- Slightly reduced damage for ranged
        damage = math.max(1, damage) -- Minimum 1 damage
        
        gameState.player.health = gameState.player.health - damage
        
        -- Add a message about the ranged attack
        if gameState.addMessage then
            gameState.addMessage("The " .. enemy.name .. " attacks you from afar for " .. damage .. " damage!")
        end
        
        return true
    end
    
    return false
end

-- Move toward a specific target position
function Enemy.moveTowardTarget(enemy, targetX, targetY, gameState)
    -- Determine best direction to move
    local dx = 0
    local dy = 0
    
    if enemy.x < targetX then dx = 1
    elseif enemy.x > targetX then dx = -1 end
    
    if enemy.y < targetY then dy = 1
    elseif enemy.y > targetY then dy = -1 end
    
    -- For faster enemies, try to move multiple steps
    local moved = false
    for i = 1, enemy.movementSpeed do
        if moved then break end
        
        -- Try to move (only in one direction at a time for simplicity)
        if dx ~= 0 and dy ~= 0 then
            -- Choose randomly between horizontal and vertical movement
            if math.random() < 0.5 then
                moved = Enemy.tryMove(enemy, dx, 0, gameState)
                if not moved then
                    moved = Enemy.tryMove(enemy, 0, dy, gameState)
                end
            else
                moved = Enemy.tryMove(enemy, 0, dy, gameState)
                if not moved then
                    moved = Enemy.tryMove(enemy, dx, 0, gameState)
                end
            end
        else
            -- Move in the non-zero direction
            moved = Enemy.tryMove(enemy, dx, dy, gameState)
        end
    end
    
    -- If couldn't move in primary direction, try alternate directions
    if not moved then
        local directions = {{1,0}, {-1,0}, {0,1}, {0,-1}}
        for _, dir in ipairs(directions) do
            if Enemy.tryMove(enemy, dir[1], dir[2], gameState) then
                break
            end
        end
    end
end

-- Move away from a target position
function Enemy.moveAwayFromTarget(enemy, targetX, targetY, gameState)
    -- Calculate direction away from player
    local dx = enemy.x - targetX
    local dy = enemy.y - targetY
    
    -- Normalize to -1, 0, or 1
    if dx > 0 then dx = 1 elseif dx < 0 then dx = -1 end
    if dy > 0 then dy = 1 elseif dy < 0 then dy = -1 end
    
    -- Try to move away
    local moved = false
    
    if dx ~= 0 and dy ~= 0 then
        -- Choose randomly between horizontal and vertical movement
        if math.random() < 0.5 then
            moved = Enemy.tryMove(enemy, dx, 0, gameState)
            if not moved then
                moved = Enemy.tryMove(enemy, 0, dy, gameState)
            end
        else
            moved = Enemy.tryMove(enemy, 0, dy, gameState)
            if not moved then
                moved = Enemy.tryMove(enemy, dx, 0, gameState)
            end
        end
    else
        -- Move in the non-zero direction
        moved = Enemy.tryMove(enemy, dx, dy, gameState)
    end
    
    -- If couldn't move away, try random movement
    if not moved then
        Enemy.moveRandomly(enemy, gameState)
    end
end

-- Make small position adjustments (for ranged enemies holding position)
function Enemy.adjustPosition(enemy, gameState)
    local directions = {{0,0}, {1,0}, {-1,0}, {0,1}, {0,-1}}
    
    -- Shuffle directions
    for i = #directions, 2, -1 do
        local j = math.random(i)
        directions[i], directions[j] = directions[j], directions[i]
    end
    
    -- Try each direction
    for _, dir in ipairs(directions) do
        if Enemy.tryMove(enemy, dir[1], dir[2], gameState) then
            break
        end
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
    -- No movement requested
    if dx == 0 and dy == 0 then return true end
    
    local newX = enemy.x + dx
    local newY = enemy.y + dy
    
    if Enemy.isValidPosition(newX, newY, gameState) then
        enemy.x = newX
        enemy.y = newY
        
        -- Check for hazards at new position
        if gameState.hazards then
            local _, hazard = nil, nil
            for i, h in ipairs(gameState.hazards) do
                if h.x == newX and h.y == newY and h.active then
                    _, hazard = i, h
                    break
                end
            end
            
            if hazard then
                -- Trigger hazard for enemy
                Hazard.trigger(hazard, enemy, gameState)
            end
        end
        
        return true
    end
    
    return false
end

return Enemy
