--!strict
--[[
    LanternManager - Client-side automatic lantern system for Legions & Cycles: Ancient Rome
    Automatically activates a warm oil lamp light when ambient darkness crosses a threshold.

    Features:
    - Automatic activation when ambient light < 0.3
    - Hysteresis prevents flicker (deactivates when ambient > 0.4)
    - Warm orange PointLight attached to character
    - Subtle flicker effect to simulate flame movement
    - Smooth fade in/out transitions

    Based on BRicey lighting techniques, themed for Ancient Rome
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared:WaitForChild("Maid"))

local LanternManager = {}
LanternManager.__index = LanternManager
LanternManager.VERSION = "1.0.0"

-- Lantern configuration
local ACTIVATION_THRESHOLD = 0.3 -- Activate when ambient < this
local DEACTIVATION_THRESHOLD = 0.4 -- Deactivate when ambient > this (hysteresis)
local FADE_IN_DURATION = 0.5 -- Seconds to fade in
local FADE_OUT_DURATION = 1.0 -- Seconds to fade out
local CHECK_INTERVAL = 0.5 -- How often to check ambient level (seconds)

-- Light properties (Roman oil lamp aesthetic)
local LIGHT_COLOR = Color3.fromRGB(255, 200, 150) -- Warm oil lamp
local LIGHT_BRIGHTNESS = 1.5
local LIGHT_RANGE = 25
local LIGHT_SHADOWS = true

-- Flicker configuration
local FLICKER_MIN = 0.9 -- Minimum brightness multiplier
local FLICKER_MAX = 1.1 -- Maximum brightness multiplier
local FLICKER_SPEED = 8 -- Flicker frequency

export type AtmosphereManagerType = {
    getCurrentAmbientLevel: (self: AtmosphereManagerType) -> number,
}

export type LanternManager = typeof(setmetatable({} :: {
    _atmosphereManager: AtmosphereManagerType,
    _light: PointLight?,
    _isActive: boolean,
    _flickerEnabled: boolean,
    _flickerTime: number,
    _currentTween: Tween?,
    _maid: Maid.Maid,
    _flickerConnection: RBXScriptConnection?,
    _characterConnection: RBXScriptConnection?,
}, LanternManager))

--- Creates a new LanternManager instance
function LanternManager.new(atmosphereManager: AtmosphereManagerType): LanternManager
    local self = setmetatable({
        _atmosphereManager = atmosphereManager,
        _light = nil :: PointLight?,
        _isActive = false,
        _flickerEnabled = true,
        _flickerTime = 0,
        _currentTween = nil :: Tween?,
        _maid = Maid.new(),
        _flickerConnection = nil :: RBXScriptConnection?,
        _characterConnection = nil :: RBXScriptConnection?,
    }, LanternManager)

    return self
end

--- Creates and attaches the lantern light to the character
function LanternManager:_createLight(character: Model): PointLight?
    -- Find the torso/chest area for attachment
    local attachment = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not attachment then
        -- Try HumanoidRootPart as fallback
        attachment = character:FindFirstChild("HumanoidRootPart")
    end

    if not attachment then
        warn("[LanternManager] Could not find suitable attachment point on character")
        return nil
    end

    -- Create the PointLight
    local light = Instance.new("PointLight")
    light.Name = "RomanLantern"
    light.Color = LIGHT_COLOR
    light.Brightness = 0 -- Start at 0, will fade in
    light.Range = LIGHT_RANGE
    light.Shadows = LIGHT_SHADOWS
    light.Parent = attachment

    self._maid:give(light)
    return light
end

--- Activates the lantern with a smooth fade in
function LanternManager:activate(): ()
    if self._isActive then
        return
    end

    local player = Players.LocalPlayer
    if not player then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    -- Create light if it doesn't exist
    if not self._light then
        self._light = self:_createLight(character)
    end

    if not self._light then
        return
    end

    self._isActive = true

    -- Cancel any existing transition
    if self._currentTween then
        self._currentTween:Cancel()
        self._currentTween = nil
    end

    -- Fade in
    local tweenInfo = TweenInfo.new(
        FADE_IN_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(self._light, tweenInfo, {
        Brightness = LIGHT_BRIGHTNESS,
    })

    self._currentTween = tween
    tween:Play()

    -- Start flicker effect
    self:_startFlicker()

    print("[LanternManager] Lantern activated")
end

--- Deactivates the lantern with a smooth fade out
function LanternManager:deactivate(): ()
    if not self._isActive then
        return
    end

    self._isActive = false

    -- Stop flicker
    self:_stopFlicker()

    if not self._light then
        return
    end

    -- Cancel any existing transition
    if self._currentTween then
        self._currentTween:Cancel()
        self._currentTween = nil
    end

    -- Fade out
    local tweenInfo = TweenInfo.new(
        FADE_OUT_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In
    )

    local tween = TweenService:Create(self._light, tweenInfo, {
        Brightness = 0,
    })

    self._currentTween = tween
    tween:Play()

    print("[LanternManager] Lantern deactivated")
end

--- Starts the flicker effect for flame simulation
function LanternManager:_startFlicker(): ()
    if not self._flickerEnabled then
        return
    end

    if self._flickerConnection then
        return -- Already flickering
    end

    self._flickerConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
        if not self._isActive or not self._light then
            return
        end

        self._flickerTime = self._flickerTime + deltaTime * FLICKER_SPEED

        -- Use noise function for organic flicker
        local noise = math.noise(self._flickerTime, 0.5)
        local flickerMultiplier = FLICKER_MIN + (FLICKER_MAX - FLICKER_MIN) * (noise + 1) / 2

        -- Only apply flicker if not in the middle of a fade transition
        if not self._currentTween or self._currentTween.PlaybackState ~= Enum.PlaybackState.Playing then
            self._light.Brightness = LIGHT_BRIGHTNESS * flickerMultiplier
        end
    end)

    self._maid:give(self._flickerConnection)
end

--- Stops the flicker effect
function LanternManager:_stopFlicker(): ()
    if self._flickerConnection then
        self._flickerConnection:Disconnect()
        self._flickerConnection = nil
    end
end

--- Checks the ambient level and activates/deactivates lantern accordingly
function LanternManager:_checkAmbientLevel(): ()
    local ambientLevel = self._atmosphereManager:getCurrentAmbientLevel()

    if self._isActive then
        -- Use higher threshold for deactivation (hysteresis)
        if ambientLevel > DEACTIVATION_THRESHOLD then
            self:deactivate()
        end
    else
        -- Use lower threshold for activation
        if ambientLevel < ACTIVATION_THRESHOLD then
            self:activate()
        end
    end
end

--- Sets up character tracking for the local player
function LanternManager:_setupCharacterTracking(): ()
    local player = Players.LocalPlayer
    if not player then
        return
    end

    -- Handle current character
    if player.Character then
        self:_onCharacterAdded(player.Character)
    end

    -- Handle future characters
    self._characterConnection = player.CharacterAdded:Connect(function(character: Model)
        self:_onCharacterAdded(character)
    end)

    self._maid:give(self._characterConnection)
end

--- Called when the player's character is added
function LanternManager:_onCharacterAdded(character: Model): ()
    -- Reset state
    self._light = nil
    self._isActive = false
    self:_stopFlicker()

    -- Wait for humanoid to be ready
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        warn("[LanternManager] Humanoid not found on character")
        return
    end

    -- Check ambient level immediately
    self:_checkAmbientLevel()

    print(string.format("[LanternManager v%s] Character ready, monitoring ambient light", LanternManager.VERSION))
end

--- Enables or disables the flicker effect
function LanternManager:setFlickerEnabled(enabled: boolean): ()
    self._flickerEnabled = enabled

    if enabled and self._isActive then
        self:_startFlicker()
    elseif not enabled then
        self:_stopFlicker()
        -- Reset brightness to base value
        if self._light and self._isActive then
            self._light.Brightness = LIGHT_BRIGHTNESS
        end
    end

    print(string.format("[LanternManager] Flicker %s", enabled and "enabled" or "disabled"))
end

--- Returns whether the lantern is currently active
function LanternManager:isActive(): boolean
    return self._isActive
end

--- Returns whether flicker is enabled
function LanternManager:isFlickerEnabled(): boolean
    return self._flickerEnabled
end

--- Starts the lantern manager system
function LanternManager:start(): ()
    print(string.format("[LanternManager v%s] Starting lantern system...", LanternManager.VERSION))

    -- Setup character tracking
    self:_setupCharacterTracking()

    -- Start ambient level monitoring using a spawned task with interval
    local checkThread = task.spawn(function()
        while true do
            task.wait(CHECK_INTERVAL)
            self:_checkAmbientLevel()
        end
    end)

    self._maid:give(function()
        task.cancel(checkThread)
    end)

    print("[LanternManager] Lantern system started - Monitoring ambient light for automatic activation")
end

--- Cleans up the LanternManager
function LanternManager:destroy(): ()
    self:_stopFlicker()

    if self._currentTween then
        self._currentTween:Cancel()
        self._currentTween = nil
    end

    self._maid:destroy()
    print("[LanternManager] Destroyed")
end

return LanternManager
