-- Tilemap System for rendering tileset-based backgrounds
-- Handles rendering of tilemap components using tilesets

local System = require("src.ecs.system")
local Config = require("src.config")

local TileMapSystem = setmetatable({}, {__index = System})
TileMapSystem.__index = TileMapSystem

function TileMapSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.requirements = {"transform", "tilemap"}
    system.assetManager = nil
    system.springTileset = nil
    
    return system
end

function TileMapSystem:addEntity(entity)
    -- Call parent method first
    System.addEntity(self, entity)
end

function TileMapSystem:initialize(assetManager)
    self.assetManager = assetManager
    -- Load the spring tileset
    self.springTileset = self.assetManager:loadImage("spring_tileset", "assets/images/tiles/Tileset_Spring.png")
end

-- Remove custom draw method and let base System handle it

function TileMapSystem:drawEntity(entity)
    if not self.springTileset then return end
    if not entity:hasTag("background") then return end
    
    local transform = entity:getComponent("transform")
    local tilemap = entity:getComponent("tilemap")
    
    if not transform or not tilemap then return end
    
    -- Create quad for the specific tile in the tileset
    local quad = tilemap:getTileQuad(self.springTileset:getDimensions())
    
    if quad then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.springTileset, quad, 
                          transform.x, transform.y, 0,
                          transform.width / tilemap.tileSize,
                          transform.height / tilemap.tileSize)
    end
end

-- Helper function to create a tilemap background
function TileMapSystem:createBackgroundTiles(world, gridSystem, pattern)
    local TileMap = require("src.components.tilemap")
    local Transform = require("src.components.transform")
    local Entity = require("src.ecs.entity")
    
    pattern = pattern or "default"
    
    for row = 0, Config.GRID_ROWS - 1 do
        for col = 0, Config.GRID_COLS - 1 do
            local entity = world:createEntity()
            entity:addTag("background")
            entity:addTag("tilemap_background")
            
            -- Calculate position  
            local bounds = gridSystem:getGridBounds()
            local tileSize = gridSystem:getTileSize()
            local x = bounds.left + (col * tileSize)
            local y = bounds.top + (row * tileSize)
            local width = tileSize
            local height = tileSize
            
            -- Determine tile type based on pattern
            local tileType = self:getTileTypeForPosition(row, col, pattern)
            
            -- Add components
            entity:addComponent("transform", Transform:new(x, y, width, height))
            entity:addComponent("tilemap", TileMap:new(tileType))
            
            -- Set the specific tile type
            local tilemap = entity:getComponent("tilemap")
            tilemap:setTileType(tileType)
            
            -- Register entity with systems
            world:addEntityToSystems(entity)
        end
    end
    
    -- Background tiles created
end

function TileMapSystem:getTileTypeForPosition(row, col, pattern)
    if pattern == "dirt_patches" then
        -- Create a nice grass layout with scattered dirt patches
        local seed = (row * 7 + col * 11) % 20
        
        if seed < 2 then
            -- 10% dirt patches for variety
            return (row + col) % 2 == 0 and "DIRT_CENTER" or "DIRT_TOP_LEFT"
        elseif seed < 4 then
            -- 10% sandy areas
            return (row + col) % 2 == 0 and "SAND_CENTER" or "SAND_TOP_LEFT"
        else
            -- 80% grass with variation
            local grassTypes = {"GRASS_CENTER", "GRASS_TOP_LEFT", "GRASS_TOP_RIGHT", "GRASS_BOTTOM_LEFT"}
            local grassType = ((row * 3 + col * 5) % #grassTypes) + 1
            return grassTypes[grassType]
        end
    elseif pattern == "spring_park" then
        -- Create a park-like pattern with varied terrain
        if (row == 0 or row == Config.GRID_ROWS - 1) or 
           (col == 0 or col == Config.GRID_COLS - 1) then
            return "GRASS_CENTER_LEFT" -- Borders
        elseif row == math.floor(Config.GRID_ROWS / 2) or 
               col == math.floor(Config.GRID_COLS / 2) then
            return "SAND_CENTER" -- Central paths
        elseif (row + col) % 4 == 0 then
            return "DIRT_CENTER" -- Scattered dirt patches
        else
            return "GRASS_CENTER" -- Fill with grass
        end
    elseif pattern == "varied_terrain" then
        -- Create varied terrain pattern
        local seed = (row * 13 + col * 7) % 8
        if seed < 2 then
            local grassTypes = {"GRASS_CENTER", "GRASS_TOP_CENTER"}
            return grassTypes[(seed % 2) + 1]
        elseif seed < 4 then
            local sandTypes = {"SAND_CENTER", "SAND_TOP_CENTER"}
            return sandTypes[((seed - 2) % 2) + 1]
        elseif seed < 6 then
            local dirtTypes = {"DIRT_CENTER", "DIRT_TOP_CENTER"}
            return dirtTypes[((seed - 4) % 2) + 1]
        else
            local edgeTypes = {"GRASS_CENTER_LEFT", "GRASS_CENTER_RIGHT"}
            return edgeTypes[((seed - 6) % 2) + 1]
        end
    else
        -- Default: simple grass pattern with variation
        local variation = (row + col) % 4
        if variation < 2 then
            return "GRASS_CENTER"
        else
            return "GRASS_TOP_CENTER"
        end
    end
end

function TileMapSystem:clear()
    -- Clean up tilemap entities
    if self.entities then
        for _, entity in pairs(self.entities) do
            if entity:hasTag("tilemap_background") then
                entity.active = false
            end
        end
    end
end

return TileMapSystem