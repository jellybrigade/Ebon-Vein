-- Hazard module for environmental interactions

local Hazard = {}
local Map = require("map")  -- Import the Map module
local Visibility = require("visibility")  -- Import Visibility module
local Sanity = require("sanity")  -- Import Sanity module

-- Hazard types
Hazard.TYPES = {
    ACID_POOL = "acid",      -- Damages entities that step on it
    GAS_VENT = "gas",        -- Periodically releases gas clouds 
    SPIKE_TRAP = "spikes",   -- Damages the first entity to step on it
    FIRE = "fire",           -- Damages over time, can spread
    CRUMBLING = "crumbling"  -- Floor that collapses after being stepped on
}

-- Visual representation for hazards
Hazard.SYMBOLS = {
    [Hazard.TYPES.ACID_POOL] = "~",
    [Hazard.TYPES.GAS_VENT] = "^",
    [Hazard.TYPES.SPIKE_TRAP] = "_",
    [Hazard.TYPES.FIRE] = "&",
    [Hazard.TYPES.CRUMBLING] = "."  -- Similar to floor but will be colored differently
}

-- Colors for hazards
Hazard.COLORS = {
    [Hazard.TYPES.ACID_POOL] = {0.2, 0.9, 0.2},
    [Hazard.TYPES.GAS_VENT] = {0.7, 0.7, 0.2},
    [Hazard.TYPES.SPIKE_TRAP] = {0.7, 0.7, 0.7},
    [Hazard.TYPES.FIRE] = {0.9, 0.4, 0.1},
    [Hazard.TYPES.CRUMBLING] = {0.6, 0.5, 0.4}
}

-- Create a new hazard
function Hazard.create(type, x, y)
    local hazard = {
        type = type,
        x = x,
        y = y,
        symbol = Hazard.SYMBOLS[type],
        color = Hazard.COLORS[type],
        active = true,      -- Whether the hazard is active
        duration = nil,     -- For temporary hazards like fire
        triggered = false,  -- For one-time traps
        gas = {},           -- For gas vents to track gas clouds
        
        -- Special properties per hazard type
        properties = {}
    }
    
    -- Set up type-specific properties
    if type == Hazard.TYPES.ACID_POOL then
        hazard.properties.damage = 2
    elseif type == Hazard.TYPES.GAS_VENT then
        hazard.properties.gasType = "confusion"
        hazard.properties.ventInterval = 5  -- Turns between gas releases
        hazard.properties.ventCounter = math.random(1, 5)  -- Randomize starting countdown
    elseif type == Hazard.TYPES.SPIKE_TRAP then
        hazard.properties.damage = 3
        hazard.properties.visible = math.random() < 0.3  -- Some traps are visible
        if not hazard.properties.visible then
            hazard.symbol = "."  -- Hidden trap looks like floor
            hazard.color = {0.4, 0.4, 0.4}  -- Slightly darker than normal floor
        end
    elseif type == Hazard.TYPES.FIRE then
        hazard.properties.damage = 1
        hazard.properties.spreadChance = 0.2
        hazard.duration = 10 + math.random(1, 10)  -- Fires burn out after some time
    elseif type == Hazard.TYPES.CRUMBLING then
        hazard.properties.stepsBeforeCollapse = 1
    end
    
    return hazard
end

-- Find a hazard at specific coordinates
function Hazard.findAt(hazards, x, y)
    for i, hazard in ipairs(hazards) do
        if hazard.x == x and hazard.y == y and hazard.active then
            return i, hazard
        end
    end
    return nil, nil
end

-- Trigger a hazard effect when stepped on
function Hazard.trigger(hazard, entity, gameState)
    if not hazard.active then
        return false
    end
    
    local effect = false
    
    if hazard.type == Hazard.TYPES.ACID_POOL then
        -- Apply acid damage
        entity.health = entity.health - hazard.properties.damage
        effect = true
        
        -- Add message if player stepped on acid
        if entity == gameState.player and gameState.addMessage then
            gameState.addMessage("You step in acid and take " .. hazard.properties.damage .. " damage!")
        elseif gameState.addMessage and entity.name then
            gameState.addMessage("The " .. entity.name .. " steps in acid.")
        end
        
    elseif hazard.type == Hazard.TYPES.SPIKE_TRAP and not hazard.triggered then
        -- Trigger spike trap once
        entity.health = entity.health - hazard.properties.damage
        hazard.triggered = true
        hazard.symbol = "_"  -- Show as triggered trap
        hazard.color = Hazard.COLORS[Hazard.TYPES.SPIKE_TRAP]  -- Show normal trap color now
        effect = true
        
        if entity == gameState.player and gameState.addMessage then
            gameState.addMessage("You trigger a spike trap and take " .. hazard.properties.damage .. " damage!")
        elseif gameState.addMessage and entity.name then
            gameState.addMessage("The " .. entity.name .. " triggers a spike trap.")
        end
        
    elseif hazard.type == Hazard.TYPES.FIRE then
        -- Apply fire damage
        entity.health = entity.health - hazard.properties.damage
        effect = true
        
        if entity == gameState.player and gameState.addMessage then
            gameState.addMessage("You walk through fire and take " .. hazard.properties.damage .. " damage!")
        elseif gameState.addMessage and entity.name then
            gameState.addMessage("The " .. entity.name .. " walks through fire.")
        end
        
    elseif hazard.type == Hazard.TYPES.CRUMBLING then
        -- Reduce steps until collapse
        hazard.properties.stepsBeforeCollapse = hazard.properties.stepsBeforeCollapse - 1
        
        if hazard.properties.stepsBeforeCollapse <= 0 then
            -- Floor collapses
            hazard.active = false
            hazard.symbol = " "  -- Empty space
            effect = true
            
            if entity == gameState.player and gameState.addMessage then
                gameState.addMessage("The floor crumbles beneath your feet!")
                
                -- Player takes falling damage
                entity.health = entity.health - 2
                gameState.addMessage("You fall and take 2 damage.")
            elseif gameState.addMessage and entity.name then
                gameState.addMessage("The floor collapses beneath the " .. entity.name .. "!")
                
                -- Remove the enemy if it falls
                for i, enemy in ipairs(gameState.enemies) do
                    if enemy == entity then
                        table.remove(gameState.enemies, i)
                        gameState.addMessage("The " .. entity.name .. " falls into the darkness below.")
                        break
                    end
                end
            end
        elseif entity == gameState.player and gameState.addMessage then
            gameState.addMessage("The floor feels unstable...")
        end
    end
    
    return effect
end

-- Update hazards (gases, fire spreading, etc.)
function Hazard.updateHazards(hazards, gameState)
    -- Track new hazards to add (e.g., spreading fire)
    local newHazards = {}
    
    for i = #hazards, 1, -1 do
        local hazard = hazards[i]
        
        if not hazard.active then
            -- Clean up inactive hazards
            table.remove(hazards, i)
        elseif hazard.duration then
            -- Reduce duration for temporary hazards
            hazard.duration = hazard.duration - 1
            if hazard.duration <= 0 then
                hazard.active = false
            end
        elseif hazard.type == Hazard.TYPES.GAS_VENT then
            -- Handle gas vent releasing gas periodically
            hazard.properties.ventCounter = hazard.properties.ventCounter - 1
            if hazard.properties.ventCounter <= 0 then
                -- Reset counter
                hazard.properties.ventCounter = hazard.properties.ventInterval
                
                -- Add gas cloud message if player can see it
                if gameState.addMessage and 
                   Visibility.isVisible(gameState.visibilityMap, hazard.x, hazard.y) then
                    gameState.addMessage("A vent releases clouds of noxious gas!")
                    
                    -- Create a sanity effect for gas exposure
                    if gameState.player.sanity then
                        local sanityLoss = math.random(1, 3)
                        local _, message = Sanity.decrease(
                            gameState.player.sanity, 
                            sanityLoss, 
                            "Exposure to strange gases"
                        )
                        if message then
                            gameState.addMessage(message)
                        end
                    end
                end
                
                -- Apply confusion effect if player is nearby
                local dx = math.abs(gameState.player.x - hazard.x)
                local dy = math.abs(gameState.player.y - hazard.y)
                if dx <= 2 and dy <= 2 then
                    -- Make player attack randomly for a few turns
                    gameState.player.attackRandomly = true
                    gameState.player.randomAttackTurns = 3
                    if gameState.addMessage then
                        gameState.addMessage("The gas makes you feel disoriented!")
                    end
                end
            end
        elseif hazard.type == Hazard.TYPES.FIRE and math.random() < hazard.properties.spreadChance then
            -- Fire can spread to adjacent tiles
            local directions = {{0,1}, {1,0}, {0,-1}, {-1,0}}
            local direction = directions[math.random(#directions)]
            local newX, newY = hazard.x + direction[1], hazard.y + direction[2]
            
            -- Check if the target position is valid for fire
            if Map.getTile(gameState.map, newX, newY) == Map.FLOOR then
                -- Don't spread if there's already fire there
                if not Hazard.findAt(hazards, newX, newY) then
                    local newFire = Hazard.create(Hazard.TYPES.FIRE, newX, newY)
                    newFire.duration = math.floor(hazard.duration / 2)  -- Shorter duration for spread fire
                    table.insert(newHazards, newFire)
                    
                    -- Notify if player can see it
                    if gameState.addMessage and 
                       Visibility.isVisible(gameState.visibilityMap, newX, newY) then
                        gameState.addMessage("The fire spreads!")
                    end
                end
            end
        end
    end
    
    -- Add any new hazards that were created
    for _, newHazard in ipairs(newHazards) do
        table.insert(hazards, newHazard)
    end
end

-- Generate hazards for a level
function Hazard.generateHazards(map, level)
    local hazards = {}
    local roomCount = #map.rooms
    
    -- More hazards in deeper levels
    local hazardCount = math.floor(level * 1.5) + math.random(0, 2)
    
    -- List of valid hazard types for this level
    local validHazardTypes = {Hazard.TYPES.SPIKE_TRAP}  -- Traps available at all levels
    
    -- Add different hazard types based on level
    if level >= 2 then
        table.insert(validHazardTypes, Hazard.TYPES.ACID_POOL)
    end
    if level >= 3 then
        table.insert(validHazardTypes, Hazard.TYPES.GAS_VENT)
        table.insert(validHazardTypes, Hazard.TYPES.CRUMBLING)
    end
    if level >= 4 then
        table.insert(validHazardTypes, Hazard.TYPES.FIRE)
    end
    
    -- Place hazards
    for i = 1, hazardCount do
        -- Choose a random room (not the first room where player starts)
        local roomIndex = math.random(2, roomCount)
        local room = map.rooms[roomIndex]
        
        -- Place inside the room, not on the edge
        local x = math.random(room.x + 1, room.x + room.width - 2)
        local y = math.random(room.y + 1, room.y + room.height - 2)
        
        -- Choose a random hazard type from valid options
        local hazardType = validHazardTypes[math.random(#validHazardTypes)]
        
        -- Create and add the hazard
        table.insert(hazards, Hazard.create(hazardType, x, y))
    end
    
    -- Additionally, place a few spike traps in corridors
    local trapCount = math.random(1, level)
    for i = 1, trapCount do
        -- Find a suitable corridor position
        local attempts = 0
        while attempts < 20 do
            local x = math.random(2, map.width - 1)
            local y = math.random(2, map.height - 1)
            
            -- Check if this is a corridor (floor tile not in a room)
            if map.tiles[y][x] == Map.FLOOR then
                local inRoom = false
                for _, room in ipairs(map.rooms) do
                    if x >= room.x and x < room.x + room.width and
                       y >= room.y and y < room.y + room.height then
                        inRoom = true
                        break
                    end
                end
                
                if not inRoom then
                    -- Place a spike trap here
                    table.insert(hazards, Hazard.create(Hazard.TYPES.SPIKE_TRAP, x, y))
                    break
                end
            end
            
            attempts = attempts + 1
        end
    end
    
    return hazards
end

return Hazard
