-- This is a modification to the Player class's damage handling function

-- Replace the takeDamage function completely
function Player:takeDamage(amount)
    -- Skip ALL damage if debug mode is active
    if DEBUG_MODE then
        print("Debug mode blocked " .. amount .. " damage")
        return false
    end
    
    -- Normal damage handling continues here
    self.health = self.health - amount
    
    -- Call flash if it exists
    if self.flash then
        self:flash(0.2)
    end
    
    -- Check for death but don't allow it in debug mode
    if self.health <= 0 and not DEBUG_MODE then
        self:die()
    end
    
    return true
end

-- Completely replace the die function
function Player:die()
    -- Absolutely prevent death in debug mode
    if DEBUG_MODE then
        print("Debug mode prevented death attempt")
        self.health = self.maxHealth or 100 -- Reset to full health
        return false -- Indicate death was prevented
    end
    
    -- Original death code
    -- ...existing code...
end

-- Add this helper function
function Player:isDeadOrDying()
    if DEBUG_MODE then
        return false -- Never report as dead in debug mode
    end
    
    -- Original death check
    return self.health <= 0
end

-- Also find any update function that might check health and trigger death
function Player:update(dt)
    -- ...existing code...
    
    -- If there's a check like this, add the debug mode protection
    if self.health <= 0 then
        if not DEBUG_MODE then
            self:die()
        else
            self.health = 1 -- Keep player alive in debug mode
        end
    end
    
    -- ...existing code...
end
