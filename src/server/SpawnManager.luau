--!strict
--[[
    SpawnManager - Terrain-Adaptive Player Spawn System
    Handles player spawning with proper terrain height queries and first impression design
    Based on BRicey spawn techniques adapted for Ancient Rome theme
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SpawnManager = {}
SpawnManager.__index = SpawnManager
SpawnManager.VERSION = "1.0.0"

-- Type definitions
export type SpawnConfig = {
    position: Vector3,
    facingDirection: Vector3,
    spawnRadius: number,
}

-- Default spawn configuration - Southeast hilltop overlooking the map
local DEFAULT_SPAWN_CONFIG: SpawnConfig = {
    position = Vector3.new(400, 0, 400), -- X, Z only - Y calculated from terrain
    facingDirection = Vector3.new(-1, 0, -1).Unit, -- Face northwest toward map center
    spawnRadius = 10, -- Random offset to prevent player stacking
}

-- Character height offset to spawn above terrain
local CHARACTER_HEIGHT_OFFSET = 3

function SpawnManager.new(config: SpawnConfig?)
    local self = setmetatable({}, SpawnManager)

    self._config = config or DEFAULT_SPAWN_CONFIG
    self._terrainUtils = nil :: any
    self._connections = {} :: { RBXScriptConnection }

    print(string.format("[SpawnManager v%s] Initializing...", SpawnManager.VERSION))

    return self
end

function SpawnManager:start()
    -- Load TerrainUtils from Shared
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    self._terrainUtils = require(Shared:WaitForChild("TerrainUtils"))

    -- Remove default Roblox objects
    self:_removeDefaults()

    -- Set up spawn handling
    self:_setupSpawnHandling()

    print(string.format("[SpawnManager v%s] Started - Spawn at (%.0f, terrain, %.0f) facing northwest", SpawnManager.VERSION, self._config.position.X, self._config.position.Z))
end

function SpawnManager:_removeDefaults()
    -- Remove baseplate
    local baseplate = workspace:FindFirstChild("Baseplate")
    if baseplate then
        baseplate:Destroy()
        print("[SpawnManager] Removed default Baseplate")
    end

    -- Remove default SpawnLocation
    local spawnLocation = workspace:FindFirstChild("SpawnLocation")
    if spawnLocation then
        spawnLocation:Destroy()
        print("[SpawnManager] Removed default SpawnLocation")
    end
end

function SpawnManager:getSpawnCFrame(): CFrame
    local config = self._config

    -- Apply random offset within spawn radius to prevent player stacking
    local randomOffsetX = (math.random() - 0.5) * config.spawnRadius * 2
    local randomOffsetZ = (math.random() - 0.5) * config.spawnRadius * 2

    local x = config.position.X + randomOffsetX
    local z = config.position.Z + randomOffsetZ

    -- CRITICAL: Query terrain height - never hardcode Y
    local terrainHeight = self._terrainUtils.getHeightAt(workspace.Terrain, x, z)
    local y = terrainHeight + CHARACTER_HEIGHT_OFFSET

    local position = Vector3.new(x, y, z)
    local lookAt = position + config.facingDirection

    return CFrame.lookAt(position, lookAt)
end

function SpawnManager:_setupSpawnHandling()
    -- Handle new players joining
    local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:_handlePlayerAdded(player)
    end)
    table.insert(self._connections, playerAddedConnection)

    -- Handle players that already joined before this script ran
    for _, player in ipairs(Players:GetPlayers()) do
        self:_handlePlayerAdded(player)
    end
end

function SpawnManager:_handlePlayerAdded(player: Player)
    local characterAddedConnection = player.CharacterAdded:Connect(function(character)
        self:_handleCharacterAdded(player, character)
    end)
    table.insert(self._connections, characterAddedConnection)

    -- Handle character that may already exist
    if player.Character then
        self:_handleCharacterAdded(player, player.Character)
    end
end

function SpawnManager:_handleCharacterAdded(player: Player, character: Model)
    -- Wait a frame for character to fully load
    task.wait()

    local spawnCFrame = self:getSpawnCFrame()
    character:PivotTo(spawnCFrame)

    local pos = spawnCFrame.Position
    print(string.format(
        "[SpawnManager v%s] Spawned %s at (%.1f, %.1f, %.1f)",
        SpawnManager.VERSION,
        player.Name,
        pos.X,
        pos.Y,
        pos.Z
    ))
end

function SpawnManager:destroy()
    -- Clean up all connections
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}

    print(string.format("[SpawnManager v%s] Destroyed", SpawnManager.VERSION))
end

return SpawnManager
