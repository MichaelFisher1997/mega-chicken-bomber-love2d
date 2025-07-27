-- Timer system for handling countdowns and timed events

local System = require("src.ecs.system")

local TimerSystem = setmetatable({}, {__index = System})
TimerSystem.__index = TimerSystem

function TimerSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.requirements = {"timer"}
    
    return system
end

function TimerSystem:update(dt)
    for _, entity in pairs(self.entities) do
        if entity.active then
            local timer = entity:getComponent("timer")
            if timer then
                timer:update(dt)
                
                -- Remove entity when timer expires
                if not timer.active then
                    entity.active = false
                end
            end
        end
    end
end

function TimerSystem:draw()
    -- Timer system doesn't need to draw anything
end

return TimerSystem