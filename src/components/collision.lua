-- Collision component for entity collision detection

local Collision = {}
Collision.__index = Collision

function Collision:new(width, height, offsetX, offsetY)
    local collision = {
        width = width or 0,
        height = height or 0,
        offsetX = offsetX or 0,
        offsetY = offsetY or 0,
        solid = true,
        entity = nil
    }
    setmetatable(collision, self)
    return collision
end

function Collision:getBounds(transform)
    if not transform then return 0, 0, 0, 0 end
    
    local left = transform.x + self.offsetX
    local top = transform.y + self.offsetY
    local right = left + self.width
    local bottom = top + self.height
    
    return left, top, right, bottom
end

function Collision:checkCollision(transform, otherTransform, otherCollision)
    local left1, top1, right1, bottom1 = self:getBounds(transform)
    local left2, top2, right2, bottom2 = otherCollision:getBounds(otherTransform)
    
    return left1 < right2 and right1 > left2 and top1 < bottom2 and bottom1 > top2
end

return Collision