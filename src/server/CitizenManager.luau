--!strict
--[[
    CitizenManager - Foundation system for NPC citizens

    Creates stationary citizens near landmarks to bring the world to life.
    This is a foundation module - citizens are anchored and use simple idle behavior.

    Future enhancements (not implemented here):
    - Pathfinding and walking
    - State machine (IDLE -> WALKING -> DESTINATION -> ACTION)
    - Population scaling with progression

    Based on BRicey NPC techniques adapted for mobile performance
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))

local CitizenManager = {}
CitizenManager.__index = CitizenManager
CitizenManager.VERSION = "1.0.0"

-- Roman citizen appearance colors
local TUNIC_COLORS = {
    Color3.fromRGB(230, 220, 200), -- Undyed linen
    Color3.fromRGB(180, 100, 70),  -- Terracotta/russet
    Color3.fromRGB(150, 140, 120), -- Gray-brown wool
    Color3.fromRGB(200, 180, 140), -- Tan
    Color3.fromRGB(160, 120, 80),  -- Brown
}

local SKIN_COLORS = {
    Color3.fromRGB(240, 200, 160), -- Light
    Color3.fromRGB(220, 180, 140), -- Medium light
    Color3.fromRGB(180, 140, 100), -- Medium
    Color3.fromRGB(140, 100, 70),  -- Medium dark
}

local HAIR_COLORS = {
    Color3.fromRGB(60, 40, 20),    -- Dark brown
    Color3.fromRGB(100, 70, 40),   -- Medium brown
    Color3.fromRGB(40, 30, 20),    -- Black
    Color3.fromRGB(160, 130, 90),  -- Light brown
}

-- Citizen dimensions (studs)
local HEAD_SIZE = 1.5
local TORSO_HEIGHT = 2.5
local LEG_HEIGHT = 2.0
local ARM_LENGTH = 2.0

-- Configuration
local CITIZENS_PER_LANDMARK = 3
local SPAWN_RADIUS = 15 -- Distance from landmark center to spawn citizens
local MIN_SPAWN_DISTANCE = 5 -- Minimum distance from landmark center

export type CitizenManagerConfig = {
    worldPlan: WorldPlan.WorldPlanInstance,
    maxCitizens: number?,
}

export type Citizen = {
    model: Model,
    landmark: WorldPlan.Landmark,
    position: Vector3,
}

export type CitizenManagerInstance = typeof(setmetatable(
    {} :: {
        worldPlan: WorldPlan.WorldPlanInstance,
        terrain: Terrain,
        folder: Folder?,
        citizens: { Citizen },
        maxCitizens: number,
    },
    CitizenManager
))

function CitizenManager.new(config: CitizenManagerConfig): CitizenManagerInstance
    local self = setmetatable({}, CitizenManager)
    self.worldPlan = config.worldPlan
    self.terrain = workspace.Terrain
    self.folder = nil
    self.citizens = {}
    self.maxCitizens = config.maxCitizens or 50

    print(string.format("[CitizenManager v%s] Initializing...", CitizenManager.VERSION))
    return self
end

-- Create a simple humanoid figure part
function CitizenManager:_createPart(
    name: string,
    size: Vector3,
    color: Color3,
    parent: Instance
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false -- NPCs don't block player movement
    part.Parent = parent
    return part
end

-- Create a single citizen model at a position
function CitizenManager:_createCitizenModel(position: Vector3): Model
    local model = Instance.new("Model")
    model.Name = "Citizen"

    -- Random appearance
    local tunicColor = TUNIC_COLORS[math.random(1, #TUNIC_COLORS)]
    local skinColor = SKIN_COLORS[math.random(1, #SKIN_COLORS)]
    local hairColor = HAIR_COLORS[math.random(1, #HAIR_COLORS)]

    -- Calculate Y offsets from ground
    local groundY = position.Y
    local legsY = groundY + LEG_HEIGHT / 2
    local torsoY = groundY + LEG_HEIGHT + TORSO_HEIGHT / 2
    local headY = groundY + LEG_HEIGHT + TORSO_HEIGHT + HEAD_SIZE / 2

    -- Create body parts
    -- Legs (simplified as single part - tunic covers them)
    local legs = self:_createPart(
        "Legs",
        Vector3.new(1.4, LEG_HEIGHT, 1.1),
        tunicColor,
        model
    )
    legs.Position = Vector3.new(position.X, legsY, position.Z)

    -- Torso (tunic)
    local torso = self:_createPart(
        "Torso",
        Vector3.new(1.8, TORSO_HEIGHT, 1.3),
        tunicColor,
        model
    )
    torso.Position = Vector3.new(position.X, torsoY, position.Z)

    -- Arms (at sides)
    local armOffsetX = 1.8 / 2 + 0.2
    local armY = torsoY

    local leftArm = self:_createPart(
        "LeftArm",
        Vector3.new(0.5, ARM_LENGTH, 0.5),
        skinColor,
        model
    )
    leftArm.Position = Vector3.new(position.X - armOffsetX, armY, position.Z)

    local rightArm = self:_createPart(
        "RightArm",
        Vector3.new(0.5, ARM_LENGTH, 0.5),
        skinColor,
        model
    )
    rightArm.Position = Vector3.new(position.X + armOffsetX, armY, position.Z)

    -- Head
    local head = self:_createPart(
        "Head",
        Vector3.new(HEAD_SIZE, HEAD_SIZE, HEAD_SIZE),
        skinColor,
        model
    )
    head.Position = Vector3.new(position.X, headY, position.Z)

    -- Hair (on top of head)
    local hair = self:_createPart(
        "Hair",
        Vector3.new(HEAD_SIZE * 0.9, HEAD_SIZE * 0.4, HEAD_SIZE * 0.9),
        hairColor,
        model
    )
    hair.Position = Vector3.new(position.X, headY + HEAD_SIZE * 0.4, position.Z)

    -- Set primary part for model
    model.PrimaryPart = torso

    return model
end

-- Get a random position near a landmark
function CitizenManager:_getSpawnPosition(landmark: WorldPlan.Landmark): Vector3
    -- Random angle around landmark
    local angle = math.random() * math.pi * 2

    -- Random distance within spawn radius
    local distance = MIN_SPAWN_DISTANCE + math.random() * (SPAWN_RADIUS - MIN_SPAWN_DISTANCE)

    local x = landmark.position.X + math.cos(angle) * distance
    local z = landmark.position.Y + math.sin(angle) * distance -- Vector2.Y is world Z

    -- Query terrain height
    local y = TerrainUtils.getHeightAt(self.terrain, x, z)

    return Vector3.new(x, y, z)
end

-- Spawn citizens near a specific landmark
function CitizenManager:_spawnCitizensAtLandmark(landmark: WorldPlan.Landmark, folder: Folder): number
    local spawned = 0

    -- Skip spawning if we've reached max citizens
    if #self.citizens >= self.maxCitizens then
        return 0
    end

    -- Create landmark subfolder
    local landmarkFolder = Instance.new("Folder")
    landmarkFolder.Name = landmark.landmarkType
    landmarkFolder.Parent = folder

    for i = 1, CITIZENS_PER_LANDMARK do
        -- Check max again for each citizen
        if #self.citizens >= self.maxCitizens then
            break
        end

        local position = self:_getSpawnPosition(landmark)

        -- Skip if in river exclusion zone
        if self.worldPlan:isInRiverExclusionZone(position.X, position.Z) then
            continue
        end

        local citizenModel = self:_createCitizenModel(position)
        citizenModel.Name = string.format("Citizen_%d", i)
        citizenModel.Parent = landmarkFolder

        -- Random facing direction
        local facingAngle = math.random() * math.pi * 2
        local facingCFrame = CFrame.new(position) * CFrame.Angles(0, facingAngle, 0)
        citizenModel:PivotTo(facingCFrame)

        -- Track citizen
        local citizen: Citizen = {
            model = citizenModel,
            landmark = landmark,
            position = position,
        }
        table.insert(self.citizens, citizen)

        spawned = spawned + 1
    end

    return spawned
end

-- Spawn citizens at all landmarks
function CitizenManager:start(): Folder
    local startTime = tick()

    print(string.format("[CitizenManager v%s] Spawning citizens near landmarks...",
        CitizenManager.VERSION
    ))

    -- Create main folder for all citizens
    local folder = Instance.new("Folder")
    folder.Name = "Citizens_Cives"
    folder.Parent = workspace
    self.folder = folder

    -- Get all landmarks from WorldPlan
    local landmarks = self.worldPlan:getLandmarks()
    local totalSpawned = 0

    for _, landmark in ipairs(landmarks) do
        local spawned = self:_spawnCitizensAtLandmark(landmark, folder)
        totalSpawned = totalSpawned + spawned

        -- Yield periodically to avoid script timeout
        if totalSpawned % 10 == 0 then
            task.wait()
        end
    end

    local elapsed = tick() - startTime
    print(string.format("[CitizenManager v%s] Spawned %d citizens in %.2f seconds",
        CitizenManager.VERSION,
        totalSpawned,
        elapsed
    ))

    return folder
end

-- Get the number of citizens spawned
function CitizenManager:getCitizenCount(): number
    return #self.citizens
end

-- Get all citizen data
function CitizenManager:getCitizens(): { Citizen }
    return self.citizens
end

-- Destroy all citizens
function CitizenManager:destroy(): ()
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end

    self.citizens = {}

    print(string.format("[CitizenManager v%s] All citizens removed", CitizenManager.VERSION))
end

return CitizenManager
