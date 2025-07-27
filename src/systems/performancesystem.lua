-- Performance monitoring system for profiling and optimization

local System = require("src.ecs.system")
local Config = require("src.config")

local PerformanceSystem = setmetatable({}, {__index = System})
PerformanceSystem.__index = PerformanceSystem

function PerformanceSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.requirements = {}
    system.frameTime = 0
    system.frameCount = 0
    system.fps = 0
    system.lastTime = love.timer.getTime()
    system.entityCount = 0
    system.memoryUsage = 0
    system.drawCalls = 0
    
    return system
end

function PerformanceSystem:update(dt)
    self.frameTime = self.frameTime + dt
    self.frameCount = self.frameCount + 1
    
    -- Calculate FPS every second
    local currentTime = love.timer.getTime()
    if currentTime - self.lastTime >= 1.0 then
        self.fps = self.frameCount
        self.frameCount = 0
        self.lastTime = currentTime
        
        -- Update memory usage
        self.memoryUsage = collectgarbage("count")
        
        -- Count entities
        if self.world then
            local count = 0
            for _ in pairs(self.world.entities) do
                count = count + 1
            end
            self.entityCount = count
        end
    end
end

function PerformanceSystem:draw()
    if not Config.DEBUG then return end
    
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    
    local x, y = 10, 120
    
    -- Performance metrics
    love.graphics.print(string.format("FPS: %d", self.fps), x, y)
    love.graphics.print(string.format("Frame Time: %.2fms", self.frameTime * 1000), x, y + 15)
    love.graphics.print(string.format("Memory: %.1fKB", self.memoryUsage), x, y + 30)
    love.graphics.print(string.format("Entities: %d", self.entityCount), x, y + 45)
    love.graphics.print(string.format("Draw Calls: %d", love.graphics.getStats().drawcalls), x, y + 60)
    
    -- System performance
    if self.world then
        local systemCount = 0
        for _ in ipairs(self.world.systems) do
            systemCount = systemCount + 1
        end
        love.graphics.print(string.format("Systems: %d", systemCount), x, y + 75)
    end
end

function PerformanceSystem:setWorld(world)
    self.world = world
end

return PerformanceSystem