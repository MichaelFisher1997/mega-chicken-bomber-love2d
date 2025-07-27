-- Lifetime system for handling temporary entities

local System = require("src.ecs.system")

local LifetimeSystem = setmetatable({}, {__index = System})
LifetimeSystem.__index = LifetimeSystem

function LifetimeSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.requirements = {"lifetime"}
    
    return system
end

function LifetimeSystem:update(dt)
    for _, entity in pairs(self.entities) do
        if entity.active then
            local lifetime = entity:getComponent("lifetime")
            if lifetime then
                lifetime:update(dt)
                
                -- Remove entity when lifetime expires
                if not lifetime.active then
                    entity.active = false
                end
            end
        end
    end
end

return LifetimeSystem