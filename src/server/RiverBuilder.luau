--!strict
--[[
    RiverBuilder - Constructs a single continuous river structure across the map

    Creates the physical river with:
    - Part-based walls (continuous, no gaps)
    - Part-based floor (follows terrain curve)
    - Water terrain ONLY inside the walls
    - Clears ALL terrain inside walls (including above water surface)

    Based on BRicey techniques for procedural environment generation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))

local RiverBuilder = {}
RiverBuilder.__index = RiverBuilder
RiverBuilder.VERSION = "1.0.1"

-- River construction constants (exported for other modules like BridgeBuilder)
local WALL_HEIGHT = 12 -- Height of river walls (deep enough to swim: 8-12 studs)
RiverBuilder.WALL_HEIGHT = WALL_HEIGHT -- Export for BridgeBuilder
local WALL_THICKNESS = 2 -- Thickness of wall parts
local FLOOR_THICKNESS = 2 -- Thickness of river floor
local _SEGMENT_LENGTH = 20 -- Length of each river segment (reserved for future use)
local WATER_SURFACE_OFFSET = 0.5 -- How far below terrain surface to fill water

-- River material colors (rock/natural)
local WALL_COLOR = Color3.fromRGB(100, 95, 85)
local FLOOR_COLOR = Color3.fromRGB(90, 85, 75)

export type RiverBuilderConfig = {
    worldPlan: WorldPlan.WorldPlanInstance,
}

export type RiverBuilderInstance = typeof(setmetatable(
    {} :: {
        worldPlan: WorldPlan.WorldPlanInstance,
        terrain: Terrain,
        folder: Folder?,
        parts: { Part },
    },
    RiverBuilder
))

function RiverBuilder.new(config: RiverBuilderConfig): RiverBuilderInstance
    local self = setmetatable({}, RiverBuilder)
    self.worldPlan = config.worldPlan
    self.terrain = workspace.Terrain
    self.folder = nil
    self.parts = {}

    print(string.format("[RiverBuilder v%s] Initializing...", RiverBuilder.VERSION))
    return self
end

-- Helper: Calculate direction vector between two points
local function getDirection(p1: Vector2, p2: Vector2): Vector2
    local diff = p2 - p1
    local mag = diff.Magnitude
    if mag < 0.001 then
        return Vector2.new(1, 0)
    end
    return diff / mag
end

-- Helper: Get perpendicular vector (for wall placement)
local function getPerpendicular(dir: Vector2): Vector2
    return Vector2.new(-dir.Y, dir.X)
end

-- Create a single wall part
function RiverBuilder:_createPart(
    name: string,
    position: Vector3,
    size: Vector3,
    rotation: number
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
    part.Anchored = true
    part.Material = Enum.Material.Rock
    part.Color = WALL_COLOR
    part.CanCollide = true
    table.insert(self.parts, part)
    return part
end

-- Build a single river segment between two path points
function RiverBuilder:_buildSegment(
    segmentIndex: number,
    p1: Vector2,
    p2: Vector2,
    riverWidth: number,
    folder: Folder
): ()
    local direction = getDirection(p1, p2)
    local perpendicular = getPerpendicular(direction)
    local segmentLength = (p2 - p1).Magnitude

    -- Skip very short segments
    if segmentLength < 1 then
        return
    end

    -- Calculate segment center position
    local centerX = (p1.X + p2.X) / 2
    local centerZ = (p1.Y + p2.Y) / 2

    -- Query terrain height at center
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local floorY = terrainY - WALL_HEIGHT + FLOOR_THICKNESS / 2
    local wallCenterY = terrainY - WALL_HEIGHT / 2

    -- Calculate rotation from direction
    local rotation = math.atan2(direction.X, direction.Y)

    -- Half width for wall placement
    local halfWidth = riverWidth / 2

    -- Create floor
    local floorPart = self:_createPart(
        string.format("RiverFloor_%d", segmentIndex),
        Vector3.new(centerX, floorY, centerZ),
        Vector3.new(riverWidth, FLOOR_THICKNESS, segmentLength + WALL_THICKNESS),
        rotation
    )
    floorPart.Color = FLOOR_COLOR
    floorPart.Parent = folder

    -- Create left wall
    local leftWallX = centerX + perpendicular.X * (halfWidth + WALL_THICKNESS / 2)
    local leftWallZ = centerZ + perpendicular.Y * (halfWidth + WALL_THICKNESS / 2)
    local leftWall = self:_createPart(
        string.format("RiverWallLeft_%d", segmentIndex),
        Vector3.new(leftWallX, wallCenterY, leftWallZ),
        Vector3.new(WALL_THICKNESS, WALL_HEIGHT, segmentLength + WALL_THICKNESS),
        rotation
    )
    leftWall.Parent = folder

    -- Create right wall
    local rightWallX = centerX - perpendicular.X * (halfWidth + WALL_THICKNESS / 2)
    local rightWallZ = centerZ - perpendicular.Y * (halfWidth + WALL_THICKNESS / 2)
    local rightWall = self:_createPart(
        string.format("RiverWallRight_%d", segmentIndex),
        Vector3.new(rightWallX, wallCenterY, rightWallZ),
        Vector3.new(WALL_THICKNESS, WALL_HEIGHT, segmentLength + WALL_THICKNESS),
        rotation
    )
    rightWall.Parent = folder
end

-- Clear terrain inside the river corridor
function RiverBuilder:_clearTerrainInRiver(): ()
    local riverPath = self.worldPlan:getRiverPath()
    local riverWidth = self.worldPlan:getRiverWidth()
    local _halfWidth = riverWidth / 2 + WALL_THICKNESS

    print(string.format("[RiverBuilder v%s] Clearing terrain inside river corridor...", RiverBuilder.VERSION))

    -- Clear terrain along each segment of the river path
    for i = 1, #riverPath - 1 do
        local p1 = riverPath[i]
        local p2 = riverPath[i + 1]

        local direction = getDirection(p1, p2)
        local segmentLength = (p2 - p1).Magnitude

        local centerX = (p1.X + p2.X) / 2
        local centerZ = (p1.Y + p2.Y) / 2

        -- Query terrain height at this position
        local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

        -- Calculate rotation
        local rotation = math.atan2(direction.X, direction.Y)

        -- Clear region extends from below river floor to above terrain surface
        local clearHeight = WALL_HEIGHT + 20 -- Extra clearance above
        local clearY = terrainY - WALL_HEIGHT / 2 + 5 -- Center of clear region

        -- Create CFrame for the rotated fill region
        local clearCFrame = CFrame.new(centerX, clearY, centerZ) * CFrame.Angles(0, rotation, 0)
        local clearSize = Vector3.new(riverWidth, clearHeight, segmentLength + WALL_THICKNESS)

        -- Clear to air first
        self.terrain:FillBlock(clearCFrame, clearSize, Enum.Material.Air)

        -- Yield periodically
        if i % 10 == 0 then
            task.wait()
        end
    end
end

-- Fill river with water terrain
function RiverBuilder:_fillWithWater(): ()
    local riverPath = self.worldPlan:getRiverPath()
    local riverWidth = self.worldPlan:getRiverWidth()

    print(string.format("[RiverBuilder v%s] Filling river with water...", RiverBuilder.VERSION))

    -- Fill water along each segment
    for i = 1, #riverPath - 1 do
        local p1 = riverPath[i]
        local p2 = riverPath[i + 1]

        local direction = getDirection(p1, p2)
        local segmentLength = (p2 - p1).Magnitude

        local centerX = (p1.X + p2.X) / 2
        local centerZ = (p1.Y + p2.Y) / 2

        -- Query terrain height
        local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

        -- Water fills from floor to just below terrain surface
        local waterHeight = WALL_HEIGHT - FLOOR_THICKNESS - WATER_SURFACE_OFFSET
        local waterY = terrainY - WALL_HEIGHT / 2 - WATER_SURFACE_OFFSET / 2

        -- Calculate rotation
        local rotation = math.atan2(direction.X, direction.Y)

        -- Create water fill region (slightly smaller than walls to avoid overlap)
        local waterCFrame = CFrame.new(centerX, waterY, centerZ) * CFrame.Angles(0, rotation, 0)
        local waterSize = Vector3.new(riverWidth - 1, waterHeight, segmentLength)

        self.terrain:FillBlock(waterCFrame, waterSize, Enum.Material.Water)

        -- Yield periodically
        if i % 10 == 0 then
            task.wait()
        end
    end
end

-- Build the complete river structure
function RiverBuilder:build(): Folder
    local startTime = tick()

    local riverPath = self.worldPlan:getRiverPath()
    local riverWidth = self.worldPlan:getRiverWidth()

    print(string.format(
        "[RiverBuilder v%s] Building river with %d path points, width: %d studs",
        RiverBuilder.VERSION,
        #riverPath,
        riverWidth
    ))

    -- Create folder for organization
    local folder = Instance.new("Folder")
    folder.Name = "River_Tiberis"
    folder.Parent = workspace
    self.folder = folder

    -- Step 1: Build wall segments along path
    for i = 1, #riverPath - 1 do
        self:_buildSegment(i, riverPath[i], riverPath[i + 1], riverWidth, folder)

        -- Yield periodically
        if i % 10 == 0 then
            task.wait()
        end
    end

    -- Step 2: Clear ALL terrain inside walls (critical!)
    self:_clearTerrainInRiver()

    -- Step 3: Fill with water terrain
    self:_fillWithWater()

    local elapsed = tick() - startTime
    print(string.format(
        "[RiverBuilder v%s] River built in %.2f seconds (%d segments, %d parts)",
        RiverBuilder.VERSION,
        elapsed,
        #riverPath - 1,
        #self.parts
    ))

    return folder
end

-- Destroy the river structure
function RiverBuilder:destroy(): ()
    -- Clear water along river path
    local riverPath = self.worldPlan:getRiverPath()
    local riverWidth = self.worldPlan:getRiverWidth()

    for i = 1, #riverPath - 1 do
        local p1 = riverPath[i]
        local p2 = riverPath[i + 1]

        local direction = getDirection(p1, p2)
        local segmentLength = (p2 - p1).Magnitude

        local centerX = (p1.X + p2.X) / 2
        local centerZ = (p1.Y + p2.Y) / 2

        local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
        local clearY = terrainY - WALL_HEIGHT / 2

        local rotation = math.atan2(direction.X, direction.Y)
        local clearCFrame = CFrame.new(centerX, clearY, centerZ) * CFrame.Angles(0, rotation, 0)
        local clearSize = Vector3.new(riverWidth, WALL_HEIGHT + 10, segmentLength + WALL_THICKNESS)

        self.terrain:FillBlock(clearCFrame, clearSize, Enum.Material.Air)
    end

    -- Destroy folder and all parts
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end

    self.parts = {}
    print(string.format("[RiverBuilder v%s] River destroyed", RiverBuilder.VERSION))
end

return RiverBuilder
