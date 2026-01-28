--!strict
--[[
    WorldPlan - Single source of truth for map layout
    Defines the abstract plan for world generation that all systems query.

    This is created FIRST, before any generation, and provides:
    - River path (source of truth for water)
    - Zones (urban, rural, civic, wilderness)
    - Landmark positions
    - Road network
    - Player plot areas
]]

local WorldPlan = {}
WorldPlan.__index = WorldPlan
WorldPlan.VERSION = "1.0.0"

-- Type definitions for the world plan data
export type ZoneType = "urban" | "rural" | "civic" | "wilderness"

export type Zone = {
    center: Vector2,
    radius: number,
    zoneType: ZoneType,
}

export type Landmark = {
    position: Vector2,
    landmarkType: string,
    radius: number,
}

export type Road = {
    path: { Vector2 },
    width: number,
    roadType: "via" | "path",
}

export type PlayerPlot = {
    center: Vector2,
    size: Vector2,
}

export type TerrainContext = {
    zone: ZoneType,
    distanceToRiver: number,
    distanceToRoad: number,
    nearestLandmark: string?,
    distanceToLandmark: number?,
}

export type WorldPlanData = {
    -- River path (source of truth for water)
    riverPath: { Vector2 },
    riverWidth: number,

    -- Zones (source of truth for urban/rural)
    zones: { Zone },

    -- Landmark positions (source of truth for major structures)
    landmarks: { Landmark },

    -- Road network (source of truth for paths)
    roads: { Road },

    -- Player plot areas
    playerPlots: { PlayerPlot },

    -- Map dimensions
    mapSize: number,
}

export type WorldPlanInstance = typeof(setmetatable(
    {} :: {
        data: WorldPlanData,
    },
    WorldPlan
))

-- Helper function to calculate distance from point to line segment
local function distanceToLineSegment(point: Vector2, lineStart: Vector2, lineEnd: Vector2): number
    local lineVec = lineEnd - lineStart
    local lineLen = lineVec.Magnitude

    if lineLen < 0.001 then
        return (point - lineStart).Magnitude
    end

    local lineDir = lineVec / lineLen
    local pointVec = point - lineStart
    local projection = pointVec:Dot(lineDir)

    if projection < 0 then
        return (point - lineStart).Magnitude
    elseif projection > lineLen then
        return (point - lineEnd).Magnitude
    else
        local closestPoint = lineStart + lineDir * projection
        return (point - closestPoint).Magnitude
    end
end

-- Helper function to calculate distance from point to a path (series of line segments)
local function distanceToPath(point: Vector2, path: { Vector2 }): number
    if #path == 0 then
        return math.huge
    end

    if #path == 1 then
        return (point - path[1]).Magnitude
    end

    local minDistance = math.huge
    for i = 1, #path - 1 do
        local dist = distanceToLineSegment(point, path[i], path[i + 1])
        if dist < minDistance then
            minDistance = dist
        end
    end

    return minDistance
end

-- Create a new WorldPlan instance from data
function WorldPlan.new(data: WorldPlanData): WorldPlanInstance
    local self = setmetatable({}, WorldPlan)
    self.data = data
    print(string.format("[WorldPlan v%s] Created with %d zones, %d landmarks, %d roads",
        WorldPlan.VERSION,
        #data.zones,
        #data.landmarks,
        #data.roads
    ))
    return self
end

-- River queries
function WorldPlan.getRiverPath(self: WorldPlanInstance): { Vector2 }
    return self.data.riverPath
end

function WorldPlan.getRiverWidth(self: WorldPlanInstance): number
    return self.data.riverWidth
end

function WorldPlan.isOnRiver(self: WorldPlanInstance, x: number, z: number): boolean
    local point = Vector2.new(x, z)
    local distance = distanceToPath(point, self.data.riverPath)
    return distance <= (self.data.riverWidth / 2)
end

function WorldPlan.getDistanceToRiver(self: WorldPlanInstance, x: number, z: number): number
    local point = Vector2.new(x, z)
    return distanceToPath(point, self.data.riverPath)
end

-- Zone queries
function WorldPlan.getZoneAt(self: WorldPlanInstance, x: number, z: number): ZoneType
    local point = Vector2.new(x, z)

    -- Check each zone, return the first one that contains the point
    -- Zones are checked in order, so earlier zones have priority
    for _, zone in ipairs(self.data.zones) do
        local distance = (point - zone.center).Magnitude
        if distance <= zone.radius then
            return zone.zoneType
        end
    end

    -- Default to wilderness if not in any defined zone
    return "wilderness"
end

function WorldPlan.isUrban(self: WorldPlanInstance, x: number, z: number): boolean
    local zone = self:getZoneAt(x, z)
    return zone == "urban" or zone == "civic"
end

function WorldPlan.isRural(self: WorldPlanInstance, x: number, z: number): boolean
    return self:getZoneAt(x, z) == "rural"
end

function WorldPlan.getZones(self: WorldPlanInstance): { Zone }
    return self.data.zones
end

-- Landmark queries
function WorldPlan.getLandmarks(self: WorldPlanInstance): { Landmark }
    return self.data.landmarks
end

function WorldPlan.getNearestLandmark(self: WorldPlanInstance, x: number, z: number): { landmarkType: string, distance: number }?
    local point = Vector2.new(x, z)
    local nearest: { landmarkType: string, distance: number }? = nil
    local minDistance = math.huge

    for _, landmark in ipairs(self.data.landmarks) do
        local distance = (point - landmark.position).Magnitude
        if distance < minDistance then
            minDistance = distance
            nearest = {
                landmarkType = landmark.landmarkType,
                distance = distance,
            }
        end
    end

    return nearest
end

function WorldPlan.isNearLandmark(self: WorldPlanInstance, x: number, z: number, searchRadius: number): boolean
    local point = Vector2.new(x, z)

    for _, landmark in ipairs(self.data.landmarks) do
        local distance = (point - landmark.position).Magnitude
        if distance <= searchRadius + landmark.radius then
            return true
        end
    end

    return false
end

function WorldPlan.getLandmarkAt(self: WorldPlanInstance, x: number, z: number): Landmark?
    local point = Vector2.new(x, z)

    for _, landmark in ipairs(self.data.landmarks) do
        local distance = (point - landmark.position).Magnitude
        if distance <= landmark.radius then
            return landmark
        end
    end

    return nil
end

-- Road queries
function WorldPlan.getRoads(self: WorldPlanInstance): { Road }
    return self.data.roads
end

function WorldPlan.isOnRoad(self: WorldPlanInstance, x: number, z: number): boolean
    local point = Vector2.new(x, z)

    for _, road in ipairs(self.data.roads) do
        local distance = distanceToPath(point, road.path)
        if distance <= (road.width / 2) then
            return true
        end
    end

    return false
end

function WorldPlan.getDistanceToRoad(self: WorldPlanInstance, x: number, z: number): number
    local point = Vector2.new(x, z)
    local minDistance = math.huge

    for _, road in ipairs(self.data.roads) do
        local distance = distanceToPath(point, road.path)
        if distance < minDistance then
            minDistance = distance
        end
    end

    return minDistance
end

-- Player plot queries
function WorldPlan.getPlayerPlots(self: WorldPlanInstance): { PlayerPlot }
    return self.data.playerPlots
end

function WorldPlan.isInPlayerPlot(self: WorldPlanInstance, x: number, z: number): boolean
    local point = Vector2.new(x, z)

    for _, plot in ipairs(self.data.playerPlots) do
        local halfSize = plot.size / 2
        local minX = plot.center.X - halfSize.X
        local maxX = plot.center.X + halfSize.X
        local minZ = plot.center.Y - halfSize.Y -- Vector2 Y is world Z
        local maxZ = plot.center.Y + halfSize.Y

        if point.X >= minX and point.X <= maxX and point.Y >= minZ and point.Y <= maxZ then
            return true
        end
    end

    return false
end

-- Combined queries
function WorldPlan.canPlaceStructure(self: WorldPlanInstance, x: number, z: number, size: Vector2): (boolean, string?)
    -- Check if position is on river
    if self:isOnRiver(x, z) then
        return false, "Cannot place on river"
    end

    -- Check corners and center for river collision
    local halfSize = size / 2
    local checkPoints = {
        Vector2.new(x - halfSize.X, z - halfSize.Y),
        Vector2.new(x + halfSize.X, z - halfSize.Y),
        Vector2.new(x - halfSize.X, z + halfSize.Y),
        Vector2.new(x + halfSize.X, z + halfSize.Y),
    }

    for _, point in ipairs(checkPoints) do
        if self:isOnRiver(point.X, point.Y) then
            return false, "Structure would overlap river"
        end
    end

    -- Check if inside a landmark exclusion zone
    local landmark = self:getLandmarkAt(x, z)
    if landmark then
        return false, "Cannot place on landmark: " .. landmark.landmarkType
    end

    return true, nil
end

function WorldPlan.getTerrainContext(self: WorldPlanInstance, x: number, z: number): TerrainContext
    local context: TerrainContext = {
        zone = self:getZoneAt(x, z),
        distanceToRiver = self:getDistanceToRiver(x, z),
        distanceToRoad = self:getDistanceToRoad(x, z),
        nearestLandmark = nil,
        distanceToLandmark = nil,
    }

    local nearest = self:getNearestLandmark(x, z)
    if nearest then
        context.nearestLandmark = nearest.landmarkType
        context.distanceToLandmark = nearest.distance
    end

    return context
end

-- Map info
function WorldPlan.getMapSize(self: WorldPlanInstance): number
    return self.data.mapSize
end

return WorldPlan
