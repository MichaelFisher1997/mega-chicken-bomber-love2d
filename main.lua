-- Bomberman Love2D - Main Entry Point
-- A responsive Bomberman game rebuilt in Love2D with ECS architecture

local GameState = require("src.states.gamestate")
local MenuState = require("src.states.menustate")
local AssetManager = require("src.managers.assetmanager")
local InputManager = require("src.managers.inputmanager")
local Config = require("src.config")

local currentState
local assetManager
local inputManager

function love.load()
    -- Set up window
    love.window.setTitle("Bomberman Love2D")
    love.window.setMode(Config.WINDOW_WIDTH, Config.WINDOW_HEIGHT, {
        resizable = true,
        minwidth = 800,
        minheight = 600
    })
    
    -- Initialize managers
    assetManager = AssetManager:new()
    inputManager = InputManager:new()
    
    -- Load assets
    assetManager:load()
    
    -- Start with menu state
    currentState = MenuState:new(assetManager, inputManager)
    currentState:enter()
end

function love.update(dt)
    -- Update input manager
    inputManager:update(dt)
    
    -- Update current state
    if currentState then
        currentState:update(dt)
        
        -- Handle state transitions
        if currentState.shouldTransition then
            local nextState = currentState.nextState
            currentState:exit()
            
            if nextState == "game" then
                currentState = GameState:new(assetManager, inputManager)
            elseif nextState == "menu" then
                currentState = MenuState:new(assetManager, inputManager)
            end
            
            currentState:enter()
        end
    end
end

function love.draw()
    -- Clear screen
    love.graphics.clear(0.1, 0.1, 0.1)
    
    -- Draw current state
    if currentState then
        currentState:draw()
    end
    
    -- Debug info
    if Config.DEBUG then
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        love.graphics.print("Memory: " .. math.floor(collectgarbage("count")) .. "KB", 10, 30)
    end
end

function love.resize(w, h)
    if currentState and currentState.resize then
        currentState:resize(w, h)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f1" then
        Config.DEBUG = not Config.DEBUG
    end
    
    if currentState and currentState.keypressed then
        currentState:keypressed(key)
    end
end

function love.gamepadpressed(joystick, button)
    if currentState and currentState.gamepadpressed then
        currentState:gamepadpressed(joystick, button)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if currentState and currentState.touchpressed then
        currentState:touchpressed(id, x, y, dx, dy, pressure)
    end
end