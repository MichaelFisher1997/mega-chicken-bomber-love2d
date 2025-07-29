-- Tilemap component for handling tileset-based rendering
-- Stores tile type and coordinates within a tileset

local TileMap = {}
TileMap.__index = TileMap

function TileMap:new(tileType, tilesetX, tilesetY, tileSize)
    local tilemap = {
        tileType = tileType or "grass", -- Type of tile (grass, path, edge, etc.)
        tilesetX = tilesetX or 0,       -- X coordinate in tileset
        tilesetY = tilesetY or 0,       -- Y coordinate in tileset  
        tileSize = tileSize or 16,      -- Size of each tile in pixels 
        tileset = nil                   -- Reference to loaded tileset image
    }
    setmetatable(tilemap, self)
    return tilemap
end

-- Tile type definitions for Tileset_Spring.png (3x4 tile groups starting at column 8)
TileMap.TILE_TYPES = {
    -- GRASS TILES (8,0 to 11,3)
    GRASS_TOP_LEFT = {x = 8, y = 0, type = "grass"},
    GRASS_TOP_CENTER = {x = 10, y = 0, type = "grass"},
    GRASS_TOP_RIGHT = {x = 11, y = 0, type = "grass"},
    GRASS_CENTER_LEFT = {x = 8, y = 1, type = "grass"},
    GRASS_CENTER = {x = 9, y = 2, type = "grass"},
    GRASS_CENTER_RIGHT = {x = 11, y = 2, type = "grass"},
    GRASS_BOTTOM_LEFT = {x = 8, y = 3, type = "grass"},
    GRASS_BOTTOM_CENTER = {x = 9, y = 3, type = "grass"},
    GRASS_BOTTOM_RIGHT = {x = 11, y = 3, type = "grass"},
    
    -- DIRT TILES (8,4 to 11,7 - same pattern as grass)
    DIRT_TOP_LEFT = {x = 8, y = 4, type = "dirt"},
    DIRT_TOP_CENTER = {x = 10, y = 4, type = "dirt"},
    DIRT_TOP_RIGHT = {x = 11, y = 4, type = "dirt"},
    DIRT_CENTER_LEFT = {x = 8, y = 5, type = "dirt"},
    DIRT_CENTER = {x = 9, y = 6, type = "dirt"},
    DIRT_CENTER_RIGHT = {x = 11, y = 6, type = "dirt"},
    DIRT_BOTTOM_LEFT = {x = 8, y = 7, type = "dirt"},
    DIRT_BOTTOM_CENTER = {x = 9, y = 7, type = "dirt"},
    DIRT_BOTTOM_RIGHT = {x = 11, y = 7, type = "dirt"},
    
    -- SAND TILES (8,8 to 11,11 - same pattern as grass)
    SAND_TOP_LEFT = {x = 8, y = 8, type = "sand"},
    SAND_TOP_CENTER = {x = 10, y = 8, type = "sand"},
    SAND_TOP_RIGHT = {x = 11, y = 8, type = "sand"},
    SAND_CENTER_LEFT = {x = 8, y = 9, type = "sand"},
    SAND_CENTER = {x = 9, y = 10, type = "sand"},
    SAND_CENTER_RIGHT = {x = 11, y = 10, type = "sand"},
    SAND_BOTTOM_LEFT = {x = 8, y = 11, type = "sand"},
    SAND_BOTTOM_CENTER = {x = 9, y = 11, type = "sand"},
    SAND_BOTTOM_RIGHT = {x = 11, y = 11, type = "sand"},
}

function TileMap:setTileType(tileTypeName)
    local tileData = TileMap.TILE_TYPES[tileTypeName]
    if tileData then
        self.tileType = tileData.type
        self.tilesetX = tileData.x
        self.tilesetY = tileData.y
    end
end

function TileMap:getTileQuad(tilesetWidth, tilesetHeight)
    return love.graphics.newQuad(
        self.tilesetX * self.tileSize,
        self.tilesetY * self.tileSize,
        self.tileSize,
        self.tileSize,
        tilesetWidth,
        tilesetHeight
    )
end

return TileMap