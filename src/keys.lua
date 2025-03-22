-- ...existing code...

-- Debug mode (changed from F key to a more accessible combination)
-- You can adjust the key to any that works better for you
function love.keypressed(key)
    -- ...existing code...
    
    -- Debug mode toggle with 'D' key (while holding Ctrl)
    -- Debug mode includes invincibility
    if key == 'd' and love.keyboard.isDown('lctrl', 'rctrl') then
        DEBUG_MODE = not DEBUG_MODE
        print("Debug mode: " .. tostring(DEBUG_MODE) .. " (invincibility " .. (DEBUG_MODE and "ON" or "OFF") .. ")")
    end
    
    -- ...existing code...
end

-- ...existing code...
