# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Running the Game
```bash
# Run the game
love .

# Run from parent directory
love bomberman-love2d/
```

### Testing
```bash
# Run comprehensive test suite
love . --test

# Run simple verification tests
love . test_run.lua
```

### Development
```bash
# Toggle debug mode during gameplay
# Press F1 to show FPS, memory usage, and performance overlay

# Essential game controls:
# WASD/Arrows - Move player
# Space - Place bomb
# P - Pause/unpause  
# R - Restart game
# +/= - Increase powerup drop rate (+10%)
# - - Decrease powerup drop rate (-10%)
# F1 - Toggle debug info
# Escape - Quit
```

## Architecture Overview

### ECS (Entity-Component-System) Pattern
This codebase uses a strict ECS architecture where:

- **Entities** (`src/ecs/entity.lua`) are containers with unique IDs and tags
- **Components** (`src/components/`) hold pure data (no logic)
  - Core: `transform.lua`, `gridposition.lua`, `movement.lua`, `powerup.lua`
  - Death System: `death.lua`, `invincibility.lua`
  - Visual: `destruction.lua`, `lifetime.lua`
- **Systems** (`src/systems/`) contain all game logic and operate on entities with required components
  - Core: `gridsystem.lua`, `movementsystem.lua`, `renderingsystem.lua`
  - Death Cycle: `deathsystem.lua`, `invincibilitysystem.lua`
  - Lifecycle: `destructionsystem.lua`, `lifetimesystem.lua`, `timersystem.lua`
- **World** (`src/ecs/world.lua`) manages entities and systems, handles entity lifecycle

### Critical ECS Integration Pattern
When adding components to existing entities, you MUST call `world:addEntityToSystems(entity)` to ensure the entity is registered with systems that now match its components. This is essential for destruction animations, lifetime management, and other dynamic component additions.

### State Management
- **Game States** (`src/states/`) manage different screens (menu, gameplay)
- **State transitions** handled in `main.lua` through `shouldTransition` flags
- Each state has enter/exit lifecycle and manages its own ECS world

### Responsive Grid System
- **GridSystem** (`src/systems/gridsystem.lua`) handles responsive scaling
- Grid size adapts to screen dimensions while maintaining aspect ratio
- Tile size calculated dynamically: `math.min(maxWidth/COLS, maxHeight/ROWS)`
- All positioning goes through grid coordinates, not raw pixels

### Hit Detection Architecture
The hit detection system uses multiple approaches:

1. **Grid-based collision**: Primary collision using grid positions for walls/boxes
2. **Pixel-level precision**: For powerup collection with generous thresholds (1.2 tile-size radius)
3. **Continuous checking**: Collision detection during movement, not just on movement completion
4. **Multi-entity handling**: Explosion system destroys ALL entities at same position (prevents duplicate entity bugs)

### Entity Lifecycle Management
- **DestructionSystem**: Handles visual destruction animations (shrinking, fading, rotation)
- **LifetimeSystem**: Manages entity removal after animations complete
- **Immediate cleanup**: Uses `world:destroyEntity()` for complete removal, not just `active = false`

### Level Generation
- **Position tracking**: Uses `occupiedPositions` lookup table to prevent duplicate entities at same coordinates
- **Collision prevention**: Pre-marks walls and spawn areas as occupied before placing boxes
- This prevents the "boxes not destroyed" bug caused by duplicate entities

### Asset and Input Management
- **AssetManager** (`src/managers/assetmanager.lua`) handles all asset loading with fallback colors
- **InputManager** (`src/managers/inputmanager.lua`) abstracts keyboard/gamepad/touch input
- **Cross-platform input**: Single API works across desktop, mobile, and gamepad

### Configuration System
All game constants in `src/config.lua`:
- Grid dimensions, player stats, timing values
- Color fallbacks when assets not available  
- Input sensitivity and platform-specific settings
- Debug flags and performance parameters

## Key Implementation Details

### Movement System
- **Smooth interpolation** between grid positions using cubic easing
- **Sub-tile positioning** for fluid movement
- **Input buffering** allows continuous movement by holding keys
- Movement and collision detection separated for clean architecture

### Explosion Algorithm
4-step atomic process:
1. Calculate explosion positions in all directions until hitting walls
2. Identify ALL entities at each position (handles duplicates)
3. Check for player damage and trigger death system if hit
4. Destroy entities atomically (prevents race conditions)
5. Create visual explosion effects

### Death & Respawn System
Complete player death lifecycle:
1. **Damage Detection**: Player hit by explosion loses 1 life
2. **Death Animation**: 1.5s skull animation with rotation and scaling
3. **Respawn**: Player returns to spawn position (1,1) 
4. **Invincibility**: 2s immunity with 8Hz flickering effect
5. **Powerup Reset**: All powerups reset to starting values
6. **Anti-exploit**: No damage during death animation or invincibility

### Enhanced Powerup System
4 powerup types with balanced progression:
- **Heart**: +1 health (max 5) - extends survivability
- **Speed**: +0.5 movement speed (max 6.0) - improves mobility  
- **Ammo**: +1 bomb capacity (max 8) - increases offensive power
- **Range**: +1 explosion range (max 12) - extends bomb effectiveness

**Features**:
- 50% drop rate from destroyed boxes (adjustable with +/- keys)
- Precise same-tile collection (0.7 tile threshold)
- Real-time drop rate adjustment during gameplay
- All powerups reset on death for meaningful risk/reward

### Character Selection System
Dynamic character selection with smooth animations:
- **Menu Access**: Main Menu → Settings → Character Selection
- **Dynamic Discovery**: Automatically detects `character_X` folders in `assets/images/player/`
- **Drag-and-Drop Ready**: Simply add new character folders with sprite sheets
- **Smooth Transitions**: 0.5-second sprite sliding animations with cubic easing
- **Input Controls**: LEFT/RIGHT arrows or A/D keys to navigate characters
- **Persistent Selection**: Character choice saved and applied to gameplay
- **Visual Feedback**: Animated sprite previews with walking animations

**Character Folder Structure**:
```
assets/images/player/character_X/
└── character_X_frame32x32.png  # 32x32 sprite sheet (4 rows x 3 columns)
```

**Navigation**:
- LEFT/RIGHT or A/D: Navigate between characters
- SPACE/ENTER: Confirm selection and return to menu
- R: Return to menu without saving changes

### Performance Considerations
- **Responsive design**: Everything scales based on screen size
- **Entity pooling**: Reuse explosion and particle entities when possible
- **System ordering**: Critical that LifetimeSystem runs after DestructionSystem
- **Debug overlay**: Press F1 for real-time performance monitoring

### Testing Strategy
- **Component tests**: Verify individual component behavior
- **System integration**: Test system interactions with mock entities
- **End-to-end**: Full gameplay scenarios in test suite
- **Responsive testing**: Window resizing and cross-platform input

### Common Pitfalls
1. **Adding components to existing entities**: Always call `world:addEntityToSystems(entity)` after adding new components
2. **Entity cleanup**: Use `world:destroyEntity()`, not just `entity.active = false`
3. **Grid positioning**: Work with grid coordinates first, then convert to pixels via GridSystem
4. **Duplicate entities**: Level generation must check `occupiedPositions` before placing entities
5. **Hit detection**: Use generous thresholds for player interaction (1.2+ tile-size radius)
6. **Asset reloading**: AssetManager now reloads images even if already loaded (removed `if not self.images[name]` condition)
7. **Character transitions**: Always complete animation state before exiting settings to ensure proper character selection save