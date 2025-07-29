-- Destruction system for handling destruction animations

local System = require("src.ecs.system")

local DestructionSystem = {}
setmetatable(DestructionSystem, {__index = System})

function DestructionSystem:new()
    local system = System:new()
    setmetatable(system, {__index = self})
    
    system.requirements = {"destruction"}
    
    return system
end

function DestructionSystem:update(dt)
    for _, entity in pairs(self.entities) do
        local destruction = entity:getComponent("destruction")
        if destruction then
            destruction:update(dt)
            
            -- Check if destruction is complete
            if not destruction.isDestroying and destruction.elapsed >= destruction.duration then
                -- Call completion callback if it exists
                if destruction.onComplete then
                    destruction.onComplete()
                end
                -- Remove the destruction component
                entity:removeComponent("destruction")
            end
        end
    end
end

function DestructionSystem:draw()
    -- Destruction system doesn't need to draw anything
end

function DestructionSystem:clear()
    -- Destruction system doesn't maintain entity lists
end

return DestructionSystem