-- Configuration for LÖVE

function love.conf(t)
    t.title = "Ebon Vein - A Roguelike Adventure"
    t.version = "11.4"  -- Adjust based on your LÖVE version
    
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    
    t.console = true  -- Enable console output for debugging
end
