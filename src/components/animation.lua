-- Animation component for sprite-based animations
local Animation = {}
Animation.__index = Animation

function Animation:new(spriteSheet, frameWidth, frameHeight, animations)
    local animation = {
        spriteSheet = spriteSheet, -- The loaded image
        frameWidth = frameWidth or 32,
        frameHeight = frameHeight or 32,
        animations = animations or {}, -- Table of animation definitions
        currentAnimation = "idle",
        currentFrame = 1,
        frameTime = 0,
        frameDuration = 0.15, -- Default frame duration in seconds
        isPlaying = true,
        direction = "down" -- Current facing direction
    }
    setmetatable(animation, self)
    return animation
end

function Animation:setAnimation(name, direction)
    if direction then
        self.direction = direction
    end
    
    local animKey = name .. "_" .. self.direction
    if self.animations[animKey] and self.currentAnimation ~= animKey then
        self.currentAnimation = animKey
        self.currentFrame = 1
        self.frameTime = 0
    end
end

function Animation:update(dt)
    if not self.isPlaying then return end
    
    local anim = self.animations[self.currentAnimation]
    if not anim then return end
    
    self.frameTime = self.frameTime + dt
    
    if self.frameTime >= self.frameDuration then
        self.frameTime = 0
        self.currentFrame = self.currentFrame + 1
        
        if self.currentFrame > anim.frameCount then
            if anim.loop then
                self.currentFrame = 1
            else
                self.currentFrame = anim.frameCount
                self.isPlaying = false
            end
        end
    end
end

function Animation:getCurrentFrame()
    local anim = self.animations[self.currentAnimation]
    if not anim then return 1, 1 end
    
    local frameIndex = self.currentFrame - 1
    local row = anim.row or 0
    local col = anim.startFrame + frameIndex
    
    return row, col
end

function Animation:getQuad()
    local row, col = self:getCurrentFrame()
    local x = col * self.frameWidth
    local y = row * self.frameHeight
    
    return love.graphics.newQuad(x, y, self.frameWidth, self.frameHeight, 
                                self.spriteSheet:getDimensions())
end

return Animation