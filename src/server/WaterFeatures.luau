--!strict
--[[
    WaterFeatures - Creates Roman water features (fountains, rivers)
    Demonstrates CRITICAL water architecture: Water Terrain inside Part-built walls
    Based on BRicey techniques for procedural environment generation

    Fountain System:
    - Multiple fountains across the map (from FountainConfig)
    - 4 types: Basin, Impluvium, PublicFountain, Nymphaeum
    - Proper depth (4-6 studs) and containment
    - Walls extend above water surface
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaterFeatures = {}
WaterFeatures.__index = WaterFeatures
WaterFeatures.VERSION = "2.2.0"

-- Import WaterPool module (same folder)
local WaterPool = require(script.Parent.WaterPool)

-- Type for configuration
export type WaterFeaturesConfig = {
    enableFountains: boolean?, -- Enable fountain system (default: true)
    enableRiver: boolean?, -- Enable river (default: true)
    customFountainPlacements: any?, -- Custom fountain placements (optional)
    riverStartPosition: Vector3?, -- Custom river start (default valley)
    worldPlan: any?, -- WorldPlan instance for river exclusion checks
}

export type WaterFeaturesInstance = typeof(setmetatable(
    {} :: {
        config: WaterFeaturesConfig,
        fountainPools: { typeof(WaterPool.new({} :: any)) },
        riverPools: { typeof(WaterPool.new({} :: any)) },
        terrainUtils: any,
        terrain: Terrain,
        fountainConfig: any,
        constants: any,
        worldPlan: any?,
    },
    WaterFeatures
))

-- Roman color palette for river
local ROCK_GRAY = Color3.fromRGB(120, 110, 100)

function WaterFeatures.new(config: WaterFeaturesConfig?): WaterFeaturesInstance
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
    local FountainConfig = require(Shared:WaitForChild("FountainConfig"))
    local Constants = require(Shared:WaitForChild("Constants"))

    local self = setmetatable({}, WaterFeatures)
    self.config = config or {}
    self.fountainPools = {} :: { typeof(WaterPool.new({} :: any)) }
    self.riverPools = {} :: { typeof(WaterPool.new({} :: any)) }
    self.terrainUtils = TerrainUtils
    self.terrain = workspace.Terrain
    self.fountainConfig = FountainConfig
    self.constants = Constants
    self.worldPlan = (config or {}).worldPlan

    print(string.format("[WaterFeatures v%s] Initializing...", WaterFeatures.VERSION))
    return self
end

function WaterFeatures:start()
    local config = self.config

    -- Default: enable both features
    local enableFountains = config.enableFountains ~= false
    local enableRiver = config.enableRiver ~= false

    if enableFountains then
        self:_createAllFountains()
    end

    if enableRiver then
        self:_createRiver()
    end

    print(string.format("[WaterFeatures v%s] Water features created", WaterFeatures.VERSION))
end

function WaterFeatures:_createAllFountains()
    local FountainConfig = self.fountainConfig
    local TerrainUtils = self.terrainUtils
    local Constants = self.constants

    -- Get placements (custom or default)
    local placements = self.config.customFountainPlacements or FountainConfig.getDefaultPlacements()
    local maxFountainSlope = Constants.SLOPE.MAX_FOUNTAIN_SLOPE
    local sampleDistance = Constants.SLOPE.SAMPLE_DISTANCE

    print(string.format("[WaterFeatures v%s] Evaluating %d fountain placements...", WaterFeatures.VERSION, #placements))

    local skippedCount = 0
    local skippedRiverCount = 0
    for _, placement in ipairs(placements) do
        local x, z = placement.position.X, placement.position.Z

        -- Check river exclusion zone FIRST (before slope check)
        if self.worldPlan and self.worldPlan:isInRiverExclusionZone(x, z) then
            print(string.format(
                "[WaterFeatures v%s] Skipping fountain '%s' at (%.0f, %.0f) - inside river exclusion zone",
                WaterFeatures.VERSION,
                placement.name or "unnamed",
                x,
                z
            ))
            skippedRiverCount = skippedRiverCount + 1
            continue
        end

        local isFlatEnough = TerrainUtils.isFlatEnoughDegrees(self.terrain, x, z, maxFountainSlope, sampleDistance)

        if isFlatEnough then
            self:_createFountain(placement)
        else
            local slope = TerrainUtils.getMaxSlopeDegrees(self.terrain, x, z, sampleDistance)
            print(string.format(
                "[WaterFeatures v%s] Skipping fountain '%s' at (%.0f, %.0f) - slope %.1f° exceeds max %.0f°",
                WaterFeatures.VERSION,
                placement.name or "unnamed",
                x,
                z,
                slope,
                maxFountainSlope
            ))
            skippedCount = skippedCount + 1
        end
    end

    print(string.format(
        "[WaterFeatures v%s] Created %d fountains, skipped %d due to steep terrain, %d due to river proximity",
        WaterFeatures.VERSION,
        #self.fountainPools,
        skippedCount,
        skippedRiverCount
    ))
end

function WaterFeatures:_createFountain(placement: any)
    local FountainConfig = self.fountainConfig

    -- Get type config
    local typeConfig = FountainConfig.getTypeConfig(placement.fountainType)

    -- Create fountain name
    local fountainName = placement.name or string.format(
        "%s_%.0f_%.0f",
        typeConfig.name,
        placement.position.X,
        placement.position.Z
    )

    -- Create the fountain pool with proper containment
    local fountain = WaterPool.new({
        position = placement.position,
        size = typeConfig.size,
        wallMaterial = typeConfig.wallMaterial,
        wallColor = typeConfig.wallColor,
        wallThickness = typeConfig.wallThickness,
        rimHeight = typeConfig.rimHeight,
        name = fountainName,
    })

    fountain:build()
    table.insert(self.fountainPools, fountain)

    print(string.format(
        "[WaterFeatures v%s] Created %s '%s' at (%.0f, %.0f) - depth: %.0f, rim: %.0f",
        WaterFeatures.VERSION,
        typeConfig.name,
        fountainName,
        placement.position.X,
        placement.position.Z,
        typeConfig.size.Y,
        typeConfig.rimHeight
    ))
end

function WaterFeatures:_createRiver()
    -- River runs through terrain - series of connected pool segments
    -- Default: runs roughly north-south through the western side of the map
    local riverStart = self.config.riverStartPosition or Vector3.new(200, 0, 100)

    -- River segments follow a meandering path
    -- Each segment slightly offsets from previous for natural curve
    local riverSegments = {
        { offset = Vector3.new(0, 0, 0), size = Vector3.new(18, 5, 60) },
        { offset = Vector3.new(-15, 0, 55), size = Vector3.new(20, 5, 60) },
        { offset = Vector3.new(-25, 0, 110), size = Vector3.new(18, 5, 60) },
        { offset = Vector3.new(-20, 0, 165), size = Vector3.new(22, 5, 60) },
        { offset = Vector3.new(-10, 0, 220), size = Vector3.new(18, 5, 60) },
    }

    for i, segment in ipairs(riverSegments) do
        local segmentPos = riverStart + segment.offset

        local riverPool = WaterPool.new({
            position = segmentPos,
            size = segment.size,
            wallMaterial = Enum.Material.Rock,
            wallColor = ROCK_GRAY,
            wallThickness = 2,
            rimHeight = 1, -- River banks extend 1 stud above water
            name = string.format("River_Segment_%d", i),
        })

        riverPool:build()
        table.insert(self.riverPools, riverPool)
    end

    print(string.format(
        "[WaterFeatures v%s] Created river with %d segments starting at (%.0f, %.0f)",
        WaterFeatures.VERSION,
        #riverSegments,
        riverStart.X,
        riverStart.Z
    ))
end

function WaterFeatures:getFountainCount(): number
    return #self.fountainPools
end

function WaterFeatures:getRiverSegmentCount(): number
    return #self.riverPools
end

function WaterFeatures:destroy()
    -- Destroy all fountains
    for _, fountain in ipairs(self.fountainPools) do
        fountain:destroy()
    end
    self.fountainPools = {}

    -- Destroy river segments
    for _, riverPool in ipairs(self.riverPools) do
        riverPool:destroy()
    end
    self.riverPools = {}

    print(string.format("[WaterFeatures v%s] Destroyed all water features", WaterFeatures.VERSION))
end

return WaterFeatures
