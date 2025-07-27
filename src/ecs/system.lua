-- System base class for ECS architecture
-- Handles processing of entities with specific component requirements

local System = {}
System.__index = System

function System:new()
    local system = {
        entities = {},
        requirements = {},
        active = true
    }
    setmetatable(system, self)
    return system
end

function System:addEntity(entity)
    if self:meetsRequirements(entity) then
        self.entities[entity.id] = entity
        if self.onEntityAdded then
            self:onEntityAdded(entity)
        end
    end
end

function System:removeEntity(entity)
    if self.entities[entity.id] then
        self.entities[entity.id] = nil
        if self.onEntityRemoved then
            self:onEntityRemoved(entity)
        end
    end
end

function System:meetsRequirements(entity)
    for _, requirement in ipairs(self.requirements) do
        if not entity:hasComponent(requirement) then
            return false
        end
    end
    return true
end

function System:update(dt)
    if not self.active then return end
    
    for _, entity in pairs(self.entities) do
        if entity.active then
            self:processEntity(entity, dt)
        end
    end
end

function System:processEntity(entity, dt)
    -- Override in subclasses
end

function System:draw()
    if not self.active then return end
    
    for _, entity in pairs(self.entities) do
        if entity.active then
            self:drawEntity(entity)
        end
    end
end

function System:drawEntity(entity)
    -- Override in subclasses
end

function System:clear()
    self.entities = {}
end

return System