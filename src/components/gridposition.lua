-- GridPosition component for grid-based positioning

local GridPosition = {}
GridPosition.__index = GridPosition

function GridPosition:new(row, col)
    local gridPos = {
        row = row or 0,
        col = col or 0,
        entity = nil
    }
    setmetatable(gridPos, self)
    return gridPos
end

function GridPosition:setPosition(row, col)
    self.row = row
    self.col = col
end

function GridPosition:getPosition()
    return self.row, self.col
end

function GridPosition:distanceTo(other)
    local dx = self.col - other.col
    local dy = self.row - other.row
    return math.sqrt(dx * dx + dy * dy)
end

function GridPosition:manhattanDistanceTo(other)
    return math.abs(self.col - other.col) + math.abs(self.row - other.row)
end

return GridPosition