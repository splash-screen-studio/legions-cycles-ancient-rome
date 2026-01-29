--!strict
--[[
    RuinsBuilder - Generates procedural Roman ruins throughout the world

    Creates an atmosphere of ancient history by scattering weathered ruins:
    - Fallen columns (single, grouped, broken fragments)
    - Crumbling walls (partial walls, archways, foundations)
    - Rubble piles (scattered stone blocks, debris)

    Placement rules:
    - Rural zones and wilderness areas (NOT civic centers)
    - Away from landmarks (registered in WorldPlan)
    - Adapted to terrain height using TerrainUtils
    - Near roads for historical context (but not blocking them)

    Based on BRicey procedural generation techniques adapted for Roman aesthetics.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))

local RuinsBuilder = {}
RuinsBuilder.__index = RuinsBuilder
RuinsBuilder.VERSION = "1.0.0"

-- Weathered Roman colors (more muted than LandmarkBuilder for ancient feel)
local WEATHERED_MARBLE = Color3.fromRGB(200, 195, 180)
local WEATHERED_CREAM = Color3.fromRGB(180, 170, 155)
local MOSSY_STONE = Color3.fromRGB(140, 145, 130)
local CRACKED_BRICK = Color3.fromRGB(150, 90, 65)
local AGED_CONCRETE = Color3.fromRGB(130, 125, 115)
local DARK_STONE = Color3.fromRGB(100, 95, 90)

-- Ruin size categories (studs)
local RUIN_SIZES = {
    small = { min = 8, max = 12 },
    medium = { min = 20, max = 30 },
    large = { min = 40, max = 60 },
}

-- Column dimensions for ruins
local RUIN_COLUMN_RADIUS_SMALL = 1.2
local RUIN_COLUMN_RADIUS_MEDIUM = 1.8
local RUIN_COLUMN_RADIUS_LARGE = 2.2
local RUIN_COLUMN_HEIGHT_SMALL = 8
local RUIN_COLUMN_HEIGHT_MEDIUM = 14
local RUIN_COLUMN_HEIGHT_LARGE = 20

-- Minimum distance from landmarks to place ruins
local MIN_LANDMARK_DISTANCE = 60

-- Minimum distance from roads to place ruins
local MIN_ROAD_DISTANCE = 15

-- Maximum distance from roads to place ruins (for historical context)
local MAX_ROAD_DISTANCE = 200

export type RuinType = "fallen_column" | "column_fragment" | "column_base" | "fallen_colonnade"
    | "partial_wall" | "wall_foundation" | "broken_archway"
    | "building_foundation" | "steps_to_nothing" | "platform"
    | "rubble_pile" | "debris_scatter" | "broken_statuary"

export type RuinsBuilderConfig = {
    worldPlan: WorldPlan.WorldPlanInstance,
    ruinCount: number?,
    seed: number?,
}

export type RuinsBuilderInstance = typeof(setmetatable(
    {} :: {
        worldPlan: WorldPlan.WorldPlanInstance,
        terrain: Terrain,
        folder: Folder?,
        parts: { BasePart },
        ruinCount: number,
        targetCount: number,
        seed: number,
        mapSize: number,
    },
    RuinsBuilder
))

function RuinsBuilder.new(config: RuinsBuilderConfig): RuinsBuilderInstance
    local self = setmetatable({}, RuinsBuilder)
    self.worldPlan = config.worldPlan
    self.terrain = workspace.Terrain
    self.folder = nil
    self.parts = {}
    self.ruinCount = 0
    self.targetCount = config.ruinCount or 50
    self.seed = config.seed or math.random(1, 100000)
    self.mapSize = config.worldPlan:getMapSize()

    print(string.format("[RuinsBuilder v%s] Initializing with seed: %d, target: %d ruins",
        RuinsBuilder.VERSION, self.seed, self.targetCount))
    return self
end

-- Helper: Create a basic part with weathered appearance
function RuinsBuilder:_createPart(
    name: string,
    position: Vector3,
    size: Vector3,
    color: Color3,
    material: Enum.Material?,
    rotation: CFrame?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Anchored = true
    part.Material = material or Enum.Material.Concrete
    part.Color = color
    part.CanCollide = true

    if rotation then
        part.CFrame = CFrame.new(position) * rotation
    else
        part.Position = position
    end

    table.insert(self.parts, part)
    return part
end

-- Helper: Create a cylinder part for columns
function RuinsBuilder:_createCylinder(
    name: string,
    position: Vector3,
    radius: number,
    height: number,
    color: Color3,
    rotation: CFrame?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = Enum.PartType.Cylinder
    part.Size = Vector3.new(height, radius * 2, radius * 2)
    part.Anchored = true
    part.Material = Enum.Material.Marble
    part.Color = color
    part.CanCollide = true

    -- Default cylinder orientation is horizontal along X axis
    local baseCFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    if rotation then
        part.CFrame = CFrame.new(position) * rotation
    else
        part.CFrame = baseCFrame
    end

    table.insert(self.parts, part)
    return part
end

-- Create a fallen column lying on the ground
function RuinsBuilder:_createFallenColumn(
    x: number,
    z: number,
    folder: Folder,
    size: string?
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)
    local columnSize = size or "medium"

    local radius, height
    if columnSize == "small" then
        radius = RUIN_COLUMN_RADIUS_SMALL
        height = RUIN_COLUMN_HEIGHT_SMALL
    elseif columnSize == "large" then
        radius = RUIN_COLUMN_RADIUS_LARGE
        height = RUIN_COLUMN_HEIGHT_LARGE
    else
        radius = RUIN_COLUMN_RADIUS_MEDIUM
        height = RUIN_COLUMN_HEIGHT_MEDIUM
    end

    -- Random rotation for fallen direction
    math.randomseed(self.seed + math.floor(x * 100 + z))
    local rotation = math.random() * math.pi * 2

    -- Fallen column lies on ground (cylinder rotated to be horizontal)
    local column = self:_createCylinder(
        "FallenColumn",
        Vector3.new(x, terrainY + radius, z),
        radius,
        height,
        WEATHERED_MARBLE,
        CFrame.Angles(0, rotation, math.rad(90))
    )
    column.Parent = folder

    -- Column base (often remains in place)
    local baseSize = radius * 2.5
    local base = self:_createPart(
        "ColumnBase",
        Vector3.new(x - math.cos(rotation) * height * 0.5, terrainY + 0.5, z - math.sin(rotation) * height * 0.5),
        Vector3.new(baseSize, 1, baseSize),
        WEATHERED_CREAM
    )
    base.Parent = folder
end

-- Create a broken column fragment
function RuinsBuilder:_createColumnFragment(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local rotation = math.random() * math.pi * 2
    local fragmentHeight = 3 + math.random() * 4
    local radius = RUIN_COLUMN_RADIUS_SMALL + math.random() * 0.5

    -- Fragment lying on ground at an angle
    local tilt = math.rad(10 + math.random() * 30)
    local fragment = self:_createCylinder(
        "ColumnFragment",
        Vector3.new(x, terrainY + radius + 0.5, z),
        radius,
        fragmentHeight,
        MOSSY_STONE,
        CFrame.Angles(tilt, rotation, math.rad(90))
    )
    fragment.Parent = folder
end

-- Create a column base without its column (column gone)
function RuinsBuilder:_createColumnBase(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local baseSize = 3 + math.random() * 2
    local baseHeight = 0.8 + math.random() * 0.5

    -- Square base
    local base = self:_createPart(
        "LonelyColumnBase",
        Vector3.new(x, terrainY + baseHeight / 2, z),
        Vector3.new(baseSize, baseHeight, baseSize),
        WEATHERED_CREAM
    )
    base.Parent = folder

    -- Maybe a small stump of column
    if math.random() > 0.5 then
        local stumpRadius = baseSize / 3
        local stumpHeight = 1 + math.random() * 2
        local stump = self:_createCylinder(
            "ColumnStump",
            Vector3.new(x, terrainY + baseHeight + stumpHeight / 2, z),
            stumpRadius,
            stumpHeight,
            WEATHERED_MARBLE
        )
        stump.Parent = folder
    end
end

-- Create a fallen colonnade (multiple columns in a row, all fallen)
function RuinsBuilder:_createFallenColonnade(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local numColumns = 3 + math.random(0, 2)
    local spacing = 6 + math.random() * 3
    local direction = math.random() * math.pi * 2

    local dirX = math.cos(direction)
    local dirZ = math.sin(direction)

    for i = 0, numColumns - 1 do
        local colX = x + dirX * i * spacing
        local colZ = z + dirZ * i * spacing
        local colY = TerrainUtils.getHeightAt(self.terrain, colX, colZ)

        -- Alternate between fallen columns and standing bases
        if math.random() > 0.3 then
            -- Fallen column
            local fallDir = direction + math.rad(90) + math.rad(math.random(-20, 20))
            local height = RUIN_COLUMN_HEIGHT_MEDIUM + math.random(-2, 2)
            local column = self:_createCylinder(
                string.format("FallenColumn_%d", i),
                Vector3.new(colX, colY + RUIN_COLUMN_RADIUS_MEDIUM, colZ),
                RUIN_COLUMN_RADIUS_MEDIUM,
                height,
                WEATHERED_MARBLE,
                CFrame.Angles(0, fallDir, math.rad(90))
            )
            column.Parent = folder
        end

        -- Base (always present)
        local baseSize = RUIN_COLUMN_RADIUS_MEDIUM * 2.5
        local base = self:_createPart(
            string.format("ColumnBase_%d", i),
            Vector3.new(colX, colY + 0.5, colZ),
            Vector3.new(baseSize, 1, baseSize),
            WEATHERED_CREAM
        )
        base.Parent = folder
    end
end

-- Create a partial wall with gaps
function RuinsBuilder:_createPartialWall(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local wallLength = 15 + math.random() * 15
    local wallHeight = 4 + math.random() * 6
    local wallThickness = 2 + math.random()
    local rotation = math.random() * math.pi

    -- Create wall segments with gaps
    local numSegments = 2 + math.random(0, 2)
    local segmentLength = wallLength / numSegments * 0.7

    for i = 0, numSegments - 1 do
        local offsetX = (i - numSegments / 2) * (wallLength / numSegments) * math.cos(rotation)
        local offsetZ = (i - numSegments / 2) * (wallLength / numSegments) * math.sin(rotation)

        local segX = x + offsetX
        local segZ = z + offsetZ
        local segY = TerrainUtils.getHeightAt(self.terrain, segX, segZ)

        -- Vary height for crumbling effect
        local segHeight = wallHeight * (0.5 + math.random() * 0.5)

        local segment = self:_createPart(
            string.format("WallSegment_%d", i),
            Vector3.new(segX, segY + segHeight / 2, segZ),
            Vector3.new(segmentLength, segHeight, wallThickness),
            CRACKED_BRICK,
            Enum.Material.Brick,
            CFrame.Angles(0, rotation, 0)
        )
        segment.Parent = folder
    end
end

-- Create a wall foundation (outline only)
function RuinsBuilder:_createWallFoundation(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local length = 20 + math.random() * 20
    local rotation = math.random() * math.pi

    local foundationHeight = 0.5 + math.random() * 0.5
    local foundationWidth = 2 + math.random()

    local foundation = self:_createPart(
        "WallFoundation",
        Vector3.new(x, terrainY + foundationHeight / 2, z),
        Vector3.new(length, foundationHeight, foundationWidth),
        DARK_STONE,
        Enum.Material.Slate,
        CFrame.Angles(0, rotation, 0)
    )
    foundation.Parent = folder
end

-- Create a broken archway
function RuinsBuilder:_createBrokenArchway(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local archWidth = 8 + math.random() * 4
    local archHeight = 8 + math.random() * 6
    local pillarThickness = 2 + math.random()
    local rotation = math.random() * math.pi

    -- Left pillar (full height or partial)
    local leftHeight = archHeight * (0.6 + math.random() * 0.4)
    local leftPillar = self:_createPart(
        "ArchPillarLeft",
        Vector3.new(
            x - (archWidth / 2) * math.cos(rotation),
            terrainY + leftHeight / 2,
            z - (archWidth / 2) * math.sin(rotation)
        ),
        Vector3.new(pillarThickness, leftHeight, pillarThickness),
        WEATHERED_MARBLE,
        Enum.Material.Marble,
        CFrame.Angles(0, rotation, 0)
    )
    leftPillar.Parent = folder

    -- Right pillar (usually shorter - broken)
    local rightHeight = archHeight * (0.3 + math.random() * 0.5)
    local rightPillar = self:_createPart(
        "ArchPillarRight",
        Vector3.new(
            x + (archWidth / 2) * math.cos(rotation),
            terrainY + rightHeight / 2,
            z + (archWidth / 2) * math.sin(rotation)
        ),
        Vector3.new(pillarThickness, rightHeight, pillarThickness),
        WEATHERED_MARBLE,
        Enum.Material.Marble,
        CFrame.Angles(0, rotation, 0)
    )
    rightPillar.Parent = folder

    -- Fallen keystone nearby
    local keystoneSize = 2 + math.random()
    local keystone = self:_createPart(
        "FallenKeystone",
        Vector3.new(
            x + (math.random() - 0.5) * 6,
            terrainY + keystoneSize / 2,
            z + (math.random() - 0.5) * 6
        ),
        Vector3.new(keystoneSize, keystoneSize, keystoneSize * 0.6),
        MOSSY_STONE,
        Enum.Material.Concrete
    )
    keystone.Parent = folder
end

-- Create a building foundation outline
function RuinsBuilder:_createBuildingFoundation(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local width = 15 + math.random() * 20
    local depth = 12 + math.random() * 15
    local rotation = math.random() * math.pi
    local wallThickness = 1.5 + math.random() * 0.5
    local wallHeight = 0.8 + math.random() * 0.7

    local rotCFrame = CFrame.Angles(0, rotation, 0)

    -- Foundation walls (4 sides, some may be missing)
    local walls = {
        { offset = Vector3.new(0, 0, -depth / 2), size = Vector3.new(width, wallHeight, wallThickness) },
        { offset = Vector3.new(0, 0, depth / 2), size = Vector3.new(width, wallHeight, wallThickness) },
        { offset = Vector3.new(-width / 2, 0, 0), size = Vector3.new(wallThickness, wallHeight, depth) },
        { offset = Vector3.new(width / 2, 0, 0), size = Vector3.new(wallThickness, wallHeight, depth) },
    }

    for i, wallData in ipairs(walls) do
        -- Some walls may be missing (ruined)
        if math.random() > 0.2 then
            local rotatedOffset = rotCFrame:VectorToWorldSpace(wallData.offset)
            local wallX = x + rotatedOffset.X
            local wallZ = z + rotatedOffset.Z
            local wallY = TerrainUtils.getHeightAt(self.terrain, wallX, wallZ)

            local wall = self:_createPart(
                string.format("FoundationWall_%d", i),
                Vector3.new(wallX, wallY + wallHeight / 2, wallZ),
                wallData.size,
                DARK_STONE,
                Enum.Material.Slate,
                rotCFrame
            )
            wall.Parent = folder
        end
    end
end

-- Create steps leading to nothing
function RuinsBuilder:_createStepsToNothing(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local numSteps = 4 + math.random(0, 4)
    local stepWidth = 8 + math.random() * 6
    local stepDepth = 1.2 + math.random() * 0.5
    local stepHeight = 0.5 + math.random() * 0.3
    local rotation = math.random() * math.pi * 2

    local dirX = math.cos(rotation)
    local dirZ = math.sin(rotation)

    for i = 0, numSteps - 1 do
        local stepX = x + dirX * i * stepDepth
        local stepZ = z + dirZ * i * stepDepth
        local stepY = terrainY + i * stepHeight

        -- Steps may be broken/partial
        local actualWidth = stepWidth * (0.7 + math.random() * 0.3)
        if i > numSteps - 2 and math.random() > 0.5 then
            -- Last steps often broken
            actualWidth = actualWidth * 0.5
        end

        local step = self:_createPart(
            string.format("Step_%d", i),
            Vector3.new(stepX, stepY + stepHeight / 2, stepZ),
            Vector3.new(actualWidth, stepHeight, stepDepth),
            WEATHERED_MARBLE,
            Enum.Material.Marble,
            CFrame.Angles(0, rotation, 0)
        )
        step.Parent = folder
    end
end

-- Create a raised platform (former building floor)
function RuinsBuilder:_createPlatform(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local width = 10 + math.random() * 15
    local depth = 8 + math.random() * 12
    local height = 1.5 + math.random() * 1.5
    local rotation = math.random() * math.pi

    local platform = self:_createPart(
        "RuinedPlatform",
        Vector3.new(x, terrainY + height / 2, z),
        Vector3.new(width, height, depth),
        AGED_CONCRETE,
        Enum.Material.Concrete,
        CFrame.Angles(0, rotation, 0)
    )
    platform.Parent = folder

    -- Add some broken edges (smaller blocks around perimeter)
    local numDebris = 2 + math.random(0, 3)
    for i = 1, numDebris do
        local debrisX = x + (math.random() - 0.5) * width * 1.2
        local debrisZ = z + (math.random() - 0.5) * depth * 1.2
        local debrisY = TerrainUtils.getHeightAt(self.terrain, debrisX, debrisZ)
        local debrisSize = 1 + math.random() * 2

        local debris = self:_createPart(
            string.format("PlatformDebris_%d", i),
            Vector3.new(debrisX, debrisY + debrisSize / 2, debrisZ),
            Vector3.new(debrisSize, debrisSize * 0.6, debrisSize),
            AGED_CONCRETE,
            Enum.Material.Concrete
        )
        debris.Parent = folder
    end
end

-- Create a rubble pile
function RuinsBuilder:_createRubblePile(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local numBlocks = 5 + math.random(0, 8)
    local pileRadius = 4 + math.random() * 4

    local colors = { WEATHERED_MARBLE, MOSSY_STONE, AGED_CONCRETE, CRACKED_BRICK, DARK_STONE }
    local materials = { Enum.Material.Marble, Enum.Material.Concrete, Enum.Material.Brick, Enum.Material.Slate }

    for i = 1, numBlocks do
        local angle = math.random() * math.pi * 2
        local dist = math.random() * pileRadius
        local blockX = x + math.cos(angle) * dist
        local blockZ = z + math.sin(angle) * dist
        local blockY = TerrainUtils.getHeightAt(self.terrain, blockX, blockZ)

        local blockSize = 1 + math.random() * 3
        local colorIndex = math.random(1, #colors)
        local materialIndex = math.random(1, #materials)

        local block = self:_createPart(
            string.format("Rubble_%d", i),
            Vector3.new(blockX, blockY + blockSize / 2, blockZ),
            Vector3.new(blockSize, blockSize * (0.5 + math.random() * 0.5), blockSize * (0.6 + math.random() * 0.4)),
            colors[colorIndex],
            materials[materialIndex],
            CFrame.Angles(
                math.rad(math.random(-15, 15)),
                math.random() * math.pi * 2,
                math.rad(math.random(-15, 15))
            )
        )
        block.Parent = folder
    end
end

-- Create scattered debris
function RuinsBuilder:_createDebrisScatter(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))
    local numPieces = 8 + math.random(0, 10)
    local scatterRadius = 6 + math.random() * 6

    for i = 1, numPieces do
        local angle = math.random() * math.pi * 2
        local dist = math.random() * scatterRadius
        local pieceX = x + math.cos(angle) * dist
        local pieceZ = z + math.sin(angle) * dist
        local pieceY = TerrainUtils.getHeightAt(self.terrain, pieceX, pieceZ)

        local pieceSize = 0.5 + math.random() * 1.5

        local piece = self:_createPart(
            string.format("Debris_%d", i),
            Vector3.new(pieceX, pieceY + pieceSize / 3, pieceZ),
            Vector3.new(pieceSize, pieceSize * 0.4, pieceSize * 0.8),
            MOSSY_STONE,
            Enum.Material.Slate,
            CFrame.Angles(
                math.rad(math.random(-10, 10)),
                math.random() * math.pi * 2,
                math.rad(math.random(-10, 10))
            )
        )
        piece.Parent = folder
    end
end

-- Create broken statuary
function RuinsBuilder:_createBrokenStatuary(
    x: number,
    z: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, x, z)

    math.randomseed(self.seed + math.floor(x * 100 + z))

    -- Pedestal base
    local pedestalSize = 3 + math.random() * 2
    local pedestalHeight = 2 + math.random() * 1.5

    local pedestal = self:_createPart(
        "StatuePedestal",
        Vector3.new(x, terrainY + pedestalHeight / 2, z),
        Vector3.new(pedestalSize, pedestalHeight, pedestalSize),
        WEATHERED_MARBLE,
        Enum.Material.Marble
    )
    pedestal.Parent = folder

    -- Broken statue base/feet on pedestal
    local feetSize = pedestalSize * 0.6
    local feet = self:_createPart(
        "StatueFeet",
        Vector3.new(x, terrainY + pedestalHeight + 0.4, z),
        Vector3.new(feetSize, 0.8, feetSize * 0.5),
        WEATHERED_MARBLE,
        Enum.Material.Marble
    )
    feet.Parent = folder

    -- Fallen torso nearby
    local torsoX = x + (math.random() - 0.5) * 8
    local torsoZ = z + (math.random() - 0.5) * 8
    local torsoY = TerrainUtils.getHeightAt(self.terrain, torsoX, torsoZ)

    local torso = self:_createCylinder(
        "FallenTorso",
        Vector3.new(torsoX, torsoY + 1.5, torsoZ),
        1.5,
        4,
        WEATHERED_MARBLE,
        CFrame.Angles(math.rad(math.random(-30, 30)), math.random() * math.pi, math.rad(90))
    )
    torso.Parent = folder

    -- Maybe a head
    if math.random() > 0.5 then
        local headX = x + (math.random() - 0.5) * 10
        local headZ = z + (math.random() - 0.5) * 10
        local headY = TerrainUtils.getHeightAt(self.terrain, headX, headZ)

        local head = Instance.new("Part")
        head.Name = "FallenHead"
        head.Shape = Enum.PartType.Ball
        head.Size = Vector3.new(2, 2, 2)
        head.Position = Vector3.new(headX, headY + 1, headZ)
        head.Anchored = true
        head.Material = Enum.Material.Marble
        head.Color = WEATHERED_MARBLE
        head.Parent = folder
        table.insert(self.parts, head)
    end
end

-- Map ruin types to builder methods
function RuinsBuilder:_buildRuinByType(
    ruinType: RuinType,
    x: number,
    z: number,
    folder: Folder
): ()
    if ruinType == "fallen_column" then
        self:_createFallenColumn(x, z, folder)
    elseif ruinType == "column_fragment" then
        self:_createColumnFragment(x, z, folder)
    elseif ruinType == "column_base" then
        self:_createColumnBase(x, z, folder)
    elseif ruinType == "fallen_colonnade" then
        self:_createFallenColonnade(x, z, folder)
    elseif ruinType == "partial_wall" then
        self:_createPartialWall(x, z, folder)
    elseif ruinType == "wall_foundation" then
        self:_createWallFoundation(x, z, folder)
    elseif ruinType == "broken_archway" then
        self:_createBrokenArchway(x, z, folder)
    elseif ruinType == "building_foundation" then
        self:_createBuildingFoundation(x, z, folder)
    elseif ruinType == "steps_to_nothing" then
        self:_createStepsToNothing(x, z, folder)
    elseif ruinType == "platform" then
        self:_createPlatform(x, z, folder)
    elseif ruinType == "rubble_pile" then
        self:_createRubblePile(x, z, folder)
    elseif ruinType == "debris_scatter" then
        self:_createDebrisScatter(x, z, folder)
    elseif ruinType == "broken_statuary" then
        self:_createBrokenStatuary(x, z, folder)
    end
end

-- Check if a position is valid for placing a ruin
function RuinsBuilder:_isValidRuinPosition(x: number, z: number): boolean
    -- Check zone type - prefer rural and wilderness, avoid civic
    local zoneType = self.worldPlan:getZoneAt(x, z)
    if zoneType == "civic" then
        return false
    end

    -- Check distance from landmarks
    if self.worldPlan:isNearLandmark(x, z, MIN_LANDMARK_DISTANCE) then
        return false
    end

    -- Check road distance - not too close, not too far
    local distToRoad = self.worldPlan:getDistanceToRoad(x, z)
    if distToRoad < MIN_ROAD_DISTANCE then
        return false
    end

    -- Check if on river
    if self.worldPlan:isOnRiver(x, z) then
        return false
    end

    -- Check if in river exclusion zone
    if self.worldPlan:isInRiverExclusionZone(x, z) then
        return false
    end

    -- Check if in player plot
    if self.worldPlan:isInPlayerPlot(x, z) then
        return false
    end

    return true
end

-- Select a ruin type based on zone and randomness
function RuinsBuilder:_selectRuinType(x: number, z: number): RuinType
    math.randomseed(self.seed + math.floor(x * 10 + z * 10))

    local zoneType = self.worldPlan:getZoneAt(x, z)
    local distToRoad = self.worldPlan:getDistanceToRoad(x, z)

    -- Near roads: more structured ruins (historical remnants)
    -- Far from roads: more scattered debris

    local roll = math.random()

    if distToRoad < 50 then
        -- Near road: more substantial ruins
        if roll < 0.15 then
            return "fallen_colonnade"
        elseif roll < 0.25 then
            return "broken_archway"
        elseif roll < 0.40 then
            return "fallen_column"
        elseif roll < 0.55 then
            return "partial_wall"
        elseif roll < 0.65 then
            return "building_foundation"
        elseif roll < 0.75 then
            return "steps_to_nothing"
        elseif roll < 0.85 then
            return "broken_statuary"
        else
            return "column_base"
        end
    elseif zoneType == "rural" then
        -- Rural: mix of ruins and debris
        if roll < 0.20 then
            return "fallen_column"
        elseif roll < 0.35 then
            return "partial_wall"
        elseif roll < 0.50 then
            return "rubble_pile"
        elseif roll < 0.65 then
            return "wall_foundation"
        elseif roll < 0.80 then
            return "debris_scatter"
        else
            return "column_fragment"
        end
    else
        -- Wilderness: mostly debris and fragments
        if roll < 0.30 then
            return "rubble_pile"
        elseif roll < 0.50 then
            return "debris_scatter"
        elseif roll < 0.65 then
            return "column_fragment"
        elseif roll < 0.80 then
            return "wall_foundation"
        elseif roll < 0.90 then
            return "platform"
        else
            return "column_base"
        end
    end
end

-- Build all ruins across the map
function RuinsBuilder:build(): Folder
    local startTime = tick()

    print(string.format("[RuinsBuilder v%s] Scattering ruins across the world...",
        RuinsBuilder.VERSION
    ))

    -- Create main folder for all ruins
    local folder = Instance.new("Folder")
    folder.Name = "Ruins_Ruinae"
    folder.Parent = workspace
    self.folder = folder

    -- Initialize random with seed
    math.randomseed(self.seed)

    local halfSize = self.mapSize / 2
    local attempts = 0
    local maxAttempts = self.targetCount * 10

    while self.ruinCount < self.targetCount and attempts < maxAttempts do
        attempts = attempts + 1

        -- Generate random position
        local x = (math.random() - 0.5) * self.mapSize * 0.9
        local z = (math.random() - 0.5) * self.mapSize * 0.9

        if self:_isValidRuinPosition(x, z) then
            local ruinType = self:_selectRuinType(x, z)

            local ruinFolder = Instance.new("Folder")
            ruinFolder.Name = string.format("%s_%d", ruinType, self.ruinCount + 1)
            ruinFolder.Parent = folder

            self:_buildRuinByType(ruinType, x, z, ruinFolder)
            self.ruinCount = self.ruinCount + 1

            -- Yield periodically to avoid script timeout
            if self.ruinCount % 10 == 0 then
                task.wait()
            end
        end
    end

    local elapsed = tick() - startTime
    print(string.format("[RuinsBuilder v%s] Scattered %d ruins in %.2f seconds (%d parts, %d attempts)",
        RuinsBuilder.VERSION,
        self.ruinCount,
        elapsed,
        #self.parts,
        attempts
    ))

    return folder
end

-- Get the number of ruins built
function RuinsBuilder:getRuinCount(): number
    return self.ruinCount
end

-- Get all parts created
function RuinsBuilder:getParts(): { BasePart }
    return self.parts
end

-- Destroy all ruins
function RuinsBuilder:destroy(): ()
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end

    self.parts = {}
    self.ruinCount = 0

    print(string.format("[RuinsBuilder v%s] All ruins destroyed", RuinsBuilder.VERSION))
end

return RuinsBuilder
