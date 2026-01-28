--!strict
--[[
    TerrainMaterials - Context-aware terrain material application
    Based on BRicey procedural generation techniques adapted for terrain materials.

    Applies terrain materials following a priority chain:
    1. Road proximity (cobblestone)
    2. Water proximity (sand)
    3. Landmark proximity (cobblestone/marble)
    4. Zone overlay (urban = paved, rural = grass)
    5. Base altitude (high = rock, low = grass)

    This module should be run AFTER terrain shape is generated.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MaterialConfig = require(Shared:WaitForChild("MaterialConfig"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

local TerrainMaterials = {}
TerrainMaterials.__index = TerrainMaterials
TerrainMaterials.VERSION = "1.0.0"

-- Constants
local DEFAULT_RESOLUTION = 4 -- Studs per terrain voxel
local DEFAULT_CELL_SIZE = Vector3.new(4, 4, 4)

export type TerrainMaterialsConfig = {
    terrain: Terrain?,
    worldPlan: WorldPlan.WorldPlanInstance?,
    resolution: number?,
    seed: number?,
}

export type TerrainMaterialsInstance = typeof(setmetatable(
    {} :: {
        terrain: Terrain,
        worldPlan: WorldPlan.WorldPlanInstance?,
        resolution: number,
        seed: number,
    },
    TerrainMaterials
))

function TerrainMaterials.new(config: TerrainMaterialsConfig?): TerrainMaterialsInstance
    local self = setmetatable({}, TerrainMaterials)
    local cfg = config or {}

    self.terrain = cfg.terrain or workspace.Terrain
    self.worldPlan = cfg.worldPlan
    self.resolution = cfg.resolution or DEFAULT_RESOLUTION
    self.seed = cfg.seed or math.random(1, 100000)

    print(string.format("[TerrainMaterials v%s] Initializing...", TerrainMaterials.VERSION))
    return self
end

-- Set the world plan (can be set after construction)
function TerrainMaterials:setWorldPlan(worldPlan: WorldPlan.WorldPlanInstance)
    self.worldPlan = worldPlan
end

-- Get material by altitude only (base layer)
function TerrainMaterials:_getMaterialByAltitude(altitude: number, x: number, z: number): Enum.Material
    local band = MaterialConfig.getAltitudeBand(altitude)

    -- Use noise for variety between primary and secondary
    local varietyNoise = math.noise(x * 0.02 + self.seed, z * 0.02 + self.seed * 1.3)

    -- Normalize noise from [-1, 1] to [0, 1]
    local normalizedNoise = (varietyNoise + 1) / 2

    -- Choose between primary and secondary based on noise
    if normalizedNoise < 0.6 then
        return band.primaryMaterial
    else
        return band.secondaryMaterial
    end
end

-- Get material for a zone type
function TerrainMaterials:_getZoneMaterial(zoneType: string, x: number, z: number): Enum.Material
    local zoneOverride = MaterialConfig.getZoneMaterial(zoneType)
    if not zoneOverride then
        return Enum.Material.Ground
    end

    -- Use noise for variety within the zone
    local varietyNoise = math.noise(x * 0.03 + self.seed + 500, z * 0.03 + self.seed * 1.5 + 500)
    local normalizedNoise = (varietyNoise + 1) / 2

    -- Grass percentage determines the chance of grass vs primary
    if normalizedNoise < zoneOverride.grassPercentage then
        return Enum.Material.Grass
    elseif normalizedNoise < zoneOverride.grassPercentage + 0.4 then
        return zoneOverride.primaryMaterial
    else
        return zoneOverride.secondaryMaterial
    end
end

-- Get material at a specific position following the priority chain
function TerrainMaterials:getMaterialAt(x: number, z: number): Enum.Material
    -- Get altitude for base material calculation
    local altitude = TerrainUtils.getHeightAt(self.terrain, x, z)

    -- 1. Start with base material from altitude
    local material = self:_getMaterialByAltitude(altitude, x, z)

    -- If no world plan, return altitude-based material
    if not self.worldPlan then
        return material
    end

    -- 2. Check zone override
    local zone = self.worldPlan:getZoneAt(x, z)
    material = self:_getZoneMaterial(zone, x, z)

    -- 3. Check landmark proximity (overrides zone)
    local landmarkInfo = self.worldPlan:getNearestLandmark(x, z)
    if landmarkInfo then
        local landmarkMaterial = MaterialConfig.getLandmarkMaterial(landmarkInfo.landmarkType)
        if landmarkMaterial and landmarkInfo.distance < MaterialConfig.PROXIMITY_RULES.structure.radius then
            return landmarkMaterial
        end
    end

    -- 4. Check water proximity (high priority override)
    local distanceToRiver = self.worldPlan:getDistanceToRiver(x, z)
    if distanceToRiver < MaterialConfig.PROXIMITY_RULES.river.radius then
        -- Gradient: closer to river = more sand
        local riverInfluence = 1 - (distanceToRiver / MaterialConfig.PROXIMITY_RULES.river.radius)
        local sandNoise = math.noise(x * 0.05 + self.seed + 1000, z * 0.05)
        if sandNoise + riverInfluence > 0.5 then
            return Enum.Material.Sand
        end
    end

    -- 5. Check road proximity (highest priority)
    if self.worldPlan:isOnRoad(x, z) then
        return Enum.Material.Cobblestone
    end

    local distanceToRoad = self.worldPlan:getDistanceToRoad(x, z)
    if distanceToRoad < MaterialConfig.PROXIMITY_RULES.road.radius then
        return Enum.Material.Cobblestone
    end

    return material
end

-- Apply materials to a region of terrain
function TerrainMaterials:applyToRegion(minX: number, maxX: number, minZ: number, maxZ: number)
    print(string.format("[TerrainMaterials v%s] Applying materials to region: (%d,%d) to (%d,%d)",
        TerrainMaterials.VERSION, minX, minZ, maxX, maxZ))

    local startTime = tick()
    local cellCount = 0

    for x = minX, maxX, self.resolution do
        for z = minZ, maxZ, self.resolution do
            local material = self:getMaterialAt(x, z)
            local height = TerrainUtils.getHeightAt(self.terrain, x, z)

            -- Only apply to surface (top layer)
            if height > 0 then
                local surfaceCFrame = CFrame.new(
                    x + self.resolution / 2,
                    height,
                    z + self.resolution / 2
                )

                -- Replace the top layer with the new material
                self.terrain:FillBlock(
                    surfaceCFrame,
                    DEFAULT_CELL_SIZE,
                    material
                )

                cellCount = cellCount + 1
            end
        end

        -- Yield periodically to prevent script timeout
        if x % 64 == 0 then
            task.wait()
        end
    end

    local elapsed = tick() - startTime
    print(string.format("[TerrainMaterials v%s] Applied materials to %d cells in %.2f seconds",
        TerrainMaterials.VERSION, cellCount, elapsed))
end

-- Apply materials to the entire map
function TerrainMaterials:applyAll()
    if not self.worldPlan then
        warn("[TerrainMaterials] No world plan set - materials will be altitude-based only")
    end

    local mapSize = if self.worldPlan then self.worldPlan:getMapSize() else 1024
    local halfSize = mapSize / 2

    print(string.format("[TerrainMaterials v%s] Starting full material pass for %dx%d map...",
        TerrainMaterials.VERSION, mapSize, mapSize))

    self:applyToRegion(-halfSize, halfSize - self.resolution, -halfSize, halfSize - self.resolution)
end

-- Get material statistics for a region (useful for testing/validation)
function TerrainMaterials:getMaterialStats(minX: number, maxX: number, minZ: number, maxZ: number): { [string]: number }
    local stats: { [string]: number } = {}
    local totalCells = 0

    for x = minX, maxX, self.resolution do
        for z = minZ, maxZ, self.resolution do
            local material = self:getMaterialAt(x, z)
            local materialName = material.Name

            stats[materialName] = (stats[materialName] or 0) + 1
            totalCells = totalCells + 1
        end
    end

    -- Convert counts to percentages
    for materialName, count in pairs(stats) do
        stats[materialName] = count / totalCells
    end

    return stats
end

return TerrainMaterials
