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
LandmarkBuilder.VERSION = "1.3.0"

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

-- Helper: Create a wall with a centered doorway (returns 2 wall segments)
function LandmarkBuilder:_createWallWithDoorway(
    wallCenterX: number,
    wallBaseY: number,
    wallCenterZ: number,
    wallWidth: number,
    wallHeight: number,
    wallThickness: number,
    doorwayWidth: number,
    doorwayHeight: number,
    isZAligned: boolean, -- true = wall runs along Z axis, false = along X axis
    color: Color3,
    material: Enum.Material,
    folder: Folder
): ()
    local segmentWidth = (wallWidth - doorwayWidth) / 2

    if isZAligned then
        -- Wall runs along Z axis (east-west facing)
        -- Left segment
        local leftX = wallCenterX
        local leftZ = wallCenterZ - wallWidth / 4 - doorwayWidth / 4
        local left = self:_createPart(
            "Wall_Left",
            Vector3.new(leftX, wallBaseY + wallHeight / 2, leftZ),
            Vector3.new(wallThickness, wallHeight, segmentWidth),
            color,
            material
        )
        left.Parent = folder

        -- Right segment
        local rightZ = wallCenterZ + wallWidth / 4 + doorwayWidth / 4
        local right = self:_createPart(
            "Wall_Right",
            Vector3.new(wallCenterX, wallBaseY + wallHeight / 2, rightZ),
            Vector3.new(wallThickness, wallHeight, segmentWidth),
            color,
            material
        )
        right.Parent = folder

        -- Lintel above doorway
        local lintelHeight = wallHeight - doorwayHeight
        if lintelHeight > 0 then
            local lintel = self:_createPart(
                "Wall_Lintel",
                Vector3.new(wallCenterX, wallBaseY + doorwayHeight + lintelHeight / 2, wallCenterZ),
                Vector3.new(wallThickness, lintelHeight, doorwayWidth),
                color,
                material
            )
            lintel.Parent = folder
        end
    else
        -- Wall runs along X axis (north-south facing)
        -- Left segment
        local leftX = wallCenterX - wallWidth / 4 - doorwayWidth / 4
        local left = self:_createPart(
            "Wall_Left",
            Vector3.new(leftX, wallBaseY + wallHeight / 2, wallCenterZ),
            Vector3.new(segmentWidth, wallHeight, wallThickness),
            color,
            material
        )
        left.Parent = folder

        -- Right segment
        local rightX = wallCenterX + wallWidth / 4 + doorwayWidth / 4
        local right = self:_createPart(
            "Wall_Right",
            Vector3.new(rightX, wallBaseY + wallHeight / 2, wallCenterZ),
            Vector3.new(segmentWidth, wallHeight, wallThickness),
            color,
            material
        )
        right.Parent = folder

        -- Lintel above doorway
        local lintelHeight = wallHeight - doorwayHeight
        if lintelHeight > 0 then
            local lintel = self:_createPart(
                "Wall_Lintel",
                Vector3.new(wallCenterX, wallBaseY + doorwayHeight + lintelHeight / 2, wallCenterZ),
                Vector3.new(doorwayWidth, lintelHeight, wallThickness),
                color,
                material
            )
            lintel.Parent = folder
        end
    end
end

-- Helper: Create a solid wall (no doorway)
function LandmarkBuilder:_createSolidWall(
    wallCenterX: number,
    wallBaseY: number,
    wallCenterZ: number,
    wallWidth: number,
    wallHeight: number,
    wallThickness: number,
    isZAligned: boolean, -- true = wall runs along Z axis, false = along X axis
    color: Color3,
    material: Enum.Material,
    folder: Folder
): ()
    local sizeX, sizeZ
    if isZAligned then
        sizeX = wallThickness
        sizeZ = wallWidth
    else
        sizeX = wallWidth
        sizeZ = wallThickness
    end

    local wall = self:_createPart(
        "Wall_Solid",
        Vector3.new(wallCenterX, wallBaseY + wallHeight / 2, wallCenterZ),
        Vector3.new(sizeX, wallHeight, sizeZ),
        color,
        material
    )
    wall.Parent = folder
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

-- Build Thermae (bath complex) - walkable hollow interior
function LandmarkBuilder:_buildThermae(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local platformTop = self:_createPlatform(centerX, terrainY, centerZ, radius * 1.4, radius * 1.2, folder)

    -- Building dimensions
    local buildingWidth = radius * 1.2
    local buildingDepth = radius
    local wallHeight = 16
    local wallThickness = 2
    local doorwayWidth = 6
    local doorwayHeight = 10

    -- Interior floor
    local floor = self:_createPart(
        "InteriorFloor",
        Vector3.new(centerX, platformTop + 0.5, centerZ),
        Vector3.new(buildingWidth - wallThickness * 2, 1, buildingDepth - wallThickness * 2),
        MARBLE_CREAM,
        Enum.Material.Marble
    )
    floor.Parent = folder

    -- North wall (back) with doorway
    self:_createWallWithDoorway(
        centerX, platformTop, centerZ - buildingDepth / 2 + wallThickness / 2,
        buildingWidth, wallHeight, wallThickness, doorwayWidth, doorwayHeight,
        false, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- South wall (front) with doorway
    self:_createWallWithDoorway(
        centerX, platformTop, centerZ + buildingDepth / 2 - wallThickness / 2,
        buildingWidth, wallHeight, wallThickness, doorwayWidth, doorwayHeight,
        false, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- East wall (solid)
    self:_createSolidWall(
        centerX + buildingWidth / 2 - wallThickness / 2, platformTop, centerZ,
        buildingDepth - wallThickness * 2, wallHeight, wallThickness,
        true, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- West wall (solid)
    self:_createSolidWall(
        centerX - buildingWidth / 2 + wallThickness / 2, platformTop, centerZ,
        buildingDepth - wallThickness * 2, wallHeight, wallThickness,
        true, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- Roof
    local roof = self:_createPart(
        "Roof",
        Vector3.new(centerX, platformTop + wallHeight + 1, centerZ),
        Vector3.new(buildingWidth, 2, buildingDepth),
        TERRACOTTA,
        Enum.Material.Brick
    )
    roof.Parent = folder

    -- Domed roof section
    local dome = self:_createPart(
        "Dome",
        Vector3.new(centerX, platformTop + wallHeight + 5, centerZ),
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

-- Build Temple (classical temple with pediment) - walkable cella interior
function LandmarkBuilder:_buildTemple(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder,
    templeName: string?
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local platformTop = self:_createPlatform(centerX, terrainY, centerZ, radius * 1.6, radius * 1.2, folder)

    -- Cella (inner chamber) dimensions - hollow with walls
    local cellaWidth = radius * 0.8
    local cellaDepth = radius * 0.6
    local cellaCenterZ = centerZ - radius * 0.2
    local cellaHeight = 16
    local wallThickness = 2
    local doorwayWidth = 5
    local doorwayHeight = 10

    -- Cella interior floor
    local cellaFloor = self:_createPart(
        "CellaFloor",
        Vector3.new(centerX, platformTop + 0.5, cellaCenterZ),
        Vector3.new(cellaWidth - wallThickness * 2, 1, cellaDepth - wallThickness * 2),
        MARBLE_WHITE,
        Enum.Material.Marble
    )
    cellaFloor.Parent = folder

    -- Cella front wall (south, facing columns) with doorway
    self:_createWallWithDoorway(
        centerX, platformTop, cellaCenterZ + cellaDepth / 2 - wallThickness / 2,
        cellaWidth, cellaHeight, wallThickness, doorwayWidth, doorwayHeight,
        false, MARBLE_WHITE, Enum.Material.Marble, folder
    )

    -- Cella back wall (north, solid)
    self:_createSolidWall(
        centerX, platformTop, cellaCenterZ - cellaDepth / 2 + wallThickness / 2,
        cellaWidth, cellaHeight, wallThickness,
        false, MARBLE_WHITE, Enum.Material.Marble, folder
    )

    -- Cella east wall (solid)
    self:_createSolidWall(
        centerX + cellaWidth / 2 - wallThickness / 2, platformTop, cellaCenterZ,
        cellaDepth - wallThickness * 2, cellaHeight, wallThickness,
        true, MARBLE_WHITE, Enum.Material.Marble, folder
    )

    -- Cella west wall (solid)
    self:_createSolidWall(
        centerX - cellaWidth / 2 + wallThickness / 2, platformTop, cellaCenterZ,
        cellaDepth - wallThickness * 2, cellaHeight, wallThickness,
        true, MARBLE_WHITE, Enum.Material.Marble, folder
    )

    -- Cella roof
    local cellaRoof = self:_createPart(
        "CellaRoof",
        Vector3.new(centerX, platformTop + cellaHeight + 1, cellaCenterZ),
        Vector3.new(cellaWidth, 2, cellaDepth),
        MARBLE_CREAM,
        Enum.Material.Marble
    )
    cellaRoof.Parent = folder

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

-- Build Circus Maximus (grand chariot racing stadium)
-- The largest structure in Rome, seats 250,000 spectators
function LandmarkBuilder:_buildCircusMaximus(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Scale dimensions based on radius but ensure impressive size
    -- Target: ~200 studs long, ~60 studs wide
    local trackLength = math.max(radius * 3, 200)
    local trackWidth = math.max(radius * 0.9, 60)
    local _innerTrackWidth = trackWidth - 12 -- Width inside the spina

    -- ============================================
    -- 1. RACING TRACK (elongated oval, sandy surface)
    -- ============================================
    local track = self:_createPart(
        "RaceTrack",
        Vector3.new(centerX, terrainY + 0.5, centerZ),
        Vector3.new(trackLength, 1, trackWidth),
        SAND,
        Enum.Material.Sand
    )
    track.Parent = folder

    -- Rounded ends (semicircular sections using wedge-like parts)
    -- West end (turning end)
    local westEndRadius = trackWidth / 2
    local westEnd = self:_createPart(
        "WestEnd",
        Vector3.new(centerX - trackLength / 2 - westEndRadius / 2 + 2, terrainY + 0.5, centerZ),
        Vector3.new(westEndRadius, 1, trackWidth),
        SAND,
        Enum.Material.Sand
    )
    westEnd.Parent = folder

    -- East end (near starting gates)
    local eastEnd = self:_createPart(
        "EastEnd",
        Vector3.new(centerX + trackLength / 2 + westEndRadius / 2 - 2, terrainY + 0.5, centerZ),
        Vector3.new(westEndRadius, 1, trackWidth),
        SAND,
        Enum.Material.Sand
    )
    eastEnd.Parent = folder

    -- ============================================
    -- 2. SPINA (Central Barrier)
    -- ============================================
    local spinaLength = trackLength * 0.65
    local spinaWidth = 8
    local spinaHeight = 4

    -- Main spina platform
    local spina = self:_createPart(
        "Spina",
        Vector3.new(centerX, terrainY + spinaHeight / 2 + 1, centerZ),
        Vector3.new(spinaLength, spinaHeight, spinaWidth),
        MARBLE_CREAM,
        Enum.Material.Concrete
    )
    spina.Parent = folder

    -- Central obelisk (tall narrow part)
    local obeliskHeight = 30
    local obeliskBase = 4
    local obelisk = self:_createPart(
        "Obelisk",
        Vector3.new(centerX, terrainY + spinaHeight + obeliskHeight / 2 + 1, centerZ),
        Vector3.new(obeliskBase, obeliskHeight, obeliskBase),
        STONE_GRAY,
        Enum.Material.Slate
    )
    obelisk.Parent = folder

    -- Obelisk cap (pyramid-like top)
    local obeliskCap = self:_createPart(
        "ObeliskCap",
        Vector3.new(centerX, terrainY + spinaHeight + obeliskHeight + 3, centerZ),
        Vector3.new(2, 4, 2),
        BRONZE,
        Enum.Material.Metal
    )
    obeliskCap.Parent = folder

    -- Lap counters (7 dolphin/egg markers - simplified as bronze parts)
    local lapCounterSpacing = spinaLength / 8
    for i = 1, 7 do
        local counterX = centerX - spinaLength / 2 + lapCounterSpacing * i
        local counter = self:_createPart(
            string.format("LapCounter_%d", i),
            Vector3.new(counterX, terrainY + spinaHeight + 4, centerZ + spinaWidth / 2 - 1),
            Vector3.new(2, 3, 1),
            BRONZE,
            Enum.Material.Metal
        )
        counter.Parent = folder
    end

    -- Decorative fountains on spina (smaller basins)
    local fountainPositions = { -spinaLength * 0.3, spinaLength * 0.3 }
    for idx, offsetX in ipairs(fountainPositions) do
        local fountain = self:_createCylinder(
            string.format("SpinaFountain_%d", idx),
            Vector3.new(centerX + offsetX, terrainY + spinaHeight + 3, centerZ),
            3,
            4,
            MARBLE_WHITE
        )
        fountain.Parent = folder
    end

    -- ============================================
    -- 3. METAE (Turning Posts at each end of spina)
    -- ============================================
    local metaHeight = 15
    local metaRadius = 3

    -- West meta (3 conical posts)
    for j = -1, 1 do
        local metaWest = self:_createCylinder(
            string.format("MetaWest_%d", j + 2),
            Vector3.new(centerX - spinaLength / 2 - 4, terrainY + metaHeight / 2 + 1, centerZ + j * 4),
            metaRadius,
            metaHeight,
            BRONZE
        )
        metaWest.Parent = folder
    end

    -- East meta (3 conical posts)
    for j = -1, 1 do
        local metaEast = self:_createCylinder(
            string.format("MetaEast_%d", j + 2),
            Vector3.new(centerX + spinaLength / 2 + 4, terrainY + metaHeight / 2 + 1, centerZ + j * 4),
            metaRadius,
            metaHeight,
            BRONZE
        )
        metaEast.Parent = folder
    end

    -- ============================================
    -- 4. TIERED SEATING (Cavea) on both long sides
    -- ============================================
    local numTiers = 3
    local tierHeights = { 8, 16, 24 }
    local tierDepths = { 10, 10, 10 }

    for side = -1, 1, 2 do
        local sideName = side > 0 and "South" or "North"
        local baseZ = centerZ + side * (trackWidth / 2 + 5)

        for tier = 1, numTiers do
            local tierY = terrainY + tierHeights[tier] / 2
            local tierZ = baseZ + side * (tier - 1) * tierDepths[tier]

            local seating = self:_createPart(
                string.format("Seating_%s_Tier%d", sideName, tier),
                Vector3.new(centerX, tierY, tierZ),
                Vector3.new(trackLength + 20, tierHeights[tier], tierDepths[tier]),
                STONE_GRAY,
                Enum.Material.Concrete
            )
            seating.Parent = folder
        end

        -- Top colonnade along the seating (decorative)
        local colonnadeZ = baseZ + side * (numTiers * 10 - 5)
        local numColumns = math.floor(trackLength / 20)
        self:_createColonnade(
            centerX - (numColumns - 1) * 10,
            terrainY + tierHeights[numTiers],
            colonnadeZ,
            numColumns,
            20,
            COLUMN_RADIUS_SMALL,
            COLUMN_HEIGHT_SMALL,
            Vector3.new(1, 0, 0),
            folder
        )
    end

    -- Curved seating at west end (turning end)
    local curvedSeatZ = centerZ
    local curvedSeatX = centerX - trackLength / 2 - 15
    local curvedSeating = self:_createPart(
        "Seating_West_Curved",
        Vector3.new(curvedSeatX, terrainY + 12, curvedSeatZ),
        Vector3.new(20, 24, trackWidth + 40),
        STONE_GRAY,
        Enum.Material.Concrete
    )
    curvedSeating.Parent = folder

    -- ============================================
    -- 5. CARCERES (Starting Gates) at east end
    -- ============================================
    local carceresWidth = trackWidth + 20
    local carceresDepth = 12
    local carceresHeight = 16
    local carceresX = centerX + trackLength / 2 + 20

    -- Main gate structure (back wall with arches)
    local gateBack = self:_createPart(
        "Carceres_Back",
        Vector3.new(carceresX + carceresDepth / 2, terrainY + carceresHeight / 2, centerZ),
        Vector3.new(4, carceresHeight, carceresWidth),
        MARBLE_CREAM,
        Enum.Material.Concrete
    )
    gateBack.Parent = folder

    -- Individual starting gates (12 gates for 12 chariots)
    local numGates = 12
    local gateSpacing = carceresWidth / (numGates + 1)
    local gateWidth = gateSpacing - 2
    local gateHeight = 10

    for gateIdx = 1, numGates do
        local gateZ = centerZ - carceresWidth / 2 + gateSpacing * gateIdx

        -- Gate pillars (sides of each starting box)
        local pillarLeft = self:_createPart(
            string.format("Gate_%d_PillarLeft", gateIdx),
            Vector3.new(carceresX, terrainY + carceresHeight / 2, gateZ - gateWidth / 2),
            Vector3.new(carceresDepth, carceresHeight, 2),
            MARBLE_WHITE,
            Enum.Material.Marble
        )
        pillarLeft.Parent = folder

        -- Gate arch (lintel above opening)
        local arch = self:_createPart(
            string.format("Gate_%d_Arch", gateIdx),
            Vector3.new(carceresX, terrainY + gateHeight + (carceresHeight - gateHeight) / 2, gateZ),
            Vector3.new(carceresDepth, carceresHeight - gateHeight, gateWidth - 2),
            MARBLE_CREAM,
            Enum.Material.Concrete
        )
        arch.Parent = folder
    end

    -- Carceres towers at corners
    local towerHeight = 24
    local towerWidth = 8
    for side = -1, 1, 2 do
        local tower = self:_createPart(
            string.format("Carceres_Tower_%s", side > 0 and "South" or "North"),
            Vector3.new(carceresX + carceresDepth / 2, terrainY + towerHeight / 2, centerZ + side * (carceresWidth / 2 + towerWidth / 2)),
            Vector3.new(towerWidth, towerHeight, towerWidth),
            STONE_GRAY,
            Enum.Material.Brick
        )
        tower.Parent = folder
    end

    -- ============================================
    -- 6. IMPERIAL BOX (Pulvinar) - special seating
    -- ============================================
    local pulvinarX = centerX + trackLength / 4
    local pulvinarZ = centerZ - trackWidth / 2 - 25
    local pulvinarWidth = 30
    local pulvinarDepth = 15
    local pulvinarHeight = 20

    -- Elevated platform for emperor
    local pulvinarBase = self:_createPart(
        "Pulvinar_Base",
        Vector3.new(pulvinarX, terrainY + pulvinarHeight / 2, pulvinarZ),
        Vector3.new(pulvinarWidth, pulvinarHeight, pulvinarDepth),
        MARBLE_WHITE,
        Enum.Material.Marble
    )
    pulvinarBase.Parent = folder

    -- Pulvinar columns
    self:_createColonnade(
        pulvinarX - pulvinarWidth / 2 + 4,
        terrainY + pulvinarHeight,
        pulvinarZ + pulvinarDepth / 2 - 2,
        4,
        8,
        COLUMN_RADIUS_MEDIUM,
        COLUMN_HEIGHT_MEDIUM,
        Vector3.new(1, 0, 0),
        folder
    )

    -- Pulvinar roof/canopy
    local pulvinarRoof = self:_createPart(
        "Pulvinar_Roof",
        Vector3.new(pulvinarX, terrainY + pulvinarHeight + COLUMN_HEIGHT_MEDIUM + 2, pulvinarZ),
        Vector3.new(pulvinarWidth + 4, 3, pulvinarDepth + 4),
        TERRACOTTA,
        Enum.Material.Brick
    )
    pulvinarRoof.Parent = folder
end

-- Build Castrum (military fortress) - Principia has walkable interior
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

    -- Central command building (Principia) - hollow with doorways
    local principiaWidth = radius * 0.6
    local principiaDepth = radius * 0.6
    local principiaHeight = 12
    local principiaWallThickness = 2
    local doorwayWidth = 5
    local doorwayHeight = 8

    -- Principia interior floor
    local principiaFloor = self:_createPart(
        "PrincipiaFloor",
        Vector3.new(centerX, terrainY + 0.5, centerZ),
        Vector3.new(principiaWidth - principiaWallThickness * 2, 1, principiaDepth - principiaWallThickness * 2),
        MARBLE_CREAM,
        Enum.Material.Marble
    )
    principiaFloor.Parent = folder

    -- Principia north wall with doorway (back entrance)
    self:_createWallWithDoorway(
        centerX, terrainY, centerZ - principiaDepth / 2 + principiaWallThickness / 2,
        principiaWidth, principiaHeight, principiaWallThickness, doorwayWidth, doorwayHeight,
        false, MARBLE_CREAM, Enum.Material.Brick, folder
    )

    -- Principia south wall with doorway (front entrance)
    self:_createWallWithDoorway(
        centerX, terrainY, centerZ + principiaDepth / 2 - principiaWallThickness / 2,
        principiaWidth, principiaHeight, principiaWallThickness, doorwayWidth, doorwayHeight,
        false, MARBLE_CREAM, Enum.Material.Brick, folder
    )

    -- Principia east wall (solid)
    self:_createSolidWall(
        centerX + principiaWidth / 2 - principiaWallThickness / 2, terrainY, centerZ,
        principiaDepth - principiaWallThickness * 2, principiaHeight, principiaWallThickness,
        true, MARBLE_CREAM, Enum.Material.Brick, folder
    )

    -- Principia west wall (solid)
    self:_createSolidWall(
        centerX - principiaWidth / 2 + principiaWallThickness / 2, terrainY, centerZ,
        principiaDepth - principiaWallThickness * 2, principiaHeight, principiaWallThickness,
        true, MARBLE_CREAM, Enum.Material.Brick, folder
    )

    -- Principia roof
    local principiaRoof = self:_createPart(
        "PrincipiaRoof",
        Vector3.new(centerX, terrainY + principiaHeight + 1, centerZ),
        Vector3.new(principiaWidth, 2, principiaDepth),
        TERRACOTTA,
        Enum.Material.Brick
    )
    principiaRoof.Parent = folder
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

-- Build Horreum (warehouse) - large hollow interior with cargo doorways
function LandmarkBuilder:_buildHorreum(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Warehouse dimensions
    local buildingWidth = radius * 1.5
    local buildingDepth = radius
    local wallHeight = 16
    local wallThickness = 2
    local cargoDoorwayWidth = 8 -- Large cargo doors
    local cargoDoorwayHeight = 12

    -- Interior floor
    local floor = self:_createPart(
        "InteriorFloor",
        Vector3.new(centerX, terrainY + 0.5, centerZ),
        Vector3.new(buildingWidth - wallThickness * 2, 1, buildingDepth - wallThickness * 2),
        STONE_GRAY,
        Enum.Material.Slate
    )
    floor.Parent = folder

    -- North wall (solid, back)
    self:_createSolidWall(
        centerX, terrainY, centerZ - buildingDepth / 2 + wallThickness / 2,
        buildingWidth, wallHeight, wallThickness,
        false, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- South wall (front) with large cargo doorway
    self:_createWallWithDoorway(
        centerX, terrainY, centerZ + buildingDepth / 2 - wallThickness / 2,
        buildingWidth, wallHeight, wallThickness, cargoDoorwayWidth, cargoDoorwayHeight,
        false, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- East wall with cargo doorway (side entrance)
    self:_createWallWithDoorway(
        centerX + buildingWidth / 2 - wallThickness / 2, terrainY, centerZ,
        buildingDepth - wallThickness * 2, wallHeight, wallThickness, cargoDoorwayWidth, cargoDoorwayHeight,
        true, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- West wall (solid)
    self:_createSolidWall(
        centerX - buildingWidth / 2 + wallThickness / 2, terrainY, centerZ,
        buildingDepth - wallThickness * 2, wallHeight, wallThickness,
        true, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- Roof
    local roof = self:_createPart(
        "Roof",
        Vector3.new(centerX, terrainY + wallHeight + 1, centerZ),
        Vector3.new(buildingWidth + 2, 2, buildingDepth + 2),
        TERRACOTTA,
        Enum.Material.Brick
    )
    roof.Parent = folder

    -- Loading dock (outside, in front of main entrance)
    local dock = self:_createPart(
        "LoadingDock",
        Vector3.new(centerX, terrainY + 2, centerZ + buildingDepth / 2 + 4),
        Vector3.new(radius * 1.2, 4, 6),
        STONE_GRAY,
        Enum.Material.Brick
    )
    dock.Parent = folder
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

-- Build VillaRustica (rural estate) - MainHouse has walkable interior
function LandmarkBuilder:_buildVillaRustica(
    centerX: number,
    centerZ: number,
    radius: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Main house dimensions
    local houseWidth = radius * 1.2
    local houseDepth = radius
    local wallHeight = 12
    local wallThickness = 2
    local doorwayWidth = 5
    local doorwayHeight = 8

    -- Interior floor
    local floor = self:_createPart(
        "InteriorFloor",
        Vector3.new(centerX, terrainY + 0.5, centerZ),
        Vector3.new(houseWidth - wallThickness * 2, 1, houseDepth - wallThickness * 2),
        TERRACOTTA,
        Enum.Material.Brick
    )
    floor.Parent = folder

    -- North wall (back) with doorway
    self:_createWallWithDoorway(
        centerX, terrainY, centerZ - houseDepth / 2 + wallThickness / 2,
        houseWidth, wallHeight, wallThickness, doorwayWidth, doorwayHeight,
        false, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- South wall (front) with doorway
    self:_createWallWithDoorway(
        centerX, terrainY, centerZ + houseDepth / 2 - wallThickness / 2,
        houseWidth, wallHeight, wallThickness, doorwayWidth, doorwayHeight,
        false, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- East wall (solid)
    self:_createSolidWall(
        centerX + houseWidth / 2 - wallThickness / 2, terrainY, centerZ,
        houseDepth - wallThickness * 2, wallHeight, wallThickness,
        true, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- West wall (solid)
    self:_createSolidWall(
        centerX - houseWidth / 2 + wallThickness / 2, terrainY, centerZ,
        houseDepth - wallThickness * 2, wallHeight, wallThickness,
        true, TERRACOTTA, Enum.Material.Brick, folder
    )

    -- Roof
    local roof = self:_createPart(
        "Roof",
        Vector3.new(centerX, terrainY + wallHeight + 1, centerZ),
        Vector3.new(houseWidth + 2, 2, houseDepth + 2),
        TERRACOTTA,
        Enum.Material.Brick
    )
    roof.Parent = folder

    -- Peristyle courtyard columns (in front of house)
    local courtSize = radius * 0.5
    local columnPositions = {
        { x = centerX - courtSize, z = centerZ + houseDepth / 2 + 4 },
        { x = centerX + courtSize, z = centerZ + houseDepth / 2 + 4 },
        { x = centerX - courtSize, z = centerZ + houseDepth / 2 + 4 + courtSize },
        { x = centerX + courtSize, z = centerZ + houseDepth / 2 + 4 + courtSize },
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
