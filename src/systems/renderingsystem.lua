-- Rendering system for displaying game entities

local System = require("src.ecs.system")
local Config = require("src.config")

local RenderingSystem = setmetatable({}, {__index = System})
RenderingSystem.__index = RenderingSystem

function RenderingSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.requirements = {"transform"}
    system.assetManager = nil
    
    return system
end

function RenderingSystem:draw()
    -- Draw entities in layers for proper z-ordering
    -- Layer 1: Tiles (walls, boxes, floors)
    for _, entity in pairs(self.entities) do
        if entity.active and (entity:hasTag("wall") or entity:hasTag("indestructible") or 
                             entity:hasTag("box") or entity:hasTag("destroyed_box")) then
            self:drawEntity(entity)
        end
    end
    
    -- Layer 2: Bombs and explosions
    for _, entity in pairs(self.entities) do
        if entity.active and (entity:hasTag("bomb") or entity:hasTag("explosion")) then
            self:drawEntity(entity)
        end
    end
    
    -- Layer 3: Powerups
    for _, entity in pairs(self.entities) do
        if entity.active and entity:hasTag("powerup") then
            self:drawEntity(entity)
        end
    end
    
    -- Layer 4: Player (topmost layer)
    for _, entity in pairs(self.entities) do
        if entity.active and entity:hasTag("player") then
            self:drawEntity(entity)
        end
    end
end

function RenderingSystem:drawEntity(entity)
    local transform = entity:getComponent("transform")
    
    if not transform then return end

    -- Draw based on entity type (tags)
    if entity:hasTag("player") then
        self:drawPlayer(entity, transform)
    elseif entity:hasTag("box") or entity:hasTag("destroyed_box") then
        self:drawBox(entity, transform)
    elseif entity:hasTag("wall") then
        self:drawWall(entity, transform)
    elseif entity:hasTag("bomb") then
        self:drawBomb(entity, transform)
    elseif entity:hasTag("explosion") then
        self:drawExplosion(entity, transform)
    elseif entity:hasTag("powerup") then
        self:drawPowerUp(entity, transform)
    end
end

function RenderingSystem:drawPlayer(entity, transform)
    -- Check for death animation
    local death = entity:getComponent("death")
    if death and death.isDying then
        self:drawDeathAnimation(entity, transform, death)
        return
    end
    
    -- Check for invincibility flickering
    local invincibility = entity:getComponent("invincibility")
    if invincibility and invincibility:shouldFlicker() then
        -- Skip drawing to create flicker effect
        return
    end
    
    -- Check for animated sprite
    local animation = entity:getComponent("animation")
    if animation and animation.spriteSheet then
        love.graphics.setColor(1, 1, 1)
        local quad = animation:getQuad()
        
        -- Scale sprite to be larger than the grid tile
        local spriteScale = 1.5 -- Make sprite 50% larger
        local scaleX = (transform.width / animation.frameWidth) * spriteScale
        local scaleY = (transform.height / animation.frameHeight) * spriteScale
        
        -- Center the larger sprite on the tile
        local offsetX = transform.width * (spriteScale - 1) / 2
        local offsetY = transform.height * (spriteScale - 1) / 2
        
        love.graphics.draw(animation.spriteSheet, quad, 
                          transform.x - offsetX, transform.y - offsetY, 
                          0, scaleX, scaleY)
    else
        -- Fallback to static player image
        local image = self.assetManager:getImage("player")
        if image then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(image, transform.x, transform.y, 0,
                              transform.width / image:getWidth(),
                              transform.height / image:getHeight())
        else
            -- Fallback to colored rectangle
            love.graphics.setColor(Config.COLORS.PLAYER)
            love.graphics.rectangle("fill", transform.x, transform.y,
                                   transform.width, transform.height)
        end
    end
end

function RenderingSystem:drawDeathAnimation(entity, transform, death)
    local image = self.assetManager:getImage("death")
    local progress = death:getProgress()
    
    -- Create shrinking and rotation effect
    local scale = 1.0 - (progress * 0.5) -- Shrink to 50% of original size
    local rotation = progress * math.pi * 2 -- Full rotation during death
    local alpha = 1.0 - (progress * 0.3) -- Slight fade
    
    if image then
        love.graphics.setColor(1, 1, 1, alpha)
        
        -- Draw with rotation and scaling from center
        local centerX = transform.x + transform.width / 2
        local centerY = transform.y + transform.height / 2
        local scaleX = (transform.width / image:getWidth()) * scale
        local scaleY = (transform.height / image:getHeight()) * scale
        
        love.graphics.draw(image, centerX, centerY, rotation, scaleX, scaleY,
                          image:getWidth() / 2, image:getHeight() / 2)
    else
        -- Fallback to colored rectangle with death effect
        love.graphics.setColor(0.8, 0.8, 0.8, alpha)
        local shrunkWidth = transform.width * scale
        local shrunkHeight = transform.height * scale
        local offsetX = (transform.width - shrunkWidth) / 2
        local offsetY = (transform.height - shrunkHeight) / 2
        
        love.graphics.rectangle("fill", 
                               transform.x + offsetX, 
                               transform.y + offsetY,
                               shrunkWidth, shrunkHeight)
    end
end

function RenderingSystem:drawWall(entity, transform)
    local imageName = entity:hasTag("indestructible") and "indestructible" or "wall"
    local image = self.assetManager:getImage(imageName)
    
    if image then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, transform.x, transform.y, 0,
                          transform.width / image:getWidth(),
                          transform.height / image:getHeight())
    else
        -- Fallback to colored rectangle
        love.graphics.setColor(Config.COLORS.WALL)
        love.graphics.rectangle("fill", transform.x, transform.y,
                               transform.width, transform.height)
    end
end

function RenderingSystem:drawBox(entity, transform)
    local destruction = entity:getComponent("destruction")
    local scale = 1.0
    local alpha = 1.0
    local rotation = 0
    
    -- Apply destruction animation effects
    if destruction and destruction.isDestroying then
        scale = destruction:getCurrentScale()
        alpha = destruction:getCurrentAlpha()
        -- Add slight rotation during destruction
        rotation = destruction:getProgress() * math.pi * 0.5
    end
    
    local centerX = transform.x + transform.width / 2
    local centerY = transform.y + transform.height / 2
    
    local image = self.assetManager:getImage("box")
    if image then
        love.graphics.setColor(1, 1, 1, alpha)
        
        local scaleX = (transform.width / image:getWidth()) * scale
        local scaleY = (transform.height / image:getHeight()) * scale
        
        love.graphics.draw(image, centerX, centerY, rotation, scaleX, scaleY,
                          image:getWidth() / 2, image:getHeight() / 2)
    else
        -- Fallback to colored rectangle with destruction effects
        love.graphics.setColor(Config.COLORS.BOX[1], Config.COLORS.BOX[2], Config.COLORS.BOX[3], alpha)
        
        local width = transform.width * scale
        local height = transform.height * scale
        local x = centerX - width / 2
        local y = centerY - height / 2
        
        love.graphics.push()
        love.graphics.translate(centerX, centerY)
        love.graphics.rotate(rotation)
        love.graphics.rectangle("fill", -width/2, -height/2, width, height)
        love.graphics.pop()
    end
end

function RenderingSystem:drawBomb(entity, transform)
    local timer = entity:getComponent("timer")
    local timeLeft = timer and timer.remaining or 3.0
    local totalTime = timer and timer.duration or 3.0
    local progress = timeLeft / totalTime -- 1.0 = just placed, 0.0 = about to explode
    
    -- Calculate animation effects
    local pulseSpeed = math.max(0.5, 3.0 * (1.0 - progress)) -- Pulses faster as timer decreases
    local pulseScale = 1.0 + math.sin(love.timer.getTime() * pulseSpeed * math.pi * 2) * 0.15 * (1.0 - progress)
    
    -- Color intensity - starts normal/white, gets redder as time runs out
    local red = 1.0
    local green = 1.0 - (1.0 - progress) * 0.8  -- Starts at 1.0, goes down to 0.2
    local blue = 1.0 - (1.0 - progress) * 0.8   -- Starts at 1.0, goes down to 0.2
    local alpha = 1.0
    
    -- Flash effect in final second - flashes back to white
    if timeLeft < 1.0 then
        local flashRate = math.max(2, 8 * (1.0 - timeLeft)) -- Flash faster as explosion approaches
        local flash = math.sin(love.timer.getTime() * flashRate * math.pi * 2)
        if flash > 0.5 then
            red = 1.0
            green = 1.0
            blue = 1.0
            alpha = 0.9 + flash * 0.1
        end
    end
    
    local centerX = transform.x + transform.width / 2
    local centerY = transform.y + transform.height / 2
    
    local image = self.assetManager:getImage("bomb")
    if image then
        love.graphics.setColor(red, green, blue, alpha)
        
        -- Apply pulsing scale
        local scaleX = (transform.width / image:getWidth()) * pulseScale
        local scaleY = (transform.height / image:getHeight()) * pulseScale
        
        -- Draw with center origin for proper scaling
        love.graphics.draw(image, centerX, centerY, 0, scaleX, scaleY, 
                          image:getWidth() / 2, image:getHeight() / 2)
    else
        -- Fallback to colored circle with animations
        love.graphics.setColor(red, green, blue, alpha)
        local radius = math.min(transform.width, transform.height) * 0.35 * pulseScale
        love.graphics.circle("fill", centerX, centerY, radius)
        
        -- Add countdown ring
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setLineWidth(3)
        local ringRadius = radius * 1.3
        local arcLength = progress * 2 * math.pi
        
        -- Draw countdown arc
        if arcLength > 0.1 then
            love.graphics.arc("line", "open", centerX, centerY, ringRadius, 
                             -math.pi/2, -math.pi/2 + arcLength)
        end
        
        love.graphics.setLineWidth(1) -- Reset line width
    end
end

function RenderingSystem:drawExplosion(entity, transform)
    local image = self.assetManager:getImage("Explosion")
    if image then
        local alpha = 0.8
        local lifetime = entity:getComponent("lifetime")
        if lifetime then
            alpha = lifetime.remaining / lifetime.duration
        end
        
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(image, transform.x, transform.y, 0,
                          transform.width / image:getWidth(),
                          transform.height / image:getHeight())
    else
        -- Fallback to colored circles
        local alpha = 0.8
        local lifetime = entity:getComponent("lifetime")
        if lifetime then
            alpha = lifetime.remaining / lifetime.duration
        end
        
        love.graphics.setColor(1, 0.8, 0, alpha)
        local centerX = transform.x + transform.width / 2
        local centerY = transform.y + transform.height / 2
        local maxRadius = math.min(transform.width, transform.height) * 0.5
        
        for i = 1, 3 do
            local radius = maxRadius * (i / 3)
            love.graphics.circle("line", centerX, centerY, radius)
        end
    end
end

function RenderingSystem:drawPowerUp(entity, transform)
    local powerup = entity:getComponent("powerup")
    if not powerup then return end
    
    local imageName = "powerup_" .. powerup.type
    local image = self.assetManager:getImage(imageName)
    
    if image then
        local pulse = math.sin(love.timer.getTime() * 3) * 0.3 + 0.7
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.draw(image, transform.x, transform.y, 0,
                          transform.width / image:getWidth(),
                          transform.height / image:getHeight())
    else
        -- Fallback to colored diamond
        if powerup.type == "heart" then
            love.graphics.setColor(Config.COLORS.POWERUP_HEART)
        elseif powerup.type == "speed" then
            love.graphics.setColor(Config.COLORS.POWERUP_SPEED)
        elseif powerup.type == "ammo" then
            love.graphics.setColor(Config.COLORS.POWERUP_AMMO)
        elseif powerup.type == "range" then
            love.graphics.setColor(Config.COLORS.POWERUP_RANGE)
        else
            love.graphics.setColor(1, 1, 1)
        end
        
        local centerX = transform.x + transform.width / 2
        local centerY = transform.y + transform.height / 2
        local size = math.min(transform.width, transform.height) * 0.3
        
        love.graphics.polygon("fill",
            centerX, centerY - size,
            centerX + size, centerY,
            centerX, centerY + size,
            centerX - size, centerY
        )
    end
end

return RenderingSystem