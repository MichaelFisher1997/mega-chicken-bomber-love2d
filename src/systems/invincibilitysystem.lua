-- Invincibility system handles temporary immunity and flickering effects
local InvincibilitySystem = {}
InvincibilitySystem.__index = InvincibilitySystem

function InvincibilitySystem:new()
    local system = {
        requiredComponents = {"invincibility"},
        entities = {}
    }
    setmetatable(system, self)
    return system
end

function InvincibilitySystem:addEntity(entity)
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

function InvincibilitySystem:removeEntity(entity)
    self.entities[entity.id] = nil
end

function InvincibilitySystem:update(dt, entities)
    -- Use system's own entities list
    for _, entity in pairs(self.entities) do
        if entity.active and entity:hasComponent("invincibility") then
            local invincibility = entity:getComponent("invincibility")
            invincibility:update(dt)
            
            -- Remove invincibility component when it expires
            if not invincibility:isInvincible() then
                entity:removeComponent("invincibility")
                self:removeEntity(entity) -- Remove from this system
                print("[INVINCIBILITY] Removed invincibility from entity", entity.id)
            end
        end
    end
end

function InvincibilitySystem:draw()
    -- Invincibility system doesn't need to draw anything
end

function InvincibilitySystem:clear()
    self.entities = {}
end

return InvincibilitySystem