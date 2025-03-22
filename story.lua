-- Story module for narrative elements and progression

local Story = {}

-- Story phases
Story.PHASE = {
    PROLOGUE = 0,
    LEVEL_1 = 1,
    LEVEL_2 = 2,
    LEVEL_3 = 3,
    LEVEL_4 = 4,
    FINALE = 5,
    EPILOGUE = 6
}

-- Level names and descriptions
Story.LEVELS = {
    [0] = {
        name = "Prologue: The Call",
        subtitle = "The Descent Begins",
        description = "The world above is collapsing. As you descend into the Abyss, the stone walls seem to shudder around you."
    },
    [1] = {
        name = "The First Depths",
        subtitle = "Echoes of Humanity",
        description = "Skeletal remains litter the ground. Messages are scrawled in blood on the walls, blurring when you try to read them."
    },
    [2] = {
        name = "The Shifting Labyrinth",
        subtitle = "A Living Trap",
        description = "The Abyss mutates with each step. Corridors twist and rooms rearrange, as logic itself unravels around you."
    },
    [3] = {
        name = "The Third Depth",
        subtitle = "Madness Creeps In",
        description = "The walls pulse like veins. The floor feels warm, almost fleshy. The Abyss whispers directly to you now."
    },
    [4] = {
        name = "The Fourth Depth", 
        subtitle = "The Breaking Point",
        description = "You've lost all sense of time. The whispers are now screams, and you can barely think. The Black Heart grows stronger."
    },
    [5] = {
        name = "The Final Depth",
        subtitle = "The Black Heart",
        description = "A vast, pulsating chamber of living flesh. The Black Heart hangs at the center, suspended by writhing tendrils."
    },
    [6] = {
        name = "Epilogue",
        subtitle = "The Transformation",
        description = "You are now part of the Abyss, the new voice calling out to the next desperate soul."
    }
}

-- Full narrative text for each phase
Story.NARRATIVES = {
    [Story.PHASE.PROLOGUE] = {
        "The world above is collapsing. The skies have turned gray with ash, the rivers run black, and humanity clings to survival like rats in the shadows.",
        "Amid the chaos, a fractured prophecy whispers of The Black Heart, an ancient artifact buried within the Abyss.",
        "Night after night, visions of the Black Heart plague your dreams. Its pulsing beat consumes your thoughts, and its distant, unspoken voice beckons you.",
        "With nothing left to lose, you descend into the Abyss—a cursed labyrinth that predates human memory.",
        "The stone walls seem to shudder as you enter. The ground beneath your feet shifts like the tide. The Abyss is alive."
    },
    [Story.PHASE.LEVEL_1] = {
        "The first floor is haunting but familiar. The walls are cracked, the air is stale, and skeletal remains litter the ground.",
        "These are the remnants of others who sought the artifact and failed.",
        "Messages are scrawled in blood on the walls, but the words blur when you try to read them, as if the Abyss itself doesn't want you to understand.",
        "The enemies here are grotesque mockeries of human form—shambling horrors pieced together from flesh and bone.",
        "They groan with voices that sound almost...human, as though pieces of their old selves remain trapped within.",
        "You tell yourself: \"They're just monsters. Keep going.\""
    },
    [Story.PHASE.LEVEL_2] = {
        "With each descent, the Abyss mutates. The corridors twist, rooms rearrange, and the environment becomes less structured.",
        "Logic itself seems to be unraveling. You encounter walls that bleed, corridors that whisper, and traps that feel deliberately placed.",
        "The Abyss knows where you'll go before you do.",
        "The enemies grow more otherworldly. Shadows with no physical form stalk you, their hollow laughter ringing in your ears.",
        "At night—or is it day?—you dream of the Black Heart, and its voice begins to take form.",
        "It whispers promises of power, salvation, and...truth."
    },
    [Story.PHASE.LEVEL_3] = {
        "Reality starts to bend. The walls pulse like veins, and the floor feels warm, almost fleshy.",
        "The Abyss begins to speak directly to you—not in words, but in feelings. Regret. Dread. Hunger.",
        "The whispers grow louder, overlapping, like a hundred voices arguing in your mind.",
        "You begin to question whether the artifact is even real. Did you come down here for salvation, or is this a punishment?",
        "The enemies now mimic people from your past. A former friend. A lost lover.",
        "They scream your name as they lunge at you, and for a brief moment, you hesitate. Were they really here?"
    },
    [Story.PHASE.LEVEL_4] = {
        "You've lost all sense of time. The light from your torch flickers, and darkness presses against your mind.",
        "The labyrinth seems endless, but you feel the Black Heart's presence growing stronger.",
        "The whispers are now screams, and you can barely think. You begin to hear your own voice among them.",
        "\"It's your fault.\" \"You knew.\" \"The Abyss was waiting.\"",
        "The enemies are no longer tangible. They're emotions—shame, anger, despair—given form.",
        "Fighting them feels like fighting yourself, and each victory feels like a loss."
    },
    [Story.PHASE.FINALE] = {
        "The Black Heart is not a relic. It is the Abyss itself.",
        "The final floor is a vast, pulsating chamber, where the walls, floor, and ceiling are made entirely of living flesh.",
        "The Black Heart hangs at the center, suspended by tendrils that writhe like serpents. Its pulsing beat is deafening.",
        "As you approach, the voice finally becomes clear.",
        "\"You were always meant to find me. I am the truth you sought.\"",
        "You realize the artifact wasn't calling you—it was feeding on you."
    },
    [Story.PHASE.EPILOGUE] = {
        "When you touch the Black Heart, you see flashes of your life. The friends you betrayed. The loved ones you abandoned.",
        "The terrible choices that led you here. And then, the final revelation: you have always been part of the Abyss.",
        "The artifact didn't lure you—it simply brought you home.",
        "The Black Heart pulses faster, and your form begins to dissolve, merging with the living labyrinth.",
        "You are the new voice in the Abyss, calling out to the next desperate soul.",
        "THE END"
    }
}

-- Level-specific visual themes
Story.VISUAL_THEMES = {
    [0] = {
        floor_color = {0.2, 0.2, 0.3},
        wall_color = {0.5, 0.5, 0.6},
        ambient_light = 0.9,
        filter = nil  -- No special filter for prologue
    },
    [1] = {
        floor_color = {0.2, 0.2, 0.3},
        wall_color = {0.5, 0.5, 0.6},
        ambient_light = 0.8,
        filter = nil  -- Default lighting
    },
    [2] = {
        floor_color = {0.15, 0.15, 0.25},
        wall_color = {0.4, 0.4, 0.5},
        ambient_light = 0.7,
        filter = "shifting"  -- Subtle shifting effect
    },
    [3] = {
        floor_color = {0.25, 0.15, 0.15},
        wall_color = {0.5, 0.3, 0.3},
        ambient_light = 0.6,
        filter = "pulsing"  -- Pulsing walls effect
    },
    [4] = {
        floor_color = {0.1, 0.1, 0.2},
        wall_color = {0.3, 0.2, 0.4},
        ambient_light = 0.5,
        filter = "distortion"  -- Visual distortions
    },
    [5] = {
        floor_color = {0.3, 0.1, 0.1},
        wall_color = {0.6, 0.2, 0.2},
        ambient_light = 0.4,
        filter = "flesh"  -- Organic, flesh-like textures
    }
}

-- Get level name based on current phase
function Story.getLevelName(phase)
    if Story.LEVELS[phase] then
        return Story.LEVELS[phase].name
    end
    return "Unknown Depth"
end

-- Get level description based on current phase
function Story.getLevelDescription(phase)
    if Story.LEVELS[phase] then
        return Story.LEVELS[phase].description
    end
    return "The Abyss shifts around you."
end

-- Get narrative lines for the current phase
function Story.getNarrative(phase)
    return Story.NARRATIVES[phase] or {}
end

-- Helper function to sanitize text
local function sanitizeText(text)
    -- Replace any potentially problematic characters with safe ones
    -- Remove or replace non-ASCII characters that might cause UTF-8 issues
    local sanitized = text:gsub("[^\32-\126]", " ")
    return sanitized
end

-- Display a story screen with phased narrative text
function Story.showNarrativeScreen(phase, callback)
    -- Sanitize narrative texts before use
    local sanitizedNarrative = {}
    local originalLines = Story.NARRATIVES[phase] or {}
    for i, line in ipairs(originalLines) do
        sanitizedNarrative[i] = sanitizeText(line)
    end
    
    local narrativeScreen = {
        phase = phase,
        lines = sanitizedNarrative,
        currentLine = 1,
        timePerChar = 0.03,  -- Time per character for typing effect
        charIndex = 0,
        active = true,
        callback = callback,
        displayedText = "",
        continueText = "Press SPACE to continue...",
        showContinue = false,
        continueTimer = 0
    }
    
    narrativeScreen.update = function(dt)
        -- Update text animation
        if narrativeScreen.currentLine <= #narrativeScreen.lines then
            local fullLine = narrativeScreen.lines[narrativeScreen.currentLine]
            
            -- Progress character display with typing effect
            narrativeScreen.continueTimer = narrativeScreen.continueTimer + dt
            if narrativeScreen.charIndex < #fullLine then
                narrativeScreen.charIndex = narrativeScreen.charIndex + 1
                narrativeScreen.displayedText = string.sub(fullLine, 1, narrativeScreen.charIndex)
                narrativeScreen.showContinue = false
                narrativeScreen.continueTimer = 0
            else
                -- Full line displayed, show continue prompt after delay
                if narrativeScreen.continueTimer > 0.5 then
                    narrativeScreen.showContinue = true
                end
            end
        else
            -- All lines completed
            narrativeScreen.active = false
            if narrativeScreen.callback then
                narrativeScreen.callback()
            end
        end
    end
    
    narrativeScreen.keypressed = function(key)
        if key == "space" or key == "return" then
            if narrativeScreen.charIndex < #narrativeScreen.lines[narrativeScreen.currentLine] then
                -- Skip animation and show full line
                narrativeScreen.charIndex = #narrativeScreen.lines[narrativeScreen.currentLine]
                narrativeScreen.displayedText = narrativeScreen.lines[narrativeScreen.currentLine]
            else
                -- Move to next line
                narrativeScreen.currentLine = narrativeScreen.currentLine + 1
                narrativeScreen.charIndex = 0
                narrativeScreen.displayedText = ""
                narrativeScreen.showContinue = false
            end
        elseif key == "escape" then
            -- Skip entire narrative
            narrativeScreen.active = false
            if narrativeScreen.callback then
                narrativeScreen.callback()
            end
        end
    end
    
    narrativeScreen.draw = function()
        -- Draw dark background
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Draw title
        love.graphics.setColor(0.7, 0.2, 0.2)
        local levelInfo = Story.LEVELS[phase]
        local title = levelInfo and levelInfo.name or "The Abyss"
        local subtitle = levelInfo and levelInfo.subtitle or ""
        
        -- Center the title
        local fontSize = love.graphics.getFont():getHeight()
        local titleWidth = love.graphics.getFont():getWidth(title)
        love.graphics.print(title, 
                          (love.graphics.getWidth() - titleWidth) / 2, 
                          love.graphics.getHeight() * 0.15)
                          
        -- Subtitle
        love.graphics.setColor(0.6, 0.6, 0.7)
        local subtitleWidth = love.graphics.getFont():getWidth(subtitle)
        love.graphics.print(subtitle,
                         (love.graphics.getWidth() - subtitleWidth) / 2,
                         love.graphics.getHeight() * 0.15 + fontSize * 1.5)
        
        -- Draw narrative text safely with proper wrapping
        love.graphics.setColor(0.8, 0.8, 0.9)
        local status, err = pcall(function()
            love.graphics.printf(
                narrativeScreen.displayedText,
                love.graphics.getWidth() * 0.15,
                love.graphics.getHeight() * 0.3,
                love.graphics.getWidth() * 0.7,
                "left"
            )
        end)
        
        if not status then
            -- Fallback if printf fails
            love.graphics.print(
                "Error displaying text. Press SPACE to continue.",
                love.graphics.getWidth() * 0.15,
                love.graphics.getHeight() * 0.3
            )
        end
        
        -- Draw continue prompt if applicable
        if narrativeScreen.showContinue then
            love.graphics.setColor(0.7, 0.7, 0.8, 0.7 + math.sin(love.timer.getTime() * 3) * 0.3)
            
            -- Use safer print method for continue text too
            pcall(function()
                love.graphics.printf(
                    narrativeScreen.continueText,
                    0,
                    love.graphics.getHeight() * 0.8,
                    love.graphics.getWidth(),
                    "center"
                )
            end)
        end
    end
    
    return narrativeScreen
end

-- Apply visual theme based on current level
function Story.applyVisualTheme(level, rendererModule, mapModule)
    local theme = Story.VISUAL_THEMES[level] or Story.VISUAL_THEMES[1]
    
    -- Update renderer colors
    if rendererModule and rendererModule.COLORS then
        rendererModule.COLORS.floor = theme.floor_color
        rendererModule.COLORS.wall = theme.wall_color
        
        -- Apply ambient light adjustments
        if theme.ambient_light then
            for k, v in pairs(rendererModule.COLORS) do
                if type(v) == "table" and #v >= 3 then
                    -- Adjust non-UI colors based on ambient light
                    if k ~= "ui" and k ~= "title" and k ~= "message" and k ~= "inventory" then
                        rendererModule.COLORS[k] = {
                            v[1] * theme.ambient_light,
                            v[2] * theme.ambient_light,
                            v[3] * theme.ambient_light
                        }
                        -- Keep alpha if it exists
                        if v[4] then rendererModule.COLORS[k][4] = v[4] end
                    end
                end
            end
        end
        
        -- Store current theme for later reference
        Story.currentTheme = theme
    end
end

-- Get level-specific visual or audio effects
function Story.getLevelEffects(level)
    local effects = {
        visualFilter = Story.VISUAL_THEMES[level] and Story.VISUAL_THEMES[level].filter,
        ambientSounds = level > 2, -- Enable ambient sounds from level 3 onwards
        whispers = level >= 3,     -- Enable whisper effects from level 3
        heartbeat = level >= 4,    -- Enable heartbeat effects from level 4
        pulsingWalls = level == 5  -- Enable pulsing wall effect in final level
    }
    
    return effects
end

return Story
