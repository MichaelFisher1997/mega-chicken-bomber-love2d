-- Lifetime component for temporary entities

local Lifetime = {}
Lifetime.__index = Lifetime

function Lifetime:new(duration)
    local lifetime = {
        duration = duration or 1.0,
        remaining = duration or 1.0,
        active = true,
        entity = nil
    }
    setmetatable(lifetime, self)
    return lifetime
end

function Lifetime:update(dt)
    if not self.active then return end
    
    self.remaining = self.remaining - dt
    
    if self.remaining <= 0 then
        self.active = false
    end
end

function Lifetime:getProgress()
    return 1 - (self.remaining / self.duration)
end

return Lifetime