-- Animation system handles sprite-based animations
local AnimationSystem = {}
AnimationSystem.__index = AnimationSystem

function AnimationSystem:new()
    local system = {
        requiredComponents = {"animation"},
        entities = {}
    }
    setmetatable(system, self)
    return system
end

function AnimationSystem:addEntity(entity)
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

function AnimationSystem:removeEntity(entity)
    self.entities[entity.id] = nil
end

function AnimationSystem:update(dt, entities)
    -- Use system's own entities list
    for _, entity in pairs(self.entities) do
        if entity.active and entity:hasComponent("animation") then
            local animation = entity:getComponent("animation")
            animation:update(dt)
            
            -- Update animation based on movement
            if entity:hasComponent("movement") then
                self:updateMovementAnimation(entity)
            end
        end
    end
end

function AnimationSystem:updateMovementAnimation(entity)
    local movement = entity:getComponent("movement")
    local animation = entity:getComponent("animation")
    
    if not movement or not animation then return end
    
    -- Only update direction when there's actual input
    if movement.inputX ~= 0 or movement.inputY ~= 0 then
        local direction = "down" -- default
        if movement.inputY < 0 then
            direction = "up"
        elseif movement.inputY > 0 then
            direction = "down"
        elseif movement.inputX < 0 then
            direction = "left"
        elseif movement.inputX > 0 then
            direction = "right"
        end
        
        -- Update the stored direction
        animation.direction = direction
    end
    
    -- Set animation based on movement state, using the stored direction
    if movement.isMoving then
        animation:setAnimation("walk", animation.direction)
    else
        animation:setAnimation("idle", animation.direction)
    end
end

function AnimationSystem:draw()
    -- Animation system doesn't need to draw anything
end

function AnimationSystem:clear()
    self.entities = {}
end

return AnimationSystem