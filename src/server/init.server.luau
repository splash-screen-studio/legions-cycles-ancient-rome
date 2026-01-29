--!strict
-- Server Entry Point - Bootstraps all server systems

local VERSION = "1.5.0"
print(string.format("[Server v%s] Starting...", VERSION))

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to be available
print("[Server] Waiting for Shared folder...")
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
    error("[Server] FATAL: Shared folder not found in ReplicatedStorage!")
end
print("[Server] Found Shared folder")

-- Require server modules
-- CRITICAL: WorldPlanGenerator must be loaded FIRST as all other systems depend on it
local WorldPlanGenerator = require(script.WorldPlanGenerator)
print(string.format("[Server] Loaded WorldPlanGenerator v%s", WorldPlanGenerator.VERSION))

local TerrainManager = require(script.TerrainManager)
print(string.format("[Server] Loaded TerrainManager v%s", TerrainManager.VERSION))

local MapBoundary = require(script.MapBoundary)
print(string.format("[Server] Loaded MapBoundary v%s", MapBoundary.VERSION))

local SpawnManager = require(script.SpawnManager)
print(string.format("[Server] Loaded SpawnManager v%s", SpawnManager.VERSION))

local WaterFeatures = require(script.WaterFeatures)
print(string.format("[Server] Loaded WaterFeatures v%s", WaterFeatures.VERSION))

local RiverBuilder = require(script.RiverBuilder)
print(string.format("[Server] Loaded RiverBuilder v%s", RiverBuilder.VERSION))

local TerrainMaterials = require(script.TerrainMaterials)
print(string.format("[Server] Loaded TerrainMaterials v%s", TerrainMaterials.VERSION))

local BridgeBuilder = require(script.BridgeBuilder)
print(string.format("[Server] Loaded BridgeBuilder v%s", BridgeBuilder.VERSION))

local LandmarkBuilder = require(script.LandmarkBuilder)
print(string.format("[Server] Loaded LandmarkBuilder v%s", LandmarkBuilder.VERSION))

local AqueductBuilder = require(script.AqueductBuilder)
print(string.format("[Server] Loaded AqueductBuilder v%s", AqueductBuilder.VERSION))

-- Configuration
local MAP_SIZE = 1024

-- STEP 1: Generate World Plan FIRST (single source of truth)
-- This defines the abstract layout that all other systems query
local worldPlanGenerator = WorldPlanGenerator.new({
    mapSize = MAP_SIZE,
})
local worldPlan = worldPlanGenerator:generate()

-- Store world plan in a ModuleScript for other systems to access
-- (In production, this would be stored in a shared location)
print(string.format("[Server] World plan created - %d landmarks, %d roads",
    #worldPlan:getLandmarks(),
    #worldPlan:getRoads()
))

-- STEP 2: Generate Terrain (queries WorldPlan for river to make low points)
local terrainManager = TerrainManager.new({
    size = MAP_SIZE,
    baseHeight = 20,
    heightAmplitude = 40,
    noiseScale = 0.01,
    worldPlan = worldPlan, -- Pass world plan for river corridor depression
})
terrainManager:generate()

-- STEP 3: Build River Structure (after terrain, before other features)
local riverBuilder = RiverBuilder.new({
    worldPlan = worldPlan,
})
riverBuilder:build()

-- STEP 4: Apply context-aware terrain materials
-- This must run AFTER terrain shape is generated
local terrainMaterials = TerrainMaterials.new({
    terrain = workspace.Terrain,
    worldPlan = worldPlan,
})
terrainMaterials:applyAll()

-- STEP 5: Build bridges at road/river intersections
local bridgeBuilder = BridgeBuilder.new({
    worldPlan = worldPlan,
})
bridgeBuilder:build()

-- STEP 6: Build pre-built landmarks (Forum, Colosseum, Temples, etc.)
-- These make the world feel inhabited from the start
local landmarkBuilder = LandmarkBuilder.new({
    worldPlan = worldPlan,
})
landmarkBuilder:build()

-- STEP 7: Build aqueduct spanning the map (after landmarks to avoid them)
-- Creates iconic Roman aqueduct with functional and ruined sections
local aqueductBuilder = AqueductBuilder.new({
    worldPlan = worldPlan,
})
aqueductBuilder:build()

-- Bootstrap map boundary walls
local mapBoundary = MapBoundary.new({
    mapSize = MAP_SIZE,
    wallHeight = 200,
    wallTransparency = 0.8,
})
mapBoundary:generate()

-- Bootstrap spawn manager (must be after terrain generation)
local spawnManager = SpawnManager.new({
    position = Vector3.new(400, 0, 400), -- Southeast quadrant
    facingDirection = Vector3.new(-1, 0, -1).Unit, -- Face northwest toward map center
    spawnRadius = 10,
})
spawnManager:start()

-- Bootstrap water features (must be after terrain generation)
-- NOTE: River is now handled by RiverBuilder, fountains from FountainConfig
local waterFeatures = WaterFeatures.new({
    enableFountains = true, -- Creates multiple fountains from FountainConfig
    enableRiver = false, -- Disabled: river now built by RiverBuilder
})
waterFeatures:start()

print(string.format("[Server v%s] All systems initialized", VERSION))
