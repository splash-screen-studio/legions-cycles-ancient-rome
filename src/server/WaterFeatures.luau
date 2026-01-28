--!strict
--[[
    WaterFeatures - Creates Roman water features (fountains, rivers)
    Demonstrates CRITICAL water architecture: Water Terrain inside Part-built walls
    Based on BRicey techniques for procedural environment generation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaterFeatures = {}
WaterFeatures.__index = WaterFeatures
WaterFeatures.VERSION = "1.0.0"

-- Import WaterPool module (same folder)
local WaterPool = require(script.Parent.WaterPool)

-- Type for configuration
export type WaterFeaturesConfig = {
    fountainPosition: Vector3?, -- Custom fountain position (default near spawn)
    riverStartPosition: Vector3?, -- Custom river start (default valley)
    enableFountain: boolean?,
    enableRiver: boolean?,
}

export type WaterFeaturesInstance = typeof(setmetatable(
    {} :: {
        config: WaterFeaturesConfig,
        fountainPool: typeof(WaterPool.new({} :: any))?,
        riverPools: { typeof(WaterPool.new({} :: any)) },
        terrainUtils: any,
        terrain: Terrain,
    },
    WaterFeatures
))

-- Roman color palette
local MARBLE_WHITE = Color3.fromRGB(245, 240, 230)
local ROCK_GRAY = Color3.fromRGB(120, 110, 100)

function WaterFeatures.new(config: WaterFeaturesConfig?): WaterFeaturesInstance
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

    local self = setmetatable({}, WaterFeatures)
    self.config = config or {}
    self.fountainPool = nil
    self.riverPools = {} :: { typeof(WaterPool.new({} :: any)) }
    self.terrainUtils = TerrainUtils
    self.terrain = workspace.Terrain

    print(string.format("[WaterFeatures v%s] Initializing...", WaterFeatures.VERSION))
    return self
end

function WaterFeatures:start()
    local config = self.config

    -- Default: enable both features
    local enableFountain = config.enableFountain ~= false
    local enableRiver = config.enableRiver ~= false

    if enableFountain then
        self:_createFountain()
    end

    if enableRiver then
        self:_createRiver()
    end

    print(string.format("[WaterFeatures v%s] Water features created", WaterFeatures.VERSION))
end

function WaterFeatures:_createFountain()
    -- Fountain position near spawn area (default: southeast quadrant, near player spawn)
    local fountainPos = self.config.fountainPosition or Vector3.new(350, 0, 350)

    -- Roman Impluvium-style fountain: square marble basin
    -- Size: 20x20 studs, 3 studs deep
    local fountain = WaterPool.new({
        position = fountainPos,
        size = Vector3.new(20, 3, 20),
        wallMaterial = Enum.Material.Marble,
        wallColor = MARBLE_WHITE,
        wallThickness = 1,
        name = "RomanFountain_Impluvium",
    })

    fountain:build()
    self.fountainPool = fountain

    print(string.format(
        "[WaterFeatures v%s] Created Roman fountain at (%.0f, %.0f)",
        WaterFeatures.VERSION,
        fountainPos.X,
        fountainPos.Z
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

function WaterFeatures:destroy()
    -- Destroy fountain
    if self.fountainPool then
        self.fountainPool:destroy()
        self.fountainPool = nil
    end

    -- Destroy river segments
    for _, riverPool in ipairs(self.riverPools) do
        riverPool:destroy()
    end
    self.riverPools = {}

    print(string.format("[WaterFeatures v%s] Destroyed all water features", WaterFeatures.VERSION))
end

return WaterFeatures
