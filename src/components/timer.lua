-- Timer component for countdown functionality

local Timer = {}
Timer.__index = Timer

function Timer:new(duration, callback)
    local timer = {
        duration = duration or 1.0,
        remaining = duration or 1.0,
        callback = callback,
        active = true,
        entity = nil
    }
    setmetatable(timer, self)
    return timer
end

function Timer:update(dt)
    if not self.active then return end
    
    self.remaining = self.remaining - dt
    
    if self.remaining <= 0 then
        self.active = false
        if self.callback then
            self.callback()
        end
    end
end

function Timer:reset()
    self.remaining = self.duration
    self.active = true
end

return Timer