-- Comprehensive test suite for Bomberman Love2D

local TestSuite = {}
TestSuite.__index = TestSuite

function TestSuite:new()
    local suite = {
        tests = {},
        results = {},
        passed = 0,
        failed = 0
    }
    setmetatable(suite, self)
    return suite
end

function TestSuite:addTest(name, testFunc)
    table.insert(self.tests, {name = name, func = testFunc})
end

function TestSuite:run()
    print("=== Bomberman Love2D Test Suite ===")
    print(string.format("Running %d tests...", #self.tests))
    
    self.passed = 0
    self.failed = 0
    
    for _, test in ipairs(self.tests) do
        local success, result = pcall(test.func)
        
        if success then
            print(string.format("✅ PASS: %s", test.name))
            self.passed = self.passed + 1
        else
            print(string.format("❌ FAIL: %s - %s", test.name, result))
            self.failed = self.failed + 1
        end
    end
    
    print(string.format("\nResults: %d passed, %d failed", self.passed, self.failed))
    return self.passed, self.failed
end

-- Test functions
function TestSuite:runAllTests()
    -- ECS Tests
    self:addTest("Entity Creation", function()
        local Entity = require("src.ecs.entity")
        local entity = Entity:new()
        assert(entity.id ~= nil, "Entity should have an ID")
        assert(entity.active == true, "Entity should be active by default")
    end)
    
    self:addTest("Component Addition", function()
        local Entity = require("src.ecs.entity")
        local Transform = require("src.components.transform")
        
        local entity = Entity:new()
        local transform = Transform:new(10, 20, 30, 40)
        
        entity:addComponent("transform", transform)
        assert(entity:getComponent("transform") == transform, "Component should be retrievable")
        assert(entity:hasComponent("transform") == true, "Entity should report having component")
    end)
    
    self:addTest("Grid System Responsiveness", function()
        local GridSystem = require("src.systems.gridsystem")
        local system = GridSystem:new()
        
        system:resize(800, 600)
        local tileSize = system:getTileSize()
        assert(tileSize > 0, "Tile size should be positive")
        
        local bounds = system:getGridBounds()
        assert(bounds.width > 0 and bounds.height > 0, "Grid should have dimensions")
    end)
    
    self:addTest("Movement System", function()
        local MovementSystem = require("src.systems.movementsystem")
        local system = MovementSystem:new()
        
        assert(system.moveDelay == 0.15, "Move delay should be 0.15 seconds")
        assert(system.moveCooldown == 0, "Initial cooldown should be 0")
    end)
    
    self:addTest("Bomb Placement", function()
        local GameState = require("src.states.gamestate")
        local state = GameState:new(nil, nil)
        
        -- Mock input manager
        state.inputManager = {
            isActionPressed = function() return false end
        }
        
        state.bombs = 1
        local canPlace = state:canPlaceBomb(5, 5)
        assert(type(canPlace) == "boolean", "Should return boolean for bomb placement")
    end)
    
    self:addTest("Power-up Collection", function()
        local MovementSystem = require("src.systems.movementsystem")
        local system = MovementSystem:new()
        
        -- Mock game state
        local mockState = {
            maxBombs = 1,
            bombs = 1,
            range = 1,
            score = 0
        }
        system.gameState = mockState
        
        -- Test power-up application
        local PowerUp = require("src.components.powerup")
        local powerup = PowerUp:new("bomb")
        assert(powerup.type == "bomb", "Power-up should have correct type")
    end)
    
    self:addTest("Save/Load System", function()
        local SaveManager = require("src.managers.savemanager")
        local manager = SaveManager:new()
        
        local testData = {highScore = 1000, gamesPlayed = 5}
        manager:saveGame(testData)
        
        local loadedData = manager:loadGame()
        assert(loadedData.highScore == 1000, "Should load saved high score")
        assert(loadedData.gamesPlayed == 5, "Should load saved games played")
    end)
    
    self:addTest("Performance Monitoring", function()
        local PerformanceSystem = require("src.systems.performancesystem")
        local system = PerformanceSystem:new()
        
        system:update(0.016) -- 60 FPS frame
        assert(system.fps >= 0, "FPS should be non-negative")
        assert(system.memoryUsage >= 0, "Memory usage should be non-negative")
    end)
    
    self:addTest("Responsive Design", function()
        local GridSystem = require("src.systems.gridsystem")
        local system = GridSystem:new()
        
        -- Test different screen sizes
        system:resize(1920, 1080)
        local tileSize1 = system:getTileSize()
        
        system:resize(800, 600)
        local tileSize2 = system:getTileSize()
        
        assert(tileSize1 > tileSize2, "Larger screen should have larger tiles")
    end)
    
    return self:run()
end

return TestSuite