-- Combat module for handling battles between entities

local Combat = {}

-- Check if two entities are adjacent to each other
function Combat.isAdjacent(entity1, entity2)
    local dx = math.abs(entity1.x - entity2.x)
    local dy = math.abs(entity1.y - entity2.y)
    
    -- Adjacent if they're one tile away horizontally or vertically
    return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)
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
function Combat.attack(attacker, defender)
    local damage = Combat.calculateDamage(attacker, defender)
    
    -- Apply damage to defender
    defender.health = defender.health - damage
    
    -- Check if defender is killed
    local killed = defender.health <= 0
    
    -- Return damage dealt and killed status
    return damage, killed
end

return Combat
