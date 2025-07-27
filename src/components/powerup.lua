-- Power-up component for collectible items

local PowerUp = {}
PowerUp.__index = PowerUp

function PowerUp:new(type)
    local powerup = {
        type = type or "bomb", -- "bomb", "range", "speed"
        entity = nil
    }
    setmetatable(powerup, self)
    return powerup
end

function PowerUp:getType()
    return self.type
end

return PowerUp