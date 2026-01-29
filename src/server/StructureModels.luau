--!strict
--[[
    StructureModels - Creates Roman-looking structure models for player buildings

    Provides functions to build each structure type with walls, roofs, and doorways:
    - Domus: Roman house with walls, doorway, roof
    - Taberna: Shop with open front, counter, roof
    - Temple: Small temple with columns, steps, roof
    - Wall: Simple defensive wall segment

    Uses similar techniques to LandmarkBuilder for consistent Roman aesthetic.
]]

local StructureModels = {}
StructureModels.__index = StructureModels
StructureModels.VERSION = "1.2.0"

-- Roman architectural colors (consistent with LandmarkBuilder)
local MARBLE_WHITE = Color3.fromRGB(240, 235, 225)
local MARBLE_CREAM = Color3.fromRGB(230, 220, 200)
local TERRACOTTA = Color3.fromRGB(180, 100, 70)
local STONE_GRAY = Color3.fromRGB(160, 155, 145)
local SAND_BEIGE = Color3.fromRGB(194, 178, 128)
local WOOD_BROWN = Color3.fromRGB(139, 90, 43)
local POOL_BLUE = Color3.fromRGB(100, 150, 200)

-- Wall and doorway defaults
local WALL_THICKNESS = 1.5
local DOORWAY_WIDTH = 4
local DOORWAY_HEIGHT = 6

-- Column dimensions for temples
local COLUMN_RADIUS = 1
local COLUMN_HEIGHT = 10

--[[
    Helper: Create a basic anchored part
    @param name Part name
    @param position Part center position
    @param size Part dimensions
    @param color Part color
    @param material Part material
    @param parent Parent instance
    @return The created Part
]]
local function createPart(
    name: string,
    position: Vector3,
    size: Vector3,
    color: Color3,
    material: Enum.Material,
    parent: Instance
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Material = material
    part.Color = color
    part.CanCollide = true
    part.CastShadow = true
    part.Parent = parent
    return part
end

--[[
    Helper: Create a cylinder part (for columns)
    @param name Part name
    @param position Part center position
    @param radius Cylinder radius
    @param height Cylinder height
    @param color Part color
    @param parent Parent instance
    @return The created Part
]]
local function createCylinder(
    name: string,
    position: Vector3,
    radius: number,
    height: number,
    color: Color3,
    parent: Instance
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
    part.CastShadow = true
    part.Parent = parent
    return part
end

--[[
    Helper: Create a wall with a centered doorway
    Creates two wall segments and a lintel above the doorway
    @param centerX Wall center X position
    @param baseY Wall base Y position
    @param centerZ Wall center Z position
    @param wallLength Total wall length
    @param wallHeight Wall height
    @param wallThickness Wall thickness
    @param isZAligned True if wall runs along Z axis
    @param color Wall color
    @param material Wall material
    @param parent Parent instance
]]
local function createWallWithDoorway(
    centerX: number,
    baseY: number,
    centerZ: number,
    wallLength: number,
    wallHeight: number,
    wallThickness: number,
    isZAligned: boolean,
    color: Color3,
    material: Enum.Material,
    parent: Instance
): ()
    local segmentLength = (wallLength - DOORWAY_WIDTH) / 2

    if isZAligned then
        -- Wall runs along Z axis
        -- Left segment
        local leftZ = centerZ - wallLength / 4 - DOORWAY_WIDTH / 4
        createPart(
            "Wall_Left",
            Vector3.new(centerX, baseY + wallHeight / 2, leftZ),
            Vector3.new(wallThickness, wallHeight, segmentLength),
            color,
            material,
            parent
        )

        -- Right segment
        local rightZ = centerZ + wallLength / 4 + DOORWAY_WIDTH / 4
        createPart(
            "Wall_Right",
            Vector3.new(centerX, baseY + wallHeight / 2, rightZ),
            Vector3.new(wallThickness, wallHeight, segmentLength),
            color,
            material,
            parent
        )

        -- Lintel above doorway
        local lintelHeight = wallHeight - DOORWAY_HEIGHT
        if lintelHeight > 0 then
            createPart(
                "Wall_Lintel",
                Vector3.new(centerX, baseY + DOORWAY_HEIGHT + lintelHeight / 2, centerZ),
                Vector3.new(wallThickness, lintelHeight, DOORWAY_WIDTH),
                color,
                material,
                parent
            )
        end
    else
        -- Wall runs along X axis
        -- Left segment
        local leftX = centerX - wallLength / 4 - DOORWAY_WIDTH / 4
        createPart(
            "Wall_Left",
            Vector3.new(leftX, baseY + wallHeight / 2, centerZ),
            Vector3.new(segmentLength, wallHeight, wallThickness),
            color,
            material,
            parent
        )

        -- Right segment
        local rightX = centerX + wallLength / 4 + DOORWAY_WIDTH / 4
        createPart(
            "Wall_Right",
            Vector3.new(rightX, baseY + wallHeight / 2, centerZ),
            Vector3.new(segmentLength, wallHeight, wallThickness),
            color,
            material,
            parent
        )

        -- Lintel above doorway
        local lintelHeight = wallHeight - DOORWAY_HEIGHT
        if lintelHeight > 0 then
            createPart(
                "Wall_Lintel",
                Vector3.new(centerX, baseY + DOORWAY_HEIGHT + lintelHeight / 2, centerZ),
                Vector3.new(DOORWAY_WIDTH, lintelHeight, wallThickness),
                color,
                material,
                parent
            )
        end
    end
end

--[[
    Helper: Create a solid wall (no doorway)
    @param centerX Wall center X position
    @param baseY Wall base Y position
    @param centerZ Wall center Z position
    @param wallLength Wall length
    @param wallHeight Wall height
    @param wallThickness Wall thickness
    @param isZAligned True if wall runs along Z axis
    @param color Wall color
    @param material Wall material
    @param parent Parent instance
]]
local function createSolidWall(
    centerX: number,
    baseY: number,
    centerZ: number,
    wallLength: number,
    wallHeight: number,
    wallThickness: number,
    isZAligned: boolean,
    color: Color3,
    material: Enum.Material,
    parent: Instance
): ()
    local sizeX, sizeZ
    if isZAligned then
        sizeX = wallThickness
        sizeZ = wallLength
    else
        sizeX = wallLength
        sizeZ = wallThickness
    end

    createPart(
        "Wall_Solid",
        Vector3.new(centerX, baseY + wallHeight / 2, centerZ),
        Vector3.new(sizeX, wallHeight, sizeZ),
        color,
        material,
        parent
    )
end

--[[
    Helper: Create a Roman column with base and capital
    @param centerX Column center X
    @param baseY Column base Y
    @param centerZ Column center Z
    @param parent Parent instance
]]
local function createColumn(
    centerX: number,
    baseY: number,
    centerZ: number,
    parent: Instance
): ()
    -- Column base (square)
    local baseSize = COLUMN_RADIUS * 2.5
    createPart(
        "ColumnBase",
        Vector3.new(centerX, baseY + 0.4, centerZ),
        Vector3.new(baseSize, 0.8, baseSize),
        MARBLE_CREAM,
        Enum.Material.Marble,
        parent
    )

    -- Column shaft
    createCylinder(
        "ColumnShaft",
        Vector3.new(centerX, baseY + 0.8 + COLUMN_HEIGHT / 2, centerZ),
        COLUMN_RADIUS,
        COLUMN_HEIGHT,
        MARBLE_WHITE,
        parent
    )

    -- Column capital (wider top)
    local capitalSize = COLUMN_RADIUS * 2.8
    createPart(
        "ColumnCapital",
        Vector3.new(centerX, baseY + 0.8 + COLUMN_HEIGHT + 0.5, centerZ),
        Vector3.new(capitalSize, 1, capitalSize),
        MARBLE_CREAM,
        Enum.Material.Marble,
        parent
    )
end

--[[
    Create a Domus (Roman house)
    Has walls on all sides with a doorway in front, interior floor, and roof
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createDomus(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    local wallHeight = height * 0.8
    local wallThickness = WALL_THICKNESS

    -- Interior floor
    createPart(
        "Floor",
        Vector3.new(centerX, baseY + 0.25, centerZ),
        Vector3.new(width - wallThickness * 2, 0.5, depth - wallThickness * 2),
        TERRACOTTA,
        Enum.Material.Brick,
        model
    )

    -- Front wall (south, +Z) with doorway
    createWallWithDoorway(
        centerX, baseY, centerZ + depth / 2 - wallThickness / 2,
        width, wallHeight, wallThickness,
        false, SAND_BEIGE, Enum.Material.Brick, model
    )

    -- Back wall (north, -Z) solid
    createSolidWall(
        centerX, baseY, centerZ - depth / 2 + wallThickness / 2,
        width, wallHeight, wallThickness,
        false, SAND_BEIGE, Enum.Material.Brick, model
    )

    -- Left wall (west, -X) solid
    createSolidWall(
        centerX - width / 2 + wallThickness / 2, baseY, centerZ,
        depth - wallThickness * 2, wallHeight, wallThickness,
        true, SAND_BEIGE, Enum.Material.Brick, model
    )

    -- Right wall (east, +X) solid
    createSolidWall(
        centerX + width / 2 - wallThickness / 2, baseY, centerZ,
        depth - wallThickness * 2, wallHeight, wallThickness,
        true, SAND_BEIGE, Enum.Material.Brick, model
    )

    -- Roof (flat with slight overhang)
    createPart(
        "Roof",
        Vector3.new(centerX, baseY + wallHeight + 0.5, centerZ),
        Vector3.new(width + 1, 1, depth + 1),
        TERRACOTTA,
        Enum.Material.Slate,
        model
    )
end

--[[
    Create a Taberna (Roman shop)
    Has an open front for customers, a counter, side/back walls, and roof
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createTaberna(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    local wallHeight = height * 0.85
    local wallThickness = WALL_THICKNESS

    -- Interior floor
    createPart(
        "Floor",
        Vector3.new(centerX, baseY + 0.25, centerZ),
        Vector3.new(width - wallThickness * 2, 0.5, depth - wallThickness),
        STONE_GRAY,
        Enum.Material.Slate,
        model
    )

    -- Back wall (north, -Z) solid
    createSolidWall(
        centerX, baseY, centerZ - depth / 2 + wallThickness / 2,
        width, wallHeight, wallThickness,
        false, TERRACOTTA, Enum.Material.Brick, model
    )

    -- Left wall (west, -X) solid
    createSolidWall(
        centerX - width / 2 + wallThickness / 2, baseY, centerZ,
        depth - wallThickness, wallHeight, wallThickness,
        true, TERRACOTTA, Enum.Material.Brick, model
    )

    -- Right wall (east, +X) solid
    createSolidWall(
        centerX + width / 2 - wallThickness / 2, baseY, centerZ,
        depth - wallThickness, wallHeight, wallThickness,
        true, TERRACOTTA, Enum.Material.Brick, model
    )

    -- Front is OPEN (no front wall) - characteristic of Roman shops

    -- Counter at front (where shopkeeper serves customers)
    local counterHeight = 3
    local counterDepth = 2
    createPart(
        "Counter",
        Vector3.new(centerX, baseY + counterHeight / 2, centerZ + depth / 2 - counterDepth / 2 - 0.5),
        Vector3.new(width - wallThickness * 2 - 1, counterHeight, counterDepth),
        MARBLE_CREAM,
        Enum.Material.Marble,
        model
    )

    -- Roof with slight overhang at front
    createPart(
        "Roof",
        Vector3.new(centerX, baseY + wallHeight + 0.5, centerZ),
        Vector3.new(width + 1, 1, depth + 2),
        TERRACOTTA,
        Enum.Material.Slate,
        model
    )
end

--[[
    Create a Temple (small Roman temple)
    Has raised platform with steps, columns at front, cella with doorway, and roof
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createTemple(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    -- Platform/podium
    local platformHeight = 2
    createPart(
        "Platform",
        Vector3.new(centerX, baseY + platformHeight / 2, centerZ),
        Vector3.new(width, platformHeight, depth),
        MARBLE_CREAM,
        Enum.Material.Marble,
        model
    )

    -- Steps at front (+Z direction)
    local numSteps = 4
    local stepHeight = platformHeight / numSteps
    local stepDepth = 1
    for i = 1, numSteps do
        local stepY = baseY + (i - 0.5) * stepHeight
        local stepZ = centerZ + depth / 2 + (numSteps - i + 0.5) * stepDepth
        local stepWidth = width - (numSteps - i) * 0.4
        createPart(
            string.format("Step_%d", i),
            Vector3.new(centerX, stepY, stepZ),
            Vector3.new(stepWidth, stepHeight, stepDepth),
            MARBLE_WHITE,
            Enum.Material.Marble,
            model
        )
    end

    local platformTop = baseY + platformHeight

    -- Cella (inner chamber) walls
    local cellaWidth = width * 0.6
    local cellaDepth = depth * 0.5
    local cellaHeight = height * 0.6
    local cellaCenterZ = centerZ - depth * 0.15
    local wallThickness = WALL_THICKNESS

    -- Cella floor
    createPart(
        "CellaFloor",
        Vector3.new(centerX, platformTop + 0.25, cellaCenterZ),
        Vector3.new(cellaWidth - wallThickness * 2, 0.5, cellaDepth - wallThickness * 2),
        MARBLE_WHITE,
        Enum.Material.Marble,
        model
    )

    -- Cella front wall with doorway
    createWallWithDoorway(
        centerX, platformTop, cellaCenterZ + cellaDepth / 2 - wallThickness / 2,
        cellaWidth, cellaHeight, wallThickness,
        false, MARBLE_WHITE, Enum.Material.Marble, model
    )

    -- Cella back wall (solid)
    createSolidWall(
        centerX, platformTop, cellaCenterZ - cellaDepth / 2 + wallThickness / 2,
        cellaWidth, cellaHeight, wallThickness,
        false, MARBLE_WHITE, Enum.Material.Marble, model
    )

    -- Cella side walls (solid)
    createSolidWall(
        centerX - cellaWidth / 2 + wallThickness / 2, platformTop, cellaCenterZ,
        cellaDepth - wallThickness * 2, cellaHeight, wallThickness,
        true, MARBLE_WHITE, Enum.Material.Marble, model
    )
    createSolidWall(
        centerX + cellaWidth / 2 - wallThickness / 2, platformTop, cellaCenterZ,
        cellaDepth - wallThickness * 2, cellaHeight, wallThickness,
        true, MARBLE_WHITE, Enum.Material.Marble, model
    )

    -- Front columns (4 columns)
    local columnSpacing = width / 5
    local columnZ = centerZ + depth * 0.35
    for i = 1, 4 do
        local columnX = centerX - width / 2 + i * columnSpacing
        createColumn(columnX, platformTop, columnZ, model)
    end

    -- Roof over entire temple
    local roofHeight = 1.5
    createPart(
        "Roof",
        Vector3.new(centerX, platformTop + cellaHeight + roofHeight / 2, centerZ),
        Vector3.new(width + 1, roofHeight, depth + 1),
        TERRACOTTA,
        Enum.Material.Slate,
        model
    )

    -- Pediment (triangular front - simplified as a thick bar)
    createPart(
        "Pediment",
        Vector3.new(centerX, platformTop + cellaHeight + roofHeight + 1, centerZ + depth * 0.35),
        Vector3.new(width * 0.9, 2, 1.5),
        MARBLE_CREAM,
        Enum.Material.Marble,
        model
    )
end

--[[
    Create a Wall segment (defensive wall)
    Simple wall with crenellations at top
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createWall(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    -- Main wall body (slightly shorter to leave room for crenellations)
    local mainWallHeight = height * 0.8
    createPart(
        "WallBody",
        Vector3.new(centerX, baseY + mainWallHeight / 2, centerZ),
        Vector3.new(width, mainWallHeight, depth),
        STONE_GRAY,
        Enum.Material.Brick,
        model
    )

    -- Crenellations (merlons) at top
    local merlonHeight = height * 0.2
    local merlonWidth = width / 4
    local numMerlons = 3
    local merlonSpacing = width / numMerlons
    for i = 1, numMerlons do
        local merlonX = centerX - width / 2 + (i - 0.5) * merlonSpacing
        createPart(
            string.format("Merlon_%d", i),
            Vector3.new(merlonX, baseY + mainWallHeight + merlonHeight / 2, centerZ),
            Vector3.new(merlonWidth * 0.6, merlonHeight, depth),
            STONE_GRAY,
            Enum.Material.Brick,
            model
        )
    end
end

--[[
    Create an Insula (Roman apartment block)
    Multi-story residential building with multiple floors, windows, and balconies
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createInsula(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    local numFloors = 4
    local floorHeight = height / numFloors
    local wallThickness = WALL_THICKNESS

    -- Foundation
    createPart(
        "Foundation",
        Vector3.new(centerX, baseY + 0.5, centerZ),
        Vector3.new(width, 1, depth),
        STONE_GRAY,
        Enum.Material.Concrete,
        model
    )

    -- Build each floor
    for floor = 1, numFloors do
        local floorBaseY = baseY + 1 + (floor - 1) * floorHeight
        local floorSuffix = string.format("_F%d", floor)

        -- Floor slab (except for ground floor which uses foundation)
        if floor > 1 then
            createPart(
                "FloorSlab" .. floorSuffix,
                Vector3.new(centerX, floorBaseY + 0.25, centerZ),
                Vector3.new(width - wallThickness, 0.5, depth - wallThickness),
                TERRACOTTA,
                Enum.Material.Brick,
                model
            )
        end

        -- Four walls for each floor
        local wallHeight = floorHeight - 0.5

        -- Front wall (+Z) with window openings indicated by recesses
        createSolidWall(
            centerX, floorBaseY, centerZ + depth / 2 - wallThickness / 2,
            width, wallHeight, wallThickness,
            false, TERRACOTTA, Enum.Material.Brick, model
        )

        -- Back wall (-Z)
        createSolidWall(
            centerX, floorBaseY, centerZ - depth / 2 + wallThickness / 2,
            width, wallHeight, wallThickness,
            false, TERRACOTTA, Enum.Material.Brick, model
        )

        -- Left wall (-X)
        createSolidWall(
            centerX - width / 2 + wallThickness / 2, floorBaseY, centerZ,
            depth - wallThickness * 2, wallHeight, wallThickness,
            true, TERRACOTTA, Enum.Material.Brick, model
        )

        -- Right wall (+X)
        createSolidWall(
            centerX + width / 2 - wallThickness / 2, floorBaseY, centerZ,
            depth - wallThickness * 2, wallHeight, wallThickness,
            true, TERRACOTTA, Enum.Material.Brick, model
        )

        -- Balcony on front for upper floors
        if floor > 1 then
            createPart(
                "Balcony" .. floorSuffix,
                Vector3.new(centerX, floorBaseY + 0.3, centerZ + depth / 2 + 1),
                Vector3.new(width * 0.6, 0.3, 2),
                STONE_GRAY,
                Enum.Material.Concrete,
                model
            )
        end
    end

    -- Roof (flat with slight overhang)
    local roofY = baseY + 1 + numFloors * floorHeight
    createPart(
        "Roof",
        Vector3.new(centerX, roofY + 0.5, centerZ),
        Vector3.new(width + 1, 1, depth + 1),
        TERRACOTTA,
        Enum.Material.Slate,
        model
    )
end

--[[
    Create a Forum Stall (market stall)
    Simple canopy structure with wooden posts and cloth/wood awning
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createForumStall(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    local postHeight = height * 0.8
    local postSize = 0.5

    -- Ground platform
    createPart(
        "Platform",
        Vector3.new(centerX, baseY + 0.2, centerZ),
        Vector3.new(width, 0.4, depth),
        STONE_GRAY,
        Enum.Material.Slate,
        model
    )

    -- Four corner posts
    local postOffsetX = (width - postSize) / 2
    local postOffsetZ = (depth - postSize) / 2
    local postPositions = {
        Vector3.new(centerX - postOffsetX, baseY + 0.4 + postHeight / 2, centerZ - postOffsetZ),
        Vector3.new(centerX + postOffsetX, baseY + 0.4 + postHeight / 2, centerZ - postOffsetZ),
        Vector3.new(centerX - postOffsetX, baseY + 0.4 + postHeight / 2, centerZ + postOffsetZ),
        Vector3.new(centerX + postOffsetX, baseY + 0.4 + postHeight / 2, centerZ + postOffsetZ),
    }

    for i, postPos in ipairs(postPositions) do
        createPart(
            string.format("Post_%d", i),
            postPos,
            Vector3.new(postSize, postHeight, postSize),
            WOOD_BROWN,
            Enum.Material.Wood,
            model
        )
    end

    -- Awning/canopy (sloped from back to front)
    local awningY = baseY + 0.4 + postHeight
    createPart(
        "Awning",
        Vector3.new(centerX, awningY + 0.3, centerZ),
        Vector3.new(width + 1, 0.3, depth + 1),
        SAND_BEIGE,
        Enum.Material.Fabric,
        model
    )

    -- Display counter at front
    local counterHeight = 2.5
    local counterDepth = 1.5
    createPart(
        "Counter",
        Vector3.new(centerX, baseY + 0.4 + counterHeight / 2, centerZ + depth / 2 - counterDepth / 2 - 0.3),
        Vector3.new(width - 1, counterHeight, counterDepth),
        WOOD_BROWN,
        Enum.Material.Wood,
        model
    )
end

--[[
    Create a Watchtower (defensive tower)
    Tall stone tower with observation platform at top
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createWatchtower(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    local towerHeight = height * 0.85
    local wallThickness = WALL_THICKNESS

    -- Base foundation (wider than tower)
    createPart(
        "Foundation",
        Vector3.new(centerX, baseY + 0.5, centerZ),
        Vector3.new(width + 1, 1, depth + 1),
        STONE_GRAY,
        Enum.Material.Concrete,
        model
    )

    -- Tower body (hollow - four walls)
    -- Front wall with doorway
    createWallWithDoorway(
        centerX, baseY + 1, centerZ + depth / 2 - wallThickness / 2,
        width, towerHeight, wallThickness,
        false, STONE_GRAY, Enum.Material.Brick, model
    )

    -- Back wall (solid)
    createSolidWall(
        centerX, baseY + 1, centerZ - depth / 2 + wallThickness / 2,
        width, towerHeight, wallThickness,
        false, STONE_GRAY, Enum.Material.Brick, model
    )

    -- Left wall (solid)
    createSolidWall(
        centerX - width / 2 + wallThickness / 2, baseY + 1, centerZ,
        depth - wallThickness * 2, towerHeight, wallThickness,
        true, STONE_GRAY, Enum.Material.Brick, model
    )

    -- Right wall (solid)
    createSolidWall(
        centerX + width / 2 - wallThickness / 2, baseY + 1, centerZ,
        depth - wallThickness * 2, towerHeight, wallThickness,
        true, STONE_GRAY, Enum.Material.Brick, model
    )

    -- Observation platform at top (wider than tower)
    local platformY = baseY + 1 + towerHeight
    createPart(
        "ObservationPlatform",
        Vector3.new(centerX, platformY + 0.25, centerZ),
        Vector3.new(width + 2, 0.5, depth + 2),
        STONE_GRAY,
        Enum.Material.Concrete,
        model
    )

    -- Crenellations around observation platform
    local merlonHeight = height * 0.1
    local merlonSize = 1
    local merlonSpacing = 2
    local platformWidth = width + 2
    local platformDepth = depth + 2

    -- Front and back merlons
    local numMerlonsX = math.floor(platformWidth / merlonSpacing)
    for i = 1, numMerlonsX do
        local merlonX = centerX - platformWidth / 2 + (i - 0.5) * (platformWidth / numMerlonsX)
        -- Front
        createPart(
            string.format("Merlon_Front_%d", i),
            Vector3.new(merlonX, platformY + 0.5 + merlonHeight / 2, centerZ + platformDepth / 2 - merlonSize / 2),
            Vector3.new(merlonSize, merlonHeight, merlonSize),
            STONE_GRAY,
            Enum.Material.Brick,
            model
        )
        -- Back
        createPart(
            string.format("Merlon_Back_%d", i),
            Vector3.new(merlonX, platformY + 0.5 + merlonHeight / 2, centerZ - platformDepth / 2 + merlonSize / 2),
            Vector3.new(merlonSize, merlonHeight, merlonSize),
            STONE_GRAY,
            Enum.Material.Brick,
            model
        )
    end
end

--[[
    Create Thermae (Roman public baths)
    Main building with walls, columns along front, central pool, arched entrance, terracotta roof
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createThermae(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    local wallHeight = height * 0.8
    local wallThickness = WALL_THICKNESS

    -- Foundation/floor
    createPart(
        "Floor",
        Vector3.new(centerX, baseY + 0.25, centerZ),
        Vector3.new(width - wallThickness * 2, 0.5, depth - wallThickness * 2),
        MARBLE_CREAM,
        Enum.Material.Marble,
        model
    )

    -- Front wall (+Z) with arched doorway
    createWallWithDoorway(
        centerX, baseY, centerZ + depth / 2 - wallThickness / 2,
        width, wallHeight, wallThickness,
        false, MARBLE_WHITE, Enum.Material.Marble, model
    )

    -- Back wall (-Z) solid
    createSolidWall(
        centerX, baseY, centerZ - depth / 2 + wallThickness / 2,
        width, wallHeight, wallThickness,
        false, MARBLE_WHITE, Enum.Material.Marble, model
    )

    -- Left wall (-X) solid
    createSolidWall(
        centerX - width / 2 + wallThickness / 2, baseY, centerZ,
        depth - wallThickness * 2, wallHeight, wallThickness,
        true, MARBLE_WHITE, Enum.Material.Marble, model
    )

    -- Right wall (+X) solid
    createSolidWall(
        centerX + width / 2 - wallThickness / 2, baseY, centerZ,
        depth - wallThickness * 2, wallHeight, wallThickness,
        true, MARBLE_WHITE, Enum.Material.Marble, model
    )

    -- 4 columns along the front
    local columnSpacing = width / 5
    local columnZ = centerZ + depth / 2 - wallThickness - 2
    for i = 1, 4 do
        local columnX = centerX - width / 2 + i * columnSpacing
        createColumn(columnX, baseY, columnZ, model)
    end

    -- Central pool (blue-tinted Part, NOT water terrain)
    local poolWidth = width * 0.5
    local poolDepth = depth * 0.4
    local poolHeight = 1.5

    -- Pool basin (recessed)
    createPart(
        "PoolBasin",
        Vector3.new(centerX, baseY + 0.5 - poolHeight / 2, centerZ - 1),
        Vector3.new(poolWidth, poolHeight, poolDepth),
        STONE_GRAY,
        Enum.Material.Concrete,
        model
    )

    -- Pool water (blue glass part inside the basin)
    local waterDepth = poolHeight - 0.3
    createPart(
        "PoolWater",
        Vector3.new(centerX, baseY + 0.5 - waterDepth / 2, centerZ - 1),
        Vector3.new(poolWidth - 0.5, waterDepth, poolDepth - 0.5),
        POOL_BLUE,
        Enum.Material.Glass,
        model
    )

    -- Terracotta roof with slight overhang
    createPart(
        "Roof",
        Vector3.new(centerX, baseY + wallHeight + 0.5, centerZ),
        Vector3.new(width + 1, 1, depth + 1),
        TERRACOTTA,
        Enum.Material.Slate,
        model
    )
end

--[[
    Create an Arch (triumphal arch)
    Classic Roman arch with columns and decorative top
    @param position Base position (center of structure at terrain level)
    @param size Structure footprint from BuildConfig (width, height, depth)
    @param model Parent model to add parts to
]]
function StructureModels.createArch(position: Vector3, size: Vector3, model: Model): ()
    local width = size.X
    local height = size.Y
    local depth = size.Z
    local baseY = position.Y
    local centerX = position.X
    local centerZ = position.Z

    local pillarWidth = width * 0.25
    local _archOpeningWidth = width - pillarWidth * 2
    local archOpeningHeight = height * 0.65

    -- Foundation/base
    createPart(
        "Foundation",
        Vector3.new(centerX, baseY + 0.5, centerZ),
        Vector3.new(width + 1, 1, depth + 0.5),
        MARBLE_CREAM,
        Enum.Material.Marble,
        model
    )

    -- Left pillar
    createPart(
        "Pillar_Left",
        Vector3.new(centerX - width / 2 + pillarWidth / 2, baseY + 1 + height / 2, centerZ),
        Vector3.new(pillarWidth, height - 1, depth),
        MARBLE_WHITE,
        Enum.Material.Marble,
        model
    )

    -- Right pillar
    createPart(
        "Pillar_Right",
        Vector3.new(centerX + width / 2 - pillarWidth / 2, baseY + 1 + height / 2, centerZ),
        Vector3.new(pillarWidth, height - 1, depth),
        MARBLE_WHITE,
        Enum.Material.Marble,
        model
    )

    -- Top beam above arch opening (lintel/attic)
    local atticHeight = height - archOpeningHeight - 1
    createPart(
        "Attic",
        Vector3.new(centerX, baseY + 1 + archOpeningHeight + atticHeight / 2, centerZ),
        Vector3.new(width, atticHeight, depth),
        MARBLE_WHITE,
        Enum.Material.Marble,
        model
    )

    -- Decorative cornice at very top
    createPart(
        "Cornice",
        Vector3.new(centerX, baseY + height + 0.5, centerZ),
        Vector3.new(width + 0.5, 0.8, depth + 0.3),
        MARBLE_CREAM,
        Enum.Material.Marble,
        model
    )

    -- Inner arch shape (using wedge parts is complex, so we use a simplified rectangular opening)
    -- The arch opening is implicitly created by the gap between pillars and the attic above

    -- Decorative columns on pillar faces (one on each pillar, front face)
    local columnHeight = archOpeningHeight * 0.8
    createCylinder(
        "Column_Left",
        Vector3.new(centerX - width / 2 + pillarWidth / 2, baseY + 1 + columnHeight / 2, centerZ + depth / 2 - 0.3),
        0.4,
        columnHeight,
        MARBLE_CREAM,
        model
    )
    createCylinder(
        "Column_Right",
        Vector3.new(centerX + width / 2 - pillarWidth / 2, baseY + 1 + columnHeight / 2, centerZ + depth / 2 - 0.3),
        0.4,
        columnHeight,
        MARBLE_CREAM,
        model
    )
end

--[[
    Get the structure builder function for a given structure ID
    @param structureId The structure ID (DOMUS, TABERNA, TEMPLE, WALL, INSULA, FORUM_STALL, WATCHTOWER, ARCH, THERMAE)
    @return The builder function or nil if not found
]]
function StructureModels.getBuilder(structureId: string): ((position: Vector3, size: Vector3, model: Model) -> ())?
    if structureId == "DOMUS" then
        return StructureModels.createDomus
    elseif structureId == "TABERNA" then
        return StructureModels.createTaberna
    elseif structureId == "TEMPLE" then
        return StructureModels.createTemple
    elseif structureId == "WALL" then
        return StructureModels.createWall
    elseif structureId == "INSULA" then
        return StructureModels.createInsula
    elseif structureId == "FORUM_STALL" then
        return StructureModels.createForumStall
    elseif structureId == "WATCHTOWER" then
        return StructureModels.createWatchtower
    elseif structureId == "ARCH" then
        return StructureModels.createArch
    elseif structureId == "THERMAE" then
        return StructureModels.createThermae
    end
    return nil
end

return StructureModels
