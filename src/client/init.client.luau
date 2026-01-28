--!strict
-- Client Entry Point - Bootstraps all client systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to be available
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Require and initialize client modules
local MusicManager = require(script.MusicManager)

-- Bootstrap music
local musicManager = MusicManager.new()
musicManager:playPlaylist(false) -- Sequential playback

print("[Client] All systems initialized")
