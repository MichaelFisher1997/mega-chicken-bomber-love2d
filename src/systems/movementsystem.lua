-- Movement system for handling entity movement and collision

local System = require("src.ecs.system")
local Config = require("src.config")

local MovementSystem = setmetatable({}, {__index = System})
MovementSystem.__index = MovementSystem

function MovementSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.requirements = {"transform", "movement", "gridPosition"}
    system.moveCooldown = 0
    system.moveDelay = 0.15 -- seconds between moves
    
    return system
end

function MovementSystem:update(dt)
    self.moveCooldown = math.max(0, self.moveCooldown - dt)
    
    -- Process all entities with movement
    for _, entity in pairs(self.entities) do
        if entity.active then
            self:processEntity(entity, dt)
        end
    end
end

function MovementSystem:processEntity(entity, dt)
    local transform = entity:getComponent("transform")
    local movement = entity:getComponent("movement")
    local gridPos = entity:getComponent("gridPosition")
    
    -- Handle input for player
    if entity:hasTag("player") then
        self:handlePlayerMovement(entity)
    end
    
    -- Update position based on velocity
    if movement.velocityX ~= 0 or movement.velocityY ~= 0 then
        self:moveEntity(entity, movement.velocityX, movement.velocityY)
    end
end

function MovementSystem:handlePlayerMovement(entity)
    local movement = entity:getComponent("movement")
    local inputManager = self.inputManager
    
    if not inputManager then return end
    
    local moveX, moveY = inputManager:getMovement()
    
    if moveX ~= 0 or moveY ~= 0 then
        -- Determine direction
        if math.abs(moveX) > math.abs(moveY) then
            movement:setDirection(moveX > 0 and "right" or "left")
        else
            movement:setDirection(moveY > 0 and "down" or "up")
        end
        
        -- Set velocity for next move
        movement:setVelocity(moveX, moveY)
    else
        movement:stop()
    end
end

function MovementSystem:moveEntity(entity, dx, dy)
    if self.moveCooldown > 0 then return end
    
    local gridPos = entity:getComponent("gridPosition")
    local movement = entity:getComponent("movement")
    
    -- Calculate new grid position
    local newRow = gridPos.row + dy
    local newCol = gridPos.col + dx
    
    -- Check bounds
    if newRow < 0 or newRow >= Config.GRID_ROWS or 
       newCol < 0 or newCol >= Config.GRID_COLS then
        return
    end
    
    -- Check for collisions with walls
    if self:canMoveTo(newRow, newCol, entity) then
        -- Move to new position
        gridPos:setPosition(newRow, newCol)
        self.moveCooldown = self.moveDelay
        
        -- Check for power-up collection
        self:checkPowerUpCollection(entity, newRow, newCol)
    end
    
    -- Reset velocity after move
    movement:stop()
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

function MovementSystem:collectPowerUp(player, powerup)
    local powerupComp = powerup:getComponent("powerup")
    if not powerupComp then return end
    
    -- Apply power-up effect
    local gameState = self.gameState
    if not gameState then return end
    
    if powerupComp.type == "bomb" then
        gameState.maxBombs = math.min(gameState.maxBombs + 1, Config.PLAYER_MAX_BOMBS)
        gameState.bombs = gameState.maxBombs
    elseif powerupComp.type == "range" then
        gameState.range = math.min(gameState.range + 1, Config.PLAYER_MAX_RANGE)
    end
    
    gameState.score = gameState.score + 50
    
    -- Remove power-up
    powerup.active = false
end

function MovementSystem:setInputManager(inputManager)
    self.inputManager = inputManager
end

function MovementSystem:setWorld(world)
    self.world = world
end

function MovementSystem:setGameState(gameState)
    self.gameState = gameState
end

return MovementSystem