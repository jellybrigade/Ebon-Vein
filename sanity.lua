-- Sanity module for handling psychological effects of the Abyss

local Sanity = {}

-- Sanity thresholds
Sanity.THRESHOLDS = {
    NORMAL = 75,    -- Normal mental state (75-100)
    DISTURBED = 50, -- Beginning to be affected (50-74)
    UNSTABLE = 25,  -- Significantly compromised (25-49)
    CRITICAL = 10,  -- Near breaking point (10-24)
    BROKEN = 0      -- Lost to madness (0-9)
}

-- Hallucination types
Sanity.HALLUCINATIONS = {
    SHADOW_MOVEMENT = 1, -- Shadows moving in peripheral vision
    FALSE_ENEMY = 2,     -- Enemies that aren't really there
    WALL_SHIFT = 3,      -- Walls appear to move or breathe
    WHISPERS = 4,        -- Auditory hallucinations (messages)
    FALSE_EXIT = 5,      -- Illusory exits
    DOPPELGANGER = 6     -- Player sees themselves or someone familiar
}

-- List of disturbing whispers heard at low sanity
local WHISPERS = {
    "...it watches you...",
    "...turn back while you can...",
    "...you're going the wrong way...",
    "...they're behind you...",
    "...this is all your fault...",
    "...you'll never leave this place...",
    "...the Black Heart beats for you...",
    "...they're all dead because of you...",
    "...your mind is fracturing...",
    "...reality is slipping...",
    "...do you hear that?...",
    "...you've always been here...",
    "...we're waiting for you below...",
    "...the walls are moving...",
    "...the Abyss knows your name..."
}

-- Initialize sanity system
function Sanity.init(maxSanity)
    return {
        current = maxSanity,
        max = maxSanity,
        hallucinations = {},
        lastLossReason = nil,
        insanityWarnings = 0,
        recoveryPoints = 0,
        activeEffects = {}
    }
end

-- Decrease sanity with optional reason
function Sanity.decrease(sanityData, amount, reason)
    if not amount or amount <= 0 then return end
    
    sanityData.current = math.max(0, sanityData.current - amount)
    sanityData.lastLossReason = reason or sanityData.lastLossReason
    
    -- Return the new sanity value and a message if it crosses a threshold
    local message = Sanity.checkThresholdCrossed(sanityData)
    return sanityData.current, message
end

-- Increase sanity with optional source
function Sanity.increase(sanityData, amount, source)
    if not amount or amount <= 0 then return end
    
    local oldValue = sanityData.current
    sanityData.current = math.min(sanityData.max, sanityData.current + amount)
    
    -- Return the amount recovered
    return sanityData.current - oldValue
end

-- Check if sanity has crossed a threshold and return appropriate message
function Sanity.checkThresholdCrossed(sanityData)
    local current = sanityData.current
    
    if current <= Sanity.THRESHOLDS.BROKEN and sanityData.insanityWarnings < 1 then
        sanityData.insanityWarnings = 1
        return "Your mind shatters. The distinction between reality and nightmare has become meaningless."
    elseif current <= Sanity.THRESHOLDS.CRITICAL and sanityData.insanityWarnings < 2 then
        sanityData.insanityWarnings = 2
        return "Your grip on reality weakens severely. The Abyss is inside your thoughts now."
    elseif current <= Sanity.THRESHOLDS.UNSTABLE and sanityData.insanityWarnings < 3 then
        sanityData.insanityWarnings = 3
        return "Your mind begins to fracture. You can no longer trust your own senses."
    elseif current <= Sanity.THRESHOLDS.DISTURBED and sanityData.insanityWarnings < 4 then
        sanityData.insanityWarnings = 4
        return "You feel a creeping unease. The darkness seems to watch you."
    end
    
    return nil
end

-- Get current sanity state description
function Sanity.getStateDescription(sanityData)
    local current = sanityData.current
    
    if current <= Sanity.THRESHOLDS.BROKEN then
        return "Shattered", "Your mind is lost to the Abyss."
    elseif current <= Sanity.THRESHOLDS.CRITICAL then
        return "Critical", "Your grip on reality is severely compromised."
    elseif current <= Sanity.THRESHOLDS.UNSTABLE then
        return "Unstable", "You struggle to distinguish reality from nightmare."
    elseif current <= Sanity.THRESHOLDS.DISTURBED then
        return "Disturbed", "A growing unease clouds your thoughts."
    else
        return "Stable", "Your mind remains clear despite the darkness."
    end
end

-- Generate random hallucination based on sanity level
function Sanity.generateHallucination(sanityData, gameState)
    -- Only generate hallucinations at appropriate sanity levels
    if sanityData.current > Sanity.THRESHOLDS.DISTURBED then
        return nil
    end
    
    -- More hallucinations at lower sanity
    local chance = (Sanity.THRESHOLDS.DISTURBED - sanityData.current) / Sanity.THRESHOLDS.DISTURBED
    if math.random() > chance * 0.5 then
        return nil
    end
    
    -- Select hallucination type based on sanity level
    local types = {}
    
    if sanityData.current <= Sanity.THRESHOLDS.BROKEN then
        -- All types possible at broken level
        types = {1, 2, 3, 4, 5, 6}
    elseif sanityData.current <= Sanity.THRESHOLDS.CRITICAL then
        -- Most types at critical level
        types = {1, 2, 3, 4, 5}
    elseif sanityData.current <= Sanity.THRESHOLDS.UNSTABLE then
        -- Several types at unstable level
        types = {1, 3, 4}
    else
        -- Limited types at disturbed level
        types = {1, 4}
    end
    
    local hallucinationType = types[math.random(#types)]
    
    -- Generate the hallucination
    local hallucination = {
        type = hallucinationType,
        duration = math.random(3, 10), -- Duration in turns
        timeLeft = math.random(3, 10),
        x = nil,
        y = nil,
        message = nil
    }
    
    -- Setup specific hallucination details
    if hallucinationType == Sanity.HALLUCINATIONS.SHADOW_MOVEMENT then
        -- Random shadow movement in peripheral vision
        hallucination.x = gameState.player.x + math.random(-5, 5)
        hallucination.y = gameState.player.y + math.random(-5, 5)
        
    elseif hallucinationType == Sanity.HALLUCINATIONS.FALSE_ENEMY then
        -- Create a false enemy near the player
        local x, y = Sanity.findEmptySpaceNear(gameState, gameState.player.x, gameState.player.y, 3, 7)
        if x and y then
            hallucination.x = x
            hallucination.y = y
            -- Random enemy type from deep in the Abyss
            local enemyTypes = {"Wraith", "Doppelganger", "Shadow Self", "Lost One"}
            hallucination.enemyType = enemyTypes[math.random(#enemyTypes)]
        else
            return nil -- Couldn't place hallucination
        end
        
    elseif hallucinationType == Sanity.HALLUCINATIONS.WALL_SHIFT then
        -- Walls appear to move or shift
        hallucination.intensity = math.random(1, 5) / 10
        
    elseif hallucinationType == Sanity.HALLUCINATIONS.WHISPERS then
        -- Auditory hallucinations
        hallucination.message = WHISPERS[math.random(#WHISPERS)]
        
    elseif hallucinationType == Sanity.HALLUCINATIONS.FALSE_EXIT then
        -- Create a false exit
        local x, y = Sanity.findEmptySpaceNear(gameState, gameState.player.x, gameState.player.y, 5, 12)
        if x and y then
            hallucination.x = x
            hallucination.y = y
        else
            return nil -- Couldn't place hallucination
        end
        
    elseif hallucinationType == Sanity.HALLUCINATIONS.DOPPELGANGER then
        -- Player sees themselves
        local x, y = Sanity.findEmptySpaceNear(gameState, gameState.player.x, gameState.player.y, 4, 8)
        if x and y then
            hallucination.x = x
            hallucination.y = y
        else
            return nil -- Couldn't place hallucination
        end
    end
    
    return hallucination
end

-- Find an empty space near given coordinates
function Sanity.findEmptySpaceNear(gameState, x, y, minDist, maxDist)
    local attempts = 0
    local maxAttempts = 50
    
    while attempts < maxAttempts do
        -- Get random position within range
        local angle = math.random() * math.pi * 2
        local dist = minDist + math.random() * (maxDist - minDist)
        
        local testX = math.floor(x + math.cos(angle) * dist)
        local testY = math.floor(y + math.sin(angle) * dist)
        
        -- Check if position is valid (within map and on floor)
        if testX > 0 and testX <= gameState.map.width and
           testY > 0 and testY <= gameState.map.height and
           gameState.map.tiles[testY][testX] == "." then
            
            -- Check that position is not occupied by entities
            local occupied = false
            
            -- Check for enemies
            for _, enemy in ipairs(gameState.enemies) do
                if enemy.x == testX and enemy.y == testY then
                    occupied = true
                    break
                end
            end
            
            -- Check for items
            if not occupied then
                for _, item in ipairs(gameState.items) do
                    if item.x == testX and item.y == testY then
                        occupied = true
                        break
                    end
                end
            end
            
            if not occupied then
                return testX, testY
            end
        end
        
        attempts = attempts + 1
    end
    
    return nil, nil -- No valid position found
end

-- Update existing hallucinations and potentially create new ones
function Sanity.updateHallucinations(sanityData, gameState, dt, turnCompleted)
    -- Update existing hallucinations
    for i = #sanityData.hallucinations, 1, -1 do
        local hallucination = sanityData.hallucinations[i]
        
        -- Reduce time left
        if turnCompleted then
            hallucination.timeLeft = hallucination.timeLeft - 1
        end
        
        -- Remove expired hallucinations
        if hallucination.timeLeft <= 0 then
            table.remove(sanityData.hallucinations, i)
        end
    end
    
    -- Potentially create new hallucinations when turns are completed
    if turnCompleted and #sanityData.hallucinations < 3 then -- Limit active hallucinations
        local newHallucination = Sanity.generateHallucination(sanityData, gameState)
        if newHallucination then
            table.insert(sanityData.hallucinations, newHallucination)
            
            -- Return message if it's a whisper
            if newHallucination.type == Sanity.HALLUCINATIONS.WHISPERS then
                return newHallucination.message
            end
        end
    end
    
    return nil
end

-- Apply sanity effects to game state
function Sanity.applyEffects(sanityData, gameState)
    -- Clear previous active effects
    sanityData.activeEffects = {}
    
    -- Skip if sanity is in normal range
    if sanityData.current > Sanity.THRESHOLDS.DISTURBED then
        return
    end
    
    local effectChance = (Sanity.THRESHOLDS.DISTURBED - sanityData.current) / 100
    
    -- Reduced visibility at low sanity
    if sanityData.current <= Sanity.THRESHOLDS.UNSTABLE then
        local visReduction = math.floor((Sanity.THRESHOLDS.UNSTABLE - sanityData.current) / 10)
        if visReduction > 0 then
            gameState.player.visibilityReduction = visReduction
            table.insert(sanityData.activeEffects, { type = "visibility", value = -visReduction })
        end
    end
    
    -- Random attack behavior at critical sanity
    if sanityData.current <= Sanity.THRESHOLDS.CRITICAL and math.random() < effectChance * 2 then
        gameState.player.attackRandomly = true
        table.insert(sanityData.activeEffects, { type = "behavior", value = "unpredictable" })
    else
        gameState.player.attackRandomly = false
    end
    
    -- Return the list of active effects
    return sanityData.activeEffects
end

-- Check if player should attack randomly due to insanity
function Sanity.shouldAttackRandomly(sanityData, target)
    -- Only trigger on critical or lower sanity
    if sanityData.current > Sanity.THRESHOLDS.CRITICAL then
        return false
    end
    
    -- Chance increases as sanity decreases
    local chance = (Sanity.THRESHOLDS.CRITICAL - sanityData.current) / Sanity.THRESHOLDS.CRITICAL * 0.5
    return math.random() < chance
end

-- Get a meditation outcome based on current sanity
function Sanity.getMeditationOutcome(sanityData, gamePhase)
    local outcomes = {
        {
            message = "Your meditation brings clarity. The whispers recede momentarily.",
            sanityGain = 10 + math.random(5),
            healthEffect = 0
        },
        {
            message = "As you meditate, memories of the surface world strengthen your resolve.",
            sanityGain = 15 + math.random(10),
            healthEffect = 1
        },
        {
            message = "The meditation turns dark. Horrific visions assault your mind.",
            sanityGain = -5 - math.random(10),
            healthEffect = -2
        },
        {
            message = "Something speaks to you through the meditation. It knows your name.",
            sanityGain = 5 + math.random(15),
            healthEffect = -1
        },
        {
            message = "The altar resonates with your presence. You feel connected to the Abyss.",
            sanityGain = -10 + gamePhase*3,  -- Worse in deeper levels, could become positive
            healthEffect = gamePhase         -- Damage in earlier levels, healing in deeper ones
        }
    }
    
    local outcome = outcomes[math.random(#outcomes)]
    
    -- Deeper in the Abyss, meditation is riskier but potentially more powerful
    if gamePhase >= 3 then
        outcome.sanityGain = outcome.sanityGain * 1.5
        outcome.healthEffect = outcome.healthEffect * 1.2
    end
    
    return outcome
end

return Sanity
