--!strict
--[[
    SpeedBoostManager - Client-side speed boost when running on Roman roads
    Players move faster on Cobblestone terrain (Via/roads) than on other surfaces.

    Features:
    - Monitors player position at regular intervals (not every frame for performance)
    - Detects Cobblestone terrain material under player feet
    - Applies speed multiplier when on roads
    - Smooth speed transitions (no jarring snaps)

    Based on BRicey movement techniques adapted for Roman road network
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared:WaitForChild("Maid"))

local SpeedBoostManager = {}
SpeedBoostManager.__index = SpeedBoostManager
SpeedBoostManager.VERSION = "1.0.0"

-- Speed constants
local DEFAULT_WALK_SPEED = 16 -- Roblox default
local ROAD_WALK_SPEED = 22 -- 1.375x boost on roads (between 1.25x and 1.5x)

-- Timing constants
local POSITION_CHECK_INTERVAL = 0.15 -- Seconds between position checks (performance friendly)
local SPEED_TRANSITION_DURATION = 0.3 -- Smooth transition duration in seconds

-- Terrain check constants
local TERRAIN_CHECK_OFFSET = Vector3.new(0, -3, 0) -- Check slightly below feet
local TERRAIN_CHECK_REGION_SIZE = Vector3.new(2, 2, 2) -- Small region around feet

export type SpeedBoostManagerInstance = typeof(setmetatable(
    {} :: {
        _player: Player,
        _character: Model?,
        _humanoid: Humanoid?,
        _terrain: Terrain,
        _maid: Maid.Maid,
        _isOnRoad: boolean,
        _timeSinceLastCheck: number,
        _currentTween: Tween?,
    },
    SpeedBoostManager
))

--- Creates a new SpeedBoostManager instance
function SpeedBoostManager.new(): SpeedBoostManagerInstance
    local self = setmetatable({}, SpeedBoostManager)

    self._player = Players.LocalPlayer
    self._character = nil :: Model?
    self._humanoid = nil :: Humanoid?
    self._terrain = workspace.Terrain
    self._maid = Maid.new()
    self._isOnRoad = false
    self._timeSinceLastCheck = 0
    self._currentTween = nil :: Tween?

    print(string.format("[SpeedBoostManager v%s] Initializing...", SpeedBoostManager.VERSION))

    return self
end

--- Starts the speed boost monitoring system
function SpeedBoostManager:start()
    -- Connect to character added
    self._maid:give(self._player.CharacterAdded:Connect(function(character)
        self:_onCharacterAdded(character)
    end))

    -- If character already exists, connect immediately
    if self._player.Character then
        self:_onCharacterAdded(self._player.Character)
    end

    -- Connect to Heartbeat for position checks (throttled)
    self._maid:give(RunService.Heartbeat:Connect(function(deltaTime)
        self:_onHeartbeat(deltaTime)
    end))

    print(string.format("[SpeedBoostManager v%s] Started", SpeedBoostManager.VERSION))
end

--- Called when player character is added/respawns
function SpeedBoostManager:_onCharacterAdded(character: Model)
    self._character = character

    -- Wait for humanoid
    local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
    if humanoid then
        self._humanoid = humanoid
        -- Reset to default speed on respawn
        humanoid.WalkSpeed = DEFAULT_WALK_SPEED
        self._isOnRoad = false
    end
end

--- Called every frame to check position (throttled)
function SpeedBoostManager:_onHeartbeat(deltaTime: number)
    self._timeSinceLastCheck += deltaTime

    -- Only check position at the configured interval
    if self._timeSinceLastCheck < POSITION_CHECK_INTERVAL then
        return
    end
    self._timeSinceLastCheck = 0

    -- Check if we have a valid character and humanoid
    if not self._character or not self._humanoid then
        return
    end

    local humanoidRootPart = self._character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then
        return
    end

    -- Check terrain material at player feet
    local isOnRoad = self:_checkIfOnRoad(humanoidRootPart.Position)

    -- Only update speed if road state changed
    if isOnRoad ~= self._isOnRoad then
        self._isOnRoad = isOnRoad
        self:_updateSpeed(isOnRoad)
    end
end

--- Checks if the player is standing on a road (Cobblestone terrain)
function SpeedBoostManager:_checkIfOnRoad(position: Vector3): boolean
    -- Check position slightly below player feet
    local checkPosition = position + TERRAIN_CHECK_OFFSET

    -- Create a small region around the check position
    local regionMin = checkPosition - (TERRAIN_CHECK_REGION_SIZE / 2)
    local regionMax = checkPosition + (TERRAIN_CHECK_REGION_SIZE / 2)
    local region = Region3.new(regionMin, regionMax)

    -- Expand region to terrain grid
    region = region:ExpandToGrid(4)

    -- Read terrain voxels
    local materials, _occupancies = self._terrain:ReadVoxels(region, 4)

    -- Check if any voxel is Cobblestone
    for x = 1, materials.Size.X do
        for y = 1, materials.Size.Y do
            for z = 1, materials.Size.Z do
                local material = materials[x][y][z]
                if material == Enum.Material.Cobblestone then
                    return true
                end
            end
        end
    end

    return false
end

--- Updates the player's walk speed with smooth transition
function SpeedBoostManager:_updateSpeed(isOnRoad: boolean)
    if not self._humanoid then
        return
    end

    local targetSpeed = if isOnRoad then ROAD_WALK_SPEED else DEFAULT_WALK_SPEED

    -- Cancel any existing speed tween
    if self._currentTween then
        self._currentTween:Cancel()
        self._currentTween = nil
    end

    -- Create smooth transition tween
    local tweenInfo = TweenInfo.new(
        SPEED_TRANSITION_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    self._currentTween = TweenService:Create(self._humanoid, tweenInfo, {
        WalkSpeed = targetSpeed,
    })

    self._currentTween:Play()

    -- Log state change for debugging
    if isOnRoad then
        print(string.format("[SpeedBoostManager] On road - speed boost to %d", targetSpeed))
    else
        print(string.format("[SpeedBoostManager] Off road - normal speed %d", targetSpeed))
    end
end

--- Returns whether the player is currently on a road
function SpeedBoostManager:isOnRoad(): boolean
    return self._isOnRoad
end

--- Returns the current target speed
function SpeedBoostManager:getCurrentTargetSpeed(): number
    return if self._isOnRoad then ROAD_WALK_SPEED else DEFAULT_WALK_SPEED
end

--- Cleans up the SpeedBoostManager
function SpeedBoostManager:destroy()
    -- Cancel any active tween
    if self._currentTween then
        self._currentTween:Cancel()
        self._currentTween = nil
    end

    -- Reset humanoid speed if exists
    if self._humanoid then
        self._humanoid.WalkSpeed = DEFAULT_WALK_SPEED
    end

    -- Clean up all connections
    self._maid:destroy()

    self._character = nil
    self._humanoid = nil

    print(string.format("[SpeedBoostManager v%s] Destroyed", SpeedBoostManager.VERSION))
end

return SpeedBoostManager
