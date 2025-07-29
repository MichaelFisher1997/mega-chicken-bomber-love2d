-- Game state for the main gameplay
-- Manages the ECS world and game systems

local World = require("src.ecs.world")
local GridSystem = require("src.systems.gridsystem")
local MovementSystem = require("src.systems.movementsystem")
local RenderingSystem = require("src.systems.renderingsystem")
local TimerSystem = require("src.systems.timersystem")
local LifetimeSystem = require("src.systems.lifetimesystem")
local SoundSystem = require("src.systems.soundsystem")
local ParticleSystem = require("src.systems.particlesystem")
local PerformanceSystem = require("src.systems.performancesystem")
local DestructionSystem = require("src.systems.destructionsystem")
local SaveManager = require("src.managers.savemanager")
local Config = require("src.config")

local GameState = {}
GameState.__index = GameState

function GameState:new(assetManager, inputManager, characterManager)
    local state = {
        world = nil,
        assetManager = assetManager,
        inputManager = inputManager,
        characterManager = characterManager,
        gridSystem = nil,
        movementSystem = nil,
        renderingSystem = nil,
        shouldTransition = false,
        nextState = nil,
        gameTime = 0,
        paused = false,
        player = nil,
        lives = Config.PLAYER_START_LIVES,
        bombs = Config.PLAYER_START_BOMBS,
        maxBombs = Config.PLAYER_START_BOMBS,
        range = Config.PLAYER_START_RANGE,
        health = Config.PLAYER_START_HEALTH,
        speed = Config.PLAYER_SPEED,
        score = 0,
        gameOver = false,
        -- Track boxes being destroyed this frame to prevent race conditions
        destroyingBoxes = {}
    }
    setmetatable(state, self)
    return state
end

function GameState:enter()
    -- Load selected character sprite before creating entities
    if self.characterManager then
        local selectedCharacter = self.characterManager:getSelectedCharacterData()
        print("[GAMESTATE] Selected character:", selectedCharacter and selectedCharacter.name or "none")
        self.characterManager:loadSelectedCharacterSprite()
    end
    
    -- Create ECS world
    self.world = World:new()
    
    -- Create and add systems
    self.gridSystem = GridSystem:new()
    self.movementSystem = MovementSystem:new()
    self.renderingSystem = RenderingSystem:new()
    self.timerSystem = TimerSystem:new()
    self.lifetimeSystem = LifetimeSystem:new()
    self.destructionSystem = DestructionSystem:new()
    self.deathSystem = require("src.systems.deathsystem"):new()
    self.invincibilitySystem = require("src.systems.invincibilitysystem"):new()
    self.animationSystem = require("src.systems.animationsystem"):new()
    -- Configure systems
    self.renderingSystem.assetManager = self.assetManager
    self.world:addSystem(self.gridSystem)
    self.world:addSystem(self.movementSystem)
    self.world:addSystem(self.renderingSystem)
    self.world:addSystem(self.timerSystem)
    self.world:addSystem(self.lifetimeSystem)
    self.world:addSystem(self.destructionSystem)
    self.world:addSystem(self.deathSystem)
    self.world:addSystem(self.invincibilitySystem)
    self.world:addSystem(self.animationSystem)
    
    -- Connect systems
    self.movementSystem:setInputManager(self.inputManager)
    self.movementSystem:setWorld(self.world)
    self.movementSystem:setGameState(self)
    self.lifetimeSystem:setWorld(self.world)
    self.deathSystem:setWorld(self.world)
    self.deathSystem:setGridSystem(self.gridSystem)
    self.deathSystem:setGameState(self)
    
    -- Initialize grid system with current screen size
    local w, h = love.graphics.getDimensions()
    self.gridSystem:resize(w, h)
    
    -- Create initial game entities
    self:createGameEntities()
    
    -- Initialize input
    self.inputManager:resize(w, h)
end

function GameState:exit()
    if self.world then
        self.world:clear()
    end
end

function GameState:createGameEntities()
    -- Create player
    self:createPlayer(1, 1)
    
    -- Create walls and boxes
    self:createLevel()
end

function GameState:createPlayer(row, col)
    local Entity = require("src.ecs.entity")
    local Transform = require("src.components.transform")
    local GridPosition = require("src.components.gridposition")
    local Movement = require("src.components.movement")
    local Collision = require("src.components.collision")
    local Animation = require("src.components.animation")
    
    local player = self.world:createEntity()
    player:addTag("player")
    
    -- Add components
    player:addComponent("transform", Transform:new(0, 0, 0, 0))
    player:addComponent("gridPosition", GridPosition:new(row, col))
    player:addComponent("movement", Movement:new(Config.PLAYER_SPEED))
    player:addComponent("collision", Collision:new(0.8, 0.8, 0.1, 0.1))
    
    -- Add animation component with sprite sheet from selected character
    local spriteSheet = self.assetManager:getImage("player_spritesheet")
    if not spriteSheet and self.characterManager then
        -- Load the selected character sprite if not already loaded
        self.characterManager:loadSelectedCharacterSprite()
        spriteSheet = self.assetManager:getImage("player_spritesheet")
    end
    
    if spriteSheet then
        local animations = {
            -- Idle animations (feet together frame - frame 1)
            idle_down = {row = 0, startFrame = 1, frameCount = 1, loop = true},
            idle_left = {row = 1, startFrame = 1, frameCount = 1, loop = true},
            idle_right = {row = 2, startFrame = 1, frameCount = 1, loop = true},
            idle_up = {row = 3, startFrame = 1, frameCount = 1, loop = true},
            
            -- Walking animations (3 frames: left step, feet together, right step)
            walk_down = {row = 0, startFrame = 0, frameCount = 3, loop = true},
            walk_left = {row = 1, startFrame = 0, frameCount = 3, loop = true},
            walk_right = {row = 2, startFrame = 0, frameCount = 3, loop = true},
            walk_up = {row = 3, startFrame = 0, frameCount = 3, loop = true}
        }
        
        local animation = Animation:new(spriteSheet, 32, 32, animations)
        animation.frameDuration = 0.2 -- Slower animation for walking
        player:addComponent("animation", animation)
    end

    -- Add entity to systems after all initial components are added
    self.world:addEntityToSystems(player)
    
    self.player = player
    return player
end

function GameState:createLevel()
    -- Create outer walls
    for col = 0, Config.GRID_COLS - 1 do
        self:createWall(0, col, "wall")
        self:createWall(Config.GRID_ROWS - 1, col, "wall")
    end
    
    for row = 1, Config.GRID_ROWS - 2 do
        self:createWall(row, 0, "wall")
        self:createWall(row, Config.GRID_COLS - 1, "wall")
    end
    
    -- Create indestructible walls (every other tile in even rows/cols)
    for row = 2, Config.GRID_ROWS - 3, 2 do
        for col = 2, Config.GRID_COLS - 3, 2 do
            self:createWall(row, col, "indestructible")
        end
    end
    
    -- Create destructible boxes
    local boxCount = 0
    local maxBoxes = math.floor(Config.GRID_COLS * Config.GRID_ROWS * 0.3) -- 30% of grid
    local occupiedPositions = {}
    
    -- Mark walls as occupied
    for row = 0, Config.GRID_ROWS - 1 do
        for col = 0, Config.GRID_COLS - 1 do
            -- Mark outer walls and indestructible walls as occupied
            if row == 0 or row == Config.GRID_ROWS - 1 or col == 0 or col == Config.GRID_COLS - 1 or
               (row % 2 == 0 and col % 2 == 0) then
                occupiedPositions[row .. "," .. col] = true
            end
        end
    end
    
    -- Mark player spawn area as occupied
    for row = 1, 2 do
        for col = 1, 2 do
            occupiedPositions[row .. "," .. col] = true
        end
    end
    
    while boxCount < maxBoxes do
        local row = love.math.random(1, Config.GRID_ROWS - 2)
        local col = love.math.random(1, Config.GRID_COLS - 2)
        local posKey = row .. "," .. col
        
        -- Only place box if position is not occupied
        if not occupiedPositions[posKey] then
            self:createWall(row, col, "box")
            occupiedPositions[posKey] = true
            boxCount = boxCount + 1
        end
    end
end

function GameState:createWall(row, col, wallType)
    local Entity = require("src.ecs.entity")
    local Transform = require("src.components.transform")
    local GridPosition = require("src.components.gridposition")
    local Collision = require("src.components.collision")
    
    local wall = self.world:createEntity()
    wall:addTag("wall")
    wall:addTag(wallType)
    
    wall:addComponent("transform", Transform:new(0, 0, 0, 0))
    wall:addComponent("gridPosition", GridPosition:new(row, col))
    wall:addComponent("collision", Collision:new(1, 1, 0, 0))

    -- Add entity to systems after all initial components are added
    self.world:addEntityToSystems(wall)
    
    return wall
end

function GameState:update(dt)
    if self.paused then return end
    
    -- Handle game over state
    if self.gameOver then
        self:handleGameOverInput(dt)
        return
    end
    
    -- Clear destruction tracking at start of each frame
    self.destroyingBoxes = {}
    
    self.gameTime = self.gameTime + dt
    
    -- Update world
    if self.world then
        self.world:update(dt)
    end
    
    -- Handle input
    self:handleInput(dt)
end

function GameState:handleInput(dt)
    -- Handle bomb placement
    if self.inputManager:isActionPressed("bomb") then
        self:placeBomb()
    end
    
    if self.inputManager:isActionPressed("pause") then
        self.paused = not self.paused
    end
    
    if self.inputManager:isActionPressed("restart") then
        self:restart()
    end
end

function GameState:placeBomb()
    if not self.player or self.bombs <= 0 then return end
    
    -- Prevent bomb placement during death animation
    local death = self.player:getComponent("death")
    if death and death.isDying then
        return
    end
    
    local gridPos = self.player:getComponent("gridPosition")
    local movement = self.player:getComponent("movement")
    if not gridPos then return end
    
    -- Determine bomb placement position
    local bombRow, bombCol = gridPos.row, gridPos.col
    
    -- If player is moving, place bomb at destination tile for better precision
    if movement and movement.isMoving and movement.targetRow and movement.targetCol then
        -- Use the tile the player is moving towards
        bombRow, bombCol = movement.targetRow, movement.targetCol
        print("Player moving - placing bomb at destination:", bombRow, bombCol)
    else
        print("Player stationary - placing bomb at current position:", bombRow, bombCol)
    end
    
    -- Check if there's already a bomb at the target position
    local bombs = self.world:getEntitiesWithTag("bomb")
    for _, bomb in ipairs(bombs) do
        local bombPos = bomb:getComponent("gridPosition")
        if bombPos and bombPos.row == bombRow and bombPos.col == bombCol then
            print("Bomb already exists at", bombRow, bombCol)
            return -- Bomb already exists here
        end
    end
    
    self:createBomb(bombRow, bombCol)
    self.bombs = self.bombs - 1
end

function GameState:createBomb(row, col)
    local Entity = require("src.ecs.entity")
    local Transform = require("src.components.transform")
    local GridPosition = require("src.components.gridposition")
    local Timer = require("src.components.timer")
    
    local bomb = self.world:createEntity()
    bomb:addTag("bomb")
    
    bomb:addComponent("transform", Transform:new(0, 0, 0, 0))
    bomb:addComponent("gridPosition", GridPosition:new(row, col))
    bomb:addComponent("timer", Timer:new(Config.BOMB_TIMER, function()
        self:explodeBomb(bomb)
    end))

    -- Add entity to systems after all initial components are added
    self.world:addEntityToSystems(bomb)
    
    return bomb
end

function GameState:explodeBomb(bomb)
    local gridPos = bomb:getComponent("gridPosition")
    if not gridPos then return end
    
    -- Create explosion
    self:createExplosion(gridPos.row, gridPos.col)
    
    -- Remove bomb
    self.world:destroyEntity(bomb)
    
    -- Return bomb to player
    self.bombs = math.min(self.bombs + 1, self.maxBombs)
end

function GameState:createExplosion(row, col)
    print("[EXPLOSION] Creating explosion at", row, col, "with range", self.range)
    
    -- Step 1: Calculate all explosion positions and collect boxes atomically
    local explosionPositions = {{row, col}} -- Center explosion
    local boxesToDestroy = {}
    
    -- Check center position for boxes (could be multiple)
    local centerBoxes = self:getAllActiveBoxesAt(row, col)
    if #centerBoxes > 0 then
        print("[EXPLOSION] Found", #centerBoxes, "center box(es) at", row, col)
        for _, box in ipairs(centerBoxes) do
            table.insert(boxesToDestroy, {box, row, col})
        end
    end
    
    -- Add directional explosions
    local directions = {{0,1}, {0,-1}, {1,0}, {-1,0}}
    
    for _, dir in ipairs(directions) do
        local dx, dy = dir[1], dir[2]
        print("[EXPLOSION] Checking direction", dx, dy)
        
        for i = 1, self.range do
            local newRow = row + dy * i
            local newCol = col + dx * i
            
            -- Check bounds
            if newRow < 0 or newRow >= Config.GRID_ROWS or
               newCol < 0 or newCol >= Config.GRID_COLS then
                print("[EXPLOSION] Hit boundary at", newRow, newCol)
                break
            end
            
            -- Check if this position is blocked by solid walls
            local blockedByWall = self:isPositionBlocked(newRow, newCol)
            
            -- Check if this position has destructible boxes (could be multiple)
            local boxes = self:getAllActiveBoxesAt(newRow, newCol)
            
            if not blockedByWall then
                table.insert(explosionPositions, {newRow, newCol})
                print("[EXPLOSION] Adding explosion at", newRow, newCol)
                
                -- If there are boxes at this position, collect them all and stop the ray
                if #boxes > 0 then
                    print("[EXPLOSION] Found", #boxes, "box(es) at", newRow, newCol, "- will destroy all")
                    for _, box in ipairs(boxes) do
                        table.insert(boxesToDestroy, {box, newRow, newCol})
                    end
                    break
                else
                    print("[EXPLOSION] No box at", newRow, newCol)
                end
            else
                print("[EXPLOSION] Blocked by wall at", newRow, newCol)
                break
            end
        end
    end
    
    -- Step 2: Destroy all boxes atomically (before creating visual effects)
    print("[EXPLOSION] Will destroy", #boxesToDestroy, "boxes")
    for _, boxData in ipairs(boxesToDestroy) do
        local box, boxRow, boxCol = boxData[1], boxData[2], boxData[3]
        print("[EXPLOSION] Destroying box at", boxRow, boxCol)
        self:startBoxDestruction(box, boxRow, boxCol)
    end
    
    -- Step 3: Check for player damage
    self:checkPlayerDamage(explosionPositions)
    
    -- Step 4: Create all explosion effects
    print("[EXPLOSION] Creating", #explosionPositions, "explosion effects")
    for _, pos in ipairs(explosionPositions) do
        local posRow, posCol = pos[1], pos[2]
        self:createExplosionPart(posRow, posCol)
    end
    
    print("[EXPLOSION] Explosion complete")
end

function GameState:checkPlayerDamage(explosionPositions)
    if not self.player or not self.player.active then return end
    
    local playerGridPos = self.player:getComponent("gridPosition")
    if not playerGridPos then return end
    
    -- Check if player has invincibility
    local invincibility = self.player:getComponent("invincibility")
    if invincibility and invincibility:isInvincible() then
        print("[DAMAGE] Player is invincible, no damage taken")
        return
    end
    
    -- Check if player is already dying
    local death = self.player:getComponent("death")
    if death and death.isDying then
        print("[DAMAGE] Player is already dying, no additional damage")
        return
    end
    
    -- Check if player is in any explosion position
    for _, pos in ipairs(explosionPositions) do
        local expRow, expCol = pos[1], pos[2]
        if playerGridPos.row == expRow and playerGridPos.col == expCol then
            print("[DAMAGE] Player hit by explosion at", expRow, expCol)
            self:damagePlayer()
            return
        end
    end
end

function GameState:damagePlayer()
    if not self.player then return end
    
    -- Lose a life
    self.lives = self.lives - 1
    print("[DAMAGE] Player damaged! Lives remaining:", self.lives)
    
    if self.lives <= 0 then
        print("[GAME] Game Over!")
        self.gameOver = true
        return
    end
    
    -- Start death animation
    local Death = require("src.components.death")
    local death = Death:new(1.5) -- 1.5 second death animation
    death:start()
    self.player:addComponent("death", death)
    
    -- Add entity to systems to handle death animation
    self.world:addEntityToSystems(self.player)
    
    print("[DAMAGE] Started death animation")
end

function GameState:isPositionBlocked(row, col)
    -- Check for indestructible walls
    local indestructibleWalls = self.world:getEntitiesWithTag("indestructible")
    for _, wall in ipairs(indestructibleWalls) do
        local wallPos = wall:getComponent("gridPosition")
        if wallPos and wallPos.row == row and wallPos.col == col then
            return true
        end
    end
    
    -- Check for outer walls (but skip boxes)
    local outerWalls = self.world:getEntitiesWithTag("wall")
    for _, wall in ipairs(outerWalls) do
        if not wall:hasTag("box") and not wall:hasTag("destroyed_box") then
            local wallPos = wall:getComponent("gridPosition")
            if wallPos and wallPos.row == row and wallPos.col == col then
                return true
            end
        end
    end
    
    return false
end

function GameState:hasDestructibleBoxAt(row, col)
    local boxes = self.world:getEntitiesWithTag("box")
    for _, box in ipairs(boxes) do
        local boxPos = box:getComponent("gridPosition")
        if boxPos and boxPos.row == row and boxPos.col == col and box.active then
            return true
        end
    end
    return false
end

function GameState:getAllActiveBoxesAt(row, col)
    local boxes = self.world:getEntitiesWithTag("box")
    local boxesAtPosition = {}
    
    for _, box in ipairs(boxes) do
        local boxPos = box:getComponent("gridPosition")
        if boxPos and boxPos.row == row and boxPos.col == col and box.active and not box:hasComponent("destruction") then
            table.insert(boxesAtPosition, box)
        end
    end
    
    return boxesAtPosition
end

function GameState:getActiveBoxAt(row, col)
    local boxes = self:getAllActiveBoxesAt(row, col)
    
    if #boxes > 1 then
        print("[BOX CHECK] WARNING: Found", #boxes, "boxes at position", row, col, "- will destroy all")
    end
    
    -- Return the first box, but the explosion system should handle all boxes
    return boxes[1]
end

function GameState:createExplosionPart(row, col)
    local Entity = require("src.ecs.entity")
    local Transform = require("src.components.transform")
    local GridPosition = require("src.components.gridposition")
    local Lifetime = require("src.components.lifetime")
    
    local explosion = self.world:createEntity()
    explosion:addTag("explosion")
    
    explosion:addComponent("transform", Transform:new(0, 0, 0, 0))
    explosion:addComponent("gridPosition", GridPosition:new(row, col))
    explosion:addComponent("lifetime", Lifetime:new(Config.EXPLOSION_DURATION))

    -- Add entity to systems after all initial components are added
    self.world:addEntityToSystems(explosion)
    
    return explosion
end

function GameState:startBoxDestruction(box, row, col)
    print("[BOX DESTROY] Starting destruction for box", box.id, "at", row, col)
    
    -- Check if already being destroyed or inactive
    if not box.active or box:hasComponent("destruction") then
        print("[BOX DESTROY] Box already destroyed or has destruction component - skipping")
        return
    end
    
    -- Start destruction animation
    local Destruction = require("src.components.destruction")
    local destruction = Destruction:new(0.3) -- 0.3 second animation
    box:addComponent("destruction", destruction)
    destruction:start()
    
    -- CRITICAL FIX: Add entity to systems now that it has destruction component
    self.world:addEntityToSystems(box)
    
    -- Immediately destroy the box for game logic
    self:completeBoxDestruction(box, row, col)
    print("[BOX DESTROY] Completed destruction setup for box", box.id)
end

function GameState:completeBoxDestruction(box, row, col)
    -- DON'T set active = false yet! Let the destruction animation finish first
    -- box.active = false  -- REMOVED - this was preventing system updates
    
    -- Remove from collision and detection systems immediately
    if box:hasComponent("collision") then
        box:removeComponent("collision")
    end
    
    -- Remove box tag so it's no longer found by explosion system
    box:removeTag("box")
    -- Add a destroyed tag so rendering system still draws it during animation
    box:addTag("destroyed_box")
    
    -- Schedule actual removal after animation
    local Lifetime = require("src.components.lifetime")
    box:addComponent("lifetime", Lifetime:new(0.3)) -- Remove after animation
    self.world:addEntityToSystems(box) -- Ensure lifetime system gets the entity
    
    self.score = self.score + 10
    
    -- Chance to drop power-up
    if love.math.random() < Config.POWERUP_DROP_CHANCE then
        self:createPowerUp(row, col)
    end
end

function GameState:destroyBox(box, row, col)
    -- Legacy function for backwards compatibility
    self:startBoxDestruction(box, row, col)
end

function GameState:createPowerUp(row, col)
    local Entity = require("src.ecs.entity")
    local Transform = require("src.components.transform")
    local GridPosition = require("src.components.gridposition")
    local PowerUp = require("src.components.powerup")
    
    local types = {"heart", "speed", "ammo", "range"}
    local type = types[love.math.random(1, #types)]
    
    local powerup = self.world:createEntity()
    powerup:addTag("powerup")
    
    powerup:addComponent("transform", Transform:new(0, 0, 0, 0))
    powerup:addComponent("gridPosition", GridPosition:new(row, col))
    powerup:addComponent("powerup", PowerUp:new(type))

    -- Add entity to systems after all initial components are added
    self.world:addEntityToSystems(powerup)
    
    return powerup
end

function GameState:draw()
    -- Clear screen
    love.graphics.clear(Config.COLORS.BACKGROUND)
    
    -- Draw grid background
    self:drawGridBackground()
    
    -- Draw world 
    if self.world then
        self.world:draw()
    end
    
    -- Draw UI
    self:drawUI()
    
    -- Draw touch controls
    self.inputManager:drawTouchControls()
    
    -- Draw pause overlay
    if self.paused then
        self:drawPauseOverlay()
    end
    
    -- Draw game over overlay
    if self.gameOver then
        self:drawGameOverScreen()
    end
end

function GameState:drawGridBackground()
    local bounds = self.gridSystem:getGridBounds()
    local tileSize = self.gridSystem:getTileSize()
    
    -- Draw floor tiles for background
    local floorImage = self.assetManager:getImage("floor")
    if floorImage then
        love.graphics.setColor(1, 1, 1)
        for row = 0, Config.GRID_ROWS - 1 do
            for col = 0, Config.GRID_COLS - 1 do
                local x = bounds.left + (col * tileSize)
                local y = bounds.top + (row * tileSize)
                love.graphics.draw(floorImage, x, y, 0, tileSize / floorImage:getWidth(), tileSize / floorImage:getHeight())
            end
        end
    else
        -- Fallback to colored rectangle if image not found
        love.graphics.setColor(Config.COLORS.FLOOR)
        love.graphics.rectangle("fill",
            bounds.left, bounds.top,
            bounds.width, bounds.height)
    end
    
    -- Draw grid lines (subtle)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.2)
    for row = 0, Config.GRID_ROWS do
        local y = bounds.top + (row * tileSize)
        love.graphics.line(bounds.left, y, bounds.right, y)
    end
    
    for col = 0, Config.GRID_COLS do
        local x = bounds.left + (col * tileSize)
        love.graphics.line(x, bounds.top, x, bounds.bottom)
    end
end

function GameState:drawUI()
    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    love.graphics.setColor(Config.COLORS.TEXT)
    
    -- Game stats
    love.graphics.print("Score: " .. self.score, 10, 10)
    love.graphics.print("Lives: " .. self.lives, 10, 30)
    love.graphics.print("Health: " .. self.health, 10, 50)
    love.graphics.print("Bombs: " .. self.bombs .. "/" .. self.maxBombs, 10, 70)
    love.graphics.print("Range: " .. self.range, 10, 90)
    love.graphics.print("Speed: " .. string.format("%.1f", self.speed), 10, 110)
    love.graphics.print("Time: " .. string.format("%.1f", self.gameTime), 10, 130)
    love.graphics.print("Drop Rate: " .. string.format("%.0f%%", Config.POWERUP_DROP_CHANCE * 100), 10, 150)
    
    -- Controls hint
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("WASD/Arrows: Move | Space: Bomb | P: Pause | +/-: Drop Rate", 10, love.graphics.getHeight() - 30)
end

function GameState:drawGameOverScreen()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Game Over title
    love.graphics.setColor(1, 0.2, 0.2) -- Red color
    local titleFont = love.graphics.newFont(48)
    love.graphics.setFont(titleFont)
    
    local title = "GAME OVER"
    local titleWidth = titleFont:getWidth(title)
    local titleHeight = titleFont:getHeight()
    local centerX = love.graphics.getWidth() / 2 - titleWidth / 2
    local centerY = love.graphics.getHeight() / 2 - 100
    
    love.graphics.print(title, centerX, centerY)
    
    -- Final score
    love.graphics.setColor(1, 1, 1) -- White color
    local scoreFont = love.graphics.newFont(24)
    love.graphics.setFont(scoreFont)
    
    local scoreText = "Final Score: " .. self.score
    local scoreWidth = scoreFont:getWidth(scoreText)
    love.graphics.print(scoreText, love.graphics.getWidth() / 2 - scoreWidth / 2, centerY + 80)
    
    -- Instructions
    love.graphics.setFont(love.graphics.newFont(16))
    local instructions = {
        "Press SPACE, R, or ENTER to return to menu",
        "",
        "Stats:",
        "Time Played: " .. string.format("%.1f", self.gameTime) .. "s",
        "Powerup Drop Rate: " .. string.format("%.0f%%", Config.POWERUP_DROP_CHANCE * 100)
    }
    
    for i, instruction in ipairs(instructions) do
        local instrWidth = love.graphics.getFont():getWidth(instruction)
        love.graphics.print(instruction, love.graphics.getWidth() / 2 - instrWidth / 2, centerY + 120 + (i * 25))
    end
end

function GameState:drawPauseOverlay()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, love.graphics.getHeight() / 2 - 20, 
        love.graphics.getWidth(), "center")
    love.graphics.printf("Press P to resume", 0, love.graphics.getHeight() / 2 + 10, 
        love.graphics.getWidth(), "center")
end

function GameState:resize(w, h)
    if self.gridSystem then
        self.gridSystem:resize(w, h)
    end
    self.inputManager:resize(w, h)
end

function GameState:keypressed(key)
    -- Handle powerup drop chance adjustment
    if key == "=" or key == "+" then
        Config.POWERUP_DROP_CHANCE = math.min(Config.POWERUP_DROP_CHANCE + 0.1, 1.0)
        print("[CONFIG] Powerup drop chance increased to:", string.format("%.1f%%", Config.POWERUP_DROP_CHANCE * 100))
    elseif key == "-" then
        Config.POWERUP_DROP_CHANCE = math.max(Config.POWERUP_DROP_CHANCE - 0.1, 0.0)
        print("[CONFIG] Powerup drop chance decreased to:", string.format("%.1f%%", Config.POWERUP_DROP_CHANCE * 100))
    end
    
    self.inputManager:keypressed(key)
end

function GameState:handleGameOverInput(dt)
    -- Check for return to menu input
    if self.inputManager:isActionPressed("bomb") or -- Space key
       self.inputManager:isActionPressed("restart") or -- R key
       love.keyboard.isDown("return") then
        self.shouldTransition = true
        self.nextState = "menu"
    end
end

function GameState:keyreleased(key)
    self.inputManager:keyreleased(key)
end

function GameState:touchpressed(id, x, y, dx, dy, pressure)
    self.inputManager:touchpressed(id, x, y, dx, dy, pressure)
end

function GameState:touchreleased(id, x, y, dx, dy, pressure)
    self.inputManager:touchreleased(id, x, y, dx, dy, pressure)
end

function GameState:touchmoved(id, x, y, dx, dy, pressure)
    self.inputManager:touchmoved(id, x, y, dx, dy, pressure)
end

function GameState:gamepadpressed(joystick, button)
    -- Handle gamepad input
end

function GameState:restart()
    self:exit()
    self:enter()
    self.gameTime = 0
    self.paused = false
end

return GameState