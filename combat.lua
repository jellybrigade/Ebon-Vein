-- Combat module for handling battles between entities

local Combat = {}

-- Check if two entities are adjacent to each other
function Combat.isAdjacent(entity1, entity2)
    local dx = math.abs(entity1.x - entity2.x)
    local dy = math.abs(entity1.y - entity2.y)
    
    -- Adjacent if they're one tile away horizontally or vertically
    return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)
end

-- Check if entity1 can attack entity2 from range
function Combat.isInRange(entity1, entity2, range)
    local range = range or entity1.attackRange or 1
    local dx = math.abs(entity1.x - entity2.x)
    local dy = math.abs(entity1.y - entity2.y)
    local distance = math.sqrt(dx*dx + dy*dy)
    
    return distance <= range
end

-- Calculate damage with randomness factor
function Combat.calculateDamage(attacker, defender)
    -- Base damage from attacker
    local baseDamage = attacker.damage or 1
    
    -- Apply randomness (-1, 0, or +1)
    local randomFactor = math.random(-1, 1)
    local damage = baseDamage + randomFactor
    
    -- Subtract defender's defense
    damage = damage - (defender.defense or 0)
    
    -- Ensure minimum of 1 damage
    return math.max(1, damage)
end

-- Handle attack between two entities
function Combat.attack(attacker, defender, isRanged)
    local damage = Combat.calculateDamage(attacker, defender)
    
    -- Ranged attacks do slightly less damage
    if isRanged then
        damage = math.max(1, damage - 1)
    end
    
    -- Apply damage to defender
    defender.health = defender.health - damage
    
    -- Check if defender is killed
    local killed = defender.health <= 0
    
    -- Return damage dealt and killed status
    return damage, killed
end

-- Define special abilities
Combat.ABILITIES = {
    CLEAVE = {
        name = "Cleave",
        description = "Attack all adjacent enemies",
        cooldown = 5,
        execute = function(entity, gameState)
            local hitCount = 0
            local directions = {{0,1}, {1,0}, {0,-1}, {-1,0}, {1,1}, {-1,-1}, {1,-1}, {-1,1}}
            
            for _, dir in ipairs(directions) do
                local targetX = entity.x + dir[1]
                local targetY = entity.y + dir[2]
                
                -- Check for enemies at this position
                for i, enemy in ipairs(gameState.enemies) do
                    if enemy.x == targetX and enemy.y == targetY then
                        local damage = math.max(1, math.floor(entity.damage * 0.7))
                        enemy.health = enemy.health - damage
                        hitCount = hitCount + 1
                        
                        if enemy.health <= 0 then
                            gameState.addMessage("You cleaved the " .. enemy.name .. " for " .. damage .. " damage, defeating it!")
                            table.remove(gameState.enemies, i)
                        else
                            gameState.addMessage("You cleaved the " .. enemy.name .. " for " .. damage .. " damage!")
                        end
                        break
                    end
                end
            end
            
            if hitCount == 0 then
                gameState.addMessage("Your cleave hits nothing but air.")
                return false
            end
            
            return true
        end
    },
    
    DEFENSIVE_STANCE = {
        name = "Defensive Stance",
        description = "Double defense for 3 turns",
        cooldown = 8,
        duration = 3,
        execute = function(entity, gameState)
            -- Add defensive stance status effect
            table.insert(entity.statusEffects, {
                name = "Defensive Stance",
                type = "defense_boost",
                value = entity.defense,  -- Double defense
                remaining = 3
            })
            gameState.addMessage("You assume a defensive stance, doubling your defense for 3 turns.")
            return true
        end
    }
}

-- Update status effects at end of turn
function Combat.updateStatusEffects(entity)
    if not entity.statusEffects then return end
    
    for i = #entity.statusEffects, 1, -1 do
        local effect = entity.statusEffects[i]
        effect.remaining = effect.remaining - 1
        
        if effect.remaining <= 0 then
            table.remove(entity.statusEffects, i)
        end
    end
end

-- Calculate defense including status effects
function Combat.getDefense(entity)
    local totalDefense = entity.defense or 0
    
    if entity.statusEffects then
        for _, effect in ipairs(entity.statusEffects) do
            if effect.type == "defense_boost" then
                totalDefense = totalDefense + effect.value
            end
        end
    end
    
    return totalDefense
end

-- Modify damage calculation to use enhanced defense
function Combat.attack(attacker, defender)
    local damage = math.max(1, attacker.damage - Combat.getDefense(defender))
    defender.health = defender.health - damage
    return damage, defender.health <= 0
end

return Combat
