-- Destruction animation component for visual effects during entity destruction

local Destruction = {}
Destruction.__index = Destruction

function Destruction:new(duration)
    local destruction = {
        duration = duration or 0.3,
        elapsed = 0,
        startScale = 1.0,
        endScale = 0.0,
        startAlpha = 1.0,
        endAlpha = 0.0,
        isDestroying = false,
        onComplete = nil,
        entity = nil
    }
    setmetatable(destruction, self)
    return destruction
end

function Destruction:start(onComplete)
    self.isDestroying = true
    self.elapsed = 0
    self.onComplete = onComplete
end

function Destruction:update(dt)
    if not self.isDestroying then return end
    
    self.elapsed = self.elapsed + dt
    
    if self.elapsed >= self.duration then
        self.isDestroying = false
        if self.onComplete then
            self.onComplete()
        end
    end
end

function Destruction:getProgress()
    if not self.isDestroying then return 0 end
    return math.min(self.elapsed / self.duration, 1.0)
end

function Destruction:getCurrentScale()
    local progress = self:getProgress()
    return self.startScale + (self.endScale - self.startScale) * progress
end

function Destruction:getCurrentAlpha()
    local progress = self:getProgress()
    return self.startAlpha + (self.endAlpha - self.startAlpha) * progress
end

return Destruction