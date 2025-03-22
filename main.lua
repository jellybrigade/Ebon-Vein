-- Ebon Vein - A roguelike game
-- The world is dying. The sun has dimmed, the air is cold, and the lands are ruled by chaos.
-- You descend into the Abyss seeking the Black Heart artifact.

-- Load required modules
local Map = require("map")
local Renderer = require("renderer")
local Enemy = require("enemy")
local Combat = require("combat")
local Item = require("item")
local Visibility = require("visibility")  -- Add visibility module
local UI = require("ui")  -- Add UI module
local Story = require("story") -- Add story module
local Sanity = require("sanity") -- Add sanity module

-- Game state
local gameState = {
    running = true,
    gameOver = false,
    victory = false,
    gameOverMessage = "",
    map = nil,
    player = {
        x = 5,
        y = 5,
        symbol = "@",
        health = 10,
        maxHealth = 10,
        damage = 2,
        defense = 0,
        name = "Player",
        inventory = {},
        visibilityRange = 8, -- Field of vision radius
        statusEffects = {},   -- For tracking buffs/debuffs
        sanity = nil, -- Will be initialized later
        visibilityReduction = 0, -- Reduction due to insanity
        attackRandomly = false -- Random attack behavior due to insanity
    },
    enemies = {},
    items = {},
    messages = {},
    showInventory = false,
    selectedItem = 1,
    rangedAttacks = {},
    visibilityMap = nil,  -- Add visibility map
    ui = nil,            -- UI state
    currentLevel = 0,    -- Start at prologue (level 0)
    artifactPieces = 0,  -- Track collected artifact pieces
    mouseX = 0,          -- Track mouse position for tooltips
    mouseY = 0,
    hoveredEntity = nil,  -- Entity under the mouse cursor
    storyScreen = nil,    -- Current story screen if active
    gamePhase = Story.PHASE.PROLOGUE,  -- Current story phase
    levelEffects = {},     -- Level-specific visual effects
    hallucinations = {}, -- Store visual hallucinations
    lastTurnCompleted = false -- Track when a turn is completed
}

-- Initialize the game
function love.load()
    -- Set up the font (using a monospaced font is important for ASCII display)
    local font = love.graphics.newFont("fonts/DejaVuSansMono.ttf", 16)
    love.graphics.setFont(font)
    
    -- Initialize UI
    gameState.ui = UI.init(love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Set window title
    love.window.setTitle("Ebon Vein - Descent to Darkness")
    
    -- Enable mouse
    love.mouse.setVisible(true)
    
    -- Initialize sanity system
    gameState.player.sanity = Sanity.init(100)
    
    -- Start with the prologue
    showPrologue()
end

-- Show the prologue narrative
function showPrologue()
    gameState.storyScreen = Story.showNarrativeScreen(Story.PHASE.PROLOGUE, function()
        -- After prologue, initialize the first level
        gameState.gamePhase = Story.PHASE.LEVEL_1
        initializeGame()
    end)
end

-- Initialize/reset the game
function initializeGame()
    -- Reset game state
    gameState.gameOver = false
    gameState.victory = false
    gameState.gameOverMessage = ""
    
    -- Reset hallucinations
    gameState.hallucinations = {}
    gameState.lastTurnCompleted = false

    -- Initialize the map with level-appropriate size and features
    local mapSize = 40 + (gameState.gamePhase * 5) -- Maps get larger with depth
    gameState.map = Map.create(mapSize, 25, gameState.gamePhase)
    
    -- Create visibility map
    gameState.visibilityMap = Visibility.createMap(gameState.map.width, gameState.map.height)
    
    -- Reset player stats with some progression
    if gameState.gamePhase == Story.PHASE.LEVEL_1 then
        -- Starting stats for level 1
        gameState.player.health = gameState.player.maxHealth
        gameState.player.damage = 2
        gameState.player.defense = 0
        
        -- Reset sanity for new game
        gameState.player.sanity = Sanity.init(100)
    else
        -- Increase stats for each level
        gameState.player.maxHealth = 10 + (gameState.gamePhase * 2)
        gameState.player.health = gameState.player.maxHealth
        gameState.player.damage = 2 + math.floor(gameState.gamePhase * 0.5)
        gameState.player.defense = math.floor((gameState.gamePhase - 1) * 0.5)
        
        -- Sanity decreases with each level (harder to maintain in deeper levels)
        if gameState.player.sanity then
            local levelSanityLoss = 10 + (gameState.gamePhase * 5)
            local _, message = Sanity.decrease(
                gameState.player.sanity, 
                levelSanityLoss, 
                "Descending deeper into the Abyss"
            )
            
            if message then
                addMessage(message)
            end
        end
    end
    
    gameState.player.statusEffects = {}
    gameState.player.visibilityReduction = 0
    gameState.player.attackRandomly = false
    
    -- Place player in the center of the first room
    gameState.player.x, gameState.player.y = Map.getFirstRoomCenter(gameState.map)
    
    -- Update initial visibility
    updateVisibility()
    
    -- Spawn enemies - more and stronger with each level
    gameState.enemies = Enemy.spawnEnemies(gameState.map, 10 + (gameState.gamePhase * 3), gameState.gamePhase)
    
    -- Spawn items - different distribution based on level
    gameState.items = Item.spawnItems(gameState.map, 5 + gameState.gamePhase, gameState.gamePhase)
    
    -- Reset inventory between games, but not between levels
    if gameState.gamePhase == Story.PHASE.LEVEL_1 then
        gameState.player.inventory = {}
        
        -- Show legend and controls tip for new games
        if gameState.ui then
            addMessage("Press 'H' for help and 'L' for legend.")
            UI.addNotification(gameState.ui, "Press L to view legend", "info")
        end
    end
    
    -- Reset ranged attack animations
    gameState.rangedAttacks = {}
    
    -- Add initial message based on current level
    gameState.messages = {}
    addMessage(Story.getLevelDescription(gameState.gamePhase))
    
    -- Apply visual theme for the current level
    Story.applyVisualTheme(gameState.gamePhase, Renderer, Map)
    
    -- Get level-specific effects
    gameState.levelEffects = Story.getLevelEffects(gameState.gamePhase)
    
    -- Show UI notification
    if gameState.ui then
        UI.addNotification(gameState.ui, Story.getLevelName(gameState.gamePhase), "info")
    end
    
    -- Add sanity-related level effects
    initializeSanityEffects()
end

-- Initialize sanity effects for the current level
function initializeSanityEffects()
    -- Place meditation altars in the map
    local altarCount = 1 + math.floor(gameState.gamePhase / 2)
    
    -- Place the altars in random rooms (not the first room)
    local altarsPlaced = 0
    if #gameState.map.rooms > 1 then  -- Make sure there's more than one room
        for i = 2, #gameState.map.rooms do  -- Start from the second room
            if altarsPlaced >= altarCount then
                break
            end
            
            local room = gameState.map.rooms[i]
            -- Place altar in middle of room
            local altarX = room.center.x
            local altarY = room.center.y
            
            -- Create meditation altar item
            local altar = Item.createMeditationAltar(altarX, altarY)
            table.insert(gameState.items, altar)
            
            altarsPlaced = altarsPlaced + 1
        end
    end
    
    -- Apply sanity effects to player
    Sanity.applyEffects(gameState.player.sanity, gameState)
    
    -- For deeper levels, start with some hallucinations
    if gameState.gamePhase >= 3 then
        local chance = gameState.gamePhase * 0.15
        if math.random() < chance then
            local hallucination = Sanity.generateHallucination(gameState.player.sanity, gameState)
            if hallucination then
                table.insert(gameState.player.sanity.hallucinations, hallucination)
                
                if hallucination.type == Sanity.HALLUCINATIONS.WHISPERS then
                    addMessage(hallucination.message)
                end
            end
        end
    end
end

-- Update the visibility map based on player position
function updateVisibility()
    -- Reduced visibility in deeper levels
    local visRange = gameState.player.visibilityRange - math.floor(gameState.gamePhase * 0.5)
    
    -- Apply sanity-induced visibility reduction
    visRange = visRange - gameState.player.visibilityReduction
    
    -- Ensure minimum visibility
    visRange = math.max(3, visRange)
    
    Visibility.updateFOV(
        gameState.map, 
        gameState.visibilityMap, 
        gameState.player.x, 
        gameState.player.y,
        visRange
    )
end

-- Add a message to the game log
function addMessage(text)
    table.insert(gameState.messages, text)
    -- Keep only the most recent messages (increased from 5 to 6)
    if #gameState.messages > 6 then
        table.remove(gameState.messages, 1)
    end
end

-- Make the addMessage function available to other modules
gameState.addMessage = addMessage

-- Check for victory/level transition conditions
function checkVictory()
    -- Check if player is on the exit tile
    if gameState.map.exitX == gameState.player.x and gameState.map.exitY == gameState.player.y then
        -- Progress to the next level
        if gameState.gamePhase < Story.PHASE.FINALE then
            -- Found an artifact piece, show level transition
            gameState.artifactPieces = gameState.artifactPieces + 1
            
            -- Display level transition narrative
            local nextPhase = gameState.gamePhase + 1
            gameState.storyScreen = Story.showNarrativeScreen(nextPhase, function()
                -- After narrative, initialize the next level
                gameState.gamePhase = nextPhase
                initializeGame()
            end)
            
            addMessage("You found a shard of the Black Heart!")
            if gameState.ui then
                UI.addNotification(gameState.ui, "Artifact Shard Recovered", "info")
            end
            
            return true
        else
            -- Final victory - show epilogue
            gameState.storyScreen = Story.showNarrativeScreen(Story.PHASE.EPILOGUE, function()
                -- After epilogue, set game over state
                gameState.victory = true
                gameState.gameOver = true
                gameState.gameOverMessage = "You have become one with the Abyss."
            end)
            
            return true
        end
    end
    return false
end

-- Check for defeat conditions
function checkDefeat()
    if gameState.player.health <= 0 then
        gameState.victory = false
        gameState.gameOver = true
        
        -- Choose game over message based on current level
        local messages = {
            "Your journey ends here, consumed by the darkness of the Abyss...",
            "The echoes of humanity fade as your life ebbs away...",
            "The shifting labyrinth claims another victim...",
            "Madness consumes you as your light fades...",
            "At the breaking point, you shatter completely...",
            "The Black Heart rejects you, and the Abyss devours your remains..."
        }
        gameState.gameOverMessage = messages[math.min(gameState.gamePhase, #messages)]
        
        addMessage("You have been defeated!")
        if gameState.ui then
            UI.addNotification(gameState.ui, "Darkness consumes you...", "danger")
        end
        return true
    end
    return false
end

-- Attempt to move the player
function movePlayer(dx, dy)
    local newX = gameState.player.x + dx
    local newY = gameState.player.y + dy
    
    -- Check for sanity effects on flesh tiles
    local tile = Map.getTile(gameState.map, newX, newY)
    if tile == Map.FLESH then
        local sanityLoss = math.random(3, 7)
        local _, message = Sanity.decrease(gameState.player.sanity, sanityLoss, "Walking on living flesh")
        if message then
            addMessage(message)
        end
    end
    
    -- Check if the new position is valid
    if tile == Map.FLOOR or tile == Map.EXIT or tile == Map.FLESH or tile == Map.BLOOD then
        -- Check for enemies at the destination
        local enemyIndex = findEnemyAt(newX, newY)
        if enemyIndex then
            -- Attack enemy instead of moving
            local enemy = gameState.enemies[enemyIndex]
            
            -- Check if player attacks randomly due to insanity
            if gameState.player.attackRandomly and Sanity.shouldAttackRandomly(gameState.player.sanity, enemy) then
                -- Miss the target and attack in random direction
                addMessage("Your mind fractures! You swing wildly in confusion!")
                
                -- Pick a random adjacent position
                local directions = {
                    {-1, -1}, {0, -1}, {1, -1},
                    {-1, 0}, {1, 0},
                    {-1, 1}, {0, 1}, {1, 1}
                }
                
                local dir = directions[math.random(#directions)]
                local randomX = gameState.player.x + dir[1]
                local randomY = gameState.player.y + dir[2]
                
                -- Check if there's another enemy at this position
                local randomEnemyIndex = findEnemyAt(randomX, randomY)
                if randomEnemyIndex then
                    local randomEnemy = gameState.enemies[randomEnemyIndex]
                    local damageDealt, killed = Combat.attack(gameState.player, randomEnemy)
                    
                    addMessage("You hit a " .. randomEnemy.name .. " for " .. damageDealt .. " damage!")
                    
                    if killed then
                        addMessage("You defeated the " .. randomEnemy.name .. "!")
                        table.remove(gameState.enemies, randomEnemyIndex)
                    end
                else
                    addMessage("You attack nothing but air!")
                end
            else
                -- Normal attack
                local damageDealt, killed = Combat.attack(gameState.player, enemy)
                
                addMessage("You attack the " .. enemy.name .. " for " .. damageDealt .. " damage!")
                
                -- Lose sanity when attacking humanoid enemies
                if enemy.isHumanoid then
                    local sanityLoss = math.random(1, 3)
                    local _, message = Sanity.decrease(
                        gameState.player.sanity, 
                        sanityLoss, 
                        "Fighting a human-like creature"
                    )
                    if message then
                        addMessage(message)
                    end
                end
                
                if killed then
                    addMessage("You defeated the " .. enemy.name .. "!")
                    
                    -- Extra sanity loss when killing humanoid enemies
                    if enemy.isHumanoid then
                        local sanityLoss = math.random(2, 5)
                        local _, message = Sanity.decrease(
                            gameState.player.sanity, 
                            sanityLoss, 
                            "Killing a human-like creature"
                        )
                        if message then
                            addMessage(message)
                        end
                    end
                    
                    table.remove(gameState.enemies, enemyIndex)
                end
            end
            
            gameState.lastTurnCompleted = true
            return true -- Turn was used for combat
        end
        
        -- Check for items at the destination
        local itemIndex = Item.findItemAt(gameState.items, newX, newY)
        if itemIndex then
            -- Pick up item
            local item = gameState.items[itemIndex]
            pickUpItem(itemIndex)
        end
        
        -- No collision, move the player
        gameState.player.x = newX
        gameState.player.y = newY
        
        -- Update visibility after moving
        updateVisibility()
        
        -- Check for victory if player moved to the exit
        if tile == Map.EXIT then
            checkVictory()
        end
        
        gameState.lastTurnCompleted = true
        return true
    end
    
    return false
end

-- Pick up an item and add to inventory
function pickUpItem(itemIndex)
    local item = gameState.items[itemIndex]
    addMessage("You found a " .. item.name .. "!")
    
    -- Show notification
    if gameState.ui then
        UI.addNotification(gameState.ui, "Found: " .. item.name, "info")
    end
    
    -- Add to inventory
    table.insert(gameState.player.inventory, item)
    
    -- Remove from map
    table.remove(gameState.items, itemIndex)
end

-- Use an item from inventory
function useItem(itemIndex)
    local item = gameState.player.inventory[itemIndex]
    if item then
        -- Execute the item's use effect, passing sanity for sanity-affecting items
        local result, sanityEffect, healthEffect = item.use(gameState.player)
        addMessage(result)
        
        -- Apply sanity effect if any
        if sanityEffect and sanityEffect ~= 0 then
            local gained = Sanity.increase(gameState.player.sanity, sanityEffect)
            if gained > 0 then
                addMessage("You feel your mind clearing. (+" .. gained .. " Sanity)")
            end
        end
        
        -- Apply health effect if any
        if healthEffect and healthEffect ~= 0 then
            gameState.player.health = math.min(
                gameState.player.maxHealth, 
                gameState.player.health + healthEffect
            )
            if healthEffect > 0 then
                addMessage("Your wounds begin to heal. (+" .. healthEffect .. " Health)")
            else
                addMessage("You feel pain throughout your body. (" .. healthEffect .. " Health)")
            end
        end
        
        -- Show notification
        if gameState.ui then
            UI.addNotification(gameState.ui, "Used: " .. item.name, "info")
        end
        
        -- Remove from inventory after use
        table.remove(gameState.player.inventory, itemIndex)
        
        -- Reset selection if item was last in inventory
        if gameState.selectedItem > #gameState.player.inventory then
            gameState.selectedItem = math.max(1, #gameState.player.inventory)
        end
        
        -- Using items ends the turn
        gameState.lastTurnCompleted = true
        
        return true
    end
    return false
end

-- Meditate at an altar
function meditateAtAltar(altarIndex)
    local altar = gameState.items[altarIndex]
    if altar and altar.isMeditationAltar then
        -- Get meditation outcome based on current sanity
        local outcome = Sanity.getMeditationOutcome(gameState.player.sanity, gameState.gamePhase)
        
        -- Apply sanity effect
        if outcome.sanityGain ~= 0 then
            if outcome.sanityGain > 0 then
                local recovered = Sanity.increase(gameState.player.sanity, outcome.sanityGain)
                if recovered > 0 then
                    addMessage("Your meditation restores clarity. (+" .. recovered .. " Sanity)")
                end
            else
                local _, message = Sanity.decrease(
                    gameState.player.sanity, 
                    -outcome.sanityGain, 
                    "Disturbing meditation visions"
                )
                if message then
                    addMessage(message)
                end
            end
        end
        
        -- Apply health effect
        if outcome.healthEffect ~= 0 then
            gameState.player.health = math.min(
                gameState.player.maxHealth,
                gameState.player.health + outcome.healthEffect
            )
            
            if outcome.healthEffect > 0 then
                addMessage("The altar emits a healing energy. (+" .. outcome.healthEffect .. " Health)")
            else
                addMessage("Pain shoots through your body. (" .. outcome.healthEffect .. " Health)")
                
                -- Check for death from meditation
                checkDefeat()
            end
        end
        
        -- Display the outcome message
        addMessage(outcome.message)
        
        -- Show notification
        if gameState.ui then
            UI.addNotification(gameState.ui, "Meditation completed", "info")
        end
        
        -- Meditation consumes the altar (one-time use)
        table.remove(gameState.items, altarIndex)
        
        -- Meditation ends the turn
        gameState.lastTurnCompleted = true
        
        return true
    end
    return false
end

-- Toggle inventory display
function toggleInventory()
    gameState.showInventory = not gameState.showInventory
    -- Reset selection when opening inventory
    if gameState.showInventory then
        gameState.selectedItem = math.min(1, #gameState.player.inventory)
    end
end

-- Find enemy at specific coordinates
function findEnemyAt(x, y)
    for i, enemy in ipairs(gameState.enemies) do
        if enemy.x == x and enemy.y == y then
            return i -- Return the index of the enemy
        end
    end
    return nil
end

-- Find entity at specific coordinates (for tooltips)
function findEntityAt(x, y)
    -- Check for enemies
    for _, enemy in ipairs(gameState.enemies) do
        if enemy.x == x and enemy.y == y then
            return enemy
        end
    end
    
    -- Check for items
    for _, item in ipairs(gameState.items) do
        if item.x == x and item.y == y then
            return item
        end
    end
    
    -- Check for player
    if gameState.player.x == x and gameState.player.y == y then
        return gameState.player
    end
    
    return nil
end

-- Check if enemy is a hallucination
function isHallucination(x, y)
    if not gameState.player.sanity or not gameState.player.sanity.hallucinations then
        return false
    end
    
    for _, hallucination in ipairs(gameState.player.sanity.hallucinations) do
        if hallucination.x == x and hallucination.y == y and 
           (hallucination.type == Sanity.HALLUCINATIONS.FALSE_ENEMY or
            hallucination.type == Sanity.HALLUCINATIONS.FALSE_EXIT or
            hallucination.type == Sanity.HALLUCINATIONS.DOPPELGANGER) then
            return true, hallucination
        end
    end
    
    return false
end

-- Update enemies (process their turns)
function updateEnemies()
    for i = #gameState.enemies, 1, -1 do
        local enemy = gameState.enemies[i]
        Enemy.update(enemy, gameState)
        
        -- Check if enemy is adjacent to player to attack
        if Combat.isAdjacent(enemy, gameState.player) then
            local damageDealt = Combat.attack(enemy, gameState.player)
            addMessage("The " .. enemy.name .. " attacks you for " .. damageDealt .. " damage!")
            
            -- Check if player is defeated
            checkDefeat()
        end
    end
    
    -- Clean up expired ranged attacks
    gameState.rangedAttacks = {}
end

-- Update game logic (turn-based)
function love.update(dt)
    -- If story screen is active, update it
    if gameState.storyScreen and gameState.storyScreen.active then
        gameState.storyScreen.update(dt)
        return
    end
    
    -- Update the UI system
    if gameState.ui then
        UI.update(gameState.ui, gameState, dt)
    end
    
    -- Update mouse position
    gameState.mouseX = love.mouse.getX()
    gameState.mouseY = love.mouse.getY()
    
    -- Check for entities under cursor for tooltips
    if not gameState.gameOver and not gameState.showInventory then
        -- Convert mouse screen position to grid coordinates
        local gridX = math.floor((gameState.mouseX - 50) / 16) + 1
        local gridY = math.floor((gameState.mouseY - 50) / 16) + 1
        
        -- Check if these coordinates are valid and visible
        if Visibility.isVisible(gameState.visibilityMap, gridX, gridY) then
            -- Find entity at this position
            gameState.hoveredEntity = findEntityAt(gridX, gridY)
            
            -- Show tooltip for entity
            if gameState.hoveredEntity and gameState.ui then
                UI.showEntityTooltip(gameState.ui, gameState.hoveredEntity, 
                    gameState.mouseX + 10, gameState.mouseY + 10)
            end
        else
            gameState.hoveredEntity = nil
        end
    end
    
    -- Apply level-specific ambient effects
    if gameState.levelEffects.whispers and math.random() < 0.002 then
        -- Random whispers in deeper levels
        local whispers = {
            "...come closer...",
            "...you belong here...",
            "...no escape...",
            "...join us...",
            "...the heart beats for you..."
        }
        addMessage(whispers[math.random(#whispers)])
    end
    
    if gameState.levelEffects.heartbeat and math.random() < 0.005 then
        -- Heartbeat effect in final levels
        -- This could be expanded with sound effects
        if gameState.ui then
            UI.addNotification(gameState.ui, "*thump* The Black Heart pulses...", "warning")
        end
    end
    
    -- Update sanity hallucinations
    if gameState.player.sanity then
        local whisperMessage = Sanity.updateHallucinations(
            gameState.player.sanity, 
            gameState, 
            dt, 
            gameState.lastTurnCompleted
        )
        
        if whisperMessage then
            addMessage(whisperMessage)
        end
        
        -- Apply sanity effects
        Sanity.applyEffects(gameState.player.sanity, gameState)
    end
    
    -- Reset turn completion flag after processing
    gameState.lastTurnCompleted = false
end

-- Process player input
function love.keypressed(key)
    -- If story screen is active, let it handle the input
    if gameState.storyScreen and gameState.storyScreen.active then
        gameState.storyScreen.keypressed(key)
        return
    end

    -- Check if UI wants to handle this input first
    if gameState.ui and UI.handleInput(gameState.ui, key) then
        return -- UI handled the input
    end
    
    -- If game is over, only respond to restart key
    if gameState.gameOver then
        if key == "space" then
            initializeGame()
        end
        return
    end
    
    -- Handle inventory toggling
    if key == "i" then
        toggleInventory()
        return
    end
    
    -- Handle inventory navigation and item usage
    if gameState.showInventory then
        if key == "escape" then
            gameState.showInventory = false
        elseif key == "up" then
            gameState.selectedItem = math.max(1, gameState.selectedItem - 1)
        elseif key == "down" then
            gameState.selectedItem = math.min(#gameState.player.inventory, gameState.selectedItem + 1)
        elseif key == "return" or key == "e" then
            if #gameState.player.inventory > 0 then
                useItem(gameState.selectedItem)
            end
        end
        return
    end
    
    if key == "escape" then
        -- Show help instead of quitting directly
        if gameState.ui then
            gameState.ui.showHelp = true
            gameState.ui.helpDelay = 0 -- Don't auto-hide
        end
        return
    elseif key == "q" then
        love.event.quit()
        return
    end
    
    -- Movement controls - classic roguelike uses arrow keys
    local moved = false
    
    -- Arrow keys
    if key == "up" then
        moved = movePlayer(0, -1)
    elseif key == "down" then
        moved = movePlayer(0, 1)
    elseif key == "left" then
        moved = movePlayer(-1, 0)
    elseif key == "right" then
        moved = movePlayer(1, 0)
    end
    
    -- For testing: regenerate the map with 'r'
    if key == "r" then
        initializeGame()
        addMessage("A new area of the Abyss forms around you...")
    end
    
    -- If the player moved, update enemies (their turn)
    if moved and not gameState.gameOver then
        updateEnemies()
    end
end

-- Draw the game
function love.draw()
    -- If a story screen is active, draw only that
    if gameState.storyScreen and gameState.storyScreen.active then
        gameState.storyScreen.draw()
        return
    end
    
    -- Clear the screen
    love.graphics.clear(0, 0, 0)
    
    -- Apply level-specific visual effects
    if gameState.levelEffects.pulsingWalls then
        -- Make walls pulse in the final level
        local pulseFactor = 0.1 + math.sin(love.timer.getTime() * 2) * 0.05
        Renderer.setPulseEffect(pulseFactor)
    end
    
    if gameState.levelEffects.visualFilter == "distortion" then
        -- Apply visual distortion in level 4
        Renderer.setDistortionEffect(love.timer.getTime())
    end
    
    -- Apply sanity visual effects if in unstable state
    if gameState.player.sanity and gameState.player.sanity.current <= Sanity.THRESHOLDS.UNSTABLE then
        -- Add visual distortion based on sanity level
        local distortionAmount = (Sanity.THRESHOLDS.UNSTABLE - gameState.player.sanity.current) / 100
        Renderer.setSanityEffect(distortionAmount, gameState.player.sanity.hallucinations)
    end
    
    -- Render the map and entities with visibility
    Renderer.drawMap(gameState.map, gameState.visibilityMap, gameState.gamePhase)
    
    -- Draw items (only if visible)
    for _, item in ipairs(gameState.items) do
        if Visibility.isVisible(gameState.visibilityMap, item.x, item.y) then
            Renderer.drawEntity(item)
        end
    end
    
    -- Draw enemies (only if visible)
    for _, enemy in ipairs(gameState.enemies) do
        if Visibility.isVisible(gameState.visibilityMap, enemy.x, enemy.y) then
            Renderer.drawEntity(enemy)
        end
    end
    
    -- Always draw the player
    Renderer.drawEntity(gameState.player)
    
    -- Draw ranged attack animations
    for _, attack in ipairs(gameState.rangedAttacks) do
        Renderer.drawRangedAttack(attack.from, attack.to)
    end
    
    -- Draw hallucinations (only visible ones)
    if gameState.player.sanity then
        for _, hallucination in ipairs(gameState.player.sanity.hallucinations) do
            if hallucination.x and hallucination.y and
               Visibility.isVisible(gameState.visibilityMap, hallucination.x, hallucination.y) then
                
                if hallucination.type == Sanity.HALLUCINATIONS.FALSE_ENEMY then
                    -- Draw a false enemy
                    Renderer.drawHallucination(hallucination, "enemy")
                elseif hallucination.type == Sanity.HALLUCINATIONS.FALSE_EXIT then
                    -- Draw a false exit
                    Renderer.drawHallucination(hallucination, "exit")
                elseif hallucination.type == Sanity.HALLUCINATIONS.DOPPELGANGER then
                    -- Draw the doppelganger
                    Renderer.drawHallucination(hallucination, "doppelganger")
                elseif hallucination.type == Sanity.HALLUCINATIONS.SHADOW_MOVEMENT then
                    -- Draw shadow movement
                    Renderer.drawHallucination(hallucination, "shadow")
                end
            end
        end
    end
    
    -- Draw the UI frame if available
    if gameState.ui then
        UI.drawFrame(gameState.ui, gameState)
    else
        -- Legacy UI elements if UI module not available
        love.graphics.setColor(0.7, 0.2, 0.2)
        love.graphics.print("EBON VEIN", 10, 10)
        love.graphics.setColor(1, 1, 1)
        
        -- Draw messages log with wrapping
        love.graphics.setColor(0.8, 0.8, 0.6)
        local msgY = 550
        local msgWidth = love.graphics.getWidth() - 220
        for i, msg in ipairs(gameState.messages) do
            love.graphics.printf(msg, 10, msgY - ((#gameState.messages - i) * 30), 
                                msgWidth, "left")
        end
        love.graphics.setColor(1, 1, 1)
        
        -- Draw legacy UI elements
        Renderer.drawUI(gameState)
    end
    
    -- Draw inventory if open
    if gameState.showInventory then
        Renderer.drawInventory(gameState.player.inventory, gameState.selectedItem)
    end
    
    -- Draw game over/victory screen if applicable
    if gameState.gameOver then
        Renderer.drawGameOver(gameState.gameOverMessage, gameState.victory)
    end
end

-- Track mouse movement for tooltips
function love.mousemoved(x, y)
    gameState.mouseX = x
    gameState.mouseY = y
end
