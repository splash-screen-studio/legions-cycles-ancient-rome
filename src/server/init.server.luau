--!strict
-- Server Entry Point - Bootstraps all server systems

local VERSION = "1.0.0"
print(string.format("[Server v%s] Starting...", VERSION))

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to be available
print("[Server] Waiting for Shared folder...")
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
    error("[Server] FATAL: Shared folder not found in ReplicatedStorage!")
end
print("[Server] Found Shared folder")

-- Require and initialize server modules
local TerrainManager = require(script.TerrainManager)
print(string.format("[Server] Loaded TerrainManager v%s", TerrainManager.VERSION))

-- Bootstrap terrain
local terrainManager = TerrainManager.new({
    size = 1024,
    baseHeight = 20,
    heightAmplitude = 40,
    noiseScale = 0.01,
})
terrainManager:generate()

print(string.format("[Server v%s] All systems initialized", VERSION))
