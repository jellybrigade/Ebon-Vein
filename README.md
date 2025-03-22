# Ebon Vein
#### Video Demo: https://www.youtube.com/watch?v=17ZZyYRGWL8
#### Description:

## Overview
Ebon Vein is a narrative-driven roguelike game where players descend into the living labyrinth known as the Abyss in search of the legendary Black Heart artifact. As you journey deeper, the dungeon itself begins to affect your mind, blurring the line between reality and nightmare.

This game was created as a final project for CS50, showcasing procedural map generation, turn-based gameplay mechanics, and a unique sanity system that affects gameplay.

## Story
The world above is collapsing. The skies have turned gray with ash, the rivers run black, and humanity clings to survival like rats in the shadows. Amid the chaos, a fractured prophecy whispers of The Black Heart, an ancient artifact buried within the Abyss.

Night after night, visions of the Black Heart plague your dreams. Its pulsing beat consumes your thoughts, and its distant, unspoken voice beckons you. With nothing left to lose, you descend into the Abyss—a cursed labyrinth that predates human memory.

## Gameplay
Ebon Vein features classic roguelike gameplay with a unique sanity mechanic:
- **Turn-based movement and combat**: Every action you take advances the game world
- **Procedural generation**: Each playthrough features unique maps and encounters
- **Resource management**: Balance your health, sanity, and limited inventory
- **Sanity system**: Your mental state deteriorates as you explore, causing hallucinations and affecting gameplay
- **Multiple enemy types**: Each with unique behaviors and combat styles
- **Environmental hazards**: From acid pools to spike traps that threaten both you and enemies
- **Narrative progression**: The story unfolds as you descend deeper into the Abyss

## Controls
- **Arrow keys**: Move/Attack
- **1-5**: Use abilities
- **I**: Open/close inventory
- **E**: Interact with objects
- **L**: Show legend
- **H**: Show help
- **Esc**: Menu/Exit
- **Space**: Continue (when game over)

## Files and Implementation

### Core Engine
- **main.lua**: The heart of the game that initializes all systems, manages the game loop, processes player input, and coordinates interactions between different modules. It handles turn progression, victory/defeat conditions, and enemy AI activation.

- **conf.lua**: Configuration file for the LÖVE framework, setting up window properties and dimensions.

### World Generation and Visualization
- **map.lua**: Handles procedural generation of dungeon levels with distinct environments that evolve as you descend. Implements room generation, corridor placement, and environmental details like blood stains and fleshy growths in deeper levels.

- **renderer.lua**: Manages all visual representation, including map rendering, entity drawing, UI overlays, and special effects. Implements distortion effects that intensify as sanity decreases, creating a visceral representation of the character's deteriorating mental state.

- **visibility.lua**: Calculates field-of-view using raycasting to determine what's visible to the player. Maintains three states for map tiles: currently visible, previously seen, and unseen.

### Entity Systems
- **player.lua**: Manages the player character, including stats, inventory, abilities, and status effects. Implements special abilities that operate on cooldown timers.

- **enemy.lua**: Controls enemy behavior with several AI types (aggressive, patrolling, ranged, flanking). Different enemies have unique movement patterns, attack strategies, and visual representations.

- **item.lua**: Handles collectible objects that can be found throughout the dungeon, including potions, weapons, and artifacts. Implements the use effects of items that can restore health, boost stats, or affect sanity.

- **hazard.lua**: Environmental dangers like acid pools, gas vents, spike traps, and fires. Some hazards are persistent, while others trigger once and disappear.

### Mechanics
- **combat.lua**: Handles attack resolution, damage calculation, and combat outcomes between entities. Supports both melee and ranged combat with different damage types.

- **sanity.lua**: A core system that tracks mental state and generates psychological effects as sanity deteriorates. Implements hallucinations, visual distortions, and gameplay alterations that make the player question what's real.

### Presentation
- **ui.lua**: Comprehensive interface system handling health bars, inventory display, tooltips, notifications, minimap, and menu screens. Scales dynamically to different screen resolutions.

- **story.lua**: Manages narrative progression and the telling of the story through level transitions and narrative screens. Contains all text for the game's evolving plot.

## Design Decisions

### Sanity as a Core Mechanic
I wanted to create a roguelike that wasn't just about physical survival but psychological endurance. The sanity system forces players to make difficult choices: Do you explore more thoroughly and risk your mind, or hurry through levels with less preparation?

As sanity decreases, the game becomes increasingly unreliable. You might see enemies that aren't there or miss enemies that are. The walls might appear to breathe or shift. Messages appear that may or may not be trustworthy. This creates a mounting tension where players must constantly question their perceptions.

I implemented this by having the sanity level directly affect:
1. Visual distortion intensity
2. Hallucination frequency and types  
3. Visibility range
4. Combat accuracy

### Procedural Generation with Narrative Structure
Balancing procedural generation with storytelling presented a challenge. Rather than having completely random levels or fully scripted ones, I created a hybrid approach:

Each level has a distinct theme, visual style, and narrative focus, but the specific layout is generated procedurally. This ensures the story remains coherent while maintaining the replayability that roguelikes are known for. The deeper you descend, the more organic and disturbing the environment becomes—walls of stone give way to pulsing flesh, blood pools form, and reality itself seems to warp.

### ASCII-inspired Visuals with Modern Effects
While staying true to the roguelike tradition of using symbols to represent entities, I enhanced the visual experience with:
- Color variations based on visibility state
- Dynamic lighting 
- Subtle animations
- Visual filters that shift based on sanity and level

This creates a more immersive atmosphere while honoring roguelike conventions.

### Limited Resources and Risk/Reward Decisions
Health and sanity restoration items are deliberately limited, forcing players to make strategic decisions about when to use them. Meditation altars provide a way to potentially restore sanity, but with the risk of further deterioration—another risk/reward decision point that adds tension.

## How to Run
1. Install LÖVE 11.4 or later from [love2d.org](https://love2d.org/)
2. Clone or download this repository
3. Run the game using LÖVE:
   ```
   love /path/to/Ebon-Vein
   ```

## Future Enhancements
- Audio system with atmospheric sounds and music
- Additional enemy types with more complex behaviors
- Expanded item and ability systems
- Multiple endings based on player choices and sanity management
- Meta-progression between runs

## Credits
This game was created by jellybrigade as a final project for CS50. It was built with LÖVE (Love2D) using Lua.

---

*"The Abyss knows your name. It has always known it."*
