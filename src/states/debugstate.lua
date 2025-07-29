-- Debug state for visualizing tilesets and debugging graphics
local Config = require("src.config")

local DebugState = {}
DebugState.__index = DebugState

function DebugState:new(assetManager, inputManager)
    local state = {
        assetManager = assetManager,
        inputManager = inputManager,
        shouldTransition = false,
        nextState = nil,
        font = nil,
        titleFont = nil,
        springTileset = nil,
        selectedTileX = 0,
        selectedTileY = 0,
        tileSize = 16,
        maxCols = 12, -- Based on 192px width / 16px tiles
        maxRows = 20, -- Based on 320px height / 16px tiles
        inputCooldown = {
            timer = 0,
            duration = 0.15 -- 150ms cooldown between moves
        }
    }
    setmetatable(state, self)
    return state
end

function DebugState:enter()
    -- Create fonts
    local screenHeight = love.graphics.getHeight()
    self.font = love.graphics.newFont(math.floor(screenHeight * 0.03))
    self.titleFont = love.graphics.newFont(math.floor(screenHeight * 0.06))
    
    -- Load the spring tileset
    self.springTileset = self.assetManager:getImage("spring_tileset")
    if not self.springTileset then
        self.springTileset = self.assetManager:loadImage("spring_tileset", "assets/images/tiles/Tileset_Spring.png")
    end
    
    -- Initialize input
    local w, h = love.graphics.getDimensions()
    self.inputManager:resize(w, h)
end

function DebugState:exit()
    -- Cleanup
end

function DebugState:update(dt)
    -- Update input cooldown
    if self.inputCooldown.timer > 0 then
        self.inputCooldown.timer = self.inputCooldown.timer - dt
    end
    
    -- Handle input only if cooldown expired
    if self.inputCooldown.timer <= 0 then
        self:handleInput()
    end
end

function DebugState:handleInput()
    local moveX, moveY = self.inputManager:getMovement()
    local moved = false
    
    -- Navigate through tileset
    if moveX > 0 then
        self.selectedTileX = math.min(self.maxCols - 1, self.selectedTileX + 1)
        moved = true
    elseif moveX < 0 then
        self.selectedTileX = math.max(0, self.selectedTileX - 1)
        moved = true
    end
    
    if moveY > 0 then
        self.selectedTileY = math.min(self.maxRows - 1, self.selectedTileY + 1)
        moved = true
    elseif moveY < 0 then
        self.selectedTileY = math.max(0, self.selectedTileY - 1)
        moved = true
    end
    
    -- Start cooldown if we moved
    if moved then
        self.inputCooldown.timer = self.inputCooldown.duration
    end
    
    -- Go back to menu
    if self.inputManager:isActionPressed("restart") then -- R key
        self.shouldTransition = true
        self.nextState = "menu"
    end
end

function DebugState:draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    local titleText = "Tileset Debug Viewer"
    local titleWidth = self.titleFont:getWidth(titleText)
    love.graphics.print(titleText, screenWidth / 2 - titleWidth / 2, 20)
    
    -- Info
    love.graphics.setFont(self.font)
    local infoY = 80
    love.graphics.print("Selected Tile: (" .. self.selectedTileX .. ", " .. self.selectedTileY .. ")", 20, infoY)
    love.graphics.print("Tileset Size: " .. (self.springTileset and self.springTileset:getDimensions() or "Not loaded"), 20, infoY + 25)
    love.graphics.print("Use WASD/Arrows to navigate, R to return", 20, infoY + 50)
    
    if not self.springTileset then
        love.graphics.print("ERROR: Spring tileset not loaded!", 20, infoY + 100)
        return
    end
    
    -- Draw tileset grid
    local startX = 50
    local startY = 150
    local displayScale = 3 -- Make tiles bigger for viewing
    
    -- Draw grid of tiles
    for row = 0, math.min(9, self.maxRows - 1) do -- Show first 10 rows
        for col = 0, math.min(11, self.maxCols - 1) do -- Show first 12 columns
            local x = startX + col * (self.tileSize * displayScale + 2)
            local y = startY + row * (self.tileSize * displayScale + 2)
            
            -- Create quad for this tile
            local quad = love.graphics.newQuad(
                col * self.tileSize,
                row * self.tileSize,
                self.tileSize,
                self.tileSize,
                self.springTileset:getDimensions()
            )
            
            -- Highlight selected tile
            if col == self.selectedTileX and row == self.selectedTileY then
                love.graphics.setColor(1, 1, 0) -- Yellow highlight
                love.graphics.rectangle("line", x - 2, y - 2, 
                                      self.tileSize * displayScale + 4, 
                                      self.tileSize * displayScale + 4)
            end
            
            -- Draw tile
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(self.springTileset, quad, x, y, 0, displayScale, displayScale)
            
            -- Draw coordinates
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(col .. "," .. row, x + 2, y + 2)
        end
    end
    
    -- Draw selected tile larger
    local bigTileX = screenWidth - 200
    local bigTileY = startY
    local bigScale = 8
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Selected Tile (8x):", bigTileX, bigTileY - 30)
    
    local selectedQuad = love.graphics.newQuad(
        self.selectedTileX * self.tileSize,
        self.selectedTileY * self.tileSize,
        self.tileSize,
        self.tileSize,
        self.springTileset:getDimensions()
    )
    
    love.graphics.draw(self.springTileset, selectedQuad, bigTileX, bigTileY, 0, bigScale, bigScale)
    
    -- Show coordinate info
    love.graphics.print("Coord: (" .. self.selectedTileX .. ", " .. self.selectedTileY .. ")", bigTileX, bigTileY + self.tileSize * bigScale + 10)
    love.graphics.print("Pixel: (" .. (self.selectedTileX * self.tileSize) .. ", " .. (self.selectedTileY * self.tileSize) .. ")", bigTileX, bigTileY + self.tileSize * bigScale + 35)
end

function DebugState:keypressed(key)
    -- Handle navigation with cooldown
    if self.inputCooldown.timer <= 0 then
        local moved = false
        if key == "w" or key == "up" then
            self.selectedTileY = math.max(0, self.selectedTileY - 1)
            moved = true
        elseif key == "s" or key == "down" then
            self.selectedTileY = math.min(self.maxRows - 1, self.selectedTileY + 1)
            moved = true
        elseif key == "a" or key == "left" then
            self.selectedTileX = math.max(0, self.selectedTileX - 1)
            moved = true
        elseif key == "d" or key == "right" then
            self.selectedTileX = math.min(self.maxCols - 1, self.selectedTileX + 1)
            moved = true
        end
        
        if moved then
            self.inputCooldown.timer = self.inputCooldown.duration
        end
    end
    
    -- Handle other keys without cooldown
    if key == "r" then
        self.shouldTransition = true
        self.nextState = "menu"
    end
    
    self.inputManager:keypressed(key)
end

function DebugState:keyreleased(key)
    self.inputManager:keyreleased(key)
end

function DebugState:resize(w, h)
    self.inputManager:resize(w, h)
end

return DebugState