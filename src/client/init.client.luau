--!strict
-- Client Entry Point - Bootstraps all client systems

local VERSION = "1.0.0"
print(string.format("[Client v%s] Starting...", VERSION))

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to be available
print("[Client] Waiting for Shared folder...")
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
    error("[Client] FATAL: Shared folder not found in ReplicatedStorage!")
end
print("[Client] Found Shared folder")

-- Require and initialize client modules
local MusicManager = require(script.MusicManager)
print(string.format("[Client] Loaded MusicManager v%s", MusicManager.VERSION))

local AtmosphereManager = require(script.AtmosphereManager)
print(string.format("[Client] Loaded AtmosphereManager v%s", AtmosphereManager.VERSION))

-- Bootstrap atmosphere (lighting, sky, fog)
local atmosphereManager = AtmosphereManager.new()
atmosphereManager:start()

-- Bootstrap music
local musicManager = MusicManager.new()
musicManager:playPlaylist(false) -- Sequential playback

print(string.format("[Client v%s] All systems initialized", VERSION))
