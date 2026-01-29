--!strict
--[[
    AtmosphereManager - Client-side atmosphere and lighting system for Legions & Cycles: Ancient Rome
    Controls lighting, weather, fog, and mood across time of day.

    Features:
    - Golden hour Roman atmosphere (warm sunlight, Mediterranean sky)
    - Atmosphere instance for haze/distance fog
    - Sky configuration for blue Mediterranean sky
    - Time of day presets with smooth transitions
    - Weather system foundation (Mediterranean climate)

    Based on BRicey lighting techniques, themed for Ancient Rome
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared:WaitForChild("Maid"))

local AtmosphereManager = {}
AtmosphereManager.__index = AtmosphereManager
AtmosphereManager.VERSION = "1.0.1"

-- Time of Day Presets (hours in 24-hour format)
local TIME_PRESETS = {
    dawn = {
        clockTime = 6,
        ambient = Color3.fromRGB(180, 140, 120),
        outdoor = Color3.fromRGB(255, 200, 160),
        brightness = 1.5,
        colorShiftTop = Color3.fromRGB(255, 180, 140),
        colorShiftBottom = Color3.fromRGB(200, 160, 140),
        fogColor = Color3.fromRGB(255, 220, 200),
        fogStart = 100,
        fogEnd = 600,
        atmosphereDensity = 0.4,
        atmosphereColor = Color3.fromRGB(255, 200, 160),
    },
    morning = {
        clockTime = 9,
        ambient = Color3.fromRGB(200, 180, 160),
        outdoor = Color3.fromRGB(255, 250, 240),
        brightness = 2.0,
        colorShiftTop = Color3.fromRGB(255, 250, 240),
        colorShiftBottom = Color3.fromRGB(220, 200, 180),
        fogColor = Color3.fromRGB(240, 235, 230),
        fogStart = 200,
        fogEnd = 800,
        atmosphereDensity = 0.25,
        atmosphereColor = Color3.fromRGB(240, 235, 230),
    },
    midday = {
        clockTime = 12,
        ambient = Color3.fromRGB(220, 210, 200),
        outdoor = Color3.fromRGB(255, 255, 245),
        brightness = 2.5,
        colorShiftTop = Color3.fromRGB(255, 255, 250),
        colorShiftBottom = Color3.fromRGB(235, 220, 200),
        fogColor = Color3.fromRGB(245, 240, 235),
        fogStart = 300,
        fogEnd = 1000,
        atmosphereDensity = 0.15,
        atmosphereColor = Color3.fromRGB(245, 240, 235),
    },
    goldenHour = {
        clockTime = 17,
        ambient = Color3.fromRGB(200, 160, 120),
        outdoor = Color3.fromRGB(255, 200, 140),
        brightness = 2.0,
        colorShiftTop = Color3.fromRGB(255, 180, 120),
        colorShiftBottom = Color3.fromRGB(220, 160, 100),
        fogColor = Color3.fromRGB(255, 220, 180),
        fogStart = 150,
        fogEnd = 700,
        atmosphereDensity = 0.35,
        atmosphereColor = Color3.fromRGB(255, 200, 150),
    },
    dusk = {
        clockTime = 19,
        ambient = Color3.fromRGB(160, 120, 100),
        outdoor = Color3.fromRGB(255, 160, 120),
        brightness = 1.2,
        colorShiftTop = Color3.fromRGB(255, 140, 100),
        colorShiftBottom = Color3.fromRGB(180, 120, 100),
        fogColor = Color3.fromRGB(200, 160, 140),
        fogStart = 100,
        fogEnd = 500,
        atmosphereDensity = 0.45,
        atmosphereColor = Color3.fromRGB(220, 160, 120),
    },
    night = {
        clockTime = 22,
        ambient = Color3.fromRGB(80, 90, 120),
        outdoor = Color3.fromRGB(100, 110, 140),
        brightness = 0.5,
        colorShiftTop = Color3.fromRGB(80, 90, 130),
        colorShiftBottom = Color3.fromRGB(60, 70, 100),
        fogColor = Color3.fromRGB(60, 70, 100),
        fogStart = 50,
        fogEnd = 400,
        atmosphereDensity = 0.5,
        atmosphereColor = Color3.fromRGB(80, 90, 120),
    },
}

-- Default transition duration in seconds
local DEFAULT_TRANSITION_DURATION = 3.0

export type TimePreset = "dawn" | "morning" | "midday" | "goldenHour" | "dusk" | "night"

export type AtmosphereManager = typeof(setmetatable({} :: {
    _atmosphere: Atmosphere?,
    _sky: Sky?,
    _currentPreset: TimePreset,
    _currentTween: Tween?,
    _maid: Maid.Maid,
}, AtmosphereManager))

--- Creates a new AtmosphereManager instance
function AtmosphereManager.new(): AtmosphereManager
    local self = setmetatable({
        _atmosphere = nil :: Atmosphere?,
        _sky = nil :: Sky?,
        _currentPreset = "goldenHour" :: TimePreset,
        _currentTween = nil :: Tween?,
        _maid = Maid.new(),
    }, AtmosphereManager)

    self:_setupLighting()
    self:_setupAtmosphere()
    self:_setupSky()

    return self
end

--- Sets up base Lighting properties
function AtmosphereManager:_setupLighting(): ()
    -- Note: Lighting.Technology must be set in Studio (requires RobloxScript capability)
    -- Configure shadow settings
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.3

    -- Environment settings
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1

    -- Geographic latitude for sun angle (Rome is approximately 42 degrees)
    Lighting.GeographicLatitude = 42

    print(string.format("[AtmosphereManager v%s] Lighting configured", AtmosphereManager.VERSION))
end

--- Creates and configures the Atmosphere instance
function AtmosphereManager:_setupAtmosphere(): ()
    -- Remove any existing Atmosphere
    local existingAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if existingAtmosphere then
        existingAtmosphere:Destroy()
    end

    -- Create new Atmosphere for Mediterranean haze
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "RomanAtmosphere"

    -- Mediterranean haze settings (warm, slightly dusty)
    atmosphere.Density = 0.35
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(255, 200, 150) -- Warm golden haze
    atmosphere.Decay = Color3.fromRGB(200, 180, 160) -- Warm decay
    atmosphere.Glare = 0.3 -- Slight sun glare
    atmosphere.Haze = 2.0 -- Moderate distance haze

    atmosphere.Parent = Lighting
    self._atmosphere = atmosphere
    self._maid:give(atmosphere)

    print("[AtmosphereManager] Atmosphere configured for Mediterranean climate")
end

--- Creates and configures the Sky instance
function AtmosphereManager:_setupSky(): ()
    -- Remove any existing Sky
    local existingSky = Lighting:FindFirstChildOfClass("Sky")
    if existingSky then
        existingSky:Destroy()
    end

    -- Create new Sky for Mediterranean blue
    local sky = Instance.new("Sky")
    sky.Name = "MediterraneanSky"

    -- Clear blue Mediterranean sky
    sky.CelestialBodiesShown = true
    sky.StarCount = 3000

    -- Sun properties
    sky.SunAngularSize = 21
    sky.SunTextureId = "" -- Use default sun

    -- Moon properties
    sky.MoonAngularSize = 11
    sky.MoonTextureId = "" -- Use default moon

    -- Sky texture IDs (using Roblox defaults for clean look)
    -- Empty strings use Roblox's built-in procedural sky
    sky.SkyboxBk = ""
    sky.SkyboxDn = ""
    sky.SkyboxFt = ""
    sky.SkyboxLf = ""
    sky.SkyboxRt = ""
    sky.SkyboxUp = ""

    sky.Parent = Lighting
    self._sky = sky
    self._maid:give(sky)

    print("[AtmosphereManager] Sky configured for Mediterranean region")
end

--- Applies a time preset to the lighting system
function AtmosphereManager:setTimePreset(preset: TimePreset, duration: number?): ()
    local presetData = TIME_PRESETS[preset]
    if not presetData then
        warn("[AtmosphereManager] Unknown time preset:", preset)
        return
    end

    local transitionDuration = duration or DEFAULT_TRANSITION_DURATION

    -- Cancel any existing transition
    if self._currentTween then
        self._currentTween:Cancel()
        self._currentTween = nil
    end

    self._currentPreset = preset

    -- Create tween for smooth transition
    local tweenInfo = TweenInfo.new(
        transitionDuration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )

    -- Tween Lighting properties
    local lightingTween = TweenService:Create(Lighting, tweenInfo, {
        ClockTime = presetData.clockTime,
        Ambient = presetData.ambient,
        OutdoorAmbient = presetData.outdoor,
        Brightness = presetData.brightness,
        ColorShift_Top = presetData.colorShiftTop,
        ColorShift_Bottom = presetData.colorShiftBottom,
        FogColor = presetData.fogColor,
        FogStart = presetData.fogStart,
        FogEnd = presetData.fogEnd,
    })

    -- Tween Atmosphere properties if atmosphere exists
    if self._atmosphere then
        local atmosphereTween = TweenService:Create(self._atmosphere, tweenInfo, {
            Density = presetData.atmosphereDensity,
            Color = presetData.atmosphereColor,
        })
        atmosphereTween:Play()
    end

    self._currentTween = lightingTween
    lightingTween:Play()

    -- Clean up tween reference when complete
    self._maid:give(lightingTween.Completed:Once(function()
        self._currentTween = nil
    end))

    print(string.format("[AtmosphereManager] Transitioning to %s over %.1f seconds", preset, transitionDuration))
end

--- Applies the golden hour preset immediately (no transition)
function AtmosphereManager:applyGoldenHour(): ()
    local preset = TIME_PRESETS.goldenHour

    -- Apply Lighting properties immediately
    Lighting.ClockTime = preset.clockTime
    Lighting.Ambient = preset.ambient
    Lighting.OutdoorAmbient = preset.outdoor
    Lighting.Brightness = preset.brightness
    Lighting.ColorShift_Top = preset.colorShiftTop
    Lighting.ColorShift_Bottom = preset.colorShiftBottom
    Lighting.FogColor = preset.fogColor
    Lighting.FogStart = preset.fogStart
    Lighting.FogEnd = preset.fogEnd

    -- Apply Atmosphere properties
    if self._atmosphere then
        self._atmosphere.Density = preset.atmosphereDensity
        self._atmosphere.Color = preset.atmosphereColor
    end

    self._currentPreset = "goldenHour"
    print("[AtmosphereManager] Applied golden hour preset")
end

--- Gets the current time preset
function AtmosphereManager:getCurrentPreset(): TimePreset
    return self._currentPreset
end

--- Gets the current ambient light level (0.0 to 1.0) for other systems
function AtmosphereManager:getCurrentAmbientLevel(): number
    -- Calculate based on brightness and time of day
    local brightness = Lighting.Brightness
    local normalizedBrightness = math.clamp(brightness / 2.5, 0, 1)
    return normalizedBrightness
end

--- Gets the current clock time (0-24)
function AtmosphereManager:getClockTime(): number
    return Lighting.ClockTime
end

--- Sets the clock time directly (for manual control)
function AtmosphereManager:setClockTime(hours: number): ()
    Lighting.ClockTime = math.clamp(hours, 0, 24)
end

--- Starts the atmosphere system with default golden hour
function AtmosphereManager:start(): ()
    print(string.format("[AtmosphereManager v%s] Starting atmosphere system...", AtmosphereManager.VERSION))
    self:applyGoldenHour()
    print("[AtmosphereManager] Atmosphere system started - Golden hour Roman ambiance active")
end

--- Cleans up the AtmosphereManager
function AtmosphereManager:destroy(): ()
    if self._currentTween then
        self._currentTween:Cancel()
        self._currentTween = nil
    end
    self._maid:destroy()
    print("[AtmosphereManager] Destroyed")
end

return AtmosphereManager
