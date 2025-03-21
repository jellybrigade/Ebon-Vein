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
        visibilityRange = 8 -- Field of vision radius
    },
    enemies = {},
    items = {},
    messages = {},
    showInventory = false,
    selectedItem = 1,
    rangedAttacks = {},
    visibilityMap = nil  -- Add visibility map
}

-- Initialize the game
function love.load()
    -- Set up the font (using a monospaced font is important for ASCII display)
    local font = love.graphics.newFont("fonts/DejaVuSansMono.ttf", 16)
    love.graphics.setFont(font)
    
    initializeGame()
end

-- Initialize/reset the game
function initializeGame()
    -- Reset game state
    gameState.gameOver = false
    gameState.victory = false
    gameState.gameOverMessage = ""

    -- Initialize the map
    gameState.map = Map.create(40, 25)
    
    -- Create visibility map
    gameState.visibilityMap = Visibility.createMap(gameState.map.width, gameState.map.height)
    
    -- Reset player stats
    gameState.player.health = gameState.player.maxHealth
    gameState.player.damage = 2
    gameState.player.defense = 0
    
    -- Place player in the center of the first room
    gameState.player.x, gameState.player.y = Map.getFirstRoomCenter(gameState.map)
    
    -- Update initial visibility
    updateVisibility()
    
    -- Spawn enemies
    gameState.enemies = Enemy.spawnEnemies(gameState.map, 12)
    
    -- Spawn items
    gameState.items = Item.spawnItems(gameState.map, 6)
    
    -- Reset inventory on new game
    gameState.player.inventory = {}
    
    -- Reset ranged attack animations
    gameState.rangedAttacks = {}
    
    -- Add initial message
    gameState.messages = {}
    addMessage("You enter the Abyss, seeking the Black Heart...")
    addMessage("Beware the shadows that lurk within...")
    addMessage("Find the golden exit (X) to escape with the artifact!")
end

-- Update the visibility map based on player position
function updateVisibility()
    Visibility.updateFOV(
        gameState.map, 
        gameState.visibilityMap, 
        gameState.player.x, 
        gameState.player.y,
        gameState.player.visibilityRange
    )
end

-- Add a message to the game log
function addMessage(text)
    table.insert(gameState.messages, text)
    -- Keep only the most recent messages
    if #gameState.messages > 5 then
        table.remove(gameState.messages, 1)
    end
end

-- Make the addMessage function available to other modules
gameState.addMessage = addMessage

-- Check for victory conditions
function checkVictory()
    -- Check if player is on the exit tile
    if gameState.map.exitX == gameState.player.x and gameState.map.exitY == gameState.player.y then
        gameState.victory = true
        gameState.gameOver = true
        gameState.gameOverMessage = "You found the Black Heart artifact and escaped the Abyss!"
        addMessage("Victory! You found the Black Heart artifact!")
        return true
    end
    return false
end

-- Check for defeat conditions
function checkDefeat()
    if gameState.player.health <= 0 then
        gameState.victory = false
        gameState.gameOver = true
        gameState.gameOverMessage = "Your journey ends here, consumed by the darkness of the Abyss..."
        addMessage("You have been defeated!")
        return true
    end
    return false
end

-- Attempt to move the player
function movePlayer(dx, dy)
    local newX = gameState.player.x + dx
    local newY = gameState.player.y + dy
    
    -- Check if the new position is valid
    local tile = Map.getTile(gameState.map, newX, newY)
    if tile == Map.FLOOR or tile == Map.EXIT then -- Floor or exit tile
        -- Check for enemies at the destination
        local enemyIndex = findEnemyAt(newX, newY)
        if enemyIndex then
            -- Attack enemy instead of moving
            local enemy = gameState.enemies[enemyIndex]
            local damageDealt, killed = Combat.attack(gameState.player, enemy)
            
            addMessage("You attack the " .. enemy.name .. " for " .. damageDealt .. " damage!")
            
            if killed then
                addMessage("You defeated the " .. enemy.name .. "!")
                table.remove(gameState.enemies, enemyIndex)
            end
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
        
        return true
    end
    
    return false
end

-- Pick up an item and add to inventory
function pickUpItem(itemIndex)
    local item = gameState.items[itemIndex]
    addMessage("You found a " .. item.name .. "!")
    
    -- Add to inventory
    table.insert(gameState.player.inventory, item)
    
    -- Remove from map
    table.remove(gameState.items, itemIndex)
end

-- Use an item from inventory
function useItem(itemIndex)
    local item = gameState.player.inventory[itemIndex]
    if item then
        local result = item.use(gameState.player)
        addMessage(result)
        
        -- Remove from inventory after use
        table.remove(gameState.player.inventory, itemIndex)
        
        -- Reset selection if item was last in inventory
        if gameState.selectedItem > #gameState.player.inventory then
            gameState.selectedItem = math.max(1, #gameState.player.inventory)
        end
        
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
    -- Turn-based games typically don't need continuous updates
    -- Logic will be handled in keypressed events
end

-- Process player input
function love.keypressed(key)
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
        elseif key == "return" then
            if #gameState.player.inventory > 0 then
                useItem(gameState.selectedItem)
            end
        end
        return
    end
    
    if key == "escape" or key == "q" then
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
    -- Clear the screen
    love.graphics.clear(0, 0, 0)
    
    -- Render the map and entities with visibility
    Renderer.drawMap(gameState.map, gameState.visibilityMap)
    
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
    
    -- Display game title
    love.graphics.setColor(0.7, 0.2, 0.2)
    love.graphics.print("EBON VEIN", 10, 10)
    love.graphics.setColor(1, 1, 1)
    
    -- Draw messages log
    Renderer.drawMessages(gameState.messages, 10, 550)
    
    -- Draw UI elements
    Renderer.drawUI(gameState)
    
    -- Draw inventory if open
    if gameState.showInventory then
        Renderer.drawInventory(gameState.player.inventory, gameState.selectedItem)
    end
    
    -- Draw game over/victory screen if applicable
    if gameState.gameOver then
        Renderer.drawGameOver(gameState.gameOverMessage, gameState.victory)
    end
end
