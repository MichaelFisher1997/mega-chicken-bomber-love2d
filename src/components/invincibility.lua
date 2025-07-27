-- Invincibility component for temporary immunity periods
local Invincibility = {}
Invincibility.__index = Invincibility

function Invincibility:new(duration)
    local invincibility = {
        duration = duration or 2.0, -- Invincibility duration in seconds
        timer = 0,
        isActive = false,
        flickerRate = 8, -- Flickers per second
        startTime = 0
    }
    setmetatable(invincibility, self)
    return invincibility
end

function Invincibility:start()
    self.isActive = true
    self.timer = 0
    self.startTime = love.timer.getTime()
    print("[INVINCIBILITY] Started for", self.duration, "seconds")
end

function Invincibility:update(dt)
    if self.isActive then
        self.timer = self.timer + dt
        if self.timer >= self.duration then
            self.isActive = false
            print("[INVINCIBILITY] Ended")
        end
    end
end

function Invincibility:isInvincible()
    return self.isActive
end

function Invincibility:shouldFlicker()
    if not self.isActive then return false end
    -- Create flickering effect during invincibility
    local phase = (love.timer.getTime() - self.startTime) * self.flickerRate
    return math.floor(phase) % 2 == 1
end

function Invincibility:getProgress()
    if not self.isActive then return 1.0 end
    return self.timer / self.duration
end

return Invincibility