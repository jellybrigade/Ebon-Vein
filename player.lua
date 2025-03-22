local Player = {}
local Combat = require("combat")
local Sanity = require("sanity")

-- Initialize player abilities
function Player.initAbilities(player)
    player.abilities = {
        {
            id = "cleave",
            name = "Cleave",
            description = "Attack all adjacent enemies",
            cooldown = 5,
            currentCooldown = 0,
            action = Combat.ABILITIES.CLEAVE
        },
        {
            id = "defensive_stance",
            name = "Defensive Stance",
            description = "Double defense for 3 turns",
            cooldown = 8,
            currentCooldown = 0,
            action = Combat.ABILITIES.DEFENSIVE_STANCE
        }
    }
    
    -- Add ability to use when sanity is critical
    if player.sanity and player.sanity.current <= Sanity.THRESHOLDS.CRITICAL then
        table.insert(player.abilities, {
            id = "desperate_strike",
            name = "Desperate Strike",
            description = "Deal double damage but lose health",
            cooldown = 3,
            currentCooldown = 0,
            action = {
                name = "Desperate Strike",
                execute = function(entity, gameState)
                    -- Find adjacent enemy
                    local directions = {{0,1}, {1,0}, {0,-1}, {-1,0}}
                    local targetEnemy = nil
                    local targetIndex = nil
                    
                    for _, dir in ipairs(directions) do
                        local targetX = entity.x + dir[1]
                        local targetY = entity.y + dir[2]
                        
                        for i, enemy in ipairs(gameState.enemies) do
                            if enemy.x == targetX and enemy.y == targetY then
                                targetEnemy = enemy
                                targetIndex = i
                                break
                            end
                        end
                        
                        if targetEnemy then break end
                    end
                    
                    if not targetEnemy then
                        gameState.addMessage("No adjacent enemies to strike!")
                        return false
                    end
                    
                    -- Deal double damage but take damage yourself
                    local damage = entity.damage * 2
                    targetEnemy.health = targetEnemy.health - damage
                    entity.health = entity.health - 2
                    
                    gameState.addMessage("Your desperate strike hits the " .. targetEnemy.name .. 
                                       " for " .. damage .. " damage, but you suffer 2 damage!")
                    
                    if targetEnemy.health <= 0 then
                        gameState.addMessage("You defeated the " .. targetEnemy.name .. "!")
                        table.remove(gameState.enemies, targetIndex)
                    end
                    
                    return true
                end
            }
        })
    end
end

-- Update ability cooldowns
function Player.updateAbilities(player)
    for _, ability in ipairs(player.abilities) do
        if ability.currentCooldown > 0 then
            ability.currentCooldown = ability.currentCooldown - 1
        end
    end
end

-- Use ability by index
function Player.useAbility(player, abilityIndex, gameState)
    if not player.abilities[abilityIndex] then
        return false, "No such ability"
    end
    
    local ability = player.abilities[abilityIndex]
    
    -- Check if ability is on cooldown
    if ability.currentCooldown > 0 then
        return false, ability.name .. " is on cooldown for " .. ability.currentCooldown .. " more turns"
    end
    
    -- Execute ability
    local success = ability.action.execute(player, gameState)
    
    if success then
        -- Set ability on cooldown
        ability.currentCooldown = ability.cooldown
        return true, "Used " .. ability.name
    else
        return false, "Couldn't use " .. ability.name
    end
end

return Player
