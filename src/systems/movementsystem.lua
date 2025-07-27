-- Movement system for handling entity movement and collision

local System = require("src.ecs.system")
local Config = require("src.config")

local MovementSystem = {}
setmetatable(MovementSystem, {__index = System})

function MovementSystem:new()
    local system = System:new()
    setmetatable(system, {__index = self})
    
    system.requirements = {"movement", "gridPosition", "transform"}
    system.inputManager = nil
    system.gridSystem = nil
    
    return system
end

function MovementSystem:update(dt)
    -- Process all entities with movement
    for _, entity in pairs(self.entities) do
        self:processEntity(entity, dt)
    end
end

function MovementSystem:processEntity(entity, dt)
    local transform = entity:getComponent("transform")
    local movement = entity:getComponent("movement")
    local gridPos = entity:getComponent("gridPosition")
    
    -- Handle input for player (only if not dying)
    if entity:hasTag("player") then
        local death = entity:getComponent("death")
        local invincibility = entity:getComponent("invincibility")
        
        -- Only allow movement and interaction if not dying
        if not (death and death.isDying) then
            self:handlePlayerMovement(entity, dt)
            
            -- Check for power-up collection during movement (not just on completion)
            self:checkPowerUpCollectionContinuous(entity)
        end
    end
    
    -- Update movement interpolation (always, even during death for smooth animations)
    self:updateMovementInterpolation(entity, dt)
end

function MovementSystem:handlePlayerMovement(entity, dt)
    local movement = entity:getComponent("movement")
    local inputManager = self.inputManager
    local gridPos = entity:getComponent("gridPosition")
    
    if not inputManager then return end
    
    local moveX, moveY = inputManager:getMovement()
    
    -- Update current input direction
    movement.inputX = moveX
    movement.inputY = moveY
    
    -- Set facing direction immediately for responsiveness
    if moveX ~= 0 or moveY ~= 0 then
        if math.abs(moveX) > math.abs(moveY) then
            movement:setDirection(moveX > 0 and "right" or "left")
        else
            movement:setDirection(moveY > 0 and "down" or "up")
        end
    end
    
    -- Start new movement if not currently moving and input detected
    if not movement.isMoving and (moveX ~= 0 or moveY ~= 0) then
        self:startMovement(entity, moveX, moveY)
    end
end

function MovementSystem:startMovement(entity, dx, dy)
    local gridPos = entity:getComponent("gridPosition")
    local movement = entity:getComponent("movement")
    
    -- Prioritize movement direction (no diagonal movement)
    if math.abs(dx) > math.abs(dy) then
        dx = dx > 0 and 1 or dx < 0 and -1 or 0
        dy = 0
    else
        dy = dy > 0 and 1 or dy < 0 and -1 or 0
        dx = 0
    end
    
    -- Calculate target grid position
    local newRow = gridPos.row + dy
    local newCol = gridPos.col + dx
    
    -- Check bounds
    if newRow < 0 or newRow >= Config.GRID_ROWS or 
       newCol < 0 or newCol >= Config.GRID_COLS then
        return
    end
    
    -- Check for collisions
    if not self:canMoveTo(newRow, newCol, entity) then
        return
    end
    
    -- Start movement
    movement.isMoving = true
    movement.targetRow = newRow
    movement.targetCol = newCol
    movement.startRow = gridPos.row
    movement.startCol = gridPos.col
    movement.moveProgress = 0
    movement.moveSpeed = movement.speed or Config.PLAYER_SPEED
end

function MovementSystem:updateMovementInterpolation(entity, dt)
    local movement = entity:getComponent("movement")
    local gridPos = entity:getComponent("gridPosition")
    local transform = entity:getComponent("transform")
    
    if not movement.isMoving then 
        -- Ensure transform matches grid position when not moving
        if self.gridSystem then
            transform.x = self.gridSystem.gridOffsetX + (gridPos.col * self.gridSystem.tileSize)
            transform.y = self.gridSystem.gridOffsetY + (gridPos.row * self.gridSystem.tileSize)
        end
        return 
    end
    
    -- Safety check for movement data
    if not movement.targetRow or not movement.targetCol or not movement.startRow or not movement.startCol then
        movement.isMoving = false
        return
    end
    
    -- Update movement progress
    movement.moveProgress = movement.moveProgress + (movement.moveSpeed * dt)
    
    if movement.moveProgress >= 1.0 then
        -- Movement complete
        movement.moveProgress = 1.0
        gridPos:setPosition(movement.targetRow, movement.targetCol)
        
        -- Check for power-up collection
        self:checkPowerUpCollection(entity, movement.targetRow, movement.targetCol)
        
        -- Reset movement state
        movement.isMoving = false
        movement.targetRow = nil
        movement.targetCol = nil
        movement.startRow = nil
        movement.startCol = nil
        
        -- Check if player wants to continue moving
        if entity:hasTag("player") and (movement.inputX ~= 0 or movement.inputY ~= 0) then
            self:startMovement(entity, movement.inputX, movement.inputY)
        end
    end
    
    -- Update visual position with smooth interpolation
    if self.gridSystem and movement.moveProgress < 1.0 then
        local t = self:easeInOutCubic(movement.moveProgress)
        local currentRow = movement.startRow + (movement.targetRow - movement.startRow) * t
        local currentCol = movement.startCol + (movement.targetCol - movement.startCol) * t
        
        transform.x = self.gridSystem.gridOffsetX + (currentCol * self.gridSystem.tileSize)
        transform.y = self.gridSystem.gridOffsetY + (currentRow * self.gridSystem.tileSize)
    end
end

function MovementSystem:easeInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local p = 2 * t - 2
        return 1 + p * p * p / 2
    end
end

function MovementSystem:canMoveTo(row, col, movingEntity)
    -- Check for solid entities at target position
    local world = self.world
    if not world then return true end
    
    local entities = world:getEntitiesWithComponent("gridPosition")
    
    for _, entity in ipairs(entities) do
        if entity ~= movingEntity and entity.active then
            local gridPos = entity:getComponent("gridPosition")
            if gridPos.row == row and gridPos.col == col then
                -- Check if entity is solid
                if entity:hasTag("wall") or entity:hasTag("box") then
                    return false
                end
            end
        end
    end
    
    return true
end

function MovementSystem:checkPowerUpCollection(player, row, col)
    local world = self.world
    if not world then return end
    
    local entities = world:getEntitiesWithTag("powerup")
    
    for _, powerup in ipairs(entities) do
        if powerup.active then
            local gridPos = powerup:getComponent("gridPosition")
            if gridPos.row == row and gridPos.col == col then
                -- Collect power-up
                self:collectPowerUp(player, powerup)
                break
            end
        end
    end
end

function MovementSystem:checkPowerUpCollectionContinuous(player)
    local world = self.world
    if not world then return end
    
    local playerGridPos = player:getComponent("gridPosition")
    local playerTransform = player:getComponent("transform")
    local playerCollision = player:getComponent("collision")
    
    if not playerGridPos or not playerTransform or not playerCollision then return end
    
    local entities = world:getEntitiesWithTag("powerup")
    
    for _, powerup in ipairs(entities) do
        if powerup.active then
            local powerupGridPos = powerup:getComponent("gridPosition")
            local powerupTransform = powerup:getComponent("transform")
            
            if powerupGridPos and powerupTransform then
                -- Only check if player is on the same grid position
                local sameGrid = playerGridPos.row == powerupGridPos.row and playerGridPos.col == powerupGridPos.col
                
                if sameGrid then
                    -- Check pixel-level collision for precise pickup within the same tile
                    local dx = math.abs(playerTransform.x - powerupTransform.x)
                    local dy = math.abs(playerTransform.y - powerupTransform.y)
                    local tileSize = self.gridSystem and self.gridSystem.tileSize or 30
                    
                    -- Use smaller threshold: allow pickup within 0.7 tile sizes (within same tile only)
                    local threshold = tileSize * 0.7
                    
                    if dx < threshold and dy < threshold then
                        self:collectPowerUp(player, powerup)
                        break
                    end
                end
            end
        end
    end
end

function MovementSystem:collectPowerUp(player, powerup)
    local powerupComp = powerup:getComponent("powerup")
    if not powerupComp then 
        print("[POWERUP] No powerup component!")
        return 
    end
    
    -- Check if already collected (prevent double-collection)
    if not powerup.active then 
        print("[POWERUP] Already inactive!")
        return 
    end
    
    print("[POWERUP] Successfully collected:", powerupComp.type)
    
    -- Apply power-up effect
    local gameState = self.gameState
    if not gameState then 
        print("[POWERUP] No game state!")
        return 
    end
    
    if powerupComp.type == "heart" then
        gameState.health = math.min(gameState.health + 1, Config.PLAYER_MAX_HEALTH)
        print("[POWERUP] Health now:", gameState.health)
    elseif powerupComp.type == "speed" then
        gameState.speed = math.min(gameState.speed + Config.SPEED_POWERUP_INCREASE, Config.PLAYER_MAX_SPEED)
        -- Update the player's movement component with new speed
        if gameState.player and gameState.player:hasComponent("movement") then
            local playerMovement = gameState.player:getComponent("movement")
            playerMovement.speed = gameState.speed
            playerMovement.moveSpeed = gameState.speed
        end
        print("[POWERUP] Speed now:", gameState.speed)
    elseif powerupComp.type == "ammo" then
        gameState.maxBombs = math.min(gameState.maxBombs + 1, Config.PLAYER_MAX_BOMBS)
        gameState.bombs = gameState.maxBombs
        print("[POWERUP] Bomb count now:", gameState.maxBombs)
    elseif powerupComp.type == "range" then
        gameState.range = math.min(gameState.range + 1, Config.PLAYER_MAX_RANGE)
        print("[POWERUP] Range now:", gameState.range)
    end
    
    gameState.score = gameState.score + 50
    
    -- Properly destroy the powerup entity
    if self.world then
        print("[POWERUP] Destroying entity via world")
        self.world:destroyEntity(powerup)
    else
        print("[POWERUP] Setting inactive")
        powerup.active = false
    end
end

function MovementSystem:setInputManager(inputManager)
    self.inputManager = inputManager
end

function MovementSystem:setWorld(world)
    self.world = world
end

function MovementSystem:setGameState(gameState)
    self.gameState = gameState
    if gameState and gameState.gridSystem then
        self.gridSystem = gameState.gridSystem
    end
end

function MovementSystem:draw()
    -- Movement system doesn't need to draw anything
end

function MovementSystem:clear()
    -- Movement system doesn't maintain entity lists
end

return MovementSystem