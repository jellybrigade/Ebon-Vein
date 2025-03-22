-- UI module for handling interface elements

local UI = {}

-- Import required modules
local Visibility = require("visibility")
local Sanity = require("sanity")  -- Add sanity module

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

-- Panel dimensions
local PANEL_HEIGHT = 130  -- Increased from 120 for more space
local SIDE_PANEL_WIDTH = 250  -- Keeping the same
local TOOLTIP_WIDTH = 250
local TOOLTIP_PADDING = 10  -- Increased from 8

-- Initialize UI elements
function UI.init(width, height)
    return {
        width = width,
        height = height,
        showHelp = false,
        helpDelay = 0,
        tooltips = {},
        notifications = {},
        minimapEnabled = true,
        showLegend = false  -- Add legend toggle
    }
end

-- Draw the main UI frame
function UI.drawFrame(ui, gameState)
    -- Bottom panel background
    love.graphics.setColor(COLORS.panel)
    love.graphics.rectangle("fill", 0, ui.height - PANEL_HEIGHT, ui.width, PANEL_HEIGHT)
    
    -- Side panel background
    love.graphics.rectangle("fill", ui.width - SIDE_PANEL_WIDTH, 0, SIDE_PANEL_WIDTH, ui.height - PANEL_HEIGHT)
    
    -- Panel borders
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", 0, ui.height - PANEL_HEIGHT, ui.width, PANEL_HEIGHT)
    love.graphics.rectangle("line", ui.width - SIDE_PANEL_WIDTH, 0, SIDE_PANEL_WIDTH, ui.height - PANEL_HEIGHT)
    
    -- Draw the content within the panels
    UI.drawPlayerStats(ui, gameState)
    UI.drawSidePanel(ui, gameState)
    UI.drawMessages(ui, gameState)
    UI.drawControls(ui, gameState)
    
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

-- Draw player statistics in the bottom panel
function UI.drawPlayerStats(ui, gameState)
    local player = gameState.player
    local statY = ui.height - PANEL_HEIGHT + 20  -- Increased space from top of panel
    
    -- Player name and title
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("ABYSS SEEKER", 20, statY)
    
    -- Level/floor indication
    local floorText = "Depth: " .. (gameState.gamePhase or gameState.currentLevel or 1)  -- Use gamePhase if available
    love.graphics.print(floorText, 20, statY + 25)  -- Increased from 20
    
    -- Health bar
    UI.drawProgressBar(
        150, statY, 200, 18,  -- Increased height from 15
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
        UI.drawProgressBar(
            150, statY + 24, 200, 18,
            player.sanity.current / player.sanity.max,
            sanityColor, COLORS.sanity_bg,
            "Sanity: " .. player.sanity.current .. "/" .. player.sanity.max
        )
        
        -- Display sanity state if it's concerning
        if player.sanity.current <= Sanity.THRESHOLDS.DISTURBED then
            local stateName, _ = Sanity.getStateDescription(player.sanity)
            love.graphics.setColor(sanityColor)
            love.graphics.print(
                "Mental State: " .. stateName,
                370, statY + 24
            )
        end
    end
    
    -- Defense and damage stats
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Defense: " .. player.defense, 370, statY)
    love.graphics.print("Damage: " .. player.damage, 500, statY)
    
    -- Artifact pieces or quest progress
    if gameState.artifactPieces then
        love.graphics.setColor(COLORS.highlight)
        love.graphics.print("Artifact Shards: " .. gameState.artifactPieces .. "/5", 500, statY + 25)  -- Moved from 370 to 500
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
        love.graphics.setColor(COLORS.text)
        love.graphics.print("Status:", 150, statY + 49)  -- Increased from 35
        
        local effectX = 210  -- Increased from 200 for more spacing
        for _, effect in ipairs(effectsToShow) do
            if effect.type == "buff" then
                love.graphics.setColor(0.3, 0.6, 0.3)
            elseif effect.type == "debuff" then
                love.graphics.setColor(0.6, 0.3, 0.3)
            else
                love.graphics.setColor(COLORS.text)
            end
            
            love.graphics.print(effect.name, effectX, statY + 49)
            effectX = effectX + 120  -- Increased from 100 for more spacing
        end
    end
end

-- Draw a progress bar (for health, mana, etc.)
function UI.drawProgressBar(x, y, width, height, fillPercent, fillColor, bgColor, label)
    -- Background
    love.graphics.setColor(bgColor or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Filled portion
    love.graphics.setColor(fillColor or {0.7, 0.7, 0.7})
    local fillWidth = math.max(0, math.min(width * fillPercent, width))
    if fillWidth > 0 then
        love.graphics.rectangle("fill", x, y, fillWidth, height)
    end
    
    -- Border
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Label
    if label then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(label, x + 5, y + 2)
    end
end

-- Draw the side panel with additional information
function UI.drawSidePanel(ui, gameState)
    local x = ui.width - SIDE_PANEL_WIDTH + 15  -- Increased from 10 for more space
    local y = 25  -- Increased from 20 for more space at top
    
    -- Draw the title
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("EBON VEIN", x, y)
    
    -- Show inventory reminder
    y = y + 45  -- Increased from 40 for more vertical spacing
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Inventory (" .. #gameState.player.inventory .. " items)", x, y)
    
    -- Show equipped items or most important ones
    if #gameState.player.inventory > 0 then
        y = y + 25
        for i = 1, math.min(3, #gameState.player.inventory) do
            local item = gameState.player.inventory[i]
            love.graphics.setColor(item.color or COLORS.text)
            love.graphics.print(item.symbol .. " " .. item.name, x + 10, y)
            y = y + 25  -- Increased from 20 for more spacing between items
        end
        
        if #gameState.player.inventory > 3 then
            love.graphics.setColor(COLORS.text)
            love.graphics.print("(+" .. (#gameState.player.inventory - 3) .. " more)", x + 10, y)
            y = y + 25  -- Increased from 20
        end
    else
        love.graphics.setColor(COLORS.text)
        y = y + 25
        love.graphics.print("No items", x + 10, y)
        y = y + 25  -- Increased from 20
    end
    
    -- Show current objective
    y = y + 30  -- Increased from 25 for more separation
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("Objective:", x, y)
    y = y + 25  -- Increased from 20
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Find the exit (X)", x + 10, y)
    
    -- Enemy count
    y = y + 45  -- Increased from 40
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("Enemies nearby: " .. #gameState.enemies, x, y)
    
    -- Position
    y = y + 45  -- Increased from 40
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Position: " .. gameState.player.x .. ", " .. gameState.player.y, x, y)
    
    -- Toggle help text display
    y = ui.height - PANEL_HEIGHT - 50  -- Increased from 40 to move up from bottom
    love.graphics.setColor(COLORS.key)
    love.graphics.print("Press H for help", x, y)
    
    -- Toggle minimap display
    y = y + 25  -- Increased from 20
    love.graphics.setColor(COLORS.key)
    love.graphics.print("Press M for minimap", x, y)
end

-- Draw the message log with proper text wrapping and adjusted positioning
function UI.drawMessages(ui, gameState)
    -- Increased vertical position to avoid overlapping with stats
    local msgX = 20
    local msgY = ui.height - 60  -- Adjusted from 80 to move messages lower
    local msgWidth = ui.width - SIDE_PANEL_WIDTH - 40  -- Width for text wrapping
    
    -- Calculate how many messages we can show before overlapping with stats
    local maxMessages = 3
    local messageSpacing = 25
    
    -- Add a decorative separator line between stats and messages
    love.graphics.setColor(COLORS.border)
    love.graphics.line(
        20, 
        msgY - messageSpacing, 
        ui.width - SIDE_PANEL_WIDTH - 20, 
        msgY - messageSpacing
    )
    
    love.graphics.setColor(COLORS.text)
    
    -- Limit the number of messages to avoid overlap
    local startMsg = math.max(1, #gameState.messages - maxMessages + 1)
    for i = #gameState.messages, startMsg, -1 do
        local msgIndex = #gameState.messages - i + startMsg
        local alpha = 1 - (0.2 * (msgIndex - 1))
        love.graphics.setColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], alpha)
        
        -- Use printf instead of print to enable text wrapping
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
        
        -- Adjust spacing based on text height with minimum value
        msgY = msgY + math.max(messageSpacing, textHeight + 5)
    end
    
    love.graphics.setColor(1, 1, 1)
end

-- Draw controls help
function UI.drawControls(ui, gameState)
    if not gameState.ui.showHelp then return end
    
    -- Draw translucent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 100, 100, ui.width - 200, ui.height - 200)
    
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("CONTROLS", 120, 120)
    
    love.graphics.setColor(COLORS.text)
    local y = 160  -- Increased from 150 for more space at top
    local commands = {
        {"Arrow keys", "Move player"},
        {"I", "Open/close inventory"},
        {"E", "Use item or interact"},
        {"R", "Generate new level (debug)"},
        {"H", "Show/hide this help"},
        {"M", "Toggle minimap"},
        {"ESC", "Pause game"},
        {"Q", "Quit game"}
    }
    
    for _, cmd in ipairs(commands) do
        love.graphics.setColor(COLORS.key)
        love.graphics.print(cmd[1], 120, y)
        love.graphics.setColor(COLORS.text)
        love.graphics.print(cmd[2], 250, y)  -- Increased from 220 for more spacing
        y = y + 30  -- Increased from 25 for more vertical spacing
    end
    
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("Press H or ESC to close", 120, y + 25)  -- Increased from 20
    love.graphics.setColor(1, 1, 1)
end

-- Draw the minimap in the corner
function UI.drawMinimap(ui, gameState)
    local mapSize = 100
    local mapX = ui.width - SIDE_PANEL_WIDTH - mapSize - 25  -- Increased from 20
    local mapY = 25  -- Increased from 20
    local cellSize = 2
    
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
        cellSize + 2, cellSize + 2)
    
    -- Title
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Map", mapX, mapY - 20)
    
    love.graphics.setColor(1, 1, 1)
end

-- Draw the legend showing game symbols
function UI.drawLegend(ui, gameState)
    -- Position the legend in the top-right corner
    local x = ui.width - 250
    local y = 60
    local width = 230
    local lineHeight = 24
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", x - 10, y - 10, width, 340)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.rectangle("line", x - 10, y - 10, width, 340)
    
    -- Draw title
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("LEGEND", x, y)
    y = y + lineHeight + 5
    
    -- Draw legend entries
    love.graphics.setColor(1, 1, 1)
    
    -- Player
    love.graphics.print("@", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - You (The Abyss Seeker)", x + 15, y)
    y = y + lineHeight
    
    -- Enemies
    love.graphics.setColor(0.9, 0.1, 0.1)
    love.graphics.print("E", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Enemy", x + 15, y)
    y = y + lineHeight
    
    -- Meditation altar
    love.graphics.setColor(0.5, 0.5, 0.9)
    love.graphics.print("Ω", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Meditation Altar", x + 15, y)
    y = y + lineHeight
    
    -- Health potion
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.print("!", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Health Potion", x + 15, y)
    y = y + lineHeight
    
    -- Sanity elixir
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.print("!", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Sanity Elixir", x + 15, y)
    y = y + lineHeight
    
    -- Weapon
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.print("/", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Weapon", x + 15, y)
    y = y + lineHeight
    
    -- Armor
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("[", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Armor", x + 15, y)
    y = y + lineHeight
    
    -- Stairs/Level Exit
    love.graphics.setColor(1, 1, 0.5)
    love.graphics.print(">", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Level Exit", x + 15, y)
    y = y + lineHeight
    
    -- Wall
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("#", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Wall", x + 15, y)
    y = y + lineHeight
    
    -- Floor
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.print(".", x, y)
    love.graphics.setColor(COLORS.text)
    love.graphics.print(" - Floor", x + 15, y)
    y = y + lineHeight
    
    -- Controls reminder
    love.graphics.setColor(COLORS.highlight)
    love.graphics.print("Press 'L' to close legend", x, y + 10)
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

return UI
