--!strict
--[[
    FountainConfig - Definitions for Roman fountain types and placements

    Fountain Types (from smallest to largest):
    - Basin: Tiny (5x5), street corners
    - Impluvium: Small (10x10), Domus atriums (player-built)
    - PublicFountain: Medium (20x20), plazas, intersections
    - Nymphaeum: Large (30x15), Forum, civic areas

    Physical Properties:
    - Depth: 4-6 studs (visible water depth)
    - Walls: Extend ABOVE water surface (2 studs above)
    - Floor: Part-based, solid
    - Water: Terrain water ONLY inside walls
]]

local FountainConfig = {}
FountainConfig.VERSION = "1.0.0"

-- Roman color palette
FountainConfig.COLORS = {
    MARBLE_WHITE = Color3.fromRGB(245, 240, 230),
    MARBLE_CREAM = Color3.fromRGB(235, 225, 210),
    TERRACOTTA = Color3.fromRGB(180, 110, 80),
    BRICK = Color3.fromRGB(150, 90, 70),
}

-- Fountain type definitions
export type FountainType = "basin" | "impluvium" | "publicFountain" | "nymphaeum"

export type FountainTypeConfig = {
    name: string,
    size: Vector3, -- Width (X), Depth (Y), Length (Z)
    wallMaterial: Enum.Material,
    wallColor: Color3,
    wallThickness: number,
    rimHeight: number, -- How much walls extend above water
}

-- Type configurations
FountainConfig.TYPES = {
    basin = {
        name = "Basin",
        size = Vector3.new(5, 4, 5), -- 5x5 footprint, 4 studs deep
        wallMaterial = Enum.Material.Marble,
        wallColor = FountainConfig.COLORS.MARBLE_WHITE,
        wallThickness = 1,
        rimHeight = 2,
    },
    impluvium = {
        name = "Impluvium",
        size = Vector3.new(10, 4, 10), -- 10x10 footprint, 4 studs deep
        wallMaterial = Enum.Material.Marble,
        wallColor = FountainConfig.COLORS.MARBLE_CREAM,
        wallThickness = 1.5,
        rimHeight = 2,
    },
    publicFountain = {
        name = "Public Fountain",
        size = Vector3.new(20, 5, 20), -- 20x20 footprint, 5 studs deep
        wallMaterial = Enum.Material.Marble,
        wallColor = FountainConfig.COLORS.MARBLE_WHITE,
        wallThickness = 2,
        rimHeight = 2.5,
    },
    nymphaeum = {
        name = "Nymphaeum",
        size = Vector3.new(30, 6, 15), -- 30x15 footprint, 6 studs deep
        wallMaterial = Enum.Material.Marble,
        wallColor = FountainConfig.COLORS.MARBLE_CREAM,
        wallThickness = 2.5,
        rimHeight = 3,
    },
}

-- Fountain placement definition
export type FountainPlacement = {
    position: Vector3, -- X, 0, Z (Y determined from terrain)
    fountainType: FountainType,
    name: string?, -- Optional custom name
}

-- Default fountain placements across the map
-- These align with WorldPlan zones and landmarks
FountainConfig.DEFAULT_PLACEMENTS = {
    -- Forum center (large public fountain) - civic area
    {
        position = Vector3.new(512, 0, 512),
        fountainType = "nymphaeum",
        name = "Forum_Nymphaeum",
    },
    -- Near player spawn area (accessible water)
    {
        position = Vector3.new(350, 0, 350),
        fountainType = "publicFountain",
        name = "SpawnArea_PublicFountain",
    },
    -- Colosseum approach plaza
    {
        position = Vector3.new(700, 0, 300),
        fountainType = "publicFountain",
        name = "Colosseum_PublicFountain",
    },
    -- Road intersection waypoints (scattered basins)
    {
        position = Vector3.new(256, 0, 256),
        fountainType = "basin",
        name = "WestRoad_Basin",
    },
    {
        position = Vector3.new(768, 0, 256),
        fountainType = "basin",
        name = "EastRoad_Basin",
    },
    {
        position = Vector3.new(256, 0, 768),
        fountainType = "basin",
        name = "NorthWest_Basin",
    },
    {
        position = Vector3.new(768, 0, 768),
        fountainType = "basin",
        name = "NorthEast_Basin",
    },
    -- Additional public fountains at key intersections
    {
        position = Vector3.new(400, 0, 600),
        fountainType = "publicFountain",
        name = "CentralPlaza_PublicFountain",
    },
    {
        position = Vector3.new(600, 0, 400),
        fountainType = "publicFountain",
        name = "EastPlaza_PublicFountain",
    },
}

-- Helper function to get config for a fountain type
function FountainConfig.getTypeConfig(fountainType: FountainType): FountainTypeConfig
    local config = FountainConfig.TYPES[fountainType]
    if not config then
        error(string.format("[FountainConfig] Unknown fountain type: %s", tostring(fountainType)))
    end
    return config
end

-- Helper function to get all placements
function FountainConfig.getDefaultPlacements(): { FountainPlacement }
    return FountainConfig.DEFAULT_PLACEMENTS
end

-- Helper function to get placements filtered by type
function FountainConfig.getPlacementsByType(fountainType: FountainType): { FountainPlacement }
    local filtered = {}
    for _, placement in ipairs(FountainConfig.DEFAULT_PLACEMENTS) do
        if placement.fountainType == fountainType then
            table.insert(filtered, placement)
        end
    end
    return filtered
end

return FountainConfig
