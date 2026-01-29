--!strict
--[[
    AqueductBuilder - Constructs Roman aqueducts spanning the map

    Creates iconic Roman aqueduct structures with:
    - Multiple tiers of arches (up to 3 levels)
    - Both functional (intact) and ruined sections
    - Water channels on top for functional sections
    - Terrain-adaptive pillar heights
    - Avoided landmark collisions via WorldPlan

    Based on BRicey techniques for procedural environment generation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))

local AqueductBuilder = {}
AqueductBuilder.__index = AqueductBuilder
AqueductBuilder.VERSION = "1.0.0"

-- Aqueduct construction constants
local SEGMENT_LENGTH = 20 -- Distance between pillars
local ARCH_HEIGHT = 12 -- Height of each arch tier
local PILLAR_WIDTH = 4 -- Width of support pillars
local PILLAR_DEPTH = 3 -- Depth of support pillars
local CHANNEL_WIDTH = 6 -- Width of water channel on top
local CHANNEL_DEPTH = 2 -- Depth of water channel
local CHANNEL_WALL_THICKNESS = 1 -- Thickness of channel walls
local WALKWAY_WIDTH = 8 -- Total width of top walkway
local RAILING_HEIGHT = 2 -- Height of side railings
local MIN_PILLAR_HEIGHT = 4 -- Minimum pillar height
local _TOTAL_AQUEDUCT_LENGTH = 800 -- Total length in studs (reserved for future use)
local LANDMARK_AVOIDANCE_RADIUS = 80 -- Distance to avoid landmarks

-- Roman architectural colors
local STONE_GRAY = Color3.fromRGB(170, 165, 155)
local STONE_DARK = Color3.fromRGB(140, 135, 125)
local STONE_WEATHERED = Color3.fromRGB(150, 145, 135)
local STONE_RUINS = Color3.fromRGB(130, 125, 115)
local MOSS_GREEN = Color3.fromRGB(90, 110, 80)

-- Section types (ordered by condition)
export type SectionType = "functional" | "weathered" | "crumbling" | "ruined"

export type AqueductBuilderConfig = {
    worldPlan: WorldPlan.WorldPlanInstance,
    startPoint: Vector2?,
    endPoint: Vector2?,
    seed: number?,
}

export type AqueductSegment = {
    position: Vector2,
    terrainHeight: number,
    pillarHeight: number,
    sectionType: SectionType,
    tiers: number,
}

export type AqueductBuilderInstance = typeof(setmetatable(
    {} :: {
        worldPlan: WorldPlan.WorldPlanInstance,
        terrain: Terrain,
        folder: Folder?,
        parts: { BasePart },
        segments: { AqueductSegment },
        startPoint: Vector2,
        endPoint: Vector2,
        seed: number,
        segmentCount: number,
    },
    AqueductBuilder
))

function AqueductBuilder.new(config: AqueductBuilderConfig): AqueductBuilderInstance
    local self = setmetatable({}, AqueductBuilder)
    self.worldPlan = config.worldPlan
    self.terrain = workspace.Terrain
    self.folder = nil
    self.parts = {}
    self.segments = {}
    self.seed = config.seed or math.random(1, 100000)
    self.segmentCount = 0

    -- Default start and end points: span west to east, offset from center
    local mapSize = config.worldPlan:getMapSize()
    local halfMap = mapSize / 2
    self.startPoint = config.startPoint or Vector2.new(-halfMap + 50, -150)
    self.endPoint = config.endPoint or Vector2.new(halfMap - 50, 100)

    print(string.format("[AqueductBuilder v%s] Initializing with seed: %d", AqueductBuilder.VERSION, self.seed))
    return self
end

-- Helper: Create a basic part for the aqueduct
function AqueductBuilder:_createPart(
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
    part.Material = material or Enum.Material.Brick
    part.Color = color
    part.CanCollide = true

    table.insert(self.parts, part)
    return part
end

-- Helper: Create a part with rotation
function AqueductBuilder:_createPartRotated(
    name: string,
    cframe: CFrame,
    size: Vector3,
    color: Color3,
    material: Enum.Material?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.Material = material or Enum.Material.Brick
    part.Color = color
    part.CanCollide = true

    table.insert(self.parts, part)
    return part
end

-- Generate the aqueduct path, avoiding landmarks
function AqueductBuilder:_generatePath(): { Vector2 }
    local path: { Vector2 } = {}
    local direction = (self.endPoint - self.startPoint).Unit
    local totalDistance = (self.endPoint - self.startPoint).Magnitude
    local numSegments = math.floor(totalDistance / SEGMENT_LENGTH)

    math.randomseed(self.seed)

    for i = 0, numSegments do
        local t = i / numSegments
        local basePosition = self.startPoint + direction * (t * totalDistance)

        -- Add some gentle meandering using perlin noise
        local perpendicular = Vector2.new(-direction.Y, direction.X)
        local noiseOffset = math.noise(t * 3, self.seed * 0.1) * 30
        local position = basePosition + perpendicular * noiseOffset

        -- Check if position is too close to a landmark
        local tooCloseToLandmark = self.worldPlan:isNearLandmark(position.X, position.Y, LANDMARK_AVOIDANCE_RADIUS)

        if tooCloseToLandmark then
            -- Try to route around by adjusting perpendicular offset
            local adjustedOffset = noiseOffset + (math.random() > 0.5 and 100 or -100)
            position = basePosition + perpendicular * adjustedOffset

            -- If still too close, skip this segment (will create a gap/ruin)
            if self.worldPlan:isNearLandmark(position.X, position.Y, LANDMARK_AVOIDANCE_RADIUS) then
                -- Insert a nil marker to indicate a break
                table.insert(path, Vector2.new(math.huge, math.huge))
                continue
            end
        end

        table.insert(path, position)
    end

    return path
end

-- Determine section type based on position along the aqueduct
function AqueductBuilder:_determineSectionType(segmentIndex: number, totalSegments: number): SectionType
    math.randomseed(self.seed + segmentIndex)
    local random = math.random()
    local _progress = segmentIndex / totalSegments -- Reserved for future position-based logic

    -- Create natural variation in condition
    -- Earlier sections more likely to be ruined, middle functional, later weathered
    if random < 0.15 then
        return "ruined"
    elseif random < 0.25 then
        return "crumbling"
    elseif random < 0.40 then
        return "weathered"
    else
        return "functional"
    end
end

-- Calculate number of arch tiers based on pillar height
function AqueductBuilder:_calculateTiers(pillarHeight: number): number
    if pillarHeight < ARCH_HEIGHT then
        return 1
    elseif pillarHeight < ARCH_HEIGHT * 2 then
        return 2
    else
        return 3
    end
end

-- Build a single arch between two pillars
function AqueductBuilder:_buildArch(
    startX: number,
    endX: number,
    startZ: number,
    endZ: number,
    archBaseY: number,
    archHeight: number,
    rotation: number,
    folder: Folder,
    sectionType: SectionType
): ()
    local archWidth = math.sqrt((endX - startX)^2 + (endZ - startZ)^2) - PILLAR_WIDTH
    local centerX = (startX + endX) / 2
    local centerZ = (startZ + endZ) / 2

    local color = if sectionType == "ruined" then STONE_RUINS
        elseif sectionType == "crumbling" then STONE_WEATHERED
        elseif sectionType == "weathered" then STONE_WEATHERED
        else STONE_GRAY

    -- Create arch segments
    local numArchSegments = 7
    local archRadius = archWidth / 2

    for i = 0, numArchSegments do
        local angle = math.pi * (i / numArchSegments)
        local nextAngle = math.pi * ((i + 1) / numArchSegments)

        if i < numArchSegments then
            -- Skip some segments for damaged arches
            if sectionType == "crumbling" and math.random() < 0.3 then
                continue
            end
            if sectionType == "ruined" then
                continue -- Ruined sections have no arches
            end

            local x1 = math.cos(angle) * archRadius
            local y1 = math.sin(angle) * archRadius * (archHeight / archRadius)
            local x2 = math.cos(nextAngle) * archRadius
            local y2 = math.sin(nextAngle) * archRadius * (archHeight / archRadius)

            local segmentCenterX = (x1 + x2) / 2
            local segmentCenterY = (y1 + y2) / 2
            local segmentLength = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
            local segmentAngle = math.atan2(y2 - y1, x2 - x1)

            local worldX = centerX + segmentCenterX * math.cos(rotation)
            local worldZ = centerZ + segmentCenterX * math.sin(rotation)
            local worldY = archBaseY + segmentCenterY

            local archPart = self:_createPartRotated(
                string.format("Arch_%d", i),
                CFrame.new(worldX, worldY, worldZ)
                    * CFrame.Angles(0, rotation, 0)
                    * CFrame.Angles(0, 0, segmentAngle + math.pi / 2),
                Vector3.new(2, segmentLength + 0.5, PILLAR_DEPTH),
                color
            )
            archPart.Parent = folder
        end
    end
end

-- Build a pillar at a specific position
function AqueductBuilder:_buildPillar(
    x: number,
    z: number,
    baseY: number,
    height: number,
    _tiers: number,
    rotation: number,
    folder: Folder,
    sectionType: SectionType
): ()
    local color = if sectionType == "ruined" then STONE_RUINS
        elseif sectionType == "crumbling" then STONE_WEATHERED
        elseif sectionType == "weathered" then STONE_WEATHERED
        else STONE_GRAY

    -- For ruined sections, make shorter or missing pillars
    local actualHeight = height
    if sectionType == "ruined" then
        actualHeight = height * (0.2 + math.random() * 0.4)
    elseif sectionType == "crumbling" then
        actualHeight = height * (0.6 + math.random() * 0.3)
    end

    -- Main pillar
    local pillar = self:_createPartRotated(
        "Pillar",
        CFrame.new(x, baseY + actualHeight / 2, z) * CFrame.Angles(0, rotation, 0),
        Vector3.new(PILLAR_WIDTH, actualHeight, PILLAR_DEPTH),
        color
    )
    pillar.Parent = folder

    -- Add decorative elements for functional/weathered sections
    if sectionType == "functional" or sectionType == "weathered" then
        -- Pillar base (wider)
        local base = self:_createPartRotated(
            "PillarBase",
            CFrame.new(x, baseY + 1, z) * CFrame.Angles(0, rotation, 0),
            Vector3.new(PILLAR_WIDTH + 1, 2, PILLAR_DEPTH + 1),
            STONE_DARK
        )
        base.Parent = folder

        -- Pillar capital (decorative top)
        if actualHeight > MIN_PILLAR_HEIGHT then
            local capital = self:_createPartRotated(
                "PillarCapital",
                CFrame.new(x, baseY + actualHeight - 0.5, z) * CFrame.Angles(0, rotation, 0),
                Vector3.new(PILLAR_WIDTH + 1, 1, PILLAR_DEPTH + 1),
                STONE_DARK
            )
            capital.Parent = folder
        end
    end

    -- Add moss/vegetation to weathered and ruined sections
    if sectionType == "weathered" or sectionType == "crumbling" then
        if math.random() < 0.4 then
            local mossHeight = 2 + math.random() * 3
            local moss = self:_createPartRotated(
                "Moss",
                CFrame.new(x, baseY + mossHeight / 2, z) * CFrame.Angles(0, rotation, 0),
                Vector3.new(PILLAR_WIDTH + 0.5, mossHeight, PILLAR_DEPTH + 0.5),
                MOSS_GREEN,
                Enum.Material.Grass
            )
            moss.Parent = folder
        end
    end
end

-- Build the water channel on top of the aqueduct
function AqueductBuilder:_buildWaterChannel(
    startX: number,
    endX: number,
    startZ: number,
    endZ: number,
    channelY: number,
    rotation: number,
    folder: Folder,
    sectionType: SectionType
): ()
    if sectionType == "ruined" then
        return -- No channel on ruined sections
    end

    local length = math.sqrt((endX - startX)^2 + (endZ - startZ)^2)
    local centerX = (startX + endX) / 2
    local centerZ = (startZ + endZ) / 2

    local color = if sectionType == "crumbling" then STONE_WEATHERED
        elseif sectionType == "weathered" then STONE_WEATHERED
        else STONE_GRAY

    -- Channel floor (walkway)
    local floor = self:_createPartRotated(
        "ChannelFloor",
        CFrame.new(centerX, channelY, centerZ) * CFrame.Angles(0, rotation, 0),
        Vector3.new(WALKWAY_WIDTH, 1, length),
        color
    )
    floor.Parent = folder

    -- Channel walls (left and right)
    local wallOffsetX = (CHANNEL_WIDTH / 2 + CHANNEL_WALL_THICKNESS / 2)

    -- Left wall
    local leftWallX = centerX + wallOffsetX * math.cos(rotation + math.pi / 2)
    local leftWallZ = centerZ + wallOffsetX * math.sin(rotation + math.pi / 2)
    local leftWall = self:_createPartRotated(
        "ChannelWallLeft",
        CFrame.new(leftWallX, channelY + CHANNEL_DEPTH / 2 + 0.5, leftWallZ) * CFrame.Angles(0, rotation, 0),
        Vector3.new(CHANNEL_WALL_THICKNESS, CHANNEL_DEPTH, length),
        color
    )
    leftWall.Parent = folder

    -- Right wall
    local rightWallX = centerX - wallOffsetX * math.cos(rotation + math.pi / 2)
    local rightWallZ = centerZ - wallOffsetX * math.sin(rotation + math.pi / 2)
    local rightWall = self:_createPartRotated(
        "ChannelWallRight",
        CFrame.new(rightWallX, channelY + CHANNEL_DEPTH / 2 + 0.5, rightWallZ) * CFrame.Angles(0, rotation, 0),
        Vector3.new(CHANNEL_WALL_THICKNESS, CHANNEL_DEPTH, length),
        color
    )
    rightWall.Parent = folder

    -- Railings for safety (on functional sections only)
    if sectionType == "functional" then
        local railingOffset = WALKWAY_WIDTH / 2 - 0.5

        -- Left railing
        local leftRailX = centerX + railingOffset * math.cos(rotation + math.pi / 2)
        local leftRailZ = centerZ + railingOffset * math.sin(rotation + math.pi / 2)
        local leftRailing = self:_createPartRotated(
            "RailingLeft",
            CFrame.new(leftRailX, channelY + RAILING_HEIGHT / 2 + 0.5, leftRailZ) * CFrame.Angles(0, rotation, 0),
            Vector3.new(1, RAILING_HEIGHT, length),
            STONE_DARK
        )
        leftRailing.Parent = folder

        -- Right railing
        local rightRailX = centerX - railingOffset * math.cos(rotation + math.pi / 2)
        local rightRailZ = centerZ - railingOffset * math.sin(rotation + math.pi / 2)
        local rightRailing = self:_createPartRotated(
            "RailingRight",
            CFrame.new(rightRailX, channelY + RAILING_HEIGHT / 2 + 0.5, rightRailZ) * CFrame.Angles(0, rotation, 0),
            Vector3.new(1, RAILING_HEIGHT, length),
            STONE_DARK
        )
        rightRailing.Parent = folder
    end

    -- Crumbling sections have gaps in walls
    if sectionType == "crumbling" then
        -- Randomly remove some wall sections (by not adding them - already done above)
        -- Add debris below
        if math.random() < 0.5 then
            local debrisX = centerX + (math.random() - 0.5) * 10
            local debrisZ = centerZ + (math.random() - 0.5) * 10
            local debrisY = channelY - 20 - math.random() * 10
            local debris = self:_createPart(
                "Debris",
                Vector3.new(debrisX, debrisY, debrisZ),
                Vector3.new(3 + math.random() * 3, 2 + math.random() * 2, 3 + math.random() * 3),
                STONE_RUINS
            )
            debris.CFrame = debris.CFrame * CFrame.Angles(
                math.random() * 0.5,
                math.random() * math.pi * 2,
                math.random() * 0.5
            )
            debris.Parent = folder
        end
    end
end

-- Build debris for ruined sections
function AqueductBuilder:_buildDebris(
    x: number,
    z: number,
    baseY: number,
    folder: Folder
): ()
    local numDebris = 3 + math.random(1, 5)

    for i = 1, numDebris do
        local offsetX = (math.random() - 0.5) * 15
        local offsetZ = (math.random() - 0.5) * 15
        local size = Vector3.new(
            2 + math.random() * 4,
            1 + math.random() * 3,
            2 + math.random() * 4
        )

        local debris = self:_createPart(
            string.format("Debris_%d", i),
            Vector3.new(x + offsetX, baseY + size.Y / 2, z + offsetZ),
            size,
            STONE_RUINS
        )
        debris.CFrame = debris.CFrame * CFrame.Angles(
            math.random() * 0.3,
            math.random() * math.pi * 2,
            math.random() * 0.3
        )
        debris.Parent = folder
    end

    -- Fallen arch piece
    if math.random() < 0.6 then
        local archPiece = self:_createPart(
            "FallenArch",
            Vector3.new(x + (math.random() - 0.5) * 10, baseY + 2, z + (math.random() - 0.5) * 10),
            Vector3.new(8, 3, 2),
            STONE_RUINS
        )
        archPiece.CFrame = archPiece.CFrame * CFrame.Angles(
            math.random() * 0.5,
            math.random() * math.pi * 2,
            math.random() * 0.8
        )
        archPiece.Parent = folder
    end
end

-- Build a complete aqueduct segment (pillar + arch + channel)
function AqueductBuilder:_buildSegment(
    segment: AqueductSegment,
    nextSegment: AqueductSegment?,
    segmentIndex: number,
    folder: Folder
): ()
    local segmentFolder = Instance.new("Folder")
    segmentFolder.Name = string.format("Segment_%d_%s", segmentIndex, segment.sectionType)
    segmentFolder.Parent = folder

    local x = segment.position.X
    local z = segment.position.Y
    local baseY = segment.terrainHeight
    local pillarHeight = segment.pillarHeight
    local sectionType = segment.sectionType

    -- Calculate rotation to face next segment (if exists)
    local rotation = 0
    if nextSegment then
        local dx = nextSegment.position.X - x
        local dz = nextSegment.position.Y - z
        rotation = math.atan2(dx, dz)
    end

    -- Build pillar
    self:_buildPillar(x, z, baseY, pillarHeight, segment.tiers, rotation, segmentFolder, sectionType)

    -- Build arch and channel to next segment
    if nextSegment and sectionType ~= "ruined" and nextSegment.sectionType ~= "ruined" then
        local nextX = nextSegment.position.X
        local nextZ = nextSegment.position.Y
        local archBaseY = baseY + pillarHeight - ARCH_HEIGHT

        self:_buildArch(
            x, nextX, z, nextZ,
            archBaseY, ARCH_HEIGHT,
            rotation, segmentFolder, sectionType
        )

        local channelY = baseY + pillarHeight
        self:_buildWaterChannel(
            x, nextX, z, nextZ,
            channelY, rotation,
            segmentFolder, sectionType
        )
    end

    -- Build debris for ruined sections
    if sectionType == "ruined" then
        self:_buildDebris(x, z, baseY, segmentFolder)
    end
end

-- Build the complete aqueduct
function AqueductBuilder:build(): Folder
    local startTime = tick()

    print(string.format("[AqueductBuilder v%s] Building aqueduct from (%.1f, %.1f) to (%.1f, %.1f)...",
        AqueductBuilder.VERSION,
        self.startPoint.X, self.startPoint.Y,
        self.endPoint.X, self.endPoint.Y
    ))

    -- Create main folder for the aqueduct
    local folder = Instance.new("Folder")
    folder.Name = "Aqueduct_Aquaeductus"
    folder.Parent = workspace
    self.folder = folder

    -- Generate path avoiding landmarks
    local path = self:_generatePath()

    print(string.format("[AqueductBuilder v%s] Generated path with %d points",
        AqueductBuilder.VERSION, #path
    ))

    -- Create segment data
    local segments: { AqueductSegment } = {}
    local totalSegments = #path

    for i, position in ipairs(path) do
        -- Skip break markers
        if position.X == math.huge then
            continue
        end

        local terrainHeight = TerrainUtils.getHeightAt(self.terrain, position.X, position.Y)
        local sectionType = self:_determineSectionType(i, totalSegments)

        -- Calculate pillar height based on desired aqueduct height and terrain
        local desiredTopHeight = 40 -- Desired height above average terrain
        local pillarHeight = math.max(MIN_PILLAR_HEIGHT, desiredTopHeight - (terrainHeight - 20))

        local tiers = self:_calculateTiers(pillarHeight)

        table.insert(segments, {
            position = position,
            terrainHeight = terrainHeight,
            pillarHeight = pillarHeight,
            sectionType = sectionType,
            tiers = tiers,
        })
    end

    self.segments = segments

    -- Build each segment
    for i, segment in ipairs(segments) do
        local nextSegment = segments[i + 1]
        self:_buildSegment(segment, nextSegment, i, folder)
        self.segmentCount = self.segmentCount + 1

        -- Yield periodically to avoid script timeout
        if i % 5 == 0 then
            task.wait()
        end
    end

    local elapsed = tick() - startTime
    print(string.format("[AqueductBuilder v%s] Built %d segments in %.2f seconds (%d parts)",
        AqueductBuilder.VERSION,
        self.segmentCount,
        elapsed,
        #self.parts
    ))

    -- Log section type distribution
    local sectionCounts = { functional = 0, weathered = 0, crumbling = 0, ruined = 0 }
    for _, segment in ipairs(segments) do
        sectionCounts[segment.sectionType] = sectionCounts[segment.sectionType] + 1
    end
    print(string.format("[AqueductBuilder v%s] Section types: functional=%d, weathered=%d, crumbling=%d, ruined=%d",
        AqueductBuilder.VERSION,
        sectionCounts.functional,
        sectionCounts.weathered,
        sectionCounts.crumbling,
        sectionCounts.ruined
    ))

    return folder
end

-- Get the number of segments built
function AqueductBuilder:getSegmentCount(): number
    return self.segmentCount
end

-- Get all segments
function AqueductBuilder:getSegments(): { AqueductSegment }
    return self.segments
end

-- Get all parts created
function AqueductBuilder:getParts(): { BasePart }
    return self.parts
end

-- Destroy the aqueduct
function AqueductBuilder:destroy(): ()
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end

    self.parts = {}
    self.segments = {}
    self.segmentCount = 0

    print(string.format("[AqueductBuilder v%s] Aqueduct destroyed", AqueductBuilder.VERSION))
end

return AqueductBuilder
