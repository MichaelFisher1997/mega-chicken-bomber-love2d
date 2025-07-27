-- Particle system for explosion and destruction effects

local System = require("src.ecs.system")
local Config = require("src.config")

local ParticleSystem = setmetatable({}, {__index = System})
ParticleSystem.__index = ParticleSystem

function ParticleSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.requirements = {"particles"}
    system.particleSystems = {}
    
    return system
end

function ParticleSystem:createExplosion(x, y, intensity)
    local ps = love.graphics.newParticleSystem(love.graphics.newImage(1, 1), 100)
    
    -- Configure explosion particles
    ps:setParticleLifetime(0.5, 1.5)
    ps:setEmissionRate(200)
    ps:setSizeVariation(0.5)
    ps:setLinearAcceleration(-50, -50, 50, 50)
    ps:setColors(1, 0.8, 0, 1, 1, 0.4, 0, 0.8, 1, 0, 0, 0)
    ps:setSizes(0.5, 1, 0.5)
    ps:setSpeed(50, 200)
    ps:setSpread(math.pi * 2)
    ps:setEmissionArea("uniform", 10, 10)
    
    ps:setPosition(x, y)
    ps:emit(intensity or 50)
    
    table.insert(self.particleSystems, {
        system = ps,
        lifetime = 1.5,
        remaining = 1.5
    })
    
    return ps
end

function ParticleSystem:createBoxDestruction(x, y)
    local ps = love.graphics.newParticleSystem(love.graphics.newImage(1, 1), 50)
    
    -- Configure wood particle effect
    ps:setParticleLifetime(0.3, 1.0)
    ps:setEmissionRate(100)
    ps:setSizeVariation(0.3)
    ps:setLinearAcceleration(-30, -30, 30, 30)
    ps:setColors(0.6, 0.4, 0.2, 1, 0.4, 0.2, 0.1, 0)
    ps:setSizes(0.3, 0.8, 0.1)
    ps:setSpeed(20, 80)
    ps:setSpread(math.pi)
    
    ps:setPosition(x, y)
    ps:emit(30)
    
    table.insert(self.particleSystems, {
        system = ps,
        lifetime = 1.0,
        remaining = 1.0
    })
    
    return ps
end

function ParticleSystem:createPowerUpSparkle(x, y)
    local ps = love.graphics.newParticleSystem(love.graphics.newImage(1, 1), 30)
    
    -- Configure sparkle effect
    ps:setParticleLifetime(0.5, 1.2)
    ps:setEmissionRate(60)
    ps:setSizeVariation(0.8)
    ps:setLinearAcceleration(0, -20, 0, -50)
    ps:setColors(1, 1, 0, 1, 1, 0.5, 0, 0.5, 1, 0, 1, 0)
    ps:setSizes(0.2, 0.6, 0.1)
    ps:setSpeed(10, 40)
    ps:setSpread(math.pi / 3)
    
    ps:setPosition(x, y)
    ps:emit(20)
    
    table.insert(self.particleSystems, {
        system = ps,
        lifetime = 1.2,
        remaining = 1.2
    })
    
    return ps
end

function ParticleSystem:update(dt)
    -- Update all active particle systems
    local toRemove = {}
    
    for i, psData in ipairs(self.particleSystems) do
        psData.remaining = psData.remaining - dt
        psData.system:update(dt)
        
        if psData.remaining <= 0 then
            table.insert(toRemove, i)
        end
    end
    
    -- Remove expired systems
    for i = #toRemove, 1, -1 do
        table.remove(self.particleSystems, toRemove[i])
    end
end

function ParticleSystem:draw()
    -- Draw all active particle systems
    for _, psData in ipairs(self.particleSystems) do
        love.graphics.draw(psData.system)
    end
end

function ParticleSystem:clear()
    self.particleSystems = {}
end

return ParticleSystem