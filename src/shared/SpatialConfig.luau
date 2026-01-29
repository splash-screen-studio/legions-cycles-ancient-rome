--!strict
--[[
    SpatialConfig - Configuration for the Spatial Coordination System
    Defines grid size, cell size, and placement constraints
]]

local SpatialConfig = {}
SpatialConfig.VERSION = "1.0.0"

-- Grid cell size in studs
-- Smaller = more precision, larger = better performance
-- 64 studs is a good balance for Roman buildings
SpatialConfig.CELL_SIZE = 64

-- Default map size (should match WorldPlan)
SpatialConfig.DEFAULT_MAP_SIZE = 1024

-- Placement constraints
SpatialConfig.PLACEMENT = {
    -- Minimum distance from roads for structure placement
    MIN_ROAD_DISTANCE = 2,

    -- Maximum distance from roads (warning, not blocking)
    MAX_ROAD_DISTANCE = 50,

    -- Minimum padding between structures
    STRUCTURE_PADDING = 2,
}

-- Query constants
SpatialConfig.QUERY = {
    -- Default search radius for nearby features
    DEFAULT_SEARCH_RADIUS = 100,

    -- Maximum structures to return in area queries
    MAX_AREA_RESULTS = 50,
}

return SpatialConfig
