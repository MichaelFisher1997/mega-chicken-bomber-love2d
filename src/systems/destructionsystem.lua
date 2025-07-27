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
    if #self.entities > 0 then
        print("[DESTRUCTION SYS] Processing", #self.entities, "entities")
    end
    for _, entity in pairs(self.entities) do
        local destruction = entity:getComponent("destruction")
        if destruction then
            destruction:update(dt)
            print("[DESTRUCTION SYS] Entity", entity.id, "progress:", destruction:getProgress(), "destroying:", destruction.isDestroying)
            
            -- Check if destruction is complete
            if not destruction.isDestroying and destruction.elapsed >= destruction.duration then
                print("[DESTRUCTION SYS] Destruction complete for entity", entity.id)
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

return DestructionSystem