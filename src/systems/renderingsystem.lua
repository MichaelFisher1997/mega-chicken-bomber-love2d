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
    -- Draw all entities with transforms
    print("RenderingSystem: Drawing " .. #self.entities .. " entities")
    for _, entity in pairs(self.entities) do
        if entity.active then
            print("  Drawing entity ID: " .. entity.id .. ", Tags: " .. table.concat(entity.tags, ", "))
            self:drawEntity(entity)
        end
    end
end

function RenderingSystem:drawEntity(entity)
    local transform = entity:getComponent("transform")
    
    if not transform then return end

    -- Debug print transform values
    print(string.format("    Transform for entity ID %d: x=%.2f, y=%.2f, w=%.2f, h=%.2f", entity.id, transform.x, transform.y, transform.width, transform.height))

    -- Draw based on entity type (tags)
    if entity:hasTag("player") then
        self:drawPlayer(entity, transform)
    elseif entity:hasTag("box") then
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
    local image = self.assetManager:getImage("box")
    if image then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, transform.x, transform.y, 0,
                          transform.width / image:getWidth(),
                          transform.height / image:getHeight())
    else
        -- Fallback to colored rectangle
        love.graphics.setColor(Config.COLORS.BOX)
        love.graphics.rectangle("fill", transform.x, transform.y,
                               transform.width, transform.height)
    end
end

function RenderingSystem:drawBomb(entity, transform)
    local image = self.assetManager:getImage("bomb")
    if image then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, transform.x, transform.y, 0,
                          transform.width / image:getWidth(),
                          transform.height / image:getHeight())
    else
        -- Fallback to colored circle
        love.graphics.setColor(Config.COLORS.BOMB)
        local centerX = transform.x + transform.width / 2
        local centerY = transform.y + transform.height / 2
        local radius = math.min(transform.width, transform.height) * 0.35
        love.graphics.circle("fill", centerX, centerY, radius)
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
    
    local imageName = powerup.type == "bomb" and "Ammo" or "Range"
    local image = self.assetManager:getImage(imageName)
    
    if image then
        local pulse = math.sin(love.timer.getTime() * 3) * 0.3 + 0.7
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.draw(image, transform.x, transform.y, 0,
                          transform.width / image:getWidth(),
                          transform.height / image:getHeight())
    else
        -- Fallback to colored diamond
        if powerup.type == "bomb" then
            love.graphics.setColor(Config.COLORS.POWERUP_BOMB)
        elseif powerup.type == "range" then
            love.graphics.setColor(Config.COLORS.POWERUP_RANGE)
        elseif powerup.type == "speed" then
            love.graphics.setColor(Config.COLORS.POWERUP_SPEED)
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