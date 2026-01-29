--!strict
--[[
    SignpostBuilder - Creates Roman-style signposts for navigation

    Builds navigation aids throughout the world:
    - Direction posts at road intersections (pointing to nearby landmarks)
    - District signs at zone entrances
    - Milestones along major roads

    Roman authentic design:
    - Stone pillars with carved text
    - Bronze plaques on marble base
    - Directional arms pointing toward destinations

    Based on BRicey procedural generation techniques for environment decoration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))

local SignpostBuilder = {}
SignpostBuilder.__index = SignpostBuilder
SignpostBuilder.VERSION = "1.1.0"

-- Roman architectural colors
local MARBLE_WHITE = Color3.fromRGB(240, 235, 225)
local MARBLE_CREAM = Color3.fromRGB(230, 220, 200)
local STONE_GRAY = Color3.fromRGB(160, 155, 145)
local BRONZE = Color3.fromRGB(180, 140, 80)
local _TERRACOTTA = Color3.fromRGB(180, 100, 70) -- Reserved for future shop signs
local WOOD_BROWN = Color3.fromRGB(120, 80, 50)

-- Signpost dimensions
local PILLAR_WIDTH = 2
local PILLAR_HEIGHT = 8
local ARM_LENGTH = 6
local ARM_HEIGHT = 1
local ARM_DEPTH = 0.5
local BASE_SIZE = 3
local BASE_HEIGHT = 1

-- Text configuration
local _TEXT_SIZE = 24 -- Reserved for future font size configuration
local TEXT_COLOR = Color3.fromRGB(255, 250, 230) -- Cream/off-white for contrast on wood

-- Placement configuration
local MILESTONE_SPACING = 100 -- Studs between milestones
local MIN_INTERSECTION_DISTANCE = 30 -- Min distance for road segments to count as intersection
local DIRECTION_POST_SEARCH_RADIUS = 300 -- How far to look for landmarks from direction posts

export type SignpostBuilderConfig = {
    worldPlan: WorldPlan.WorldPlanInstance,
}

export type SignpostBuilderInstance = typeof(setmetatable(
    {} :: {
        worldPlan: WorldPlan.WorldPlanInstance,
        terrain: Terrain,
        folder: Folder?,
        parts: { BasePart },
        signpostCount: number,
    },
    SignpostBuilder
))

function SignpostBuilder.new(config: SignpostBuilderConfig): SignpostBuilderInstance
    local self = setmetatable({}, SignpostBuilder)
    self.worldPlan = config.worldPlan
    self.terrain = workspace.Terrain
    self.folder = nil
    self.parts = {}
    self.signpostCount = 0

    print(string.format("[SignpostBuilder v%s] Initializing...", SignpostBuilder.VERSION))
    return self
end

-- Helper: Create a basic part
function SignpostBuilder:_createPart(
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

-- Helper: Create text on a surface using SurfaceGui
function SignpostBuilder:_createSurfaceText(
    parent: BasePart,
    text: string,
    face: Enum.NormalId,
    textColor: Color3?
): SurfaceGui
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "SignText"
    surfaceGui.Face = face
    surfaceGui.Adornee = parent
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = textColor or TEXT_COLOR
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Antique
    textLabel.TextStrokeTransparency = 0.3
    textLabel.TextStrokeColor3 = Color3.fromRGB(40, 30, 20) -- Dark outline for readability
    textLabel.Parent = surfaceGui

    surfaceGui.Parent = parent
    return surfaceGui
end

-- Helper: Create a BillboardGui for text visible from any angle
function SignpostBuilder:_createBillboardText(
    parent: BasePart,
    text: string,
    offset: Vector3,
    size: UDim2?
): BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "SignBillboard"
    billboardGui.Adornee = parent
    billboardGui.Size = size or UDim2.new(8, 0, 2, 0)
    billboardGui.StudsOffset = offset
    billboardGui.AlwaysOnTop = false
    billboardGui.MaxDistance = 200

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = TEXT_COLOR
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Antique
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextStrokeColor3 = MARBLE_CREAM
    textLabel.Parent = billboardGui

    billboardGui.Parent = parent
    return billboardGui
end

-- Create a stone pillar base for signposts
function SignpostBuilder:_createPillarBase(
    centerX: number,
    baseY: number,
    centerZ: number,
    folder: Folder
): Part
    -- Square base
    local base = self:_createPart(
        "SignpostBase",
        Vector3.new(centerX, baseY + BASE_HEIGHT / 2, centerZ),
        Vector3.new(BASE_SIZE, BASE_HEIGHT, BASE_SIZE),
        MARBLE_CREAM
    )
    base.Parent = folder

    -- Main pillar
    local pillar = self:_createPart(
        "SignpostPillar",
        Vector3.new(centerX, baseY + BASE_HEIGHT + PILLAR_HEIGHT / 2, centerZ),
        Vector3.new(PILLAR_WIDTH, PILLAR_HEIGHT, PILLAR_WIDTH),
        STONE_GRAY,
        Enum.Material.Slate
    )
    pillar.Parent = folder

    -- Decorative capital on top
    local capital = self:_createPart(
        "SignpostCapital",
        Vector3.new(centerX, baseY + BASE_HEIGHT + PILLAR_HEIGHT + 0.5, centerZ),
        Vector3.new(PILLAR_WIDTH * 1.5, 1, PILLAR_WIDTH * 1.5),
        MARBLE_WHITE
    )
    capital.Parent = folder

    return pillar
end

-- Create a directional arm pointing in a specific direction
function SignpostBuilder:_createDirectionalArm(
    pillar: Part,
    direction: Vector2,
    text: string,
    armIndex: number,
    folder: Folder
): Part
    local pillarPos = pillar.Position
    local armY = pillarPos.Y + PILLAR_HEIGHT / 2 - armIndex * (ARM_HEIGHT + 0.5)

    -- Normalize direction and calculate rotation
    local dirMagnitude = direction.Magnitude
    if dirMagnitude < 0.001 then
        direction = Vector2.new(1, 0)
    else
        direction = direction / dirMagnitude
    end

    local angle = math.atan2(direction.Y, direction.X)

    -- Create arm with arrow shape pointing in the direction
    local armCenterX = pillarPos.X + direction.X * (ARM_LENGTH / 2 + PILLAR_WIDTH / 2)
    local armCenterZ = pillarPos.Z + direction.Y * (ARM_LENGTH / 2 + PILLAR_WIDTH / 2)

    local arm = self:_createPart(
        "DirectionalArm_" .. text,
        Vector3.new(armCenterX, armY, armCenterZ),
        Vector3.new(ARM_LENGTH, ARM_HEIGHT, ARM_DEPTH),
        WOOD_BROWN,
        Enum.Material.Wood
    )

    -- Rotate arm to point in direction
    arm.CFrame = CFrame.new(arm.Position) * CFrame.Angles(0, -angle, 0)
    arm.Parent = folder

    -- Arrow head at the end
    local arrowX = pillarPos.X + direction.X * (ARM_LENGTH + PILLAR_WIDTH / 2)
    local arrowZ = pillarPos.Z + direction.Y * (ARM_LENGTH + PILLAR_WIDTH / 2)

    local arrow = self:_createPart(
        "Arrow_" .. text,
        Vector3.new(arrowX, armY, arrowZ),
        Vector3.new(1.5, ARM_HEIGHT, 1.5),
        BRONZE,
        Enum.Material.Metal
    )
    -- Rotate arrow to point outward (45 degree diamond shape)
    arrow.CFrame = CFrame.new(arrow.Position) * CFrame.Angles(0, math.rad(45) - angle, 0)
    arrow.Parent = folder

    -- Add text to both sides of the arm (Front and Back) for readability
    self:_createSurfaceText(arm, text, Enum.NormalId.Front)
    self:_createSurfaceText(arm, text, Enum.NormalId.Back)

    return arm
end

-- Create a direction post at a location pointing to nearby landmarks
function SignpostBuilder:_createDirectionPost(
    centerX: number,
    centerZ: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)
    local pillar = self:_createPillarBase(centerX, terrainY, centerZ, folder)

    -- Find nearby landmarks to point to
    local landmarks = self.worldPlan:getLandmarks()
    local nearbyLandmarks: { { name: string, direction: Vector2, distance: number } } = {}

    local postPos = Vector2.new(centerX, centerZ)

    for _, landmark in ipairs(landmarks) do
        local distance = (landmark.position - postPos).Magnitude
        if distance <= DIRECTION_POST_SEARCH_RADIUS and distance > 20 then
            local direction = landmark.position - postPos
            table.insert(nearbyLandmarks, {
                name = self:_getLandmarkDisplayName(landmark.landmarkType),
                direction = direction,
                distance = distance,
            })
        end
    end

    -- Sort by distance (closest first) and take up to 4
    table.sort(nearbyLandmarks, function(a, b)
        return a.distance < b.distance
    end)

    local maxArms = math.min(4, #nearbyLandmarks)
    for i = 1, maxArms do
        local landmarkInfo = nearbyLandmarks[i]
        local distanceText = string.format("%s", landmarkInfo.name)
        self:_createDirectionalArm(pillar, landmarkInfo.direction, distanceText, i, folder)
    end

    self.signpostCount = self.signpostCount + 1
end

-- Get display name for landmark type (Latin names where appropriate)
function SignpostBuilder:_getLandmarkDisplayName(landmarkType: string): string
    local displayNames: { [string]: string } = {
        Forum = "FORUM",
        Colosseum = "AMPHITHEATRVM",
        Thermae = "THERMAE",
        Temple = "TEMPLVM",
        CircusMaximus = "CIRCVS",
        Castrum = "CASTRA",
        Macellum = "MACELLVM",
        Horreum = "HORREVM",
        Pharos = "PHAROS",
        Emporium = "EMPORIVM",
        VillaRustica = "VILLA",
        PalaestraMinor = "PALAESTRA",
        Granarium = "GRANARIVM",
        ThermaeMinor = "BALNEA",
        ForumPiscarium = "PISCARIVM",
        TempleMars = "T. MARTIS",
        TempleNeptune = "T. NEPTVNI",
        SacellumCeres = "S. CERERIS",
    }

    return displayNames[landmarkType] or landmarkType:upper()
end

-- Create a milestone marker along a road
function SignpostBuilder:_createMilestone(
    centerX: number,
    centerZ: number,
    distance: number,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Simple stone column milestone
    local milestone = self:_createPart(
        "Milestone",
        Vector3.new(centerX, terrainY + 3, centerZ),
        Vector3.new(1.5, 6, 1.5),
        STONE_GRAY,
        Enum.Material.Slate
    )
    milestone.Parent = folder

    -- Base
    local base = self:_createPart(
        "MilestoneBase",
        Vector3.new(centerX, terrainY + 0.25, centerZ),
        Vector3.new(2.5, 0.5, 2.5),
        MARBLE_CREAM
    )
    base.Parent = folder

    -- Distance marker text (Roman numerals would be ideal but using numbers for readability)
    local distanceStud = math.floor(distance)
    local text = string.format("%d", distanceStud)
    self:_createBillboardText(milestone, text, Vector3.new(0, 3, 0), UDim2.new(2, 0, 1, 0))

    self.signpostCount = self.signpostCount + 1
end

-- Create a district/zone entrance sign
function SignpostBuilder:_createDistrictSign(
    centerX: number,
    centerZ: number,
    zoneName: string,
    folder: Folder
): ()
    local terrainY = TerrainUtils.getHeightAt(self.terrain, centerX, centerZ)

    -- Large stone sign with bronze plaque
    local base = self:_createPart(
        "DistrictSignBase",
        Vector3.new(centerX, terrainY + 1, centerZ),
        Vector3.new(5, 2, 2),
        MARBLE_CREAM
    )
    base.Parent = folder

    -- Main sign stone
    local sign = self:_createPart(
        "DistrictSign",
        Vector3.new(centerX, terrainY + 5, centerZ),
        Vector3.new(8, 4, 1),
        MARBLE_WHITE
    )
    sign.Parent = folder

    -- Bronze plaque
    local plaque = self:_createPart(
        "DistrictPlaque",
        Vector3.new(centerX, terrainY + 5, centerZ + 0.55),
        Vector3.new(7, 3, 0.1),
        BRONZE,
        Enum.Material.Metal
    )
    plaque.Parent = folder

    -- Supporting columns
    for offset = -3, 3, 6 do
        local column = self:_createPart(
            "DistrictColumn",
            Vector3.new(centerX + offset, terrainY + 3.5, centerZ),
            Vector3.new(1, 5, 1),
            STONE_GRAY,
            Enum.Material.Slate
        )
        column.Parent = folder
    end

    -- Zone name text
    self:_createSurfaceText(plaque, zoneName, Enum.NormalId.Front, MARBLE_CREAM)

    self.signpostCount = self.signpostCount + 1
end

-- Find road intersections for direction post placement
function SignpostBuilder:_findRoadIntersections(): { Vector2 }
    local intersections: { Vector2 } = {}
    local roads = self.worldPlan:getRoads()

    -- Check each pair of roads for intersections
    for i = 1, #roads do
        for j = i + 1, #roads do
            local road1 = roads[i]
            local road2 = roads[j]

            -- Check all path segments against each other
            for s1 = 1, #road1.path - 1 do
                for s2 = 1, #road2.path - 1 do
                    local intersection = self:_findSegmentIntersection(
                        road1.path[s1],
                        road1.path[s1 + 1],
                        road2.path[s2],
                        road2.path[s2 + 1]
                    )

                    if intersection then
                        -- Check this intersection isn't too close to existing ones
                        local tooClose = false
                        for _, existing in ipairs(intersections) do
                            if (existing - intersection).Magnitude < MIN_INTERSECTION_DISTANCE then
                                tooClose = true
                                break
                            end
                        end

                        if not tooClose then
                            table.insert(intersections, intersection)
                        end
                    end
                end
            end
        end
    end

    return intersections
end

-- Find intersection point of two line segments (2D)
function SignpostBuilder:_findSegmentIntersection(
    p1: Vector2,
    p2: Vector2,
    p3: Vector2,
    p4: Vector2
): Vector2?
    local x1, y1, x2, y2 = p1.X, p1.Y, p2.X, p2.Y
    local x3, y3, x4, y4 = p3.X, p3.Y, p4.X, p4.Y

    local denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)

    -- Lines are parallel
    if math.abs(denom) < 0.001 then
        return nil
    end

    local t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
    local u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom

    -- Check if intersection is within both segments
    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        local intersectX = x1 + t * (x2 - x1)
        local intersectY = y1 + t * (y2 - y1)
        return Vector2.new(intersectX, intersectY)
    end

    return nil
end

-- Place milestones along all major roads (Via type)
function SignpostBuilder:_placeMilestones(folder: Folder): ()
    local roads = self.worldPlan:getRoads()

    for _, road in ipairs(roads) do
        -- Only place milestones on major roads (Via)
        if road.roadType == "via" then
            self:_placeMilestonesAlongPath(road.path, road.width, folder)
        end
    end
end

-- Place milestones along a road path
function SignpostBuilder:_placeMilestonesAlongPath(
    path: { Vector2 },
    roadWidth: number,
    folder: Folder
): ()
    if #path < 2 then
        return
    end

    local totalDistance = 0
    local lastMilestoneDistance = 0

    for i = 1, #path - 1 do
        local segStart = path[i]
        local segEnd = path[i + 1]
        local segVec = segEnd - segStart
        local segLength = segVec.Magnitude

        -- Walk along segment placing milestones
        local segDir = if segLength > 0.001 then segVec / segLength else Vector2.new(1, 0)

        -- Perpendicular offset to place milestone beside road
        local perpDir = Vector2.new(-segDir.Y, segDir.X)
        local offsetAmount = roadWidth / 2 + 3 -- Place beside road

        local distanceAlongSegment = 0
        while distanceAlongSegment < segLength do
            local currentTotalDistance = totalDistance + distanceAlongSegment

            if currentTotalDistance - lastMilestoneDistance >= MILESTONE_SPACING then
                -- Place milestone here
                local posOnRoad = segStart + segDir * distanceAlongSegment
                local milestonePos = posOnRoad + perpDir * offsetAmount

                self:_createMilestone(milestonePos.X, milestonePos.Y, currentTotalDistance, folder)
                lastMilestoneDistance = currentTotalDistance
            end

            distanceAlongSegment = distanceAlongSegment + 10 -- Check every 10 studs
        end

        totalDistance = totalDistance + segLength
    end
end

-- Place district signs at zone entrances
function SignpostBuilder:_placeDistrictSigns(folder: Folder): ()
    local zones = self.worldPlan:getZones()
    local roads = self.worldPlan:getRoads()

    -- Get unique zone types with their positions
    local zoneTypes: { [string]: Vector2 } = {}
    for _, zone in ipairs(zones) do
        if zone.zoneType == "civic" or zone.zoneType == "urban" then
            -- Only take one position per zone type (the first one)
            if not zoneTypes[zone.zoneType .. "_" .. tostring(zone.center.X)] then
                zoneTypes[zone.zoneType .. "_" .. tostring(zone.center.X)] = zone.center
            end
        end
    end

    -- Find where roads enter urban zones and place signs
    for _, road in ipairs(roads) do
        if #road.path >= 2 then
            -- Check road start and end points for zone transitions
            local startPos = road.path[1]
            local endPos = road.path[#road.path]

            local startZone = self.worldPlan:getZoneAt(startPos.X, startPos.Y)
            local endZone = self.worldPlan:getZoneAt(endPos.X, endPos.Y)

            -- Place sign if entering urban/civic from non-urban
            if (startZone == "wilderness" or startZone == "rural") and (endZone == "urban" or endZone == "civic") then
                local zoneName = self:_getZoneDisplayName(endZone)
                local signPos = road.path[math.ceil(#road.path / 2)] -- Middle of road
                self:_createDistrictSign(signPos.X, signPos.Y, zoneName, folder)
            end
        end
    end
end

-- Get display name for zone type
function SignpostBuilder:_getZoneDisplayName(zoneType: string): string
    local displayNames: { [string]: string } = {
        civic = "FORA ROMANA",
        urban = "VRBS ROMA",
        rural = "RVS ROMANVM",
        wilderness = "SILVA",
    }

    return displayNames[zoneType] or zoneType:upper()
end

-- Build all signposts from WorldPlan
function SignpostBuilder:build(): Folder
    local startTime = tick()

    print(string.format("[SignpostBuilder v%s] Building signposts from WorldPlan...",
        SignpostBuilder.VERSION
    ))

    -- Create main folder for all signposts
    local folder = Instance.new("Folder")
    folder.Name = "Signposts_Columnae"
    folder.Parent = workspace
    self.folder = folder

    -- Create subfolders for organization
    local directionPostsFolder = Instance.new("Folder")
    directionPostsFolder.Name = "DirectionPosts"
    directionPostsFolder.Parent = folder

    local milestonesFolder = Instance.new("Folder")
    milestonesFolder.Name = "Milestones"
    milestonesFolder.Parent = folder

    local districtSignsFolder = Instance.new("Folder")
    districtSignsFolder.Name = "DistrictSigns"
    districtSignsFolder.Parent = folder

    -- Step 1: Find and place direction posts at road intersections
    print(string.format("[SignpostBuilder v%s] Finding road intersections...", SignpostBuilder.VERSION))
    local intersections = self:_findRoadIntersections()

    for i, intersection in ipairs(intersections) do
        local postFolder = Instance.new("Folder")
        postFolder.Name = string.format("DirectionPost_%d", i)
        postFolder.Parent = directionPostsFolder

        self:_createDirectionPost(intersection.X, intersection.Y, postFolder)

        -- Yield periodically
        if i % 5 == 0 then
            task.wait()
        end
    end

    print(string.format("[SignpostBuilder v%s] Placed %d direction posts", SignpostBuilder.VERSION, #intersections))

    -- Step 2: Place milestones along major roads
    print(string.format("[SignpostBuilder v%s] Placing milestones...", SignpostBuilder.VERSION))
    self:_placeMilestones(milestonesFolder)

    -- Step 3: Place district signs at zone entrances
    print(string.format("[SignpostBuilder v%s] Placing district signs...", SignpostBuilder.VERSION))
    self:_placeDistrictSigns(districtSignsFolder)

    -- Step 4: Add direction posts near major landmarks
    print(string.format("[SignpostBuilder v%s] Adding landmark direction posts...", SignpostBuilder.VERSION))
    local landmarks = self.worldPlan:getLandmarks()

    -- Place direction posts near major landmarks (Forum, Colosseum, etc.)
    local majorLandmarks = { "Forum", "Colosseum", "Thermae", "CircusMaximus", "Castrum", "Emporium" }
    local landmarkPostCount = 0

    for _, landmark in ipairs(landmarks) do
        local isMajor = false
        for _, majorType in ipairs(majorLandmarks) do
            if landmark.landmarkType == majorType then
                isMajor = true
                break
            end
        end

        if isMajor then
            -- Place direction post at entrance (offset from landmark center)
            local offsetX = landmark.radius + 15
            local offsetZ = landmark.radius + 15

            local postFolder = Instance.new("Folder")
            postFolder.Name = string.format("LandmarkPost_%s", landmark.landmarkType)
            postFolder.Parent = directionPostsFolder

            self:_createDirectionPost(
                landmark.position.X + offsetX,
                landmark.position.Y + offsetZ,
                postFolder
            )

            landmarkPostCount = landmarkPostCount + 1
        end
    end

    print(string.format("[SignpostBuilder v%s] Placed %d landmark direction posts", SignpostBuilder.VERSION, landmarkPostCount))

    local elapsed = tick() - startTime
    print(string.format("[SignpostBuilder v%s] Built %d signposts in %.2f seconds (%d parts)",
        SignpostBuilder.VERSION,
        self.signpostCount,
        elapsed,
        #self.parts
    ))

    return folder
end

-- Get the number of signposts built
function SignpostBuilder:getSignpostCount(): number
    return self.signpostCount
end

-- Get all parts created
function SignpostBuilder:getParts(): { BasePart }
    return self.parts
end

-- Destroy all signposts
function SignpostBuilder:destroy(): ()
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end

    self.parts = {}
    self.signpostCount = 0

    print(string.format("[SignpostBuilder v%s] All signposts destroyed", SignpostBuilder.VERSION))
end

return SignpostBuilder
