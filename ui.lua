-- UI module for handling interface elements

local UI = {}

-- Import required modules
local Visibility = require("visibility")
local Sanity = require("sanity")  -- Add sanity module
local Renderer = require("renderer") -- Import renderer for scaling factors

-- Colors for UI elements (dark, muted palette to match the game's tone)
local COLORS = {
    panel = {0.1, 0.1, 0.15, 0.9},          -- Dark background with slight transparency
    text = {0.7, 0.7, 0.8},                 -- Muted bluish text
    health = {0.6, 0.2, 0.2},               -- Dark red for health
    health_bg = {0.25, 0.1, 0.1},           -- Darker background for health bar
    mana = {0.2, 0.2, 0.6},                 -- Dark blue for mana/energy
    sanity = {0.3, 0.6, 0.3},               -- Green for sanity
    sanity_bg = {0.15, 0.25, 0.15},         -- Darker background for sanity bar
    sanity_low = {0.7, 0.3, 0.1},           -- Orange-red for low sanity
    sanity_critical = {0.5, 0.1, 0.3},      -- Purplish-red for critical sanity
    border = {0.3, 0.3, 0.4},               -- Subtle border color
    highlight = {0.5, 0.4, 0.2},            -- Muted gold for highlights
    tooltip_bg = {0.15, 0.15, 0.2, 0.95},   -- Slightly transparent dark background for tooltips
    key = {0.5, 0.5, 0.3},                  -- Key command highlight
    minimap = {
        unseen = {0.1, 0.1, 0.1},           -- Almost black for unseen
        seen = {0.25, 0.25, 0.3},           -- Very dark for seen areas
        visible = {0.4, 0.4, 0.5},          -- Slightly brighter for visible
        player = {0.7, 0.7, 0.8},           -- Player marker
        enemy = {0.6, 0.2, 0.2},            -- Enemy marker
        exit = {0.5, 0.4, 0.2},             -- Exit marker
        item = {0.3, 0.5, 0.3}              -- Item marker
    }
}

-- Panel dimensions (base values)
local BASE_PANEL_HEIGHT = 100  -- Reduced height for message-only bottom panel
local BASE_SIDE_PANEL_WIDTH = 280  -- Increased to accommodate all player info
local BASE_TOOLTIP_WIDTH = 250
local BASE_TOOLTIP_PADDING = 10

-- Initialize UI elements
function UI.init(width, height)
    -- Create fonts that will scale with the window
    local uiScale = math.min(width / 1024, height / 768)
    local fonts = {
        small = love.graphics.newFont(math.max(8, math.floor(10 * uiScale))),
        regular = love.graphics.newFont(math.max(10, math.floor(12 * uiScale))),
        medium = love.graphics.newFont(math.max(12, math.floor(14 * uiScale))),
        large = love.graphics.newFont(math.max(14, math.floor(18 * uiScale)))
    }
    
    return {
        width = width,
        height = height,
        scale = uiScale,
        fonts = fonts,
        showHelp = false,
        helpDelay = 0,
        tooltip = nil,
        tooltips = {},
        notifications = {},
        minimapEnabled = true,
        showLegend = false  -- Add legend toggle
    }
end

-- Update UI when window is resized
function UI.resize(ui, width, height)
    ui.width = width
    ui.height = height
    
    -- Recalculate scale
    ui.scale = math.min(width / 1024, height / 768)
    
    -- Update fonts
    ui.fonts = {
        small = love.graphics.newFont(math.max(8, math.floor(10 * ui.scale))),
        regular = love.graphics.newFont(math.max(10, math.floor(12 * ui.scale))),
        medium = love.graphics.newFont(math.max(12, math.floor(14 * ui.scale))),
        large = love.graphics.newFont(math.max(14, math.floor(18 * ui.scale)))
    }
end

-- Calculate current panel dimensions based on scale
function UI.getPanelDimensions(ui)
    local panelHeight = math.floor(BASE_PANEL_HEIGHT * ui.scale)
    local sidePanelWidth = math.floor(BASE_SIDE_PANEL_WIDTH * ui.scale)
    local tooltipWidth = math.floor(BASE_TOOLTIP_WIDTH * ui.scale)
    local tooltipPadding = math.floor(BASE_TOOLTIP_PADDING * ui.scale)
    
    return panelHeight, sidePanelWidth, tooltipWidth, tooltipPadding
end

-- Draw the main UI frame
function UI.drawFrame(ui, gameState)
    local PANEL_HEIGHT, SIDE_PANEL_WIDTH, TOOLTIP_WIDTH, TOOLTIP_PADDING = UI.getPanelDimensions(ui)
    
    -- Bottom panel background (messages only)
    love.graphics.setColor(COLORS.panel)
    love.graphics.rectangle("fill", 0, ui.height - PANEL_HEIGHT, ui.width - SIDE_PANEL_WIDTH, PANEL_HEIGHT)
    
    -- Side panel background (all game info)
    love.graphics.rectangle("fill", ui.width - SIDE_PANEL_WIDTH, 0, SIDE_PANEL_WIDTH, ui.height)
    
    -- Panel borders
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", 0, ui.height - PANEL_HEIGHT, ui.width - SIDE_PANEL_WIDTH, PANEL_HEIGHT)
    love.graphics.rectangle("line", ui.width - SIDE_PANEL_WIDTH, 0, SIDE_PANEL_WIDTH, ui.height)
    
    -- Set font for UI elements
    love.graphics.setFont(ui.fonts.regular)
    
    -- Draw the content within the panels
    UI.drawSidePanel(ui, gameState)  -- Includes player stats now
    UI.drawMessages(ui, gameState)
    
    -- Draw minimap if enabled
    if ui.minimapEnabled then
        UI.drawMinimap(ui, gameState)
    end
    
    -- Draw tooltips
    UI.drawTooltips(ui)
    
    -- Draw notifications
    UI.drawNotifications(ui)
    
    -- Draw legend if enabled
    if ui.showLegend then
        UI.drawLegend(ui, gameState)
    end
end

-- Draw a progress bar (for health, sanity, etc.)
function UI.drawProgressBar(x, y, width, height, fillRatio, fillColor, bgColor, labelText)
    -- Clamp fill ratio to valid range
    fillRatio = math.max(0, math.min(1, fillRatio))
    
    -- Draw background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw fill
    love.graphics.setColor(fillColor)
    love.graphics.rectangle("fill", x, y, width * fillRatio, height)
    
    -- Draw border
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw label text centered on the bar
    if labelText then
        love.graphics.setColor(COLORS.text)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(labelText)
        local textHeight = font:getHeight()
        love.graphics.print(
            labelText, 
            x + (width / 2) - (textWidth / 2),
            y + (height / 2) - (textHeight / 2)
        )
    end
end

-- Draw player statistics in the side panel
function UI.drawPlayerStats(ui, gameState)
    local PANEL_HEIGHT, SIDE_PANEL_WIDTH = UI.getPanelDimensions(ui)
    local player = gameState.player
    local x = ui.width - SIDE_PANEL_WIDTH + 15
    local y = 50  -- Starting position in side panel
    
    -- Player name and title
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("ABYSS SEEKER", x, y)
    
    -- Level/floor indication
    local floorText = "Depth: " .. (gameState.gamePhase or gameState.currentLevel or 1)
    love.graphics.print(floorText, x, y + 25)
    
    -- Health bar
    y = y + 55  -- Additional spacing
    UI.drawProgressBar(
        x, y, SIDE_PANEL_WIDTH - 30, 18,
        player.health / player.maxHealth,
        COLORS.health, COLORS.health_bg,
        "Health: " .. player.health .. "/" .. player.maxHealth
    )
    
    -- Sanity bar (if sanity system is active)
    if player.sanity then
        -- Choose color based on sanity level
        local sanityColor = COLORS.sanity
        if player.sanity.current <= Sanity.THRESHOLDS.CRITICAL then
            sanityColor = COLORS.sanity_critical
        elseif player.sanity.current <= Sanity.THRESHOLDS.UNSTABLE then
            sanityColor = COLORS.sanity_low
        end
        
        -- Draw sanity bar
        y = y + 24
        UI.drawProgressBar(
            x, y, SIDE_PANEL_WIDTH - 30, 18,
            player.sanity.current / player.sanity.max,
            sanityColor, COLORS.sanity_bg,
            "Sanity: " .. player.sanity.current .. "/" .. player.sanity.max
        )
        
        -- Display sanity state if it's concerning
        if player.sanity.current <= Sanity.THRESHOLDS.DISTURBED then
            local stateName, _ = Sanity.getStateDescription(player.sanity)
            y = y + 24
            love.graphics.setColor(sanityColor)
            love.graphics.print(
                "Mental State: " .. stateName,
                x, y
            )
        end
    end
    
    -- Defense and damage stats
    y = y + 30
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Defense: " .. player.defense, x, y)
    love.graphics.print("Damage: " .. player.damage, x + 120, y)
    
    -- Artifact pieces or quest progress
    if gameState.artifactPieces then
        y = y + 25
        love.graphics.setColor(COLORS.highlight)
        love.graphics.print("Artifact Shards: " .. gameState.artifactPieces .. "/5", x, y)
    end
    
    -- Additional status effects including sanity effects
    local effectsToShow = {}
    
    -- Add regular status effects
    if gameState.player.statusEffects and #gameState.player.statusEffects > 0 then
        for _, effect in ipairs(gameState.player.statusEffects) do
            table.insert(effectsToShow, {
                name = effect.name,
                type = effect.type
            })
        end
    end
    
    -- Add sanity-induced effects
    if player.sanity and player.sanity.activeEffects and #player.sanity.activeEffects > 0 then
        for _, effect in ipairs(player.sanity.activeEffects) do
            local effectName = effect.type
            if effect.type == "visibility" then
                effectName = "Impaired Vision" .. " " .. effect.value
            elseif effect.type == "behavior" then
                effectName = "Unpredictable"
            end
            
            table.insert(effectsToShow, {
                name = effectName,
                type = "debuff"
            })
        end
    end
    
    -- Display all effects
    if #effectsToShow > 0 then
        y = y + 25
        love.graphics.setColor(COLORS.text)
        love.graphics.print("Status:", x, y)
        y = y + 20
        
        for i, effect in ipairs(effectsToShow) do
            if effect.type == "buff" then
                love.graphics.setColor(0.3, 0.6, 0.3)
            elseif effect.type == "debuff" then
                love.graphics.setColor(0.6, 0.3, 0.3)
            else
                love.graphics.setColor(COLORS.text)
            end
            
            love.graphics.print(effect.name, x, y)
            y = y + 20  -- Stack effects vertically
        end
    end
end

-- Draw the side panel with additional information
function UI.drawSidePanel(ui, gameState)
    local PANEL_HEIGHT, SIDE_PANEL_WIDTH = UI.getPanelDimensions(ui)
    local x = ui.width - SIDE_PANEL_WIDTH + 15
    local y = 15  -- Starting position
    
    -- Draw the title
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("EBON VEIN", x, y)
    
    -- Draw player stats (now in side panel)
    UI.drawPlayerStats(ui, gameState)
    
    -- Move down to show inventory after stats
    y = 310  -- Position after player stats
    
    -- Show inventory
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("Inventory (" .. #gameState.player.inventory .. " items)", x, y)
    
    -- Show equipped items or most important ones
    if #gameState.player.inventory > 0 then
        y = y + 25
        for i = 1, math.min(3, #gameState.player.inventory) do
            local item = gameState.player.inventory[i]
            love.graphics.setColor(item.color or COLORS.text)
            love.graphics.print(item.symbol .. " " .. item.name, x + 10, y)
            y = y + 25
        end
        
        if #gameState.player.inventory > 3 then
            love.graphics.setColor(COLORS.text)
            love.graphics.print("(+" .. (#gameState.player.inventory - 3) .. " more)", x + 10, y)
            y = y + 25
        end
    else
        love.graphics.setColor(COLORS.text)
        y = y + 25
        love.graphics.print("No items", x + 10, y)
        y = y + 25
    end
    
    -- Show current objective
    y = y + 25  -- spacing
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("Objective:", x, y)
    y = y + 25
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Find the exit (X)", x + 10, y)
    
    -- Enemy count
    y = y + 40
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("Enemies nearby: " .. #gameState.enemies, x, y)
    
    -- Position
    y = y + 25
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Position: " .. gameState.player.x .. ", " .. gameState.player.y, x, y)
    
    -- Draw abilities section at the bottom of the side panel
    if gameState.player.abilities then
        y = y + 40
        love.graphics.setColor(COLORS.highlight)
        love.graphics.print("Abilities:", x, y)
        y = y + 25
        
        for i, ability in ipairs(gameState.player.abilities) do
            -- Show cooldown or ready status
            local status = "Ready"
            if ability.currentCooldown > 0 then
                status = "CD: " .. ability.currentCooldown
            end
            
            love.graphics.setColor(COLORS.text)
            love.graphics.print(i .. ": " .. ability.name .. " (" .. status .. ")", x + 10, y)
            y = y + 20
        end
    end
    
    -- Controls reminder at bottom of side panel
    y = ui.height - 60
    love.graphics.setColor(COLORS.key)
    love.graphics.print("Press H for help", x, y)
    y = y + 25
    love.graphics.print("Press L for legend", x, y)
end

-- Draw the message log with proper text wrapping - now uses full bottom width
function UI.drawMessages(ui, gameState)
    local PANEL_HEIGHT, SIDE_PANEL_WIDTH = UI.getPanelDimensions(ui)
    local msgX = 20
    local msgY = ui.height - PANEL_HEIGHT + 15  -- Top of bottom panel
    local msgWidth = ui.width - SIDE_PANEL_WIDTH - 40  -- Full width of bottom panel minus margins
    
    -- Calculate how many messages we can show
    local maxMessages = 4  -- Can fit more with dedicated space
    local messageSpacing = 22
    
    love.graphics.setColor(COLORS.text)
    
    -- Limit the number of messages to avoid overlap
    local startMsg = math.max(1, #gameState.messages - maxMessages + 1)
    for i = #gameState.messages, startMsg, -1 do
        local msgIndex = #gameState.messages - i + startMsg
        local alpha = 1 - (0.2 * (msgIndex - 1))
        love.graphics.setColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], alpha)
        
        -- Use printf for text wrapping
        love.graphics.printf(
            gameState.messages[i],
            msgX, 
            msgY,
            msgWidth,
            "left"
        )
        
        -- Calculate height of wrapped text
        local font = love.graphics.getFont()
        local _, wrappedText = font:getWrap(gameState.messages[i], msgWidth)
        local textHeight = #wrappedText * font:getHeight() 
        
        -- Adjust spacing based on text height
        msgY = msgY + math.max(messageSpacing, textHeight + 5)
    end
    
    love.graphics.setColor(1, 1, 1)
end

-- Draw minimap in the top-left instead of overlapping with side panel
function UI.drawMinimap(ui, gameState)
    local mapSize = 120
    local mapX = 25  -- Left side position
    local mapY = 25
    
    -- Calculate cell size based on map dimensions
    local cellSize = math.min(
        mapSize / gameState.map.width,
        mapSize / gameState.map.height
    )
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", mapX - 5, mapY - 5, mapSize + 10, mapSize + 10)
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", mapX - 5, mapY - 5, mapSize + 10, mapSize + 10)
    
    -- Draw map tiles based on visibility
    for y = 1, gameState.map.height do
        for x = 1, gameState.map.width do
            local visState = gameState.visibilityMap[y][x]
            
            if visState > Visibility.UNSEEN then
                local drawX = mapX + (x - 1) * cellSize
                local drawY = mapY + (y - 1) * cellSize
                
                -- Choose color based on visibility and tile type
                if visState == Visibility.VISIBLE then
                    -- Currently visible
                    if gameState.map.tiles[y][x] == "#" then
                        love.graphics.setColor(0.3, 0.3, 0.4)
                    elseif gameState.map.tiles[y][x] == "X" then
                        love.graphics.setColor(COLORS.minimap.exit)
                    else
                        love.graphics.setColor(COLORS.minimap.visible)
                    end
                else
                    -- Previously seen
                    if gameState.map.tiles[y][x] == "#" then
                        love.graphics.setColor(0.2, 0.2, 0.25)
                    elseif gameState.map.tiles[y][x] == "X" then
                        love.graphics.setColor(0.35, 0.25, 0.15)
                    else
                        love.graphics.setColor(COLORS.minimap.seen)
                    end
                end
                
                love.graphics.rectangle("fill", drawX, drawY, cellSize, cellSize)
            end
        end
    end
    
    -- Draw items on minimap (only visible ones)
    for _, item in ipairs(gameState.items) do
        if Visibility.isVisible(gameState.visibilityMap, item.x, item.y) then
            love.graphics.setColor(COLORS.minimap.item)
            love.graphics.rectangle("fill", 
                mapX + (item.x - 1) * cellSize, 
                mapY + (item.y - 1) * cellSize, 
                cellSize, cellSize)
        end
    end
    
    -- Draw enemies on minimap (only visible ones)
    for _, enemy in ipairs(gameState.enemies) do
        if Visibility.isVisible(gameState.visibilityMap, enemy.x, enemy.y) then
            love.graphics.setColor(COLORS.minimap.enemy)
            love.graphics.rectangle("fill", 
                mapX + (enemy.x - 1) * cellSize, 
                mapY + (enemy.y - 1) * cellSize, 
                cellSize, cellSize)
        end
    end
    
    -- Draw player position
    love.graphics.setColor(COLORS.minimap.player)
    love.graphics.rectangle("fill", 
        mapX + (gameState.player.x - 1) * cellSize - 1, 
        mapY + (gameState.player.y - 1) * cellSize - 1, 
        math.max(cellSize + 2, 3), math.max(cellSize + 2, 3))
    
    -- Title
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Map", mapX, mapY - 20)
    
    love.graphics.setColor(1, 1, 1)
end

-- Get color for terrain type
function UI.getTerrainColor(tile)
    if tile == "#" then return COLORS.wall
    elseif tile == "." then return COLORS.floor
    elseif tile == "X" then return COLORS.exit
    elseif tile == "~" then return COLORS.flesh
    elseif tile == "," then return COLORS.blood
    else return {1, 1, 1} -- Default white
    end
end

-- Get description for terrain type
function UI.getTerrainDescription(tile)
    if tile == "#" then return "Wall - Solid stone barrier"
    elseif tile == "." then return "Floor - Walkable surface"
    elseif tile == "X" then return "Exit - Leads to the next level"
    elseif tile == "~" then return "Flesh - Living tissue of the dungeon"
    elseif tile == "," then return "Blood - Remains of previous victims"
    else return "Unknown terrain"
    end
end

-- Draw the legend showing game symbols
function UI.drawLegend(ui, gameState)
    -- Position the legend in the top-right corner
    local x = ui.width - 250
    local startY = 60
    local width = 230
    local lineHeight = 24
    
    -- Collect visible entities
    local visibleTerrains = {}
    local visibleItems = {}
    local visibleEnemies = {}
    
    -- Scan visible map tiles
    for mapY = 1, gameState.map.height do
        for mapX = 1, gameState.map.width do
            if Visibility.isVisible(gameState.visibilityMap, mapX, mapY) then
                local tile = gameState.map.tiles[mapY][mapX]
                -- Add each tile type only once
                visibleTerrains[tile] = true
            end
        end
    end
    
    -- Collect visible items
    for _, item in ipairs(gameState.items) do
        if Visibility.isVisible(gameState.visibilityMap, item.x, item.y) then
            -- Store by name to avoid duplicates
            visibleItems[item.name] = item
        end
    end
    
    -- Collect visible enemies
    for _, enemy in ipairs(gameState.enemies) do
        if Visibility.isVisible(gameState.visibilityMap, enemy.x, enemy.y) then
            -- Store by name to avoid duplicates
            visibleEnemies[enemy.name] = enemy
        end
    end
    
    -- Convert dictionaries to arrays for easier iteration
    local terrainsList = {}
    for tile, _ in pairs(visibleTerrains) do
        table.insert(terrainsList, tile)
    end
    
    local itemsList = {}
    for _, item in pairs(visibleItems) do
        table.insert(itemsList, item)
    end
    
    local enemiesList = {}
    for _, enemy in pairs(visibleEnemies) do
        table.insert(enemiesList, enemy)
    end
    
    -- Draw background with fixed height that's sufficient for most cases
    local contentHeight = 400 -- Fixed height for simplicity
    
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", x - 10, startY - 10, width, contentHeight)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.rectangle("line", x - 10, startY - 10, width, contentHeight)
    
    -- Draw title
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("LEGEND", x + (width/2 - 30), startY)
    local currentY = startY + 30
    
    -- Helper function to truncate text to fit width
    local function truncateText(text, maxWidth)
        local font = love.graphics.getFont()
        if font:getWidth(text) <= maxWidth then
            return text
        end
        
        local ellipsis = "..."
        local width = font:getWidth(ellipsis)
        local i = #text
        
        while i > 1 do
            local truncated = text:sub(1, i) .. ellipsis
            width = font:getWidth(truncated)
            
            if width <= maxWidth then
                return truncated
            end
            
            i = i - 1
        end
        
        return text:sub(1, 1) .. ellipsis
    end
    
    -- Draw terrain section
    if #terrainsList > 0 then
        love.graphics.setColor(COLORS.highlight)
        love.graphics.print("Terrain", x + 10, currentY)
        currentY = currentY + 25
        
        for _, tile in ipairs(terrainsList) do
            -- Get color for this tile
            love.graphics.setColor(UI.getTerrainColor(tile))
            love.graphics.print(tile, x + 20, currentY)
            
            -- Draw description
            love.graphics.setColor(COLORS.text)
            local description = UI.getTerrainDescription(tile)
            love.graphics.print(truncateText(description, width - 50), x + 40, currentY)
            currentY = currentY + lineHeight
        end
        
        currentY = currentY + 5 -- Spacing between sections
    end
    
    -- Draw items section
    if #itemsList > 0 then
        love.graphics.setColor(COLORS.highlight)
        love.graphics.print("Items", x + 10, currentY)
        currentY = currentY + 25
        
        for _, item in ipairs(itemsList) do
            -- Draw item symbol with its color
            love.graphics.setColor(item.color or {1, 1, 1})
            love.graphics.print(item.symbol, x + 20, currentY)
            
            -- Draw item name and description
            love.graphics.setColor(COLORS.text)
            local description = item.name
            if item.description then
                description = item.name .. " - " .. item.description
            end
            
            love.graphics.print(truncateText(description, width - 50), x + 40, currentY)
            currentY = currentY + lineHeight
        end
        
        currentY = currentY + 5 -- Spacing between sections
    end
    
    -- Draw enemies section
    if #enemiesList > 0 then
        love.graphics.setColor(COLORS.highlight)
        love.graphics.print("Enemies", x + 10, currentY)
        currentY = currentY + 25
        
        for _, enemy in ipairs(enemiesList) do
            -- Draw enemy symbol with its color
            love.graphics.setColor(enemy.color or {1, 0, 0})
            love.graphics.print(enemy.symbol, x + 20, currentY)
            
            -- Draw enemy name and description
            love.graphics.setColor(COLORS.text)
            local description = enemy.name
            if enemy.description then
                description = enemy.name .. " - " .. enemy.description
            else
                -- Default descriptions based on behavior
                if enemy.behavior == "aggressive" then
                    description = enemy.name .. " - Aggressively hunts you"
                elseif enemy.behavior == "ranged" then
                    description = enemy.name .. " - Attacks from a distance"
                elseif enemy.behavior == "flanking" then
                    description = enemy.name .. " - Tries to flank you"
                elseif enemy.behavior == "patrolling" then
                    description = enemy.name .. " - Patrols an area"
                elseif enemy.behavior == "defensive" then
                    description = enemy.name .. " - Defensive fighter"
                else
                    description = enemy.name
                end
            end
            
            love.graphics.print(truncateText(description, width - 50), x + 40, currentY)
            currentY = currentY + lineHeight
        end
    end
    
    -- If nothing is visible, show a message
    if #terrainsList == 0 and #itemsList == 0 and #enemiesList == 0 then
        love.graphics.setColor(COLORS.text)
        love.graphics.print("Nothing visible yet...", x + 20, currentY)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Add a tooltip that will be displayed
function UI.addTooltip(ui, text, x, y, duration)
    table.insert(ui.tooltips, {
        text = text,
        x = x,
        y = y,
        duration = duration or 3,
        timeLeft = duration or 3
    })
end

-- Draw all active tooltips
function UI.drawTooltips(ui)
    for _, tip in ipairs(ui.tooltips) do
        -- Calculate text height based on wrapped text
        local font = love.graphics.getFont()
        local _, wrappedText = font:getWrap(tip.text, TOOLTIP_WIDTH - (TOOLTIP_PADDING * 2))
        local lineCount = #wrappedText
        local height = lineCount * font:getHeight() + TOOLTIP_PADDING * 2
        
        -- Draw tooltip background
        love.graphics.setColor(COLORS.tooltip_bg)
        love.graphics.rectangle("fill", 
            tip.x, tip.y, 
            TOOLTIP_WIDTH, height, 
            5, 5)  -- Rounded corners
            
        love.graphics.setColor(COLORS.border)
        love.graphics.rectangle("line", 
            tip.x, tip.y, 
            TOOLTIP_WIDTH, height, 
            5, 5)
        
        -- Draw tooltip text with wrapping
        love.graphics.setColor(COLORS.text)
        love.graphics.printf(
            tip.text, 
            tip.x + TOOLTIP_PADDING, 
            tip.y + TOOLTIP_PADDING,
            TOOLTIP_WIDTH - (TOOLTIP_PADDING * 2),
            "left"
        )
    end
end

-- Add notification that appears briefly
function UI.addNotification(ui, text, type)
    table.insert(ui.notifications, {
        text = text,
        type = type or "info",  -- info, warning, danger
        duration = 3,
        timeLeft = 3,
        alpha = 0,   -- Start transparent and fade in
        y = 80 + (#ui.notifications * 35) -- Increased from 30 for more spacing between notifications
    })
end

-- Draw all active notifications
function UI.drawNotifications(ui)
    local baseY = 80
    
    for i, notif in ipairs(ui.notifications) do
        local color
        if notif.type == "danger" then
            color = {0.8, 0.2, 0.2, notif.alpha}
        elseif notif.type == "warning" then
            color = {0.8, 0.7, 0.2, notif.alpha}
        else
            color = {0.3, 0.6, 0.8, notif.alpha}
        end
        
        -- Calculate width based on text
        local textWidth = love.graphics.getFont():getWidth(notif.text)
        local notifWidth = math.max(300, textWidth + 40)
        
        -- Draw background with alpha
        love.graphics.setColor(0.1, 0.1, 0.15, notif.alpha * 0.8)
        love.graphics.rectangle("fill", 
            20, notif.y, notifWidth, 30, 5, 5)  -- Increased height from 25 to 30
        
        -- Draw border
        love.graphics.setColor(color[1], color[2], color[3], notif.alpha)
        love.graphics.rectangle("line", 
            20, notif.y, notifWidth, 30, 5, 5)
        
        -- Draw text
        love.graphics.print(notif.text, 30, notif.y + 8) -- Adjusted from 5 to 8 to center text better
    end
    
    love.graphics.setColor(1, 1, 1)
end

-- Update UI elements that need periodic updates
function UI.update(ui, gameState, dt)
    -- Update tooltips
    for i = #ui.tooltips, 1, -1 do
        ui.tooltips[i].timeLeft = ui.tooltips[i].timeLeft - dt
        if ui.tooltips[i].timeLeft <= 0 then
            table.remove(ui.tooltips, i)
        end
    end
    
    -- Update notifications
    for i = #ui.notifications, 1, -1 do
        local notif = ui.notifications[i]
        notif.timeLeft = notif.timeLeft - dt
        
        -- Fade in
        if notif.timeLeft > notif.duration - 0.5 then
            notif.alpha = math.min(1, (notif.duration - notif.timeLeft) * 2)
        -- Fade out
        elseif notif.timeLeft < 0.5 then
            notif.alpha = notif.timeLeft * 2
        else
            notif.alpha = 1
        end
        
        -- Move notification up smoothly as others disappear
        notif.y = notif.y + ((80 + (i * 35)) - notif.y) * dt * 5  -- Adjusted for new spacing (35)
        
        if notif.timeLeft <= 0 then
            table.remove(ui.notifications, i)
        end
    end
    
    -- Help text auto-hide after delay if enabled
    if ui.showHelp and ui.helpDelay > 0 then
        ui.helpDelay = ui.helpDelay - dt
        if ui.helpDelay <= 0 then
            ui.showHelp = false
        end
    end
end

-- Handle UI-specific key presses
function UI.handleInput(ui, key)
    if key == "h" then
        -- Toggle help display
        ui.showHelp = not ui.showHelp
        -- Reset auto-hide timer if showing
        if ui.showHelp then
            ui.helpDelay = 10  -- Hide after 10 seconds of inactivity
        end
        return true
    elseif key == "m" then
        -- Toggle minimap
        ui.minimapEnabled = not ui.minimapEnabled
        return true
    elseif key == "l" then
        -- Toggle legend
        ui.showLegend = not ui.showLegend
        return true
    elseif ui.showHelp and (key == "escape" or key == "h") then
        -- Close help screen
        ui.showHelp = false
        return true
    end
    
    return false  -- Input wasn't handled by UI
end

-- Show a tooltip when hovering over an item or enemy
function UI.showEntityTooltip(ui, entity, x, y)
    if not entity then return end
    
    local tipText = entity.name
    if entity.health then
        tipText = tipText .. " (HP: " .. entity.health .. "/" .. entity.maxHealth .. ")"
    end
    
    if entity.description then
        tipText = tipText .. " - " .. entity.description
    end
    
    -- Add tooltip at cursor position
    UI.addTooltip(ui, tipText, x, y, 0.75)
end

-- Show tooltip for an entity
function UI.showEntityTooltip(ui, entity, x, y)
    if not entity then return end
    
    ui.tooltip = {
        x = x,
        y = y,
        text = "",
        entity = entity
    }
    
    -- Handle hazard tooltips
    if entity.type and (
        entity.type == "acid" or 
        entity.type == "gas" or 
        entity.type == "spikes" or
        entity.type == "fire" or
        entity.type == "crumbling") then
        
        local hazardName = ""
        
        if entity.type == "acid" then
            hazardName = "Acid Pool"
            ui.tooltip.text = "Damages any creature that steps on it."
        elseif entity.type == "gas" then
            hazardName = "Gas Vent"
            ui.tooltip.text = "Periodically releases disorienting gas clouds."
        elseif entity.type == "spikes" then
            hazardName = "Spike Trap"
            ui.tooltip.text = "Damages the first creature to step on it."
        elseif entity.type == "fire" then
            hazardName = "Fire"
            ui.tooltip.text = "Burns creatures and can spread to nearby tiles."
        elseif entity.type == "crumbling" then
            hazardName = "Crumbling Floor"
            ui.tooltip.text = "Unstable ground that will collapse if stepped on again."
        end
        
        ui.tooltip.title = hazardName
        return
    end
    
    -- ...existing code for other entity tooltips...
end

-- Draw a tooltip
function UI.drawTooltip(ui)
    if not ui.tooltip then return end
    
    -- ...existing code...
    
    -- Special handling for hazard tooltips
    if ui.tooltip.entity and ui.tooltip.entity.type and (
        ui.tooltip.entity.type == "acid" or 
        ui.tooltip.entity.type == "gas" or 
        ui.tooltip.entity.type == "spikes" or
        ui.tooltip.entity.type == "fire" or
        ui.tooltip.entity.type == "crumbling") then
        
        love.graphics.setColor(0.9, 0.2, 0.2)
        love.graphics.print("! HAZARD !", ui.tooltip.x, ui.tooltip.y - 20)
    end
    
    -- ...existing code...
end

-- Draw inventory panel (complete reimplementation with proper scaling)
function UI.drawInventory(ui, inventory, selection, x, y, width, height)
    -- Set up base dimensions and colors with proper scaling
    local scale = ui.scale
    local padding = math.floor(10 * scale)
    local itemHeight = math.floor(30 * scale)
    local sectionSpacing = math.floor(25 * scale)
    local textSpacing = math.floor(20 * scale)
    local bottomMargin = math.floor(40 * scale)
    
    -- Colors
    local backgroundColor = {0.1, 0.1, 0.15, 0.95}
    local borderColor = {0.4, 0.4, 0.5, 1}
    local titleColor = {0.7, 0.7, 0.8}
    local headerColor = {0.6, 0.5, 0.3}
    local selectionColor = {0.2, 0.2, 0.35, 0.8}
    
    -- Split the inventory panel with proper scaling
    local leftPanelWidth = math.floor(width * 0.4)
    local rightPanelWidth = width - leftPanelWidth
    
    -- Draw main background
    love.graphics.setColor(backgroundColor)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw panel border
    love.graphics.setColor(borderColor)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw vertical separator between the two panels
    love.graphics.line(
        x + leftPanelWidth, 
        y + padding, 
        x + leftPanelWidth, 
        y + height - padding
    )
    
    -- Draw title
    love.graphics.setFont(ui.fonts.medium)
    love.graphics.setColor(titleColor)
    love.graphics.printf("INVENTORY", x, y + padding, width, "center")
    
    -- Item count subtitle with proper vertical positioning
    love.graphics.setFont(ui.fonts.small)
    local titleHeight = ui.fonts.medium:getHeight()
    local subtitleY = y + padding + titleHeight + math.floor(5 * scale)
    local itemCountText = #inventory .. " items in pack"
    love.graphics.printf(itemCountText, x, subtitleY, width, "center")
    
    -- Calculate starting Y position for list based on title height
    local headerHeight = padding + titleHeight + ui.fonts.small:getHeight() + math.floor(15 * scale)
    local listStartY = y + headerHeight
    local listHeight = height - headerHeight - padding
    
    -- Empty inventory message
    if #inventory == 0 then
        love.graphics.setFont(ui.fonts.regular)
        love.graphics.setColor(0.6, 0.6, 0.7, 0.8)
        love.graphics.printf(
            "Your pack is empty.\nNothing but dust and shadows.",
            x + padding, 
            y + (height / 2) - (ui.fonts.regular:getHeight() * 1.5),
            width - padding * 2, 
            "center"
        )
        return
    end
    
    -- Calculate how many items we can display with proper scaling
    local maxVisibleItems = math.floor(listHeight / itemHeight)
    maxVisibleItems = math.max(1, maxVisibleItems) -- Ensure at least one item is visible
    
    -- Calculate scroll position to keep selected item in view
    local scrollOffset = 0
    if selection > maxVisibleItems then
        scrollOffset = math.min(selection - math.ceil(maxVisibleItems/2), #inventory - maxVisibleItems)
        scrollOffset = math.max(0, scrollOffset)  -- Ensure we don't go negative
    end
    
    -- Draw Left Panel: Items List
    love.graphics.setFont(ui.fonts.regular)
    
    -- Draw the section header with proper positioning
    love.graphics.setColor(headerColor)
    love.graphics.print("ITEMS", x + padding, listStartY)
    
    -- Item list with scrolling and proper spacing
    local itemStartY = listStartY + ui.fonts.regular:getHeight() + math.floor(8 * scale)
    for i = 1 + scrollOffset, math.min(#inventory, maxVisibleItems + scrollOffset) do
        local item = inventory[i]
        local itemY = itemStartY + ((i - scrollOffset - 1) * itemHeight)
        
        -- Highlight selected item
        if i == selection then
            love.graphics.setColor(selectionColor)
            love.graphics.rectangle(
                "fill", 
                x + padding - math.floor(5 * scale), 
                itemY, 
                leftPanelWidth - padding * 2 + math.floor(10 * scale), 
                itemHeight - math.floor(2 * scale)
            )
        end
        
        -- Draw item symbol with its color
        love.graphics.setColor(unpack(item.color or {1,1,1}))
        love.graphics.print(item.symbol, x + padding, itemY + math.floor(itemHeight * 0.25))
        
        -- Draw item name
        if i == selection then
            love.graphics.setColor(1, 1, 1)  -- Brighter text for selected item
        else
            love.graphics.setColor(0.8, 0.8, 0.9)
        end
        love.graphics.print(
            item.name, 
            x + padding + math.floor(20 * scale),
            itemY + math.floor(itemHeight * 0.25)
        )
    end
    
    -- Draw scrollbar if needed, with proper scaling
    if #inventory > maxVisibleItems then
        local scrollbarWidth = math.max(3, math.floor(3 * scale))
        local scrollTrackY = itemStartY
        local scrollTrackHeight = maxVisibleItems * itemHeight
        
        -- Calculate scrollbar dimensions
        local scrollbarHeight = scrollTrackHeight * math.min(1, maxVisibleItems / #inventory)
        local scrollbarY = scrollTrackY + (scrollTrackHeight - scrollbarHeight) * 
                         (scrollOffset / math.max(1, #inventory - maxVisibleItems))
        
        -- Draw the track
        love.graphics.setColor(0.2, 0.2, 0.25, 0.5)
        love.graphics.rectangle(
            "fill",
            x + leftPanelWidth - scrollbarWidth - math.floor(5 * scale),
            scrollTrackY,
            scrollbarWidth,
            scrollTrackHeight
        )
        
        -- Draw the handle
        love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
        love.graphics.rectangle(
            "fill",
            x + leftPanelWidth - scrollbarWidth - math.floor(5 * scale),
            scrollbarY,
            scrollbarWidth,
            scrollbarHeight
        )
    end
    
    -- Draw Right Panel: Item Details (only if an item is selected)
    if selection > 0 and selection <= #inventory then
        local item = inventory[selection]
        local detailX = x + leftPanelWidth + padding
        local detailY = listStartY
        local detailWidth = rightPanelWidth - padding * 2
        
        -- Section header
        love.graphics.setColor(headerColor)
        love.graphics.print("DETAILS", detailX, detailY)
        
        -- Calculate positions based on font heights for proper scaling
        local headerHeight = ui.fonts.regular:getHeight()
        local nameY = detailY + headerHeight + math.floor(5 * scale)
        
        -- Item name with larger font
        love.graphics.setFont(ui.fonts.medium)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(item.name, detailX, nameY)
        
        -- Symbol position based on text height
        local mediumHeight = ui.fonts.medium:getHeight()
        local symbolY = nameY + mediumHeight + math.floor(10 * scale)
        
        -- Item symbol with color
        love.graphics.setColor(unpack(item.color or {1,1,1}))
        love.graphics.setFont(ui.fonts.large)
        love.graphics.print(item.symbol, detailX, symbolY)
        
        -- Calculate separator position based on symbol
        local largeHeight = ui.fonts.large:getHeight()
        local separatorY = symbolY + math.floor(largeHeight * 0.6)
        
        -- Draw visual separator between symbol and description
        love.graphics.setColor(0.3, 0.3, 0.4, 0.6)
        love.graphics.line(
            detailX + math.floor(30 * scale), 
            separatorY,
            detailX + detailWidth - math.floor(20 * scale), 
            separatorY
        )
        
        -- Description header positioned after separator
        love.graphics.setFont(ui.fonts.regular)
        love.graphics.setColor(0.7, 0.7, 0.8)
        local descHeaderY = separatorY + math.floor(15 * scale)
        love.graphics.print("Description:", detailX, descHeaderY)
        
        -- Item description with text wrapping, positioned after header
        local descY = descHeaderY + headerHeight + math.floor(5 * scale)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf(
            item.description,
            detailX,
            descY,
            detailWidth - math.floor(20 * scale),
            "left"
        )
        
        -- Draw use prompt at the bottom with proper scaling
        love.graphics.setColor(0.6, 0.7, 1, 0.9)
        love.graphics.printf(
            "Press ENTER to use this item",
            detailX,
            y + height - math.floor(bottomMargin * 0.8),
            detailWidth,
            "center"
        )
    else
        -- If no item is selected (shouldn't happen normally)
        love.graphics.setColor(0.6, 0.6, 0.7, 0.5)
        love.graphics.printf(
            "Select an item to view details",
            x + leftPanelWidth + padding,
            y + height/2,
            rightPanelWidth - padding*2,
            "center"
        )
    end
    
    -- Draw controls reminder at the bottom with proper scaling
    love.graphics.setFont(ui.fonts.small)
    love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
    love.graphics.printf(
        "↑/↓: Navigate   ENTER: Use   ESC/I: Close",
        x + padding,
        y + height - math.floor(bottomMargin * 0.5),
        leftPanelWidth - padding*2,
        "left"
    )
end

-- Draw wrapped text
function UI.drawWrappedText(ui, text, x, y, width)
    local font = love.graphics.getFont()
    local words = {}
    
    -- Split text into words
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local line = ""
    local lineY = y
    
    for _, word in ipairs(words) do
        local testLine = line == "" and word or line .. " " .. word
        local testWidth = font:getWidth(testLine)
        
        if testWidth <= width then
            line = testLine
        else
            love.graphics.print(line, x, lineY)
            lineY = lineY + font:getHeight() + 2
            line = word
        end
    end
    
    if line ~= "" then
        love.graphics.print(line, x, lineY)
    end
end

-- Update help text to include new actions
function UI.showHelp(ui)
    ui.showHelp = true
    ui.helpContent = {
        "EBON VEIN - CONTROLS",
        "",
        "Arrow keys: Move/attack",
        "1-5: Use abilities",
        "I: Open inventory",
        "E: Interact with environment/objects",
        "L: Show legend",
        "H: Show this help",
        "Esc: This menu / Exit",
        "SPACE: Continue (when game over)",
        "",
        "Sanity affects your perception.",
        "Low sanity causes hallucinations.",
        "Meditation at altars can help regain sanity."
    }
    ui.helpDelay = 0 -- Don't auto-hide
end

return UI
