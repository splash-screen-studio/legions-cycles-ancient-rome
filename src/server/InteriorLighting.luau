--!strict
--[[
    InteriorLighting - Adds realistic Roman light sources to landmark interiors

    Creates atmospheric lighting for Roman structures with:
    - Wall-mounted torches with flickering fire effects
    - Oil lamps on pedestals for intimate spaces
    - Large braziers for open areas and temples
    - Directional doorway lighting

    All lights use warm orange/yellow tones appropriate for fire-based Roman lighting.
    Integrates with LandmarkBuilder to illuminate existing structures.

    Based on BRicey techniques for environmental atmosphere
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))
local LightingConfig = require(Shared:WaitForChild("LightingConfig"))

local InteriorLighting = {}
InteriorLighting.__index = InteriorLighting
InteriorLighting.VERSION = "1.0.0"

-- Configuration
local FLICKER_UPDATE_RATE = 0.1 -- Seconds between flicker updates
local FIRE_PARTICLE_RATE = 20
local FIRE_PARTICLE_LIFETIME = NumberRange.new(0.5, 1.0)
local FIRE_PARTICLE_SIZE = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.5),
    NumberSequenceKeypoint.new(0.5, 1),
    NumberSequenceKeypoint.new(1, 0.2),
})

export type InteriorLightingConfig = {
    worldPlan: WorldPlan.WorldPlanInstance,
}

export type InteriorLightingInstance = typeof(setmetatable(
    {} :: {
        worldPlan: WorldPlan.WorldPlanInstance,
        terrain: Terrain,
        folder: Folder?,
        parts: { BasePart },
        lights: { Light },
        flickerLights: { { light: PointLight, baseIntensity: number, flickerIntensity: number } },
        lightCount: number,
        _flickerConnection: RBXScriptConnection?,
    },
    InteriorLighting
))

function InteriorLighting.new(config: InteriorLightingConfig): InteriorLightingInstance
    local self = setmetatable({}, InteriorLighting)
    self.worldPlan = config.worldPlan
    self.terrain = workspace.Terrain
    self.folder = nil
    self.parts = {}
    self.lights = {}
    self.flickerLights = {}
    self.lightCount = 0
    self._flickerConnection = nil

    print(string.format("[InteriorLighting v%s] Initializing...", InteriorLighting.VERSION))
    return self
end

-- Helper: Create a basic part
function InteriorLighting:_createPart(
    name: string,
    position: Vector3,
    size: Vector3,
    color: Color3,
    material: Enum.Material?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.CanCollide = false -- Light fixtures don't need collision

    table.insert(self.parts, part)
    return part
end

-- Helper: Create a PointLight with configuration
function InteriorLighting:_createPointLight(
    parent: BasePart,
    config: LightingConfig.LightSourceConfig
): PointLight
    local light = Instance.new("PointLight")
    light.Name = "InteriorLight"
    light.Brightness = config.brightness
    light.Range = config.range
    light.Color = config.color
    light.Shadows = config.shadows
    light.Parent = parent

    table.insert(self.lights, light)
    self.lightCount = self.lightCount + 1

    -- Track flickering lights
    if config.flickerEnabled and config.flickerIntensity then
        table.insert(self.flickerLights, {
            light = light,
            baseIntensity = config.brightness,
            flickerIntensity = config.flickerIntensity,
        })
    end

    return light
end

-- Helper: Create fire particle effect for torches/braziers
function InteriorLighting:_createFireEffect(parent: BasePart, scale: number): ParticleEmitter
    local fire = Instance.new("ParticleEmitter")
    fire.Name = "FireEffect"

    -- Fire appearance
    fire.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 130, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 20)),
    })
    fire.LightEmission = 1
    fire.LightInfluence = 0

    -- Fire behavior
    fire.Lifetime = FIRE_PARTICLE_LIFETIME
    fire.Rate = FIRE_PARTICLE_RATE * scale
    fire.Speed = NumberRange.new(2 * scale, 5 * scale)
    fire.SpreadAngle = Vector2.new(15, 15)
    fire.Size = FIRE_PARTICLE_SIZE

    -- Upward motion
    fire.Acceleration = Vector3.new(0, 3 * scale, 0)
    fire.Drag = 2

    -- Transparency fade out
    fire.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.7, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    })

    fire.Parent = parent
    return fire
end

-- Create a wall-mounted torch fixture
function InteriorLighting:_createTorch(
    position: Vector3,
    wallNormal: Vector3,
    folder: Folder
): ()
    local fixtureConfig = LightingConfig.Fixtures.torch
    local lightConfig = LightingConfig.Sources.torch

    -- Torch holder (bracket on wall)
    local bracket = self:_createPart(
        "TorchBracket",
        position,
        fixtureConfig.bracketSize,
        LightingConfig.FixtureColors.IRON,
        LightingConfig.Materials.IRON
    )
    bracket.Parent = folder

    -- Torch body (wooden handle)
    local torchOffset = wallNormal * 0.5
    local torch = self:_createPart(
        "TorchBody",
        position + torchOffset + Vector3.new(0, 0.5, 0),
        fixtureConfig.torchSize,
        Color3.fromRGB(100, 70, 40),
        Enum.Material.Wood
    )
    torch.Parent = folder

    -- Fire attachment point (top of torch)
    local firePoint = self:_createPart(
        "TorchFirePoint",
        position + torchOffset + fixtureConfig.lightOffset,
        Vector3.new(0.4, 0.4, 0.4),
        Color3.fromRGB(50, 30, 20),
        Enum.Material.Wood
    )
    firePoint.Transparency = 1 -- Invisible attachment point
    firePoint.Parent = folder

    -- Add light
    self:_createPointLight(firePoint, lightConfig)

    -- Add fire particles
    self:_createFireEffect(firePoint, 1)
end

-- Create an oil lamp fixture
function InteriorLighting:_createOilLamp(
    position: Vector3,
    folder: Folder
): ()
    local fixtureConfig = LightingConfig.Fixtures.oilLamp
    local lightConfig = LightingConfig.Sources.oilLamp

    -- Lamp base (terracotta)
    local base = self:_createPart(
        "LampBase",
        position,
        fixtureConfig.baseSize,
        LightingConfig.FixtureColors.TERRACOTTA,
        LightingConfig.Materials.TERRACOTTA
    )
    base.Parent = folder

    -- Lamp body (bronze oil vessel)
    local body = self:_createPart(
        "LampBody",
        position + Vector3.new(0, fixtureConfig.baseSize.Y / 2 + fixtureConfig.bodySize.Y / 2, 0),
        fixtureConfig.bodySize,
        LightingConfig.FixtureColors.BRONZE,
        LightingConfig.Materials.BRONZE
    )
    body.Parent = folder

    -- Light attachment
    local lightPoint = self:_createPart(
        "LampLightPoint",
        position + fixtureConfig.lightOffset,
        Vector3.new(0.2, 0.2, 0.2),
        LightingConfig.FixtureColors.BRONZE,
        LightingConfig.Materials.BRONZE
    )
    lightPoint.Transparency = 1
    lightPoint.Parent = folder

    -- Add light
    self:_createPointLight(lightPoint, lightConfig)

    -- Small flame effect
    self:_createFireEffect(lightPoint, 0.3)
end

-- Create a floor brazier
function InteriorLighting:_createBrazier(
    position: Vector3,
    folder: Folder
): ()
    local fixtureConfig = LightingConfig.Fixtures.brazier
    local lightConfig = LightingConfig.Sources.brazier

    -- Brazier legs (4 posts)
    local legPositions = {
        Vector3.new(0.5, 0, 0.5),
        Vector3.new(-0.5, 0, 0.5),
        Vector3.new(0.5, 0, -0.5),
        Vector3.new(-0.5, 0, -0.5),
    }

    for i, offset in ipairs(legPositions) do
        local leg = self:_createPart(
            string.format("BrazierLeg_%d", i),
            position + offset * 0.6 + Vector3.new(0, fixtureConfig.legHeight / 2, 0),
            Vector3.new(0.3, fixtureConfig.legHeight, 0.3),
            LightingConfig.FixtureColors.IRON,
            LightingConfig.Materials.IRON
        )
        leg.Parent = folder
    end

    -- Brazier bowl (holds the fire)
    local bowlY = position.Y + fixtureConfig.legHeight + fixtureConfig.bowlSize.Y / 2
    local bowl = self:_createPart(
        "BrazierBowl",
        Vector3.new(position.X, bowlY, position.Z),
        fixtureConfig.bowlSize,
        LightingConfig.FixtureColors.BRONZE,
        LightingConfig.Materials.BRONZE
    )
    bowl.Parent = folder

    -- Light attachment (above bowl)
    local lightPoint = self:_createPart(
        "BrazierLightPoint",
        position + fixtureConfig.lightOffset,
        Vector3.new(0.5, 0.5, 0.5),
        LightingConfig.FixtureColors.BRONZE,
        LightingConfig.Materials.BRONZE
    )
    lightPoint.Transparency = 1
    lightPoint.Parent = folder

    -- Add light
    self:_createPointLight(lightPoint, lightConfig)

    -- Large fire effect
    self:_createFireEffect(lightPoint, 2)
end

-- Start the flickering effect for all torches and braziers
function InteriorLighting:_startFlickerEffect(): ()
    if self._flickerConnection then
        return -- Already running
    end

    local elapsed = 0
    local random = Random.new()

    self._flickerConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < FLICKER_UPDATE_RATE then
            return
        end
        elapsed = 0

        -- Update each flickering light
        for _, flickerData in ipairs(self.flickerLights) do
            local variance = (random:NextNumber() - 0.5) * 2 * flickerData.flickerIntensity
            flickerData.light.Brightness = flickerData.baseIntensity * (1 + variance)
        end
    end)
end

-- Stop the flickering effect
function InteriorLighting:_stopFlickerEffect(): ()
    if self._flickerConnection then
        self._flickerConnection:Disconnect()
        self._flickerConnection = nil
    end
end

-- Calculate light positions around a landmark
function InteriorLighting:_calculateLightPositions(
    centerX: number,
    centerZ: number,
    radius: number,
    count: number
): { { position: Vector3, normal: Vector3 } }
    local positions = {}

    if count == 0 then
        return positions
    end

    -- Distribute lights in a circle around the landmark center
    for i = 0, count - 1 do
        local angle = (i / count) * math.pi * 2
        local distance = radius * 0.7 -- Place lights inside the structure
        local x = centerX + math.cos(angle) * distance
        local z = centerZ + math.sin(angle) * distance
        local y = TerrainUtils.getHeightAt(self.terrain, x, z)

        -- Normal points inward (toward center)
        local normal = Vector3.new(-math.cos(angle), 0, -math.sin(angle))

        table.insert(positions, {
            position = Vector3.new(x, y, z),
            normal = normal,
        })
    end

    return positions
end

-- Add lighting to a single landmark
function InteriorLighting:_lightLandmark(
    landmarkType: string,
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local config = LightingConfig.getForLandmark(landmarkType)
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Create subfolder for this landmark's lights
    local lightFolder = Instance.new("Folder")
    lightFolder.Name = string.format("Lights_%s", landmarkType)
    lightFolder.Parent = folder

    -- Add torches (wall-mounted, at head height)
    local torchPositions = self:_calculateLightPositions(centerX, centerZ, radius, config.torchCount)
    for _, posData in ipairs(torchPositions) do
        local wallHeight = 6 -- Standard torch height on walls
        local torchPos = posData.position + Vector3.new(0, wallHeight, 0)
        self:_createTorch(torchPos, posData.normal, lightFolder)
    end

    -- Add oil lamps (ground level, clustered near center)
    if config.oilLampCount > 0 then
        local lampRadius = radius * 0.4
        local lampPositions = self:_calculateLightPositions(centerX, centerZ, lampRadius, config.oilLampCount)
        for _, posData in ipairs(lampPositions) do
            local lampY = TerrainUtils.getHeightAt(self.terrain, posData.position.X, posData.position.Z)
            local lampPos = Vector3.new(posData.position.X, lampY + 2, posData.position.Z)
            self:_createOilLamp(lampPos, lightFolder)
        end
    end

    -- Add braziers (center or corners, on ground)
    if config.brazierCount > 0 then
        if config.brazierCount == 1 then
            -- Single brazier at center
            self:_createBrazier(Vector3.new(centerX, terrainY, centerZ), lightFolder)
        else
            -- Multiple braziers around perimeter
            local brazierPositions = self:_calculateLightPositions(
                centerX,
                centerZ,
                radius * 0.5,
                config.brazierCount
            )
            for _, posData in ipairs(brazierPositions) do
                local brazierY = TerrainUtils.getHeightAt(self.terrain, posData.position.X, posData.position.Z)
                local brazierPos = Vector3.new(posData.position.X, brazierY, posData.position.Z)
                self:_createBrazier(brazierPos, lightFolder)
            end
        end
    end
end

-- Build all interior lighting from WorldPlan landmarks
function InteriorLighting:build(): Folder
    local startTime = tick()

    print(string.format("[InteriorLighting v%s] Adding interior lighting to landmarks...",
        InteriorLighting.VERSION
    ))

    -- Create main folder for all lighting
    local folder = Instance.new("Folder")
    folder.Name = "InteriorLighting_Lucernae"
    folder.Parent = workspace
    self.folder = folder

    -- Get all landmarks from WorldPlan
    local landmarks = self.worldPlan:getLandmarks()

    -- Add lighting to each landmark
    for _, landmark in ipairs(landmarks) do
        local x = landmark.position.X
        local z = landmark.position.Y -- Vector2 Y is world Z

        -- Skip landmarks in river exclusion zone (same check as LandmarkBuilder)
        if self.worldPlan:isInRiverExclusionZone(x, z) then
            continue
        end

        self:_lightLandmark(
            landmark.landmarkType,
            x,
            z,
            landmark.radius,
            folder
        )
    end

    -- Start flickering effect
    self:_startFlickerEffect()

    local elapsed = tick() - startTime
    print(string.format("[InteriorLighting v%s] Added %d lights to %d landmarks in %.2f seconds",
        InteriorLighting.VERSION,
        self.lightCount,
        #landmarks,
        elapsed
    ))

    return folder
end

-- Get the number of lights created
function InteriorLighting:getLightCount(): number
    return self.lightCount
end

-- Get all parts created
function InteriorLighting:getParts(): { BasePart }
    return self.parts
end

-- Destroy all lighting
function InteriorLighting:destroy(): ()
    self:_stopFlickerEffect()

    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end

    self.parts = {}
    self.lights = {}
    self.flickerLights = {}
    self.lightCount = 0

    print(string.format("[InteriorLighting v%s] All interior lighting destroyed", InteriorLighting.VERSION))
end

return InteriorLighting
