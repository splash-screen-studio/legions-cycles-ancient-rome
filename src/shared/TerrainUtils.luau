--!strict
--[[
    TerrainUtils - Terrain height queries and slope calculations
    CRITICAL: All placed objects must query terrain height at their X,Z position
    Based on BRicey Vector3 Math techniques
]]

local TerrainUtils = {}

local DEFAULT_RAY_HEIGHT = 10000
local DEFAULT_RAY_LENGTH = 20000
local DEFAULT_SAMPLE_DISTANCE = 1

--- Raycast to find terrain height at a given X,Z position
function TerrainUtils.getHeightAt(terrain: Terrain, x: number, z: number): number
    local origin = Vector3.new(x, DEFAULT_RAY_HEIGHT, z)
    local direction = Vector3.new(0, -DEFAULT_RAY_LENGTH, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { terrain }

    local result = workspace:Raycast(origin, direction, raycastParams)
    return if result then result.Position.Y else 0
end

--- Get terrain height with a custom workspace reference (for testing)
function TerrainUtils.getHeightAtWithWorkspace(
    terrain: Terrain,
    x: number,
    z: number,
    workspaceRef: Workspace
): number
    local origin = Vector3.new(x, DEFAULT_RAY_HEIGHT, z)
    local direction = Vector3.new(0, -DEFAULT_RAY_LENGTH, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { terrain }

    local result = workspaceRef:Raycast(origin, direction, raycastParams)
    return if result then result.Position.Y else 0
end

--- Get the slope angle (in radians) at a position by sampling nearby heights
function TerrainUtils.getSlopeAt(terrain: Terrain, x: number, z: number, sampleDistance: number?): number
    local dist = sampleDistance or DEFAULT_SAMPLE_DISTANCE

    local h1 = TerrainUtils.getHeightAt(terrain, x - dist, z)
    local h2 = TerrainUtils.getHeightAt(terrain, x + dist, z)

    return math.atan2(h2 - h1, dist * 2)
end

--- Get the slope in both X and Z directions
function TerrainUtils.getSlopeXZ(
    terrain: Terrain,
    x: number,
    z: number,
    sampleDistance: number?
): (number, number)
    local dist = sampleDistance or DEFAULT_SAMPLE_DISTANCE

    local hXNeg = TerrainUtils.getHeightAt(terrain, x - dist, z)
    local hXPos = TerrainUtils.getHeightAt(terrain, x + dist, z)
    local hZNeg = TerrainUtils.getHeightAt(terrain, x, z - dist)
    local hZPos = TerrainUtils.getHeightAt(terrain, x, z + dist)

    local slopeX = math.atan2(hXPos - hXNeg, dist * 2)
    local slopeZ = math.atan2(hZPos - hZNeg, dist * 2)

    return slopeX, slopeZ
end

--- Get the terrain normal vector at a position
function TerrainUtils.getNormalAt(terrain: Terrain, x: number, z: number, sampleDistance: number?): Vector3
    local dist = sampleDistance or DEFAULT_SAMPLE_DISTANCE

    local hCenter = TerrainUtils.getHeightAt(terrain, x, z)
    local hXPos = TerrainUtils.getHeightAt(terrain, x + dist, z)
    local hZPos = TerrainUtils.getHeightAt(terrain, x, z + dist)

    local vecX = Vector3.new(dist, hXPos - hCenter, 0)
    local vecZ = Vector3.new(0, hZPos - hCenter, dist)

    return vecZ:Cross(vecX).Unit
end

--- Create a CFrame at a position aligned to terrain slope
function TerrainUtils.getCFrameAlignedToTerrain(terrain: Terrain, x: number, z: number): CFrame
    local y = TerrainUtils.getHeightAt(terrain, x, z)
    local normal = TerrainUtils.getNormalAt(terrain, x, z)

    local position = Vector3.new(x, y, z)
    local up = normal
    local forward = Vector3.new(0, 0, 1)

    -- Project forward onto the plane perpendicular to up
    forward = (forward - up * forward:Dot(up)).Unit

    local right = forward:Cross(up).Unit
    forward = up:Cross(right).Unit

    return CFrame.fromMatrix(position, right, up, -forward)
end

--- Check if terrain at a position is flat enough for building (slope in radians)
function TerrainUtils.isFlatEnough(terrain: Terrain, x: number, z: number, maxSlopeRadians: number): boolean
    local slopeX, slopeZ = TerrainUtils.getSlopeXZ(terrain, x, z)
    return math.abs(slopeX) <= maxSlopeRadians and math.abs(slopeZ) <= maxSlopeRadians
end

--- Get the average height across multiple sample points
function TerrainUtils.getAverageHeight(terrain: Terrain, x: number, z: number, radius: number, samples: number?): number
    local numSamples = samples or 4
    local totalHeight = TerrainUtils.getHeightAt(terrain, x, z)
    local count = 1

    for i = 1, numSamples do
        local angle = (i / numSamples) * math.pi * 2
        local sampleX = x + math.cos(angle) * radius
        local sampleZ = z + math.sin(angle) * radius
        totalHeight = totalHeight + TerrainUtils.getHeightAt(terrain, sampleX, sampleZ)
        count = count + 1
    end

    return totalHeight / count
end

return TerrainUtils
