function love.update(dt)
    -- Add this at the very beginning of the update function 
    -- to ensure it runs before any game logic that might cause death
    if DEBUG_MODE and player then
        -- Force health to stay above zero in debug mode
        if player.health and player.health <= 0 then
            player.health = player.maxHealth or 100 -- Reset to full health or a default value
            print("Debug mode prevented death, health reset to full")
        end
        
        -- Set an invincibility flag
        player.invincible = true
    elseif player then
        -- Only remove invincibility when debug mode is off
        player.invincible = player.invincibility or false -- Preserve any existing invincibility logic
    end
    
    -- ...existing code...
end