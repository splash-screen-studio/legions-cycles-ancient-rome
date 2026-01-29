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
WorldPlanGenerator.VERSION = "2.0.0"

-- Urban cluster configuration type
export type UrbanCluster = {
    name: string,
    center: Vector2,
    civicRadius: number,
    urbanRadius: number,
    isPrimary: boolean,
}

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
        clusters: { UrbanCluster },
    },
    WorldPlanGenerator
))

-- Default configuration
local DEFAULT_MAP_SIZE = 1024
local DEFAULT_RIVER_WIDTH = 40 -- Wider river (30-50 studs as per spec)
local DEFAULT_URBAN_RADIUS = 150
local DEFAULT_CIVIC_RADIUS = 80
local _DEFAULT_RIVER_DEPTH = 10 -- 8-12 studs deep for swimming (used by RiverBuilder)

-- Generate urban cluster positions based on map size
local function generateClusterPositions(mapSize: number, seed: number): { UrbanCluster }
    local halfSize = mapSize / 2
    local edgeOffset = 120 -- Distance from map edge for secondary clusters

    -- Seed random for consistent cluster generation
    math.randomseed(seed + 1000)

    -- Primary civic center (main Forum area) - center of map
    local clusters: { UrbanCluster } = {
        {
            name = "Roma",
            center = Vector2.new(0, 0),
            civicRadius = 80,
            urbanRadius = 150,
            isPrimary = true,
        },
        -- Northeast cluster - military/industrial district
        {
            name = "Castra",
            center = Vector2.new(halfSize - edgeOffset - 80, -halfSize + edgeOffset + 60),
            civicRadius = 40,
            urbanRadius = 80,
            isPrimary = false,
        },
        -- Northwest cluster - residential/merchant area
        {
            name = "Mercatum",
            center = Vector2.new(-halfSize + edgeOffset + 60, -halfSize + edgeOffset + 80),
            civicRadius = 35,
            urbanRadius = 70,
            isPrimary = false,
        },
        -- Southwest cluster - agricultural/rural town
        {
            name = "Rus",
            center = Vector2.new(-halfSize + edgeOffset + 100, halfSize - edgeOffset - 100),
            civicRadius = 30,
            urbanRadius = 60,
            isPrimary = false,
        },
        -- Southeast cluster - port/trade hub (closer to spawn area)
        {
            name = "Portus",
            center = Vector2.new(halfSize - edgeOffset - 100, halfSize - edgeOffset - 80),
            civicRadius = 45,
            urbanRadius = 90,
            isPrimary = false,
        },
    }

    return clusters
end

function WorldPlanGenerator.new(config: WorldPlanGeneratorConfig?): WorldPlanGeneratorInstance
    local self = setmetatable({}, WorldPlanGenerator)
    local cfg = config or {}

    self.config = cfg
    self.mapSize = cfg.mapSize or DEFAULT_MAP_SIZE
    self.seed = cfg.seed or math.random(1, 100000)
    self.riverWidth = cfg.riverWidth or DEFAULT_RIVER_WIDTH
    self.urbanRadius = cfg.urbanRadius or DEFAULT_URBAN_RADIUS
    self.civicRadius = cfg.civicRadius or DEFAULT_CIVIC_RADIUS

    -- Generate cluster positions
    self.clusters = generateClusterPositions(self.mapSize, self.seed)

    print(string.format("[WorldPlanGenerator v%s] Initializing with seed: %d, %d urban clusters",
        WorldPlanGenerator.VERSION, self.seed, #self.clusters))
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

-- Generate zone definitions for all urban clusters
function WorldPlanGenerator._generateZones(self: WorldPlanGeneratorInstance): { WorldPlan.Zone }
    local zones: { WorldPlan.Zone } = {}
    local halfSize = self.mapSize / 2

    -- Generate zones for each urban cluster
    -- Order matters: civic zones first (higher priority), then urban zones
    for _, cluster in ipairs(self.clusters) do
        -- Civic center zone for each cluster
        table.insert(zones, {
            center = cluster.center,
            radius = cluster.civicRadius,
            zoneType = "civic" :: WorldPlan.ZoneType,
        })
    end

    for _, cluster in ipairs(self.clusters) do
        -- Urban zone surrounding each civic center
        table.insert(zones, {
            center = cluster.center,
            radius = cluster.urbanRadius,
            zoneType = "urban" :: WorldPlan.ZoneType,
        })
    end

    -- Rural zones between clusters (farming/agricultural areas)
    -- These are positioned in areas between major urban centers

    -- Rural zone in the southeast (farming area near spawn, between Roma and Portus)
    table.insert(zones, {
        center = Vector2.new(halfSize / 4, halfSize / 4),
        radius = 120,
        zoneType = "rural" :: WorldPlan.ZoneType,
    })

    -- Rural zone in the southwest (between Roma and Rus)
    table.insert(zones, {
        center = Vector2.new(-halfSize / 3, halfSize / 3),
        radius = 100,
        zoneType = "rural" :: WorldPlan.ZoneType,
    })

    -- Rural zone in the northwest (between Roma and Mercatum)
    table.insert(zones, {
        center = Vector2.new(-halfSize / 4, -halfSize / 4),
        radius = 100,
        zoneType = "rural" :: WorldPlan.ZoneType,
    })

    -- Rural zone in the northeast (between Roma and Castra)
    table.insert(zones, {
        center = Vector2.new(halfSize / 3, -halfSize / 3),
        radius = 100,
        zoneType = "rural" :: WorldPlan.ZoneType,
    })

    return zones
end

-- Generate landmark positions distributed across all urban clusters
function WorldPlanGenerator:_generateLandmarks(): { WorldPlan.Landmark }
    local landmarks: { WorldPlan.Landmark } = {}

    -- ROMA (Primary Cluster) - Major civic landmarks
    local roma = self:_getClusterByName("Roma")
    if roma then
        -- Forum - center of the civic zone
        table.insert(landmarks, {
            position = roma.center,
            landmarkType = "Forum",
            radius = 40,
        })

        -- Colosseum - northeast of civic center
        table.insert(landmarks, {
            position = roma.center + Vector2.new(100, -80),
            landmarkType = "Colosseum",
            radius = 60,
        })

        -- Thermae (Baths) - southwest of civic center
        table.insert(landmarks, {
            position = roma.center + Vector2.new(-80, 60),
            landmarkType = "Thermae",
            radius = 35,
        })

        -- Temple of Jupiter - northwest of forum
        table.insert(landmarks, {
            position = roma.center + Vector2.new(-50, -100),
            landmarkType = "Temple",
            radius = 25,
        })

        -- Circus Maximus - south of civic center
        table.insert(landmarks, {
            position = roma.center + Vector2.new(30, 150),
            landmarkType = "CircusMaximus",
            radius = 80,
        })
    end

    -- CASTRA (Northeast - Military District)
    local castra = self:_getClusterByName("Castra")
    if castra then
        -- Military barracks/fortress
        table.insert(landmarks, {
            position = castra.center,
            landmarkType = "Castrum",
            radius = 35,
        })

        -- Training grounds
        table.insert(landmarks, {
            position = castra.center + Vector2.new(40, 30),
            landmarkType = "PalaestraMinor",
            radius = 25,
        })

        -- Small temple to Mars
        table.insert(landmarks, {
            position = castra.center + Vector2.new(-30, -20),
            landmarkType = "TempleMars",
            radius = 15,
        })
    end

    -- MERCATUM (Northwest - Merchant District)
    local mercatum = self:_getClusterByName("Mercatum")
    if mercatum then
        -- Main marketplace
        table.insert(landmarks, {
            position = mercatum.center,
            landmarkType = "Macellum",
            radius = 30,
        })

        -- Warehouse district
        table.insert(landmarks, {
            position = mercatum.center + Vector2.new(35, 25),
            landmarkType = "Horreum",
            radius = 25,
        })

        -- Small baths
        table.insert(landmarks, {
            position = mercatum.center + Vector2.new(-25, -30),
            landmarkType = "ThermaeMinor",
            radius = 20,
        })
    end

    -- RUS (Southwest - Agricultural Town)
    local rus = self:_getClusterByName("Rus")
    if rus then
        -- Rural villa
        table.insert(landmarks, {
            position = rus.center,
            landmarkType = "VillaRustica",
            radius = 25,
        })

        -- Grain storage
        table.insert(landmarks, {
            position = rus.center + Vector2.new(25, 20),
            landmarkType = "Granarium",
            radius = 20,
        })

        -- Shrine to Ceres
        table.insert(landmarks, {
            position = rus.center + Vector2.new(-20, -25),
            landmarkType = "SacellumCeres",
            radius = 12,
        })
    end

    -- PORTUS (Southeast - Port/Trade Hub)
    local portus = self:_getClusterByName("Portus")
    if portus then
        -- Harbor warehouse
        table.insert(landmarks, {
            position = portus.center,
            landmarkType = "Emporium",
            radius = 35,
        })

        -- Lighthouse
        table.insert(landmarks, {
            position = portus.center + Vector2.new(50, 30),
            landmarkType = "Pharos",
            radius = 15,
        })

        -- Temple to Neptune
        table.insert(landmarks, {
            position = portus.center + Vector2.new(-30, -35),
            landmarkType = "TempleNeptune",
            radius = 20,
        })

        -- Fish market
        table.insert(landmarks, {
            position = portus.center + Vector2.new(20, -25),
            landmarkType = "ForumPiscarium",
            radius = 18,
        })
    end

    return landmarks
end

-- Helper: Find the primary (Roma) cluster
function WorldPlanGenerator._getPrimaryCluster(self: WorldPlanGeneratorInstance): UrbanCluster?
    for _, cluster in ipairs(self.clusters) do
        if cluster.isPrimary then
            return cluster
        end
    end
    return nil
end

-- Helper: Get cluster by name
function WorldPlanGenerator._getClusterByName(self: WorldPlanGeneratorInstance, name: string): UrbanCluster?
    for _, cluster in ipairs(self.clusters) do
        if cluster.name == name then
            return cluster
        end
    end
    return nil
end

-- Generate road network connecting all urban clusters
function WorldPlanGenerator._generateRoads(self: WorldPlanGeneratorInstance): { WorldPlan.Road }
    local roads: { WorldPlan.Road } = {}
    local halfSize = self.mapSize / 2

    local primaryCluster = self:_getPrimaryCluster()
    if not primaryCluster then
        return roads
    end

    -- MAIN ROADS (Via) - Connect the primary cluster to all edges and secondary clusters

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

    -- INTER-CLUSTER ROADS - Connect Roma to each secondary cluster
    for _, cluster in ipairs(self.clusters) do
        if not cluster.isPrimary then
            -- Main road from Roma to this cluster
            table.insert(roads, {
                path = {
                    primaryCluster.center,
                    cluster.center,
                },
                width = 10,
                roadType = "via" :: "via" | "path",
            })
        end
    end

    -- PERIPHERAL ROADS - Connect adjacent secondary clusters to form a ring
    local castra = self:_getClusterByName("Castra")
    local mercatum = self:_getClusterByName("Mercatum")
    local rus = self:_getClusterByName("Rus")
    local portus = self:_getClusterByName("Portus")

    -- North road: Mercatum to Castra
    if mercatum and castra then
        table.insert(roads, {
            path = {
                mercatum.center,
                Vector2.new(0, -halfSize + 100), -- Pass near north edge
                castra.center,
            },
            width = 8,
            roadType = "path" :: "via" | "path",
        })
    end

    -- West road: Mercatum to Rus
    if mercatum and rus then
        table.insert(roads, {
            path = {
                mercatum.center,
                Vector2.new(-halfSize + 80, 0), -- Pass near west edge
                rus.center,
            },
            width = 8,
            roadType = "path" :: "via" | "path",
        })
    end

    -- South road: Rus to Portus
    if rus and portus then
        table.insert(roads, {
            path = {
                rus.center,
                Vector2.new(0, halfSize - 100), -- Pass near south edge
                portus.center,
            },
            width = 8,
            roadType = "path" :: "via" | "path",
        })
    end

    -- East road: Portus to Castra
    if portus and castra then
        table.insert(roads, {
            path = {
                portus.center,
                Vector2.new(halfSize - 80, 0), -- Pass near east edge
                castra.center,
            },
            width = 8,
            roadType = "path" :: "via" | "path",
        })
    end

    -- INTERNAL CLUSTER ROADS - Small roads within each cluster to landmarks
    -- These will be generated based on landmarks once we have them

    -- Road to player spawn area (southeast, from Portus area)
    if portus then
        table.insert(roads, {
            path = {
                portus.center,
                Vector2.new(halfSize - 150, halfSize - 150),
                Vector2.new(400, 400),
            },
            width = 6,
            roadType = "path" :: "via" | "path",
        })
    end

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
