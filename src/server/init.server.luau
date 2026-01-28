--!strict
-- Server Entry Point - Bootstraps all server systems

local VERSION = "1.1.0"
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
})
terrainManager:generate()

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
local waterFeatures = WaterFeatures.new({
    fountainPosition = Vector3.new(350, 0, 350), -- Near spawn area
    riverStartPosition = Vector3.new(200, 0, 100), -- Western valley
    enableFountain = true,
    enableRiver = true,
})
waterFeatures:start()

print(string.format("[Server v%s] All systems initialized", VERSION))
