-- Responsive grid system for Bomberman
-- Handles dynamic sizing and positioning based on screen dimensions

local System = require("src.ecs.system")
local Config = require("src.config")

local GridSystem = setmetatable({}, {__index = System})
GridSystem.__index = GridSystem

function GridSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.requirements = {"transform", "gridPosition"}
    system.tileSize = 0
    system.gridOffsetX = 0
    system.gridOffsetY = 0
    system.screenWidth = 0
    system.screenHeight = 0
    
    return system
end

function GridSystem:resize(w, h)
    self.screenWidth = w
    self.screenHeight = h
    
    -- Calculate responsive tile size
    local maxGridWidth = w * 0.8 -- Use 80% of screen width
    local maxGridHeight = h * 0.8 -- Use 80% of screen height
    
    local tileWidth = maxGridWidth / Config.GRID_COLS
    local tileHeight = maxGridHeight / Config.GRID_ROWS
    
    -- Use the smaller dimension to maintain square tiles
    self.tileSize = math.floor(math.min(tileWidth, tileHeight))
    
    -- Ensure minimum tile size
    self.tileSize = math.max(self.tileSize, 20)
    
    -- Calculate grid offset to center it
    local gridWidth = self.tileSize * Config.GRID_COLS
    local gridHeight = self.tileSize * Config.GRID_ROWS
    
    self.gridOffsetX = (w - gridWidth) / 2
    self.gridOffsetY = (h - gridHeight) / 2
    
    -- Update all entities with new positions
    for _, entity in pairs(self.entities) do
        self:updateEntityPosition(entity)
    end
end

function GridSystem:updateEntityPosition(entity)
    local transform = entity:getComponent("transform")
    local gridPos = entity:getComponent("gridPosition")
    local movement = entity:getComponent("movement")
    
    -- Skip position update if entity is smoothly moving
    if movement and movement.isMoving then
        -- Only update size, not position
        if transform then
            transform.width = self.tileSize
            transform.height = self.tileSize
        end
        return
    end
    
    if transform and gridPos then
        transform.x = self.gridOffsetX + (gridPos.col * self.tileSize)
        transform.y = self.gridOffsetY + (gridPos.row * self.tileSize)
        transform.width = self.tileSize
        transform.height = self.tileSize
    end
end

function GridSystem:gridToScreen(row, col)
    -- Convert grid coordinates to screen coordinates
    local x = self.gridOffsetX + (col * self.tileSize) + (self.tileSize / 2)
    local y = self.gridOffsetY + (row * self.tileSize) + (self.tileSize / 2)
    return x, y
end

function GridSystem:screenToGrid(x, y)
    -- Convert screen coordinates to grid coordinates
    local col = math.floor((x - self.gridOffsetX) / self.tileSize)
    local row = math.floor((y - self.gridOffsetY) / self.tileSize)
    
    -- Clamp to grid bounds
    col = math.max(0, math.min(Config.GRID_COLS - 1, col))
    row = math.max(0, math.min(Config.GRID_ROWS - 1, row))
    
    return row, col
end

function GridSystem:getTileSize()
    return self.tileSize
end

function GridSystem:getGridBounds()
    return {
        left = self.gridOffsetX,
        top = self.gridOffsetY,
        right = self.gridOffsetX + (self.tileSize * Config.GRID_COLS),
        bottom = self.gridOffsetY + (self.tileSize * Config.GRID_ROWS),
        width = self.tileSize * Config.GRID_COLS,
        height = self.tileSize * Config.GRID_ROWS
    }
end

function GridSystem:isValidGridPosition(row, col)
    return row >= 0 and row < Config.GRID_ROWS and 
           col >= 0 and col < Config.GRID_COLS
end

function GridSystem:onEntityAdded(entity)
    self:updateEntityPosition(entity)
end

function GridSystem:processEntity(entity, dt)
    -- Update entity positions if grid position changes
    local transform = entity:getComponent("transform")
    local gridPos = entity:getComponent("gridPosition")
    local movement = entity:getComponent("movement")
    
    -- Skip position updates for smoothly moving entities
    if movement and movement.isMoving then
        return
    end
    
    if transform and gridPos then
        local expectedX = self.gridOffsetX + (gridPos.col * self.tileSize)
        local expectedY = self.gridOffsetY + (gridPos.row * self.tileSize)
        
        -- Update position if grid position has changed
        if transform.x ~= expectedX or transform.y ~= expectedY then
            self:updateEntityPosition(entity)
        end
    end
end

function GridSystem:drawBackground(assetManager)
    local bounds = self:getGridBounds()
    
    -- Draw floor tiles
    local floorImage = assetManager and assetManager:getImage("floor")
    if floorImage then
        -- Tile the floor image
        love.graphics.setColor(1, 1, 1)
        
        for row = 0, Config.GRID_ROWS - 1 do
            for col = 0, Config.GRID_COLS - 1 do
                local x = bounds.left + col * self.tileSize
                local y = bounds.top + row * self.tileSize
                
                love.graphics.draw(floorImage, x, y, 0,
                                 self.tileSize / floorImage:getWidth(),
                                 self.tileSize / floorImage:getHeight())
            end
        end
    else
        -- Fallback to colored rectangle
        love.graphics.setColor(Config.COLORS.FLOOR)
        love.graphics.rectangle("fill",
            bounds.left, bounds.top,
            bounds.width, bounds.height)
    end
end

function GridSystem:draw()
    -- Grid system doesn't need to draw anything
end

function GridSystem:clear()
    -- Grid system doesn't maintain entity lists
end

return GridSystem