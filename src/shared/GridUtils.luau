--!strict
--[[
    GridUtils - Grid snapping and alignment utilities for Roman grid layouts
    Based on BRicey Grid Snapping techniques
]]

local GridUtils = {}
local GridUtils = {}.VERSION = "1.0.0"

export type TerrainManager = {
    getHeightAt: (self: TerrainManager, x: number, z: number) -> number,
}

--- Snap a position to the nearest grid point with terrain height adaptation
function GridUtils.snapToGrid(position: Vector3, gridSize: number, terrainManager: TerrainManager?): Vector3
    if gridSize <= 0 then
        return position
    end

    local snappedX = math.round(position.X / gridSize) * gridSize
    local snappedZ = math.round(position.Z / gridSize) * gridSize

    local terrainY: number
    if terrainManager then
        terrainY = terrainManager:getHeightAt(snappedX, snappedZ)
    else
        terrainY = position.Y
    end

    return Vector3.new(snappedX, terrainY, snappedZ)
end

--- Snap only the X and Z coordinates to grid, preserving Y
function GridUtils.snapToGridXZ(position: Vector3, gridSize: number): Vector3
    if gridSize <= 0 then
        return position
    end

    local snappedX = math.round(position.X / gridSize) * gridSize
    local snappedZ = math.round(position.Z / gridSize) * gridSize

    return Vector3.new(snappedX, position.Y, snappedZ)
end

--- Check if a position is aligned to the grid (X and Z only)
function GridUtils.isOnGrid(position: Vector3, gridSize: number): boolean
    if gridSize <= 0 then
        return true
    end

    local tolerance = 0.001
    local xRemainder = math.abs(position.X % gridSize)
    local zRemainder = math.abs(position.Z % gridSize)

    return (xRemainder < tolerance or xRemainder > gridSize - tolerance)
        and (zRemainder < tolerance or zRemainder > gridSize - tolerance)
end

--- Get the grid cell coordinates for a position
function GridUtils.getGridCell(position: Vector3, gridSize: number): (number, number)
    if gridSize <= 0 then
        return 0, 0
    end

    local cellX = math.floor(position.X / gridSize)
    local cellZ = math.floor(position.Z / gridSize)

    return cellX, cellZ
end

--- Get the world position of a grid cell center
function GridUtils.getCellCenter(cellX: number, cellZ: number, gridSize: number, terrainManager: TerrainManager?): Vector3
    local worldX = (cellX + 0.5) * gridSize
    local worldZ = (cellZ + 0.5) * gridSize

    local terrainY: number
    if terrainManager then
        terrainY = terrainManager:getHeightAt(worldX, worldZ)
    else
        terrainY = 0
    end

    return Vector3.new(worldX, terrainY, worldZ)
end

--- Get the world position of a grid cell corner (bottom-left)
function GridUtils.getCellCorner(cellX: number, cellZ: number, gridSize: number, terrainManager: TerrainManager?): Vector3
    local worldX = cellX * gridSize
    local worldZ = cellZ * gridSize

    local terrainY: number
    if terrainManager then
        terrainY = terrainManager:getHeightAt(worldX, worldZ)
    else
        terrainY = 0
    end

    return Vector3.new(worldX, terrainY, worldZ)
end

--- Iterate over grid cells in a rectangular region
function GridUtils.iterateCells(
    minX: number,
    minZ: number,
    maxX: number,
    maxZ: number,
    gridSize: number
): () -> (number?, number?)
    if gridSize <= 0 then
        local done = false
        return function()
            if done then
                return nil, nil
            end
            done = true
            return 0, 0
        end
    end

    local startCellX = math.floor(minX / gridSize)
    local startCellZ = math.floor(minZ / gridSize)
    local endCellX = math.floor(maxX / gridSize)
    local endCellZ = math.floor(maxZ / gridSize)

    local currentX = startCellX
    local currentZ = startCellZ

    return function(): (number?, number?)
        if currentZ > endCellZ then
            return nil, nil
        end

        local returnX, returnZ = currentX, currentZ

        currentX = currentX + 1
        if currentX > endCellX then
            currentX = startCellX
            currentZ = currentZ + 1
        end

        return returnX, returnZ
    end
end

return GridUtils
