--!strict
--[[
    BridgeBuilder - Constructs Roman-style stone arch bridges at road/river intersections

    Creates bridges where roads cross the river:
    - Queries WorldPlan for road paths and river path
    - Calculates intersection points using line-segment intersection
    - Builds stone arch bridges with walkable surfaces
    - Bridge width matches road width (~12 studs)

    Based on BRicey techniques for procedural environment generation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))

-- Import RiverBuilder for shared constants
local RiverBuilder = require(script.Parent.RiverBuilder)

local BridgeBuilder = {}
BridgeBuilder.__index = BridgeBuilder
BridgeBuilder.VERSION = "1.0.1"

-- Bridge construction constants
local BRIDGE_HEIGHT = 6 -- Height of bridge deck above river water
local DECK_THICKNESS = 2 -- Thickness of the bridge deck
local ARCH_SEGMENTS = 5 -- Number of segments in each arch
local RAILING_HEIGHT = 3 -- Height of side railings
local RAILING_THICKNESS = 1 -- Thickness of railings
local PILLAR_WIDTH = 3 -- Width of support pillars
local PILLAR_DEPTH = 4 -- Depth of support pillars

-- Roman bridge materials/colors
local STONE_COLOR = Color3.fromRGB(180, 175, 165) -- Light stone/marble
local ARCH_COLOR = Color3.fromRGB(160, 155, 145) -- Slightly darker stone for arches
local RAILING_COLOR = Color3.fromRGB(170, 165, 155) -- Medium stone for railings

export type BridgeBuilderConfig = {
    worldPlan: WorldPlan.WorldPlanInstance,
}

export type Intersection = {
    point: Vector2,
    roadDirection: Vector2,
    roadWidth: number,
}

export type BridgeBuilderInstance = typeof(setmetatable(
    {} :: {
        worldPlan: WorldPlan.WorldPlanInstance,
        terrain: Terrain,
        folder: Folder?,
        parts: { Part },
        intersections: { Intersection },
    },
    BridgeBuilder
))

function BridgeBuilder.new(config: BridgeBuilderConfig): BridgeBuilderInstance
    local self = setmetatable({}, BridgeBuilder)
    self.worldPlan = config.worldPlan
    self.terrain = workspace.Terrain
    self.folder = nil
    self.parts = {}
    self.intersections = {}

    print(string.format("[BridgeBuilder v%s] Initializing...", BridgeBuilder.VERSION))
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

-- Helper: Check if two line segments intersect and return intersection point
-- Uses parametric line intersection algorithm
local function lineSegmentIntersection(
    a1: Vector2,
    a2: Vector2,
    b1: Vector2,
    b2: Vector2
): Vector2?
    local dxA = a2.X - a1.X
    local dyA = a2.Y - a1.Y
    local dxB = b2.X - b1.X
    local dyB = b2.Y - b1.Y

    local denominator = dxA * dyB - dyA * dxB

    -- Lines are parallel or coincident
    if math.abs(denominator) < 0.0001 then
        return nil
    end

    local t = ((b1.X - a1.X) * dyB - (b1.Y - a1.Y) * dxB) / denominator
    local u = ((b1.X - a1.X) * dyA - (b1.Y - a1.Y) * dxA) / denominator

    -- Check if intersection is within both line segments
    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        local x = a1.X + t * dxA
        local y = a1.Y + t * dyA
        return Vector2.new(x, y)
    end

    return nil
end

-- Find all intersections between roads and river
function BridgeBuilder:_findIntersections(): { Intersection }
    local intersections: { Intersection } = {}
    local roads = self.worldPlan:getRoads()
    local riverPath = self.worldPlan:getRiverPath()

    print(string.format("[BridgeBuilder v%s] Finding road/river intersections (%d roads, %d river segments)...",
        BridgeBuilder.VERSION,
        #roads,
        #riverPath - 1
    ))

    -- Check each road segment against each river segment
    for _, road in ipairs(roads) do
        local roadPath = road.path
        local roadWidth = road.width

        for roadSegIdx = 1, #roadPath - 1 do
            local roadP1 = roadPath[roadSegIdx]
            local roadP2 = roadPath[roadSegIdx + 1]
            local roadDirection = getDirection(roadP1, roadP2)

            for riverSegIdx = 1, #riverPath - 1 do
                local riverP1 = riverPath[riverSegIdx]
                local riverP2 = riverPath[riverSegIdx + 1]

                local intersection = lineSegmentIntersection(roadP1, roadP2, riverP1, riverP2)

                if intersection then
                    -- Check if we already have a nearby intersection (avoid duplicates)
                    local isDuplicate = false
                    for _, existing in ipairs(intersections) do
                        if (intersection - existing.point).Magnitude < 20 then
                            isDuplicate = true
                            break
                        end
                    end

                    if not isDuplicate then
                        table.insert(intersections, {
                            point = intersection,
                            roadDirection = roadDirection,
                            roadWidth = roadWidth,
                        })
                        print(string.format("[BridgeBuilder v%s] Found intersection at (%.1f, %.1f)",
                            BridgeBuilder.VERSION,
                            intersection.X,
                            intersection.Y
                        ))
                    end
                end
            end
        end
    end

    print(string.format("[BridgeBuilder v%s] Found %d unique intersections",
        BridgeBuilder.VERSION,
        #intersections
    ))

    return intersections
end

-- Create a basic part for the bridge
function BridgeBuilder:_createPart(
    name: string,
    position: Vector3,
    size: Vector3,
    color: Color3,
    rotation: number?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Anchored = true
    part.Material = Enum.Material.Brick
    part.Color = color
    part.CanCollide = true

    if rotation then
        part.CFrame = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
    else
        part.CFrame = CFrame.new(position)
    end

    table.insert(self.parts, part)
    return part
end

-- Build a stone arch underneath the bridge
function BridgeBuilder:_buildArch(
    centerX: number,
    centerZ: number,
    archY: number,
    bridgeWidth: number,
    bridgeLength: number,
    rotation: number,
    folder: Folder
): ()
    -- Build segmented arch using wedge-like parts
    local archRadius = bridgeWidth / 2 - PILLAR_WIDTH / 2
    local archThickness = 2

    for i = 0, ARCH_SEGMENTS do
        local angle = math.pi * (i / ARCH_SEGMENTS)
        local nextAngle = math.pi * ((i + 1) / ARCH_SEGMENTS)

        local x1 = math.cos(angle) * archRadius
        local y1 = math.sin(angle) * archRadius
        local x2 = math.cos(nextAngle) * archRadius
        local y2 = math.sin(nextAngle) * archRadius

        if i < ARCH_SEGMENTS then
            -- Create arch segment
            local segmentCenterX = (x1 + x2) / 2
            local segmentCenterY = (y1 + y2) / 2
            local segmentLength = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
            local segmentAngle = math.atan2(y2 - y1, x2 - x1)

            -- Transform to world coordinates
            local _dirX = math.sin(rotation)
            local _dirZ = math.cos(rotation)
            local perpX = math.cos(rotation)
            local perpZ = -math.sin(rotation)

            local worldX = centerX + segmentCenterX * perpX
            local worldZ = centerZ + segmentCenterX * perpZ
            local worldY = archY + segmentCenterY

            local archPart = self:_createPart(
                string.format("BridgeArch_%d", i),
                Vector3.new(worldX, worldY, worldZ),
                Vector3.new(archThickness, segmentLength + 0.5, bridgeLength),
                ARCH_COLOR
            )
            archPart.CFrame = CFrame.new(worldX, worldY, worldZ)
                * CFrame.Angles(0, rotation, 0)
                * CFrame.Angles(0, 0, segmentAngle + math.pi / 2)
            archPart.Parent = folder
        end
    end
end

-- Build support pillars at the ends of the bridge
function BridgeBuilder:_buildPillars(
    centerX: number,
    centerZ: number,
    deckY: number,
    bridgeWidth: number,
    _bridgeLength: number,
    rotation: number,
    riverFloorY: number,
    folder: Folder
): ()
    local halfWidth = bridgeWidth / 2

    -- Calculate pillar positions (on both sides of the bridge)
    local perpX = math.cos(rotation)
    local perpZ = -math.sin(rotation)

    local pillarHeight = deckY - riverFloorY

    -- Left pillar
    local leftX = centerX + halfWidth * perpX
    local leftZ = centerZ + halfWidth * perpZ
    local leftPillar = self:_createPart(
        "BridgePillarLeft",
        Vector3.new(leftX, riverFloorY + pillarHeight / 2, leftZ),
        Vector3.new(PILLAR_WIDTH, pillarHeight, PILLAR_DEPTH),
        STONE_COLOR,
        rotation
    )
    leftPillar.Parent = folder

    -- Right pillar
    local rightX = centerX - halfWidth * perpX
    local rightZ = centerZ - halfWidth * perpZ
    local rightPillar = self:_createPart(
        "BridgePillarRight",
        Vector3.new(rightX, riverFloorY + pillarHeight / 2, rightZ),
        Vector3.new(PILLAR_WIDTH, pillarHeight, PILLAR_DEPTH),
        STONE_COLOR,
        rotation
    )
    rightPillar.Parent = folder
end

-- Build a single bridge at an intersection point
function BridgeBuilder:_buildBridge(
    intersection: Intersection,
    bridgeIndex: number,
    folder: Folder
): ()
    local point = intersection.point
    local direction = intersection.roadDirection
    local roadWidth = intersection.roadWidth

    -- Get river width for bridge length
    local riverWidth = self.worldPlan:getRiverWidth()

    -- Bridge dimensions
    local bridgeWidth = riverWidth + 20 -- Extra length to span the river banks
    local bridgeLength = roadWidth -- Width of the bridge deck matches road width
    local rotation = math.atan2(direction.X, direction.Y)

    -- Query terrain height at intersection
    local terrainY = TerrainUtils.getHeightAt(self.terrain, point.X, point.Y)

    -- Calculate deck Y position (above water level)
    local deckY = terrainY + BRIDGE_HEIGHT

    -- River floor estimate (using shared constant from RiverBuilder)
    local riverFloorY = terrainY - RiverBuilder.WALL_HEIGHT

    -- Create bridge folder for organization
    local bridgeFolder = Instance.new("Folder")
    bridgeFolder.Name = string.format("Bridge_%d", bridgeIndex)
    bridgeFolder.Parent = folder

    -- Build main deck
    local deck = self:_createPart(
        "BridgeDeck",
        Vector3.new(point.X, deckY, point.Y),
        Vector3.new(bridgeLength, DECK_THICKNESS, bridgeWidth),
        STONE_COLOR,
        rotation
    )
    deck.TopSurface = Enum.SurfaceType.Smooth
    deck.Parent = bridgeFolder

    -- Build railings
    local railingY = deckY + DECK_THICKNESS / 2 + RAILING_HEIGHT / 2
    local halfLength = bridgeLength / 2 - RAILING_THICKNESS / 2

    -- Left railing
    local leftRailingX = point.X + math.cos(rotation) * halfLength
    local leftRailingZ = point.Y - math.sin(rotation) * halfLength
    local leftRailing = self:_createPart(
        "BridgeRailingLeft",
        Vector3.new(leftRailingX, railingY, leftRailingZ),
        Vector3.new(RAILING_THICKNESS, RAILING_HEIGHT, bridgeWidth),
        RAILING_COLOR,
        rotation
    )
    leftRailing.Parent = bridgeFolder

    -- Right railing
    local rightRailingX = point.X - math.cos(rotation) * halfLength
    local rightRailingZ = point.Y + math.sin(rotation) * halfLength
    local rightRailing = self:_createPart(
        "BridgeRailingRight",
        Vector3.new(rightRailingX, railingY, rightRailingZ),
        Vector3.new(RAILING_THICKNESS, RAILING_HEIGHT, bridgeWidth),
        RAILING_COLOR,
        rotation
    )
    rightRailing.Parent = bridgeFolder

    -- Build support pillars
    self:_buildPillars(
        point.X,
        point.Y,
        deckY - DECK_THICKNESS / 2,
        bridgeWidth,
        bridgeLength,
        rotation,
        riverFloorY,
        bridgeFolder
    )

    -- Build decorative arch
    local archY = riverFloorY + 2 -- Slightly above river floor
    self:_buildArch(
        point.X,
        point.Y,
        archY,
        bridgeWidth,
        bridgeLength,
        rotation,
        bridgeFolder
    )

    print(string.format("[BridgeBuilder v%s] Built bridge %d at (%.1f, %.1f)",
        BridgeBuilder.VERSION,
        bridgeIndex,
        point.X,
        point.Y
    ))
end

-- Build all bridges at road/river intersections
function BridgeBuilder:build(): Folder
    local startTime = tick()

    print(string.format("[BridgeBuilder v%s] Building bridges at road/river intersections...",
        BridgeBuilder.VERSION
    ))

    -- Create main folder for all bridges
    local folder = Instance.new("Folder")
    folder.Name = "Bridges_Pontes"
    folder.Parent = workspace
    self.folder = folder

    -- Find all intersections
    self.intersections = self:_findIntersections()

    -- Build a bridge at each intersection
    for i, intersection in ipairs(self.intersections) do
        self:_buildBridge(intersection, i, folder)

        -- Yield periodically to avoid script timeout
        if i % 2 == 0 then
            task.wait()
        end
    end

    local elapsed = tick() - startTime
    print(string.format("[BridgeBuilder v%s] Built %d bridges in %.2f seconds (%d parts)",
        BridgeBuilder.VERSION,
        #self.intersections,
        elapsed,
        #self.parts
    ))

    return folder
end

-- Get the number of bridges built
function BridgeBuilder:getBridgeCount(): number
    return #self.intersections
end

-- Get all intersection points
function BridgeBuilder:getIntersections(): { Intersection }
    return self.intersections
end

-- Destroy all bridges
function BridgeBuilder:destroy(): ()
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end

    self.parts = {}
    self.intersections = {}

    print(string.format("[BridgeBuilder v%s] All bridges destroyed", BridgeBuilder.VERSION))
end

return BridgeBuilder

