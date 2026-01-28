--!strict
-- Server Entry Point - Bootstraps all server systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to be available
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Require and initialize server modules
local TerrainManager = require(script.TerrainManager)

-- Bootstrap terrain
local terrainManager = TerrainManager.new({
    size = 512,
    baseHeight = 20,
    heightAmplitude = 40,
    noiseScale = 0.01,
})
terrainManager:generate()

print("[Server] All systems initialized")
