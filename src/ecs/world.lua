-- World class for ECS architecture
-- Manages all entities and systems

local World = {}
World.__index = World

function World:new()
    local world = {
        entities = {},
        systems = {},
        entityCount = 0,
        active = true
    }
    setmetatable(world, self)
    return world
end

function World:createEntity()
    self.entityCount = self.entityCount + 1
    local Entity = require("src.ecs.entity")
    local entity = Entity:new(self.entityCount)
    self.entities[entity.id] = entity
    return entity
end

function World:destroyEntity(entity)
    if self.entities[entity.id] then
        entity:destroy()
        self.entities[entity.id] = nil
        
        -- Remove from all systems
        for _, system in ipairs(self.systems) do
            system:removeEntity(entity)
        end
    end
end

function World:addSystem(system)
    table.insert(self.systems, system)
    
    -- Add existing entities to new system
    for _, entity in pairs(self.entities) do
        system:addEntity(entity)
    end
    
    return system
end

function World:removeSystem(system)
    for i, s in ipairs(self.systems) do
        if s == system then
            table.remove(self.systems, i)
            system:clear()
            break
        end
    end
end

function World:update(dt)
    if not self.active then return end
    
    -- Update all systems
    for _, system in ipairs(self.systems) do
        system:update(dt)
    end
    
    -- Clean up destroyed entities
    local toRemove = {}
    for id, entity in pairs(self.entities) do
        if not entity.active then
            table.insert(toRemove, id)
        end
    end
    
    for _, id in ipairs(toRemove) do
        self:destroyEntity(self.entities[id])
    end
end

function World:draw()
    if not self.active then return end
    
    -- Draw all systems in order
    for _, system in ipairs(self.systems) do
        system:draw()
    end
end

function World:getEntitiesWithComponent(componentType)
    local result = {}
    for _, entity in pairs(self.entities) do
        if entity:hasComponent(componentType) and entity.active then
            table.insert(result, entity)
        end
    end
    return result
end

function World:getEntitiesWithTag(tag)
    local result = {}
    for _, entity in pairs(self.entities) do
        if entity:hasTag(tag) and entity.active then
            table.insert(result, entity)
        end
    end
    return result
end

function World:clear()
    -- Destroy all entities
    for _, entity in pairs(self.entities) do
        entity:destroy()
    end
    
    -- Clear all systems
    for _, system in ipairs(self.systems) do
        system:clear()
    end
    
    self.entities = {}
    self.systems = {}
    self.entityCount = 0
end

return World