--!strict
--[[
    SpatialManager - Central spatial awareness system

    Provides world awareness without tight coupling between systems.
    Uses a grid-based approach for O(1) cell lookups.

    Integrates with WorldPlan for zones and roads.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpatialManager = {}
SpatialManager.__index = SpatialManager
SpatialManager.VERSION = "1.0.0"

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
local SpatialConfig = require(Shared:WaitForChild("SpatialConfig"))
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

-- Type definitions
export type Structure = {
    name: string,
    position: Vector3,
    size: Vector3,
    cellKeys: { string },
}

export type SpatialInfo = {
    terrainHeight: number,
    zone: string,
    isOccupied: boolean,
    occupiedBy: string?,
    structureName: string?,
}

export type SpatialManagerConfig = {
    worldPlan: any, -- WorldPlanInstance
    mapSize: number?,
    cellSize: number?,
}

export type SpatialManagerInstance = typeof(setmetatable(
    {} :: {
        worldPlan: any,
        mapSize: number,
        cellSize: number,
        cells: { [string]: { structures: { Structure } } },
        structures: { [string]: Structure },
        terrain: Terrain,
    },
    SpatialManager
))

-- Helper function to get cell key from world coordinates
local function getCellKey(cellSize: number, x: number, z: number): string
    local cellX = math.floor(x / cellSize)
    local cellZ = math.floor(z / cellSize)
    return string.format("%d,%d", cellX, cellZ)
end

-- Helper function to get all cell keys that a bounding box overlaps
local function getCellKeysForArea(cellSize: number, x: number, z: number, sizeX: number, sizeZ: number): { string }
    local halfX = sizeX / 2
    local halfZ = sizeZ / 2

    local minCellX = math.floor((x - halfX) / cellSize)
    local maxCellX = math.floor((x + halfX) / cellSize)
    local minCellZ = math.floor((z - halfZ) / cellSize)
    local maxCellZ = math.floor((z + halfZ) / cellSize)

    local keys = {}
    for cx = minCellX, maxCellX do
        for cz = minCellZ, maxCellZ do
            table.insert(keys, string.format("%d,%d", cx, cz))
        end
    end

    return keys
end

-- Create a new SpatialManager instance
function SpatialManager.new(config: SpatialManagerConfig): SpatialManagerInstance
    local self = setmetatable({}, SpatialManager)

    self.worldPlan = config.worldPlan
    self.mapSize = config.mapSize or SpatialConfig.DEFAULT_MAP_SIZE
    self.cellSize = config.cellSize or SpatialConfig.CELL_SIZE
    self.cells = {}
    self.structures = {}
    self.terrain = workspace.Terrain

    print(string.format(
        "[SpatialManager v%s] Initialized with cell size %d, map size %d",
        SpatialManager.VERSION,
        self.cellSize,
        self.mapSize
    ))

    return self
end

-- Get or create a cell at the given key
function SpatialManager._getOrCreateCell(self: SpatialManagerInstance, key: string): { structures: { Structure } }
    if not self.cells[key] then
        self.cells[key] = { structures = {} }
    end
    return self.cells[key]
end

-- Query information about a single point
function SpatialManager.queryPoint(self: SpatialManagerInstance, x: number, z: number): SpatialInfo
    -- Get terrain height
    local terrainHeight = TerrainUtils.getHeightAt(self.terrain, x, z)

    -- Get zone from WorldPlan
    local zone = self.worldPlan:getZoneAt(x, z)

    -- Check if occupied by a structure
    local cellKey = getCellKey(self.cellSize, x, z)
    local cell = self.cells[cellKey]

    local isOccupied = false
    local occupiedBy: string? = nil
    local structureName: string? = nil

    if cell then
        for _, structure in ipairs(cell.structures) do
            -- Check if point is within structure bounds
            local dx = math.abs(x - structure.position.X)
            local dz = math.abs(z - structure.position.Z)
            local halfX = structure.size.X / 2
            local halfZ = structure.size.Z / 2

            if dx <= halfX and dz <= halfZ then
                isOccupied = true
                occupiedBy = "structure"
                structureName = structure.name
                break
            end
        end
    end

    return {
        terrainHeight = terrainHeight,
        zone = zone,
        isOccupied = isOccupied,
        occupiedBy = occupiedBy,
        structureName = structureName,
    }
end

-- Register a structure in the spatial grid
function SpatialManager.registerStructure(
    self: SpatialManagerInstance,
    name: string,
    position: Vector3,
    size: Vector3
): boolean
    -- Check if structure already exists
    if self.structures[name] then
        warn(string.format("[SpatialManager] Structure '%s' already registered", name))
        return false
    end

    -- Get all cells this structure occupies
    local cellKeys = getCellKeysForArea(self.cellSize, position.X, position.Z, size.X, size.Z)

    local structure: Structure = {
        name = name,
        position = position,
        size = size,
        cellKeys = cellKeys,
    }

    -- Register in all cells
    for _, key in ipairs(cellKeys) do
        local cell = self:_getOrCreateCell(key)
        table.insert(cell.structures, structure)
    end

    -- Store reference
    self.structures[name] = structure

    return true
end

-- Unregister a structure from the spatial grid
function SpatialManager.unregisterStructure(self: SpatialManagerInstance, name: string): boolean
    local structure = self.structures[name]
    if not structure then
        return false
    end

    -- Remove from all cells
    for _, key in ipairs(structure.cellKeys) do
        local cell = self.cells[key]
        if cell then
            for i, s in ipairs(cell.structures) do
                if s.name == name then
                    table.remove(cell.structures, i)
                    break
                end
            end
        end
    end

    -- Remove reference
    self.structures[name] = nil

    return true
end

-- Check if an area is free for placement
function SpatialManager.canPlaceAt(
    self: SpatialManagerInstance,
    x: number,
    z: number,
    sizeX: number,
    sizeZ: number
): (boolean, string?)
    -- Check WorldPlan constraints first (river, landmarks)
    local canPlace, reason = self.worldPlan:canPlaceStructure(x, z, Vector2.new(sizeX, sizeZ))
    if not canPlace then
        return false, reason
    end

    -- Check if on road
    if self.worldPlan:isOnRoad(x, z) then
        return false, "Cannot place on road"
    end

    -- Get all cells this placement would occupy
    local cellKeys = getCellKeysForArea(self.cellSize, x, z, sizeX, sizeZ)
    local padding = SpatialConfig.PLACEMENT.STRUCTURE_PADDING

    -- Check each cell for existing structures
    for _, key in ipairs(cellKeys) do
        local cell = self.cells[key]
        if cell then
            for _, structure in ipairs(cell.structures) do
                -- Check for overlap with padding
                local dx = math.abs(x - structure.position.X)
                local dz = math.abs(z - structure.position.Z)
                local combinedHalfX = (sizeX + structure.size.X) / 2 + padding
                local combinedHalfZ = (sizeZ + structure.size.Z) / 2 + padding

                if dx < combinedHalfX and dz < combinedHalfZ then
                    return false, string.format("Overlaps existing structure: %s", structure.name)
                end
            end
        end
    end

    return true, nil
end

-- Check if a position is near a road
function SpatialManager.isNearRoad(self: SpatialManagerInstance, x: number, z: number, distance: number): boolean
    local distanceToRoad = self.worldPlan:getDistanceToRoad(x, z)
    return distanceToRoad <= distance
end

-- Get distance to nearest road
function SpatialManager.getDistanceToRoad(self: SpatialManagerInstance, x: number, z: number): number
    return self.worldPlan:getDistanceToRoad(x, z)
end

-- Get all structures in the spatial grid
function SpatialManager.getStructures(self: SpatialManagerInstance): { [string]: Structure }
    return self.structures
end

-- Get structure by name
function SpatialManager.getStructure(self: SpatialManagerInstance, name: string): Structure?
    return self.structures[name]
end

-- Get the number of occupied cells
function SpatialManager.getOccupiedCellCount(self: SpatialManagerInstance): number
    local count = 0
    for _ in pairs(self.cells) do
        count = count + 1
    end
    return count
end

-- Get the total number of registered structures
function SpatialManager.getStructureCount(self: SpatialManagerInstance): number
    local count = 0
    for _ in pairs(self.structures) do
        count = count + 1
    end
    return count
end

return SpatialManager
