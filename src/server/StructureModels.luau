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
StructureModels.VERSION = "1.0.0"

-- Roman architectural colors (consistent with LandmarkBuilder)
local MARBLE_WHITE = Color3.fromRGB(240, 235, 225)
local MARBLE_CREAM = Color3.fromRGB(230, 220, 200)
local TERRACOTTA = Color3.fromRGB(180, 100, 70)
local STONE_GRAY = Color3.fromRGB(160, 155, 145)
local SAND_BEIGE = Color3.fromRGB(194, 178, 128)

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
    Get the structure builder function for a given structure ID
    @param structureId The structure ID (DOMUS, TABERNA, TEMPLE, WALL)
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
    end
    return nil
end

return StructureModels
