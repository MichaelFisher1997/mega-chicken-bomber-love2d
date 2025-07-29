-- Menu state for the main menu
-- Simple menu system with responsive design

local Config = require("src.config")

local MenuState = {}
MenuState.__index = MenuState

function MenuState:new(assetManager, inputManager)
    local state = {
        assetManager = assetManager,
        inputManager = inputManager,
        shouldTransition = false,
        nextState = nil,
        selectedOption = 1,
        options = {
            {text = "Start Game", action = "start"},
            {text = "Settings", action = "settings"},
            {text = "Debug Tileset", action = "debug"},
            {text = "About", action = "about"},
            {text = "Quit", action = "quit"}
        },
        font = nil,
        titleFont = nil
    }
    setmetatable(state, self)
    return state
end

function MenuState:enter()
    -- Create fonts
    local screenHeight = love.graphics.getHeight()
    self.font = love.graphics.newFont(math.floor(screenHeight * 0.05))
    self.titleFont = love.graphics.newFont(math.floor(screenHeight * 0.1))
    
    -- Initialize input
    local w, h = love.graphics.getDimensions()
    self.inputManager:resize(w, h)
end

function MenuState:exit()
    -- Cleanup
end

function MenuState:update(dt)
    -- Handle input
    self:handleInput()
end

function MenuState:handleInput()
    -- Menu selection
    if self.inputManager:isActionPressed("bomb") or 
       self.inputManager:isActionPressed("return") then
        self:selectOption()
    end
end

function MenuState:selectOption()
    local option = self.options[self.selectedOption]
    
    if option.action == "start" then
        self.shouldTransition = true
        self.nextState = "game"
    elseif option.action == "settings" then
        self.shouldTransition = true
        self.nextState = "settings"
    elseif option.action == "debug" then
        self.shouldTransition = true
        self.nextState = "debug"
    elseif option.action == "about" then
        -- TODO: Implement about
    elseif option.action == "quit" then
        love.event.quit()
    end
end

function MenuState:draw()
    -- Clear screen
    love.graphics.clear(Config.COLORS.BACKGROUND)
    
    -- Draw title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(Config.COLORS.TEXT)
    love.graphics.printf("BOMBERMAN", 0, 50, love.graphics.getWidth(), "center")
    
    -- Draw menu options
    love.graphics.setFont(self.font)
    local startY = love.graphics.getHeight() * 0.4
    
    for i, option in ipairs(self.options) do
        local color = i == self.selectedOption and {1, 1, 0} or Config.COLORS.TEXT
        love.graphics.setColor(color)
        
        local prefix = i == self.selectedOption and "> " or "  "
        love.graphics.printf(prefix .. option.text, 0, startY + (i - 1) * 60, 
            love.graphics.getWidth(), "center")
    end
    
    -- Draw instructions
    love.graphics.setColor(Config.COLORS.TEXT)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("Use arrow keys/WASD to navigate, Space/Enter to select", 
        0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")
    
    -- Draw touch controls
    self.inputManager:drawTouchControls()
end

function MenuState:resize(w, h)
    -- Recreate fonts for new size
    self.font = love.graphics.newFont(math.floor(h * 0.05))
    self.titleFont = love.graphics.newFont(math.floor(h * 0.1))
    
    -- Update input
    self.inputManager:resize(w, h)
end

function MenuState:keypressed(key)
    -- Handle menu navigation directly
    if key == "w" or key == "up" then
        self.selectedOption = math.max(1, self.selectedOption - 1)
    elseif key == "s" or key == "down" then
        self.selectedOption = math.min(#self.options, self.selectedOption + 1)
    elseif key == "space" or key == "return" then
        self:selectOption()
    end
    
    self.inputManager:keypressed(key)
end

function MenuState:keyreleased(key)
    self.inputManager:keyreleased(key)
end

function MenuState:touchpressed(id, x, y, dx, dy, pressure)
    self.inputManager:touchpressed(id, x, y, dx, dy, pressure)
end

function MenuState:touchreleased(id, x, y, dx, dy, pressure)
    self.inputManager:touchreleased(id, x, y, dx, dy, pressure)
end

function MenuState:touchmoved(id, x, y, dx, dy, pressure)
    self.inputManager:touchmoved(id, x, y, dx, dy, pressure)
end

return MenuState