-- Transform component for position, size, and rotation

local Transform = {}
Transform.__index = Transform

function Transform:new(x, y, width, height, rotation)
    local transform = {
        x = x or 0,
        y = y or 0,
        width = width or 0,
        height = height or 0,
        rotation = rotation or 0,
        scaleX = 1,
        scaleY = 1,
        originX = 0.5, -- Center origin
        originY = 0.5,
        entity = nil
    }
    setmetatable(transform, self)
    return transform
end

function Transform:getCenter()
    return self.x + (self.width * self.originX), 
           self.y + (self.height * self.originY)
end

function Transform:setCenter(cx, cy)
    self.x = cx - (self.width * self.originX)
    self.y = cy - (self.height * self.originY)
end

function Transform:getBounds()
    return {
        left = self.x,
        top = self.y,
        right = self.x + self.width,
        bottom = self.y + self.height,
        centerX = self.x + (self.width * self.originX),
        centerY = self.y + (self.height * self.originY)
    }
end

return Transform