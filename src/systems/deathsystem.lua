-- Death system handles player death animations and respawning
local DeathSystem = {}
DeathSystem.__index = DeathSystem

function DeathSystem:new()
    local system = {
        requiredComponents = {"death"},
        entities = {}
    }
    setmetatable(system, self)
    return system
end

function DeathSystem:addEntity(entity)
    -- Check if entity has required components
    local hasRequired = true
    for _, component in ipairs(self.requiredComponents) do
        if not entity:hasComponent(component) then
            hasRequired = false
            break
        end
    end
    
    if hasRequired then
        self.entities[entity.id] = entity
    end
end

function DeathSystem:removeEntity(entity)
    self.entities[entity.id] = nil
end

function DeathSystem:update(dt, entities)
    -- Use system's own entities list
    for _, entity in pairs(self.entities) do
        if entity.active and entity:hasComponent("death") then
            local death = entity:getComponent("death")
            death:update(dt)
            
            -- Check if death animation is complete
            if death:isComplete() then
                self:handlePlayerRespawn(entity)
            end
        end
    end
end

function DeathSystem:handlePlayerRespawn(player)
    if not player:hasTag("player") then return end
    
    print("[DEATH] Player death animation complete, respawning...")
    
    -- Remove death component
    player:removeComponent("death")
    
    -- Reset player position to spawn point (1, 1)
    local gridPos = player:getComponent("gridPosition")
    if gridPos then
        gridPos.row = 1
        gridPos.col = 1
        print("[DEATH] Player respawned at position", gridPos.row, gridPos.col)
    end
    
    -- Reset transform to grid position
    local transform = player:getComponent("transform")
    if transform and self.gridSystem then
        local tileSize = self.gridSystem.tileSize
        local offsetX = self.gridSystem.gridOffsetX
        local offsetY = self.gridSystem.gridOffsetY
        
        transform.x = offsetX + gridPos.col * tileSize
        transform.y = offsetY + gridPos.row * tileSize
    end
    
    -- Reset player powerups to starting values
    self:resetPlayerPowerups(player)
    
    -- Add invincibility for 2 seconds
    local Invincibility = require("src.components.invincibility")
    local invincibility = Invincibility:new(2.0) -- 2 seconds of invincibility
    invincibility:start()
    player:addComponent("invincibility", invincibility)
    
    -- Make sure player is active and visible
    player.active = true
    
    -- Add back to systems to handle invincibility
    if self.world then
        self.world:addEntityToSystems(player)
    end
    
    print("[DEATH] Player respawn complete with 2s invincibility")
end

function DeathSystem:setWorld(world)
    self.world = world
end

function DeathSystem:setGridSystem(gridSystem)
    self.gridSystem = gridSystem
end

function DeathSystem:setGameState(gameState)
    self.gameState = gameState
end

function DeathSystem:resetPlayerPowerups(player)
    if not self.gameState then return end
    
    local Config = require("src.config")
    
    -- Reset all powerup values to starting values
    self.gameState.health = Config.PLAYER_START_HEALTH
    self.gameState.speed = Config.PLAYER_SPEED
    self.gameState.maxBombs = Config.PLAYER_START_BOMBS
    self.gameState.bombs = Config.PLAYER_START_BOMBS
    self.gameState.range = Config.PLAYER_START_RANGE
    
    -- Reset player movement speed component
    if player:hasComponent("movement") then
        local movement = player:getComponent("movement")
        movement.speed = Config.PLAYER_SPEED
        movement.moveSpeed = Config.PLAYER_SPEED
    end
    
    print("[DEATH] Reset powerups: Health=" .. self.gameState.health .. 
          ", Speed=" .. self.gameState.speed .. 
          ", Bombs=" .. self.gameState.maxBombs .. 
          ", Range=" .. self.gameState.range)
end

function DeathSystem:draw()
    -- Death system doesn't need to draw anything
end

return DeathSystem