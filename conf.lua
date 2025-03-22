-- Configuration for LÖVE

function love.conf(t)
    t.title = "Ebon Vein - A Roguelike Adventure"
    t.version = "11.4"  
    
    t.window.width = 1024  
    t.window.height = 768  
    t.window.resizable = true  -- Enable window resizing
    
    t.console = true  -- Enable console output for debugging
end
