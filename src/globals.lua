-- Add or modify DEBUG_MODE initialization

-- Ensure DEBUG_MODE is initialized
if DEBUG_MODE == nil then
    DEBUG_MODE = false
end

-- Add a global event to check debug status
function isDebugMode()
    return DEBUG_MODE == true
end

-- ...existing code...