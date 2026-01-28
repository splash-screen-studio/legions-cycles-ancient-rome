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
FountainConfig.VERSION = "1.1.0"

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
-- Uses WorldPlan coordinates (centered at 0,0, map is -512 to 512)
-- IMPORTANT: Placements are validated to avoid roads (see WorldPlan)
-- Roads: Via Appia (x=0), Via Sacra (z=0), plus paths to landmarks
FountainConfig.DEFAULT_PLACEMENTS = {
    -- Forum plaza (large nymphaeum) - offset from road intersection
    -- Placed at (40, 40) to avoid Via Appia (x=0) and Via Sacra (z=0)
    {
        position = Vector3.new(40, 0, 40),
        fountainType = "nymphaeum",
        name = "Forum_Nymphaeum",
    },
    -- Near player spawn area (accessible water)
    -- Spawn path runs through (200,200)→(400,400), placed offset at (280, 150)
    {
        position = Vector3.new(280, 0, 150),
        fountainType = "publicFountain",
        name = "SpawnArea_PublicFountain",
    },
    -- Colosseum approach plaza - near landmark at (100, -80)
    -- Placed adjacent to Colosseum, away from road
    {
        position = Vector3.new(140, 0, -120),
        fountainType = "publicFountain",
        name = "Colosseum_PublicFountain",
    },
    -- Corner basins - at street corners, NOT on roads
    -- WestRoad: offset from Via Appia and Via Sacra intersection
    {
        position = Vector3.new(-30, 0, -30),
        fountainType = "basin",
        name = "WestRoad_Basin",
    },
    -- EastRoad: opposite corner from WestRoad
    {
        position = Vector3.new(30, 0, -30),
        fountainType = "basin",
        name = "EastRoad_Basin",
    },
    -- NorthWest corner basin
    {
        position = Vector3.new(-30, 0, 30),
        fountainType = "basin",
        name = "NorthWest_Basin",
    },
    -- NorthEast corner basin
    {
        position = Vector3.new(30, 0, 30),
        fountainType = "basin",
        name = "NorthEast_Basin",
    },
    -- Thermae plaza fountain - near Thermae at (-80, 60)
    -- Placed in plaza area near the baths
    {
        position = Vector3.new(-120, 0, 80),
        fountainType = "publicFountain",
        name = "Thermae_PublicFountain",
    },
    -- Temple plaza fountain - near Temple at (-50, -100)
    -- Placed in plaza area near the temple
    {
        position = Vector3.new(-80, 0, -130),
        fountainType = "publicFountain",
        name = "Temple_PublicFountain",
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
