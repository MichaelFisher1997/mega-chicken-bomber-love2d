-- Simple test to verify the game runs
-- Run with: love bomberman-love2d/ --test

local GameState = require("src.states.gamestate")
local AssetManager = require("src.managers.assetmanager")
local InputManager = require("src.managers.inputmanager")

local function testGameInitialization()
    print("Testing game initialization...")
    
    local assetManager = AssetManager:new()
    local inputManager = InputManager:new()
    local gameState = GameState:new(assetManager, inputManager)
    
    -- Test basic initialization
    assert(gameState ~= nil, "GameState should be created")
    assert(gameState.world == nil, "World should be nil before enter")
    assert(gameState.lives == 3, "Should start with 3 lives")
    assert(gameState.bombs == 1, "Should start with 1 bomb")
    assert(gameState.range == 1, "Should start with range 1")
    
    print("✅ Game initialization test passed")
end

local function testInputManager()
    print("Testing input manager...")
    
    local inputManager = InputManager:new()
    assert(inputManager ~= nil, "InputManager should be created")
    
    -- Test basic input handling
    local moveX, moveY = inputManager:getMovement()
    assert(moveX == 0 and moveY == 0, "Initial movement should be 0,0")
    
    print("✅ Input manager test passed")
end

local function testAssetManager()
    print("Testing asset manager...")
    
    local assetManager = AssetManager:new()
    assert(assetManager ~= nil, "AssetManager should be created")
    
    print("✅ Asset manager test passed")
end

-- Run tests
print("Running Bomberman Love2D tests...")
testGameInitialization()
testInputManager()
testAssetManager()
print("🎉 All tests passed! Game is ready to play.")