-- Death component for player death animation
local Death = {}
Death.__index = Death

function Death:new(duration)
    local death = {
        duration = duration or 1.5, -- Death animation duration in seconds
        timer = 0,
        isDying = false,
        startTime = 0
    }
    setmetatable(death, self)
    return death
end

function Death:start()
    self.isDying = true
    self.timer = 0
    self.startTime = love.timer.getTime()
end

function Death:update(dt)
    if self.isDying then
        self.timer = self.timer + dt
    end
end

function Death:isComplete()
    return self.isDying and self.timer >= self.duration
end

function Death:getProgress()
    if not self.isDying then return 0 end
    return math.min(self.timer / self.duration, 1.0)
end

return Death