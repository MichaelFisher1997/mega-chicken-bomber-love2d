-- Movement component for entity velocity and direction

local Movement = {}
Movement.__index = Movement

function Movement:new(speed)
    local movement = {
        speed = speed or Config.PLAYER_SPEED,
        velocityX = 0,
        velocityY = 0,
        direction = "down", -- up, down, left, right
        isMoving = false,
        entity = nil
    }
    setmetatable(movement, self)
    return movement
end

function Movement:setDirection(dir)
    self.direction = dir
end

function Movement:getDirection()
    return self.direction
end

function Movement:setVelocity(x, y)
    self.velocityX = x
    self.velocityY = y
    self.isMoving = (x ~= 0 or y ~= 0)
end

function Movement:getVelocity()
    return self.velocityX, self.velocityY
end

function Movement:stop()
    self.velocityX = 0
    self.velocityY = 0
    self.isMoving = false
end

return Movement