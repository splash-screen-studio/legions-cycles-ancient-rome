--!strict
--[[
    WorldPlanGenerator - Creates the WorldPlan before any world generation
    This is the FIRST system to run, defining the abstract layout that all other systems query.

    Based on BRicey procedural generation techniques adapted for city planning.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))
local Constants = require(Shared:WaitForChild("Constants"))

local WorldPlanGenerator = {}
WorldPlanGenerator.__index = WorldPlanGenerator
WorldPlanGenerator.VERSION = "1.1.0"

export type WorldPlanGeneratorConfig = {
    mapSize: number?,
    seed: number?,
    riverWidth: number?,
    urbanRadius: number?,
    civicRadius: number?,
    riverCliffMargin: number?, -- Extra margin around river to avoid cliff edges
}

export type WorldPlanGeneratorInstance = typeof(setmetatable(
    {} :: {
        config: WorldPlanGeneratorConfig,
        mapSize: number,
        seed: number,
        riverWidth: number,
        urbanRadius: number,
        civicRadius: number,
        riverCliffMargin: number,
    },
    WorldPlanGenerator
))

-- Default configuration
local DEFAULT_MAP_SIZE = 1024
local DEFAULT_RIVER_WIDTH = 40 -- Wider river (30-50 studs as per spec)
local DEFAULT_URBAN_RADIUS = 150
local DEFAULT_CIVIC_RADIUS = 80
local _DEFAULT_RIVER_DEPTH = 10 -- 8-12 studs deep for swimming (used by RiverBuilder)

function WorldPlanGenerator.new(config: WorldPlanGeneratorConfig?): WorldPlanGeneratorInstance
    local self = setmetatable({}, WorldPlanGenerator)
    local cfg = config or {}

    self.config = cfg
    self.mapSize = cfg.mapSize or DEFAULT_MAP_SIZE
    self.seed = cfg.seed or math.random(1, 100000)
    self.riverWidth = cfg.riverWidth or DEFAULT_RIVER_WIDTH
    self.urbanRadius = cfg.urbanRadius or DEFAULT_URBAN_RADIUS
    self.civicRadius = cfg.civicRadius or DEFAULT_CIVIC_RADIUS
    self.riverCliffMargin = cfg.riverCliffMargin or Constants.SLOPE.RIVER_CLIFF_MARGIN

    print(string.format("[WorldPlanGenerator v%s] Initializing with seed: %d", WorldPlanGenerator.VERSION, self.seed))
    return self
end

-- Helper: Evaluate cubic bezier curve at t
local function evaluateBezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: number): Vector2
    local u = 1 - t
    local tt = t * t
    local uu = u * u
    local uuu = uu * u
    local ttt = tt * t

    local x = uuu * p0.X + 3 * uu * t * p1.X + 3 * u * tt * p2.X + ttt * p3.X
    local y = uuu * p0.Y + 3 * uu * t * p1.Y + 3 * u * tt * p2.Y + ttt * p3.Y

    return Vector2.new(x, y)
end

-- Generate a meandering river path spanning the entire map edge to edge
function WorldPlanGenerator._generateRiverPath(self: WorldPlanGeneratorInstance): { Vector2 }
    local path: { Vector2 } = {}
    local halfSize = self.mapSize / 2

    -- River spans ENTIRE map from west edge to east edge
    local startX = -halfSize
    local endX = halfSize

    -- Random start and end Z positions (within reasonable bounds)
    math.randomseed(self.seed)
    local startZ = math.random(-200, 200)
    local endZ = math.random(-200, 200)

    -- Create bezier control points for smooth winding path
    local p0 = Vector2.new(startX, startZ)
    local p3 = Vector2.new(endX, endZ)

    -- Control points create the curves - use noise for variety
    local ctrl1X = startX + (endX - startX) * 0.33
    local ctrl2X = startX + (endX - startX) * 0.66

    -- Use perlin noise to generate control point offsets for natural curves
    local ctrl1Offset = math.noise(self.seed * 0.1, 0.5) * 250
    local ctrl2Offset = math.noise(self.seed * 0.2, 0.7) * 250

    local p1 = Vector2.new(ctrl1X, startZ + ctrl1Offset)
    local p2 = Vector2.new(ctrl2X, endZ + ctrl2Offset)

    -- Sample bezier curve at regular intervals (50+ points for smooth path)
    local numSamples = 50
    for i = 0, numSamples do
        local t = i / numSamples
        local point = evaluateBezier(p0, p1, p2, p3, t)
        table.insert(path, point)
    end

    return path
end

-- Generate zone definitions
function WorldPlanGenerator._generateZones(self: WorldPlanGeneratorInstance): { WorldPlan.Zone }
    local zones: { WorldPlan.Zone } = {}
    local halfSize = self.mapSize / 2

    -- Civic center (Forum area) - center of map
    table.insert(zones, {
        center = Vector2.new(0, 0),
        radius = self.civicRadius,
        zoneType = "civic" :: WorldPlan.ZoneType,
    })

    -- Urban zone surrounding civic center
    table.insert(zones, {
        center = Vector2.new(0, 0),
        radius = self.urbanRadius,
        zoneType = "urban" :: WorldPlan.ZoneType,
    })

    -- Rural zone in the southeast (farming area near spawn)
    table.insert(zones, {
        center = Vector2.new(halfSize / 2, halfSize / 2),
        radius = 200,
        zoneType = "rural" :: WorldPlan.ZoneType,
    })

    -- Rural zone in the southwest
    table.insert(zones, {
        center = Vector2.new(-halfSize / 2, halfSize / 2),
        radius = 150,
        zoneType = "rural" :: WorldPlan.ZoneType,
    })

    return zones
end

-- Generate landmark positions
function WorldPlanGenerator:_generateLandmarks(): { WorldPlan.Landmark }
    local landmarks: { WorldPlan.Landmark } = {}

    -- Forum - center of the civic zone
    table.insert(landmarks, {
        position = Vector2.new(0, 0),
        landmarkType = "Forum",
        radius = 40,
    })

    -- Colosseum - northeast of civic center
    table.insert(landmarks, {
        position = Vector2.new(100, -80),
        landmarkType = "Colosseum",
        radius = 60,
    })

    -- Thermae (Baths) - southwest of civic center
    table.insert(landmarks, {
        position = Vector2.new(-80, 60),
        landmarkType = "Thermae",
        radius = 35,
    })

    -- Temple - northwest of forum
    table.insert(landmarks, {
        position = Vector2.new(-50, -100),
        landmarkType = "Temple",
        radius = 25,
    })

    -- Circus Maximus - south of civic center
    table.insert(landmarks, {
        position = Vector2.new(30, 150),
        landmarkType = "CircusMaximus",
        radius = 80,
    })

    return landmarks
end

-- Generate road network
function WorldPlanGenerator._generateRoads(self: WorldPlanGeneratorInstance): { WorldPlan.Road }
    local roads: { WorldPlan.Road } = {}
    local halfSize = self.mapSize / 2

    -- Via Appia - main road running north-south through the center
    table.insert(roads, {
        path = {
            Vector2.new(0, -halfSize + 50),
            Vector2.new(0, halfSize - 50),
        },
        width = 12,
        roadType = "via" :: "via" | "path",
    })

    -- Via Sacra - main road running east-west through the Forum
    table.insert(roads, {
        path = {
            Vector2.new(-halfSize + 50, 0),
            Vector2.new(halfSize - 50, 0),
        },
        width = 12,
        roadType = "via" :: "via" | "path",
    })

    -- Road to Colosseum
    table.insert(roads, {
        path = {
            Vector2.new(0, 0),
            Vector2.new(100, -80),
        },
        width = 8,
        roadType = "path" :: "via" | "path",
    })

    -- Road to Thermae
    table.insert(roads, {
        path = {
            Vector2.new(0, 0),
            Vector2.new(-80, 60),
        },
        width = 8,
        roadType = "path" :: "via" | "path",
    })

    -- Road to player spawn area (southeast)
    table.insert(roads, {
        path = {
            Vector2.new(0, 0),
            Vector2.new(200, 200),
            Vector2.new(400, 400),
        },
        width = 8,
        roadType = "path" :: "via" | "path",
    })

    return roads
end

-- Generate player plot areas
function WorldPlanGenerator._generatePlayerPlots(self: WorldPlanGeneratorInstance): { WorldPlan.PlayerPlot }
    local plots: { WorldPlan.PlayerPlot } = {}
    local halfSize = self.mapSize / 2

    -- Player plots in the rural southeast area (near spawn)
    -- Create a grid of small plots
    local plotSize = Vector2.new(30, 30)
    local plotSpacing = 40
    local plotAreaStart = Vector2.new(250, 250)

    for row = 0, 2 do
        for col = 0, 2 do
            local center = Vector2.new(
                plotAreaStart.X + col * plotSpacing,
                plotAreaStart.Y + row * plotSpacing
            )

            -- Skip if too close to edge
            if math.abs(center.X) < halfSize - 50 and math.abs(center.Y) < halfSize - 50 then
                table.insert(plots, {
                    center = center,
                    size = plotSize,
                })
            end
        end
    end

    return plots
end

-- Generate the complete world plan
function WorldPlanGenerator.generate(self: WorldPlanGeneratorInstance): WorldPlan.WorldPlanInstance
    print(string.format("[WorldPlanGenerator v%s] Generating world plan...", WorldPlanGenerator.VERSION))

    local startTime = tick()

    local riverPath = self:_generateRiverPath()
    local zones = self:_generateZones()
    local landmarks = self:_generateLandmarks()
    local roads = self:_generateRoads()
    local playerPlots = self:_generatePlayerPlots()

    -- Calculate river exclusion zone (river width + cliff margin on each side)
    local riverExclusionWidth = self.riverWidth + (self.riverCliffMargin * 2)

    local planData: WorldPlan.WorldPlanData = {
        riverPath = riverPath,
        riverWidth = self.riverWidth,
        riverExclusionWidth = riverExclusionWidth,
        zones = zones,
        landmarks = landmarks,
        roads = roads,
        playerPlots = playerPlots,
        mapSize = self.mapSize,
        maxUrbanSlope = Constants.SLOPE.MAX_URBAN_SLOPE,
        maxFountainSlope = Constants.SLOPE.MAX_FOUNTAIN_SLOPE,
    }

    local worldPlan = WorldPlan.new(planData)

    local elapsed = tick() - startTime
    print(string.format("[WorldPlanGenerator v%s] World plan generated in %.3f seconds", WorldPlanGenerator.VERSION, elapsed))
    print(string.format("[WorldPlanGenerator v%s] River: %d points, Zones: %d, Landmarks: %d, Roads: %d, Plots: %d",
        WorldPlanGenerator.VERSION,
        #riverPath,
        #zones,
        #landmarks,
        #roads,
        #playerPlots
    ))
    print(string.format("[WorldPlanGenerator v%s] River exclusion zone: %.0f studs (river: %.0f + margins: %.0f)",
        WorldPlanGenerator.VERSION,
        riverExclusionWidth,
        self.riverWidth,
        self.riverCliffMargin * 2
    ))

    return worldPlan
end

return WorldPlanGenerator
