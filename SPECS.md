# Bomberman LÖVE 2D - Technical Specifications

## Overview

This document provides a comprehensive specification for the Bomberman game, detailing its architecture, systems, components, and game mechanics. This specification outlines the current LÖVE 2D implementation, rebuilt from an earlier React Native version.

## Project Structure

```
bomberman-love2d/
├── main.lua              # Main LÖVE 2D entry point
├── conf.lua              # LÖVE 2D configuration file
├── src/                  # Source code for game logic and components
│   ├── states/           # Game states (e.g., MainMenu, GameScreen)
│   ├── entities/         # Game entities (e.g., Player, Bomb, Wall)
│   ├── components/       # Reusable components
│   ├── systems/          # Game systems (e.g., physics, rendering)
│   └── utils/            # Utility functions
├── assets/               # Game assets (images, sounds, fonts)
│   ├── images/
│   ├── sounds/
│   └── fonts/
├── tests/                # Unit and integration tests
├── .git/
├── .gitignore
├── README.md
├── SPECS.md
└── TODO.md
```

## Technology Stack

- **Framework**: LÖVE 2D (Lua)
- **Language**: Lua
- **Game Engine**: LÖVE 2D
- **State Management**: Custom (Lua tables, event-driven)
- **Graphics**: LÖVE 2D drawing API (images, shapes)
- **Physics**: LÖVE 2D physics module (Love.physics) - if used
- **Build Tool**: LÖVE 2D (packaging into .love files)

## Core Game Systems

### 1. Game Loop System

The game utilizes LÖVE 2D's event-driven architecture, primarily `love.update(dt)` and `love.draw()`:

- `love.update(dt)`: Handles game logic updates based on the time elapsed (`dt`).
- `love.draw()`: Renders all game elements to the screen.

**Key Components**:

- `main.lua`: Contains the main LÖVE 2D callbacks (`love.load`, `love.update`, `love.draw`, etc.).
- State-based architecture: Game logic is organized into different states (e.g., `MainMenuState`, `GameState`).
- Entity-Component-System (ECS) pattern: Game objects are entities composed of various components (data) and processed by systems (logic).

### 2. Entity System

Game objects are structured using an Entity-Component-System (ECS) pattern. Entities are simple IDs, components hold data, and systems process entities with specific components.

**Example Entity Structure (conceptual)**:

```lua
entities = {
  player = { id = 1, components = { Position, Velocity, Renderable, PlayerInfo } },
  bomb_123 = { id = 2, components = { Position, Timer, Explosive } },
  wall_0_0 = { id = 3, components = { Position, Renderable, Collidable } },
}
```

Each entity typically consists of:

- `id`: A unique identifier.
- `components`: A table of attached components, each holding specific data (e.g., `Position = { x = 0, y = 0 }`, `Renderable = { image = 'player.png' }`).
- Systems iterate over entities that possess the required components to perform their logic (e.g., a `RenderSystem` processes all entities with `Position` and `Renderable` components).

### 3. Grid System

- **Grid Size**: 13x13 tiles (odd number for proper layout)
- **Tile Size**: 30x30 pixels
- **Coordinate System**: Grid-based positioning with pixel-perfect alignment
- **Movement**: Tile-by-tile movement with smooth animations

### 4. Player System

**Core Features**:

- Directional facing (sprite sheets or multiple images)
- Movement and animation handled by dedicated systems (e.g., `MovementSystem`, `AnimationSystem`).
- Collision detection managed by a `CollisionSystem` (e.g., using LÖVE 2D's physics module or custom AABB checks).
- Invincibility frames after death, managed by a timer component.
- Lives management, typically a component of the player entity.

**State Management**:

- Player state is managed through components attached to the player entity (e.g., `PositionComponent`, `HealthComponent`, `AnimationComponent`).
- `gridPosition`: Stored in a `PositionComponent`.
- `isVisible`: Managed by a `RenderableComponent` or `AnimationComponent`.
- `hasHitEffect`: A flag or state within a `HealthComponent` or `PlayerStateComponent`.
- `direction`: Stored in a `MovementComponent`.

**Animations**:

- Implemented using sprite sheets and LÖVE 2D's `love.graphics.newImage` and `Image:setQuad`.
- Animation states (walking, idle, hit) are controlled by an `AnimationSystem` based on player actions and status.

### 5. Bomb System

**Core Features**:

- Multiple bomb placement, controlled by a `BombCapacityComponent` on the player.
- Configurable timer, managed by a `TimerComponent` on the bomb entity.
- Position tracking to prevent overlapping bombs, handled by the `CollisionSystem` or `GridSystem`.
- Explosion range determined by a `BombRangeComponent`.

**Components**:

- `BombComponent`: Contains data like timer, range, and state.
- `RenderableComponent`: For visual representation.
- `TimerSystem`: Updates bomb timers and triggers explosions.
- `ExplosionSystem`: Handles the creation and effects of explosions.

**Animations**:

- Implemented using LÖVE 2D's graphics functions.
- Visual effects like pulsing and flickering are handled by the `AnimationSystem` or directly in the `RenderSystem` based on `TimerComponent` values.

### 6. Explosion System

**Core Features**:

- Plus-shaped pattern (up, down, left, right), generated by an `ExplosionSystem`.
- Configurable range, typically a component of the bomb entity.
- Collision detection with walls and player, handled by the `CollisionSystem`.
- Proper cleanup after duration, managed by a `TimerComponent`.

**Mechanics**:

- Center explosion at bomb position.
- Directional explosions that stop at walls, determined by raycasting or grid checks.
- Destruction of destructible boxes, handled by the `DestructionSystem`.
- Power-up drops from destroyed boxes (e.g., 30% chance), managed by a `PickupSpawnSystem`.
- Player death detection with collision checking, part of the `HealthSystem`.

**Animations**:

- Implemented using LÖVE 2D's graphics and animation capabilities (e.g., sprite sheets, `love.graphics.scale`).
- Visual effects like scaling, pulsing, and fading are controlled by `AnimationComponent` and `RenderSystem`.

### 7. Wall/Box System

**Types**:

- **Outer Walls**: Indestructible border walls, typically static entities.
- **Indestructible Walls**: Fixed pattern walls (every other tile in even rows/cols), also static.
- **Destructible Boxes**: Randomly placed wooden boxes that can be destroyed, managed by a `DestructibleComponent`.

**Visuals**:

- Uses image assets loaded with `love.graphics.newImage`.
- Assets are typically organized in `assets/images/`.
- Examples: `wall_outer.png`, `wall_indestructible.png`, `box_destructible.png`.

### 8. Power-Up System

**Types**:

- **Extra Bomb**: Increases maximum bomb count (`BombCapacityComponent`).
- **Range Up**: Increases explosion range (`BombRangeComponent`).
- **Speed Up**: Increases player movement speed (`MovementComponent`).

**Mechanics**:

- Drop rate from destroyed boxes, handled by `PickupSpawnSystem`.
- Random selection of power-up type.
- Collection triggered by `CollisionSystem` when player overlaps with power-up entity.
- Effects applied to player's components.

**Visuals**:

- Uses image assets (e.g., `powerup_bomb.png`, `powerup_range.png`, `powerup_speed.png`).
- Animations (floating, spinning, pulsing) are handled by `AnimationSystem` and `RenderSystem`.

### 9. Control System

**Input Methods**:

- Keyboard input using `love.keyboard.isDown` and `love.keypressed`.
- Mouse input using `love.mouse.isDown` and `love.mousepressed` (if applicable).
- Gamepad input using `love.joystick` (if supported).

**Features**:

- Input handling typically managed by an `InputSystem` that translates raw input into game actions.
- Continuous movement and action triggering based on key/button states.
- Event-driven input processing.

### 10. Game State Management

**Core State**:

- Game state is typically managed within a central `GameState` object or distributed across components.
- `LivesComponent`: Player lives counter.
- `BombCapacityComponent`: Current and maximum bomb capacity.
- `BombRangeComponent`: Explosion range.
- `ScoreComponent`: Points system.
- `InvincibilityComponent`: Player protection state.
- `GameStatusComponent`: Tracks game over, win conditions.

**Persistence**:

- State is managed through Lua tables and updated by various systems.
- Timers and intervals are managed by dedicated timer systems or within component logic.
- Reset functionality involves re-initializing game entities and their components.

## Game Flow

### 1. Initialization

1. `love.load()`: Called once at the start.
2. Initialize game states (e.g., `MainMenuState`, `GameState`).
3. Load assets (images, sounds, fonts).
4. Create initial game entities and components (player, map elements).
5. Set up initial game state variables.

### 2. Gameplay Loop

1. `love.update(dt)`: Called every frame.
2. Process player input via `InputSystem`.
3. Update entity positions and states via `MovementSystem`, `AnimationSystem`, etc.
4. Handle bomb placement and timer updates via `BombSystem`.
5. Detect and resolve collisions via `CollisionSystem`.
6. Process explosions, box destruction, and power-up drops via `ExplosionSystem`, `DestructionSystem`, `PickupSpawnSystem`.
7. Update score and game status.
8. Check win/lose conditions.
9. `love.draw()`: Called every frame after `update`.
10. Render all visible entities via `RenderSystem`.

### 3. Death and Respawn

1. Player entity's `HealthComponent` is affected by explosion.
2. `HealthSystem` handles life decrement and checks for game over.
3. If lives remain:
   - Player entity's `InvincibilityComponent` is activated for a duration.
   - Player position reset to spawn point.
   - Death animation played via `AnimationSystem`.
4. If no lives remain:
   - Transition to `GameOverState`.

### 4. Restart Sequence

1. Transition from `GameOverState` (or similar) to `GameState` or `MainMenuState`.
2. Re-initialize all necessary game systems and entities.
3. Reset player components (lives, bombs, range, position).
4. Clear all active bombs and explosions.
5. Re-generate map elements (walls, boxes, power-ups) if applicable.

## Configuration

### Game Constants

- Game constants are typically defined in Lua modules (e.g., `src/config/GameConfig.lua`).
- Examples include: grid dimensions, tile sizes, player starting attributes, bomb timing, explosion duration, visual parameters, power-up drop rates, movement speeds, and maximum limits for bombs and range.

## Performance Considerations

### Animation Optimization

- Efficient use of sprite sheets and `love.graphics.newQuad`.
- Pre-loading assets to avoid runtime hitches.
- Minimizing redundant drawing calls.

### Memory Management

- Proper management of Lua tables and objects to allow for garbage collection.
- Reusing objects where possible instead of constant creation/destruction.
- Efficient asset loading and unloading.

### Rendering Efficiency

- Batching draw calls using `love.graphics.newSpriteBatch`.
- Using `love.graphics.setBlendMode` and `love.graphics.setColor` efficiently.
- Avoiding complex drawing operations where simpler alternatives exist.
- Utilizing LÖVE 2D's built-in performance tools (e.g., `love.timer.getFPS`).

## Known Issues and Solutions

(This section would typically be updated with LÖVE 2D specific issues encountered during development. As this is a hypothetical rebuild, specific issues are not listed, but general areas might include performance bottlenecks, rendering glitches, or input handling quirks.)

## Asset Management

### Image Assets

- Primarily uses raster graphics (PNG, JPG) for sprites, backgrounds, and UI elements.
- LÖVE 2D does not natively support SVG; vector assets would typically be converted to raster images.

### Asset Loading Strategy

- Assets are loaded using `love.graphics.newImage()`.
- Sound assets are loaded with `love.audio.newSource()`.
- Fonts are loaded with `love.graphics.newFont()`.
- Pre-loading assets during initialization (`love.load`) is common practice.
- Assets are organized in `assets/images`, `assets/sounds`, `assets/fonts` directories.

## Future Enhancement Opportunities

### Gameplay Features

- Enemy AI with pathfinding (e.g., A* algorithm).
- Multiplayer support with networking libraries (e.g., `enet` for Lua).
- Level progression system with diverse maps and challenges.
- Additional power-up types and environmental hazards.
- Time-based challenges and bonus stages.
- Hidden power-ups and secrets for exploration.

### Visual Improvements

- Particle effects for explosions and other in-game events using `love.graphics.newParticleSystem`.
- Advanced animations using sprite sheet animations and tweening libraries.
- Custom shaders for special effects (e.g., distortion, lighting).
- Dynamic lighting effects using `love.graphics.setBlendMode` and light textures.
- Weather systems (rain, snow) for environmental variation.

### Technical Improvements

- Sound and music integration using `love.audio`.
- Save/load game state to files (`love.filesystem`).
- Analytics and telemetry integration.
- Accessibility features (e.g., customizable controls, colorblind modes).
- Cross-platform optimization for various operating systems.

## Migration Considerations

(This section is largely superseded by the successful migration to LÖVE 2D. It previously outlined considerations for moving from React Native to a 'better framework'. The current document now describes the 'better framework'.)

### Architecture Improvements (now implemented in LÖVE 2D)

- Proper separation of concerns with ECS pattern.
- State management through Lua tables and event-driven systems.
- Modular component design for reusability.
- Streamlined asset pipeline.
- Robust error handling and debugging with LÖVE 2D's console.

- Dedicated game engine (Phaser, Unity, etc.)
- WebAssembly for physics calculations
- Better memory management patterns
- Optimized rendering pipeline
- Asset compression and streaming

### Feature Expansion

- Comprehensive testing suite
- CI/CD pipeline integration
- Modular plugin system
- Extensible configuration
- Localization support
