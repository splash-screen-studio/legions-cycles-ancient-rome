--!strict
--[[
    WorldPlanGenerator - Creates the WorldPlan before any world generation
    This is the FIRST system to run, defining the abstract layout that all other systems query.

    Based on BRicey procedural generation techniques adapted for city planning.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldPlan = require(Shared:WaitForChild("WorldPlan"))

local WorldPlanGenerator = {}
WorldPlanGenerator.__index = WorldPlanGenerator
WorldPlanGenerator.VERSION = "1.0.0"

export type WorldPlanGeneratorConfig = {
    mapSize: number?,
    seed: number?,
    riverWidth: number?,
    urbanRadius: number?,
    civicRadius: number?,
}

export type WorldPlanGeneratorInstance = typeof(setmetatable(
    {} :: {
        config: WorldPlanGeneratorConfig,
        mapSize: number,
        seed: number,
        riverWidth: number,
        urbanRadius: number,
        civicRadius: number,
    },
    WorldPlanGenerator
))

-- Default configuration
local DEFAULT_MAP_SIZE = 1024
local DEFAULT_RIVER_WIDTH = 20
local DEFAULT_URBAN_RADIUS = 150
local DEFAULT_CIVIC_RADIUS = 80

function WorldPlanGenerator.new(config: WorldPlanGeneratorConfig?): WorldPlanGeneratorInstance
    local self = setmetatable({}, WorldPlanGenerator)
    local cfg = config or {}

    self.config = cfg
    self.mapSize = cfg.mapSize or DEFAULT_MAP_SIZE
    self.seed = cfg.seed or math.random(1, 100000)
    self.riverWidth = cfg.riverWidth or DEFAULT_RIVER_WIDTH
    self.urbanRadius = cfg.urbanRadius or DEFAULT_URBAN_RADIUS
    self.civicRadius = cfg.civicRadius or DEFAULT_CIVIC_RADIUS

    print(string.format("[WorldPlanGenerator v%s] Initializing with seed: %d", WorldPlanGenerator.VERSION, self.seed))
    return self
end

-- Generate a meandering river path across the map
function WorldPlanGenerator._generateRiverPath(self: WorldPlanGeneratorInstance): { Vector2 }
    local path: { Vector2 } = {}
    local halfSize = self.mapSize / 2

    -- River starts in the west, meanders eastward
    -- Use noise to create natural curves
    local numPoints = 20
    local startX = -halfSize + 50
    local endX = halfSize - 200 -- Don't go all the way to the edge

    for i = 0, numPoints do
        local t = i / numPoints
        local x = startX + (endX - startX) * t

        -- Use noise for natural meandering
        local noiseOffset = math.noise(x * 0.005 + self.seed, self.seed * 0.7) * 150

        -- Base Z position (roughly through the northern part of the map)
        local baseZ = -halfSize / 3

        local z = baseZ + noiseOffset

        table.insert(path, Vector2.new(x, z))
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
function WorldPlanGenerator._generateLandmarks(self: WorldPlanGeneratorInstance): { WorldPlan.Landmark }
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

    local planData: WorldPlan.WorldPlanData = {
        riverPath = riverPath,
        riverWidth = self.riverWidth,
        zones = zones,
        landmarks = landmarks,
        roads = roads,
        playerPlots = playerPlots,
        mapSize = self.mapSize,
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

    return worldPlan
end

return WorldPlanGenerator
