--!strict
--[[
    LandmarkBuilder - Constructs pre-built Roman landmarks from WorldPlan

    Creates recognizable landmark structures at positions defined in WorldPlan:
    - Major landmarks: Forum, Colosseum, Thermae, Temples, Circus Maximus
    - Minor landmarks: Castrum, Macellum, Horreum, Pharos, etc.

    These are pre-built structures that make the world feel inhabited from start.
    Players don't build these - they explore them.

    Based on BRicey techniques for procedural environment generation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))

local LandmarkBuilder = {}
LandmarkBuilder.__index = LandmarkBuilder
LandmarkBuilder.VERSION = "1.1.0"

-- Roman architectural colors
local MARBLE_WHITE = Color3.fromRGB(240, 235, 225)
local MARBLE_CREAM = Color3.fromRGB(230, 220, 200)
local TERRACOTTA = Color3.fromRGB(180, 100, 70)
local STONE_GRAY = Color3.fromRGB(160, 155, 145)
local BRONZE = Color3.fromRGB(180, 140, 80)
local SAND = Color3.fromRGB(210, 190, 160)

-- Column dimensions for different orders
local COLUMN_RADIUS_SMALL = 1.5
local COLUMN_RADIUS_MEDIUM = 2
local COLUMN_RADIUS_LARGE = 2.5
local COLUMN_HEIGHT_SMALL = 12
local COLUMN_HEIGHT_MEDIUM = 18
local COLUMN_HEIGHT_LARGE = 24

-- Platform dimensions
local PLATFORM_HEIGHT = 2
local STEP_HEIGHT = 0.5
local STEP_DEPTH = 1

export type LandmarkBuilderConfig = {
    worldPlan: WorldPlan.WorldPlanInstance,
}

export type LandmarkBuilderInstance = typeof(setmetatable(
    {} :: {
        worldPlan: WorldPlan.WorldPlanInstance,
        terrain: Terrain,
        folder: Folder?,
        parts: { BasePart },
        landmarkCount: number,
    },
    LandmarkBuilder
))

function LandmarkBuilder.new(config: LandmarkBuilderConfig): LandmarkBuilderInstance
    local self = setmetatable({}, LandmarkBuilder)
    self.worldPlan = config.worldPlan
    self.terrain = workspace.Terrain
    self.folder = nil
    self.parts = {}
    self.landmarkCount = 0

    print(string.format("[LandmarkBuilder v%s] Initializing...", LandmarkBuilder.VERSION))
    return self
end

-- Helper: Create a basic part
function LandmarkBuilder:_createPart(
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
    part.Material = material or Enum.Material.Marble
    part.Color = color
    part.CanCollide = true

    table.insert(self.parts, part)
    return part
end

-- Helper: Create a cylinder part for columns
function LandmarkBuilder:_createCylinder(
    name: string,
    position: Vector3,
    radius: number,
    height: number,
    color: Color3
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = Enum.PartType.Cylinder
    part.Size = Vector3.new(height, radius * 2, radius * 2)
    part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    part.Anchored = true
    part.Material = Enum.Material.Marble
    part.Color = color
    part.CanCollide = true

    table.insert(self.parts, part)
    return part
end

-- Helper: Create a Roman column with base and capital
function LandmarkBuilder:_createColumn(
    centerX: number,
    baseY: number,
    centerZ: number,
    radius: number,
    height: number,
    folder: Folder
): ()
    -- Column base (square)
    local baseSize = radius * 2.5
    local base = self:_createPart(
        "ColumnBase",
        Vector3.new(centerX, baseY + 0.5, centerZ),
        Vector3.new(baseSize, 1, baseSize),
        MARBLE_CREAM
    )
    base.Parent = folder

    -- Column shaft
    local shaft = self:_createCylinder(
        "ColumnShaft",
        Vector3.new(centerX, baseY + 1 + height / 2, centerZ),
        radius,
        height,
        MARBLE_WHITE
    )
    shaft.Parent = folder

    -- Column capital (wider top)
    local capitalSize = radius * 3
    local capital = self:_createPart(
        "ColumnCapital",
        Vector3.new(centerX, baseY + 1 + height + 0.75, centerZ),
        Vector3.new(capitalSize, 1.5, capitalSize),
        MARBLE_CREAM
    )
    capital.Parent = folder
end

-- Helper: Create a rectangular platform with steps
function LandmarkBuilder:_createPlatform(
    centerX: number,
    baseY: number,
    centerZ: number,
    width: number,
    depth: number,
    folder: Folder
): number
    -- Main platform
    local platform = self:_createPart(
        "Platform",
        Vector3.new(centerX, baseY + PLATFORM_HEIGHT / 2, centerZ),
        Vector3.new(width, PLATFORM_HEIGHT, depth),
        MARBLE_CREAM
    )
    platform.Parent = folder

    -- Front steps
    local numSteps = 4
    for i = 1, numSteps do
        local stepY = baseY - (numSteps - i + 1) * STEP_HEIGHT + STEP_HEIGHT / 2
        local stepZ = centerZ + depth / 2 + (numSteps - i + 1) * STEP_DEPTH
        local stepWidth = width - (numSteps - i) * 0.5
        local step = self:_createPart(
            string.format("Step_%d", i),
            Vector3.new(centerX, stepY, stepZ),
            Vector3.new(stepWidth, STEP_HEIGHT, STEP_DEPTH),
            MARBLE_WHITE
        )
        step.Parent = folder
    end

    return baseY + PLATFORM_HEIGHT
end

-- Helper: Create a colonnade (row of columns)
function LandmarkBuilder:_createColonnade(
    startX: number,
    baseY: number,
    startZ: number,
    count: number,
    spacing: number,
    radius: number,
    height: number,
    direction: Vector3,
    folder: Folder
): ()
    for i = 0, count - 1 do
        local x = startX + direction.X * i * spacing
        local z = startZ + direction.Z * i * spacing
        self:_createColumn(x, baseY, z, radius, height, folder)
    end
end

-- Build Forum (civic center with columns and open space)
function LandmarkBuilder:_buildForum(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local platformTop = self:_createPlatform(centerX, terrainY, centerZ, radius * 1.5, radius * 1.2, folder)

    -- Columns on all four sides
    local columnSpacing = 10
    local columnCount = math.floor(radius / columnSpacing)

    -- Front columns
    self:_createColonnade(
        centerX - (columnCount - 1) * columnSpacing / 2,
        platformTop,
        centerZ + radius * 0.5,
        columnCount,
        columnSpacing,
        COLUMN_RADIUS_MEDIUM,
        COLUMN_HEIGHT_MEDIUM,
        Vector3.new(1, 0, 0),
        folder
    )

    -- Back columns
    self:_createColonnade(
        centerX - (columnCount - 1) * columnSpacing / 2,
        platformTop,
        centerZ - radius * 0.5,
        columnCount,
        columnSpacing,
        COLUMN_RADIUS_MEDIUM,
        COLUMN_HEIGHT_MEDIUM,
        Vector3.new(1, 0, 0),
        folder
    )

    -- Central speaking platform (rostra)
    local rostra = self:_createPart(
        "Rostra",
        Vector3.new(centerX, platformTop + 2, centerZ),
        Vector3.new(8, 4, 6),
        MARBLE_WHITE
    )
    rostra.Parent = folder
end

-- Build Colosseum (elliptical arena with tiered seating)
function LandmarkBuilder:_buildColosseum(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Arena floor
    local arenaFloor = self:_createPart(
        "ArenaFloor",
        Vector3.new(centerX, terrainY + 0.5, centerZ),
        Vector3.new(radius * 1.2, 1, radius * 0.8),
        SAND,
        Enum.Material.Sand
    )
    arenaFloor.Parent = folder

    -- Tiered seating walls (3 tiers)
    local tiers = { 8, 16, 24 }
    local tierWidths = { radius * 1.4, radius * 1.6, radius * 1.8 }
    local tierDepths = { radius * 1.0, radius * 1.2, radius * 1.4 }

    for i, tierHeight in ipairs(tiers) do
        local tierWidth = tierWidths[i]
        local tierDepth = tierDepths[i]
        local wallThickness = 4

        -- North wall
        local northWall = self:_createPart(
            string.format("NorthWall_Tier%d", i),
            Vector3.new(centerX, terrainY + tierHeight / 2, centerZ - tierDepth / 2),
            Vector3.new(tierWidth, tierHeight, wallThickness),
            STONE_GRAY,
            Enum.Material.Brick
        )
        northWall.Parent = folder

        -- South wall
        local southWall = self:_createPart(
            string.format("SouthWall_Tier%d", i),
            Vector3.new(centerX, terrainY + tierHeight / 2, centerZ + tierDepth / 2),
            Vector3.new(tierWidth, tierHeight, wallThickness),
            STONE_GRAY,
            Enum.Material.Brick
        )
        southWall.Parent = folder

        -- East wall
        local eastWall = self:_createPart(
            string.format("EastWall_Tier%d", i),
            Vector3.new(centerX + tierWidth / 2, terrainY + tierHeight / 2, centerZ),
            Vector3.new(wallThickness, tierHeight, tierDepth),
            STONE_GRAY,
            Enum.Material.Brick
        )
        eastWall.Parent = folder

        -- West wall
        local westWall = self:_createPart(
            string.format("WestWall_Tier%d", i),
            Vector3.new(centerX - tierWidth / 2, terrainY + tierHeight / 2, centerZ),
            Vector3.new(wallThickness, tierHeight, tierDepth),
            STONE_GRAY,
            Enum.Material.Brick
        )
        westWall.Parent = folder
    end

    -- Entrance arches (4 main entrances)
    local archPositions = {
        { x = centerX, z = centerZ + radius * 0.7 },
        { x = centerX, z = centerZ - radius * 0.7 },
        { x = centerX + radius * 0.9, z = centerZ },
        { x = centerX - radius * 0.9, z = centerZ },
    }

    for i, pos in ipairs(archPositions) do
        local arch = self:_createPart(
            string.format("EntranceArch_%d", i),
            Vector3.new(pos.x, terrainY + 12, pos.z),
            Vector3.new(8, 10, 4),
            MARBLE_WHITE
        )
        arch.Parent = folder
    end
end

-- Build Thermae (bath complex)
function LandmarkBuilder:_buildThermae(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local platformTop = self:_createPlatform(centerX, terrainY, centerZ, radius * 1.4, radius * 1.2, folder)

    -- Main building
    local mainBuilding = self:_createPart(
        "MainBuilding",
        Vector3.new(centerX, platformTop + 8, centerZ),
        Vector3.new(radius * 1.2, 16, radius),
        TERRACOTTA,
        Enum.Material.Brick
    )
    mainBuilding.Parent = folder

    -- Domed roof section
    local dome = self:_createPart(
        "Dome",
        Vector3.new(centerX, platformTop + 18, centerZ),
        Vector3.new(radius * 0.8, 6, radius * 0.8),
        TERRACOTTA,
        Enum.Material.Brick
    )
    dome.Parent = folder

    -- Front colonnade
    self:_createColonnade(
        centerX - radius * 0.4,
        platformTop,
        centerZ + radius * 0.7,
        4,
        radius * 0.3,
        COLUMN_RADIUS_MEDIUM,
        COLUMN_HEIGHT_MEDIUM,
        Vector3.new(1, 0, 0),
        folder
    )
end

-- Build Temple (classical temple with pediment)
function LandmarkBuilder:_buildTemple(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder,
    templeName: string?
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local platformTop = self:_createPlatform(centerX, terrainY, centerZ, radius * 1.6, radius * 1.2, folder)

    -- Cella (inner chamber)
    local cella = self:_createPart(
        "Cella",
        Vector3.new(centerX, platformTop + 8, centerZ - radius * 0.2),
        Vector3.new(radius * 0.8, 16, radius * 0.6),
        MARBLE_WHITE
    )
    cella.Parent = folder

    -- Front columns (6-column portico)
    self:_createColonnade(
        centerX - radius * 0.5,
        platformTop,
        centerZ + radius * 0.5,
        6,
        radius * 0.2,
        COLUMN_RADIUS_MEDIUM,
        COLUMN_HEIGHT_LARGE,
        Vector3.new(1, 0, 0),
        folder
    )

    -- Pediment (triangular roof front)
    local pedimentBase = self:_createPart(
        "PedimentBase",
        Vector3.new(centerX, platformTop + COLUMN_HEIGHT_LARGE + 3, centerZ + radius * 0.5),
        Vector3.new(radius * 1.4, 4, 3),
        MARBLE_CREAM
    )
    pedimentBase.Parent = folder

    -- Roof
    local roof = self:_createPart(
        "Roof",
        Vector3.new(centerX, platformTop + COLUMN_HEIGHT_LARGE + 6, centerZ),
        Vector3.new(radius * 1.4, 2, radius * 1.2),
        TERRACOTTA,
        Enum.Material.Brick
    )
    roof.Parent = folder

    -- Add temple name marker if provided
    if templeName then
        local marker = self:_createPart(
            "TempleMarker",
            Vector3.new(centerX, platformTop + COLUMN_HEIGHT_LARGE + 10, centerZ + radius * 0.5),
            Vector3.new(2, 2, 2),
            BRONZE,
            Enum.Material.Metal
        )
        marker.Parent = folder
    end
end

-- Build Circus Maximus (long racing track)
function LandmarkBuilder:_buildCircusMaximus(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local trackLength = radius * 3
    local trackWidth = radius * 0.6

    -- Racing track (sand floor)
    local track = self:_createPart(
        "RaceTrack",
        Vector3.new(centerX, terrainY + 0.5, centerZ),
        Vector3.new(trackLength, 1, trackWidth),
        SAND,
        Enum.Material.Sand
    )
    track.Parent = folder

    -- Spina (central divider)
    local spina = self:_createPart(
        "Spina",
        Vector3.new(centerX, terrainY + 3, centerZ),
        Vector3.new(trackLength * 0.7, 6, 6),
        MARBLE_WHITE
    )
    spina.Parent = folder

    -- Meta (turning posts at each end)
    local metaLeft = self:_createCylinder(
        "MetaLeft",
        Vector3.new(centerX - trackLength * 0.4, terrainY + 6, centerZ),
        3,
        12,
        BRONZE
    )
    metaLeft.Parent = folder

    local metaRight = self:_createCylinder(
        "MetaRight",
        Vector3.new(centerX + trackLength * 0.4, terrainY + 6, centerZ),
        3,
        12,
        BRONZE
    )
    metaRight.Parent = folder

    -- Seating tiers on both sides
    for side = -1, 1, 2 do
        local seatZ = centerZ + side * (trackWidth / 2 + 10)
        local seating = self:_createPart(
            string.format("Seating_%s", side > 0 and "South" or "North"),
            Vector3.new(centerX, terrainY + 6, seatZ),
            Vector3.new(trackLength, 12, 8),
            STONE_GRAY,
            Enum.Material.Brick
        )
        seating.Parent = folder
    end
end

-- Build Castrum (military fortress)
function LandmarkBuilder:_buildCastrum(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local wallHeight = 12
    local wallThickness = 4
    local fortSize = radius * 1.4

    -- Perimeter walls
    local wallPositions = {
        { x = centerX, z = centerZ - fortSize / 2, w = fortSize + wallThickness, d = wallThickness },
        { x = centerX, z = centerZ + fortSize / 2, w = fortSize + wallThickness, d = wallThickness },
        { x = centerX - fortSize / 2, z = centerZ, w = wallThickness, d = fortSize },
        { x = centerX + fortSize / 2, z = centerZ, w = wallThickness, d = fortSize },
    }

    for i, pos in ipairs(wallPositions) do
        local wall = self:_createPart(
            string.format("Wall_%d", i),
            Vector3.new(pos.x, terrainY + wallHeight / 2, pos.z),
            Vector3.new(pos.w, wallHeight, pos.d),
            STONE_GRAY,
            Enum.Material.Brick
        )
        wall.Parent = folder
    end

    -- Corner towers
    local towerPositions = {
        { x = centerX - fortSize / 2, z = centerZ - fortSize / 2 },
        { x = centerX + fortSize / 2, z = centerZ - fortSize / 2 },
        { x = centerX - fortSize / 2, z = centerZ + fortSize / 2 },
        { x = centerX + fortSize / 2, z = centerZ + fortSize / 2 },
    }

    for i, pos in ipairs(towerPositions) do
        local tower = self:_createPart(
            string.format("Tower_%d", i),
            Vector3.new(pos.x, terrainY + wallHeight * 0.75, pos.z),
            Vector3.new(8, wallHeight * 1.5, 8),
            STONE_GRAY,
            Enum.Material.Brick
        )
        tower.Parent = folder
    end

    -- Central command building (Principia)
    local principia = self:_createPart(
        "Principia",
        Vector3.new(centerX, terrainY + 6, centerZ),
        Vector3.new(radius * 0.6, 12, radius * 0.6),
        MARBLE_CREAM,
        Enum.Material.Brick
    )
    principia.Parent = folder
end

-- Build Macellum (marketplace)
function LandmarkBuilder:_buildMacellum(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Central tholos (circular building)
    local tholos = self:_createCylinder(
        "Tholos",
        Vector3.new(centerX, terrainY + 6, centerZ),
        radius * 0.3,
        12,
        MARBLE_WHITE
    )
    tholos.Parent = folder

    -- Surrounding columns in a circle
    local numColumns = 8
    for i = 0, numColumns - 1 do
        local angle = (i / numColumns) * math.pi * 2
        local colX = centerX + math.cos(angle) * radius * 0.6
        local colZ = centerZ + math.sin(angle) * radius * 0.6
        self:_createColumn(colX, terrainY, colZ, COLUMN_RADIUS_SMALL, COLUMN_HEIGHT_SMALL, folder)
    end

    -- Market stalls around perimeter
    local numStalls = 6
    for i = 0, numStalls - 1 do
        local angle = (i / numStalls) * math.pi * 2
        local stallX = centerX + math.cos(angle) * radius * 0.9
        local stallZ = centerZ + math.sin(angle) * radius * 0.9
        local stall = self:_createPart(
            string.format("Stall_%d", i),
            Vector3.new(stallX, terrainY + 3, stallZ),
            Vector3.new(6, 6, 4),
            TERRACOTTA,
            Enum.Material.Brick
        )
        stall.Parent = folder
    end
end

-- Build Horreum (warehouse)
function LandmarkBuilder:_buildHorreum(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Main warehouse building
    local warehouse = self:_createPart(
        "Warehouse",
        Vector3.new(centerX, terrainY + 8, centerZ),
        Vector3.new(radius * 1.5, 16, radius),
        TERRACOTTA,
        Enum.Material.Brick
    )
    warehouse.Parent = folder

    -- Loading dock
    local dock = self:_createPart(
        "LoadingDock",
        Vector3.new(centerX, terrainY + 2, centerZ + radius * 0.6),
        Vector3.new(radius * 1.2, 4, 6),
        STONE_GRAY,
        Enum.Material.Brick
    )
    dock.Parent = folder

    -- Roof
    local roof = self:_createPart(
        "Roof",
        Vector3.new(centerX, terrainY + 17, centerZ),
        Vector3.new(radius * 1.6, 2, radius * 1.1),
        TERRACOTTA,
        Enum.Material.Brick
    )
    roof.Parent = folder
end

-- Build Pharos (lighthouse)
function LandmarkBuilder:_buildPharos(
    centerX: number,
    centerZ: number,
    _radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local towerHeight = 40

    -- Base platform
    local base = self:_createPart(
        "LighthouseBase",
        Vector3.new(centerX, terrainY + 3, centerZ),
        Vector3.new(16, 6, 16),
        STONE_GRAY,
        Enum.Material.Brick
    )
    base.Parent = folder

    -- Main tower (tapered sections)
    local section1 = self:_createPart(
        "TowerSection1",
        Vector3.new(centerX, terrainY + 15, centerZ),
        Vector3.new(12, 18, 12),
        MARBLE_WHITE
    )
    section1.Parent = folder

    local section2 = self:_createPart(
        "TowerSection2",
        Vector3.new(centerX, terrainY + 30, centerZ),
        Vector3.new(8, 12, 8),
        MARBLE_WHITE
    )
    section2.Parent = folder

    local section3 = self:_createPart(
        "TowerSection3",
        Vector3.new(centerX, terrainY + 40, centerZ),
        Vector3.new(6, 8, 6),
        MARBLE_WHITE
    )
    section3.Parent = folder

    -- Fire beacon (top)
    local beacon = self:_createPart(
        "Beacon",
        Vector3.new(centerX, terrainY + towerHeight + 6, centerZ),
        Vector3.new(4, 4, 4),
        BRONZE,
        Enum.Material.Metal
    )
    beacon.Parent = folder
end

-- Build Emporium (trade center)
function LandmarkBuilder:_buildEmporium(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Main building
    local mainBuilding = self:_createPart(
        "MainBuilding",
        Vector3.new(centerX, terrainY + 10, centerZ),
        Vector3.new(radius * 1.6, 20, radius * 1.2),
        TERRACOTTA,
        Enum.Material.Brick
    )
    mainBuilding.Parent = folder

    -- Front colonnade
    self:_createColonnade(
        centerX - radius * 0.6,
        terrainY,
        centerZ + radius * 0.7,
        6,
        radius * 0.25,
        COLUMN_RADIUS_MEDIUM,
        COLUMN_HEIGHT_MEDIUM,
        Vector3.new(1, 0, 0),
        folder
    )

    -- Side portico
    local portico = self:_createPart(
        "Portico",
        Vector3.new(centerX - radius * 0.9, terrainY + 6, centerZ),
        Vector3.new(6, 12, radius),
        MARBLE_CREAM
    )
    portico.Parent = folder
end

-- Build VillaRustica (rural estate)
function LandmarkBuilder:_buildVillaRustica(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Main house
    local house = self:_createPart(
        "MainHouse",
        Vector3.new(centerX, terrainY + 6, centerZ),
        Vector3.new(radius * 1.2, 12, radius),
        TERRACOTTA,
        Enum.Material.Brick
    )
    house.Parent = folder

    -- Peristyle courtyard columns
    local courtSize = radius * 0.5
    local columnPositions = {
        { x = centerX - courtSize, z = centerZ - courtSize },
        { x = centerX + courtSize, z = centerZ - courtSize },
        { x = centerX - courtSize, z = centerZ + courtSize },
        { x = centerX + courtSize, z = centerZ + courtSize },
    }

    for _, pos in ipairs(columnPositions) do
        self:_createColumn(pos.x, terrainY, pos.z, COLUMN_RADIUS_SMALL, COLUMN_HEIGHT_SMALL, folder)
    end

    -- Barn/outbuilding
    local barn = self:_createPart(
        "Barn",
        Vector3.new(centerX + radius, terrainY + 4, centerZ),
        Vector3.new(radius * 0.6, 8, radius * 0.8),
        TERRACOTTA,
        Enum.Material.Brick
    )
    barn.Parent = folder
end

-- Build PalaestraMinor (training ground)
function LandmarkBuilder:_buildPalaestraMinor(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Training area (sand)
    local arena = self:_createPart(
        "TrainingArena",
        Vector3.new(centerX, terrainY + 0.5, centerZ),
        Vector3.new(radius * 1.4, 1, radius * 1.2),
        SAND,
        Enum.Material.Sand
    )
    arena.Parent = folder

    -- Surrounding colonnade
    local numColumns = 8
    for i = 0, numColumns - 1 do
        local angle = (i / numColumns) * math.pi * 2
        local colX = centerX + math.cos(angle) * radius * 0.8
        local colZ = centerZ + math.sin(angle) * radius * 0.8
        self:_createColumn(colX, terrainY, colZ, COLUMN_RADIUS_SMALL, COLUMN_HEIGHT_SMALL, folder)
    end
end

-- Build Granarium (grain storage)
function LandmarkBuilder:_buildGranarium(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Elevated storage building
    local base = self:_createPart(
        "GranariumBase",
        Vector3.new(centerX, terrainY + 3, centerZ),
        Vector3.new(radius * 1.2, 6, radius),
        STONE_GRAY,
        Enum.Material.Brick
    )
    base.Parent = folder

    local storage = self:_createPart(
        "GranariumStorage",
        Vector3.new(centerX, terrainY + 10, centerZ),
        Vector3.new(radius, 8, radius * 0.8),
        TERRACOTTA,
        Enum.Material.Brick
    )
    storage.Parent = folder

    -- Roof
    local roof = self:_createPart(
        "Roof",
        Vector3.new(centerX, terrainY + 15, centerZ),
        Vector3.new(radius * 1.1, 2, radius * 0.9),
        TERRACOTTA,
        Enum.Material.Brick
    )
    roof.Parent = folder
end

-- Build small shrine (SacellumCeres, TempleMars, TempleNeptune)
function LandmarkBuilder:_buildSacellum(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local platformTop = self:_createPlatform(centerX, terrainY, centerZ, radius * 1.2, radius, folder)

    -- Small cella
    local cella = self:_createPart(
        "Cella",
        Vector3.new(centerX, platformTop + 5, centerZ - radius * 0.1),
        Vector3.new(radius * 0.6, 10, radius * 0.5),
        MARBLE_WHITE
    )
    cella.Parent = folder

    -- Front columns (4)
    self:_createColonnade(
        centerX - radius * 0.3,
        platformTop,
        centerZ + radius * 0.4,
        4,
        radius * 0.2,
        COLUMN_RADIUS_SMALL,
        COLUMN_HEIGHT_SMALL,
        Vector3.new(1, 0, 0),
        folder
    )
end

-- Build ForumPiscarium (fish market)
function LandmarkBuilder:_buildForumPiscarium(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Open market area
    local floor = self:_createPart(
        "MarketFloor",
        Vector3.new(centerX, terrainY + 0.5, centerZ),
        Vector3.new(radius * 1.4, 1, radius),
        STONE_GRAY,
        Enum.Material.Slate
    )
    floor.Parent = folder

    -- Covered stalls
    for i = -1, 1 do
        local stall = self:_createPart(
            string.format("FishStall_%d", i + 2),
            Vector3.new(centerX + i * radius * 0.5, terrainY + 4, centerZ),
            Vector3.new(radius * 0.4, 8, radius * 0.6),
            TERRACOTTA,
            Enum.Material.Brick
        )
        stall.Parent = folder
    end

    -- Central fountain
    local fountain = self:_createCylinder(
        "Fountain",
        Vector3.new(centerX, terrainY + 3, centerZ + radius * 0.4),
        4,
        6,
        MARBLE_WHITE
    )
    fountain.Parent = folder
end

-- Build ThermaeMinor (small baths)
function LandmarkBuilder:_buildThermaeMinor(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Main building (smaller than Thermae)
    local building = self:_createPart(
        "BathHouse",
        Vector3.new(centerX, terrainY + 6, centerZ),
        Vector3.new(radius * 1.0, 12, radius * 0.8),
        TERRACOTTA,
        Enum.Material.Brick
    )
    building.Parent = folder

    -- Front portico
    self:_createColonnade(
        centerX - radius * 0.3,
        terrainY,
        centerZ + radius * 0.5,
        3,
        radius * 0.3,
        COLUMN_RADIUS_SMALL,
        COLUMN_HEIGHT_SMALL,
        Vector3.new(1, 0, 0),
        folder
    )
end

-- Map landmark types to builder functions
function LandmarkBuilder:_buildLandmarkByType(
    landmarkType: string,
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): boolean
    if landmarkType == "Forum" then
        self:_buildForum(centerX, centerZ, radius, folder)
    elseif landmarkType == "Colosseum" then
        self:_buildColosseum(centerX, centerZ, radius, folder)
    elseif landmarkType == "Thermae" then
        self:_buildThermae(centerX, centerZ, radius, folder)
    elseif landmarkType == "Temple" then
        self:_buildTemple(centerX, centerZ, radius, folder, nil)
    elseif landmarkType == "CircusMaximus" then
        self:_buildCircusMaximus(centerX, centerZ, radius, folder)
    elseif landmarkType == "Castrum" then
        self:_buildCastrum(centerX, centerZ, radius, folder)
    elseif landmarkType == "Macellum" then
        self:_buildMacellum(centerX, centerZ, radius, folder)
    elseif landmarkType == "Horreum" then
        self:_buildHorreum(centerX, centerZ, radius, folder)
    elseif landmarkType == "Pharos" then
        self:_buildPharos(centerX, centerZ, radius, folder)
    elseif landmarkType == "Emporium" then
        self:_buildEmporium(centerX, centerZ, radius, folder)
    elseif landmarkType == "VillaRustica" then
        self:_buildVillaRustica(centerX, centerZ, radius, folder)
    elseif landmarkType == "PalaestraMinor" then
        self:_buildPalaestraMinor(centerX, centerZ, radius, folder)
    elseif landmarkType == "Granarium" then
        self:_buildGranarium(centerX, centerZ, radius, folder)
    elseif landmarkType == "ThermaeMinor" then
        self:_buildThermaeMinor(centerX, centerZ, radius, folder)
    elseif landmarkType == "ForumPiscarium" then
        self:_buildForumPiscarium(centerX, centerZ, radius, folder)
    elseif landmarkType == "TempleMars" or landmarkType == "TempleNeptune" or landmarkType == "SacellumCeres" then
        self:_buildSacellum(centerX, centerZ, radius, folder)
    else
        -- Unknown landmark type - create simple column marker
        print(string.format("[LandmarkBuilder v%s] Unknown landmark type: %s, creating marker",
            LandmarkBuilder.VERSION, landmarkType))
        local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
        self:_createColumn(centerX, terrainY, centerZ, COLUMN_RADIUS_LARGE, COLUMN_HEIGHT_LARGE, folder)
    end

    return true
end

-- Build all landmarks from WorldPlan
function LandmarkBuilder:build(): Folder
    local startTime = tick()

    print(string.format("[LandmarkBuilder v%s] Building landmarks from WorldPlan...",
        LandmarkBuilder.VERSION
    ))

    -- Create main folder for all landmarks
    local folder = Instance.new("Folder")
    folder.Name = "Landmarks_Monumenta"
    folder.Parent = workspace
    self.folder = folder

    -- Get all landmarks from WorldPlan
    local landmarks = self.worldPlan:getLandmarks()

    -- Build each landmark
    local skippedCount = 0
    for i, landmark in ipairs(landmarks) do
        local x = landmark.position.X
        local z = landmark.position.Y -- Vector2 Y is world Z

        -- Validate: skip landmarks in river exclusion zone
        if self.worldPlan:isInRiverExclusionZone(x, z) then
            warn(string.format("[LandmarkBuilder v%s] Skipping %s at (%.1f, %.1f) - in river exclusion zone",
                LandmarkBuilder.VERSION,
                landmark.landmarkType,
                x,
                z
            ))
            skippedCount = skippedCount + 1
            continue
        end

        local landmarkFolder = Instance.new("Folder")
        landmarkFolder.Name = string.format("%s_%d", landmark.landmarkType, i)
        landmarkFolder.Parent = folder

        self:_buildLandmarkByType(
            landmark.landmarkType,
            x,
            z,
            landmark.radius,
            landmarkFolder
        )

        self.landmarkCount = self.landmarkCount + 1

        print(string.format("[LandmarkBuilder v%s] Built %s at (%.1f, %.1f)",
            LandmarkBuilder.VERSION,
            landmark.landmarkType,
            x,
            z
        ))

        -- Yield periodically to avoid script timeout
        if i % 3 == 0 then
            task.wait()
        end
    end

    local elapsed = tick() - startTime
    print(string.format("[LandmarkBuilder v%s] Built %d landmarks in %.2f seconds (%d parts, %d skipped for river)",
        LandmarkBuilder.VERSION,
        self.landmarkCount,
        elapsed,
        #self.parts,
        skippedCount
    ))

    return folder
end

-- Get the number of landmarks built
function LandmarkBuilder:getLandmarkCount(): number
    return self.landmarkCount
end

-- Get all parts created
function LandmarkBuilder:getParts(): { BasePart }
    return self.parts
end

-- Destroy all landmarks
function LandmarkBuilder:destroy(): ()
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end

    self.parts = {}
    self.landmarkCount = 0

    print(string.format("[LandmarkBuilder v%s] All landmarks destroyed", LandmarkBuilder.VERSION))
end

return LandmarkBuilder
