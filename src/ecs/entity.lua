-- Entity class for ECS architecture
-- Represents a game object with components

local Entity = {}
Entity.__index = Entity

function Entity:new(id)
    local entity = {
        id = id or love.math.random(1000000, 9999999),
        components = {},
        active = true,
        tags = {}
    }
    setmetatable(entity, self)
    return entity
end

function Entity:addComponent(componentType, component)
    self.components[componentType] = component
    component.entity = self
    return self
end

function Entity:getComponent(componentType)
    return self.components[componentType]
end

function Entity:hasComponent(componentType)
    return self.components[componentType] ~= nil
end

function Entity:removeComponent(componentType)
    self.components[componentType] = nil
    return self
end

function Entity:addTag(tag)
    self.tags[tag] = true
    return self
end

function Entity:removeTag(tag)
    self.tags[tag] = nil
    return self
end

function Entity:hasTag(tag)
    return self.tags[tag] == true
end

function Entity:destroy()
    self.active = false
    for _, component in pairs(self.components) do
        if component.destroy then
            component:destroy()
        end
    end
end

return Entity