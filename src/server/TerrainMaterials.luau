--!strict
--[[
    TerrainMaterials - Context-aware terrain material application
    Based on BRicey procedural generation techniques adapted for terrain materials.

    Applies terrain materials following a priority chain:
    1. Road proximity (cobblestone)
    2. Water proximity (sand beach + grass ring)
    3. Landmark proximity (cobblestone/marble)
    4. Zone overlay (urban = paved, rural = grass)
    5. Slope-based (steep = rocky/arid)
    6. Base altitude (high = rock, low = grass)

    This module should be run AFTER terrain shape is generated.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MaterialConfig = require(Shared:WaitForChild("MaterialConfig"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

local TerrainMaterials = {}
TerrainMaterials.__index = TerrainMaterials
TerrainMaterials.VERSION = "2.1.0"

-- Constants
local DEFAULT_RESOLUTION = 4 -- Studs per terrain voxel
local DEFAULT_CELL_SIZE = Vector3.new(4, 4, 4)
local SLOPE_SAMPLE_DISTANCE = 4 -- Distance for slope calculation

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

    -- Check for grass based on band's grass percentage
    if normalizedNoise < band.grassPercentage then
        return Enum.Material.Grass
    elseif normalizedNoise < band.grassPercentage + 0.5 then
        return band.primaryMaterial
    else
        return band.secondaryMaterial
    end
end

-- Get material by slope (steeper = more arid/rocky)
function TerrainMaterials:_getMaterialBySlope(slopeDegrees: number, x: number, z: number): Enum.Material
    local band = MaterialConfig.getSlopeBand(slopeDegrees)

    -- Use noise for variety
    local varietyNoise = math.noise(x * 0.025 + self.seed + 200, z * 0.025 + self.seed * 1.4 + 200)
    local normalizedNoise = (varietyNoise + 1) / 2

    -- Check for grass based on slope band's grass percentage
    if normalizedNoise < band.grassPercentage then
        return Enum.Material.Grass
    elseif normalizedNoise < band.grassPercentage + 0.5 then
        return band.primaryMaterial
    else
        return band.secondaryMaterial
    end
end

-- Combine altitude and slope for base material (Mediterranean terrain)
-- Rebalanced in v2.1.0: Less aggressive rock on moderate slopes (issue #148)
function TerrainMaterials:_getBaseMaterial(altitude: number, slopeDegrees: number, x: number, z: number): Enum.Material
    -- Only very steep slopes override altitude-based selection (raised from 25 to 30)
    if slopeDegrees >= 30 then
        return self:_getMaterialBySlope(slopeDegrees, x, z)
    elseif slopeDegrees >= 18 then
        -- Moderate slopes: blend altitude and slope influence (raised from 15 to 18)
        local altitudeMaterial = self:_getMaterialByAltitude(altitude, x, z)
        local slopeMaterial = self:_getMaterialBySlope(slopeDegrees, x, z)

        -- Use noise to decide which to use
        local blendNoise = math.noise(x * 0.03 + self.seed + 300, z * 0.03 + self.seed * 1.6 + 300)
        local slopeInfluence = (slopeDegrees - 18) / 12 -- 0 at 18 degrees, 1 at 30 degrees

        -- Bias toward altitude-based (more grass) by requiring stronger slope influence
        if (blendNoise + 1) / 2 < slopeInfluence * 0.7 then
            return slopeMaterial
        else
            return altitudeMaterial
        end
    else
        -- Gentle terrain: use altitude-based selection
        return self:_getMaterialByAltitude(altitude, x, z)
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
    -- Get altitude and slope for base material calculation
    local altitude = TerrainUtils.getHeightAt(self.terrain, x, z)
    local slopeDegrees = TerrainUtils.getMaxSlopeDegrees(self.terrain, x, z, SLOPE_SAMPLE_DISTANCE)

    -- 1. Start with base material from altitude and slope (Mediterranean terrain)
    local material = self:_getBaseMaterial(altitude, slopeDegrees, x, z)

    -- If no world plan, return terrain-based material
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

    -- 4. Check water proximity (creates lush vegetation bands)
    local distanceToRiver = self.worldPlan:getDistanceToRiver(x, z)

    -- Inner band: sand beach at water edge
    if distanceToRiver < MaterialConfig.PROXIMITY_RULES.river.radius then
        local riverInfluence = 1 - (distanceToRiver / MaterialConfig.PROXIMITY_RULES.river.radius)
        local sandNoise = math.noise(x * 0.05 + self.seed + 1000, z * 0.05)
        if sandNoise + riverInfluence > 0.4 then
            return Enum.Material.Sand
        end
    -- Outer band: lush grass near water (Mediterranean oasis effect)
    elseif distanceToRiver < MaterialConfig.PROXIMITY_RULES.riverGrass.radius then
        local grassInfluence = 1 - ((distanceToRiver - MaterialConfig.PROXIMITY_RULES.river.radius) /
            (MaterialConfig.PROXIMITY_RULES.riverGrass.radius - MaterialConfig.PROXIMITY_RULES.river.radius))
        local grassNoise = math.noise(x * 0.04 + self.seed + 1500, z * 0.04 + self.seed)
        -- Higher grass chance near water
        if (grassNoise + 1) / 2 < (0.5 + grassInfluence * 0.4) then
            return Enum.Material.Grass
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
    local skippedRiverCells = 0

    for x = minX, maxX, self.resolution do
        for z = minZ, maxZ, self.resolution do
            -- CRITICAL: Skip cells that are inside the river corridor
            -- This prevents overwriting the water terrain placed by RiverBuilder
            if self.worldPlan and self.worldPlan:isOnRiver(x, z) then
                skippedRiverCells = skippedRiverCells + 1
                continue
            end

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
    print(string.format("[TerrainMaterials v%s] Applied materials to %d cells in %.2f seconds (skipped %d river cells)",
        TerrainMaterials.VERSION, cellCount, elapsed, skippedRiverCells))
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
