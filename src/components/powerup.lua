-- Power-up component for collectible items

local PowerUp = {}
PowerUp.__index = PowerUp

function PowerUp:new(type)
    local powerup = {
        type = type or "ammo", -- "heart", "speed", "ammo", "range"
        entity = nil
    }
    setmetatable(powerup, self)
    return powerup
end

function PowerUp:getType()
    return self.type
end

return PowerUp