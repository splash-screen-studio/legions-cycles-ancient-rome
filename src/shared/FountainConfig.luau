--!strict
--[[
    FountainConfig - Definitions for Roman fountain types and placements

    Fountain Types (from smallest to largest):
    - Basin: Small (8x8), street corners
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
FountainConfig.VERSION = "1.3.0"

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
        size = Vector3.new(8, 5, 8), -- 8x8 footprint, 5 studs deep
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
--
-- Urban clusters (from WorldPlanGenerator):
-- - Roma: center (0, 0), civicRadius 80, urbanRadius 150
-- - Castra: center (312, -332), civicRadius 40, urbanRadius 80 (Military)
-- - Mercatum: center (-332, -312), civicRadius 35, urbanRadius 70 (Merchant)
-- - Rus: center (-292, 292), civicRadius 30, urbanRadius 60 (Agricultural)
-- - Portus: center (292, 312), civicRadius 45, urbanRadius 90 (Port)
FountainConfig.DEFAULT_PLACEMENTS = {
    -- ============================================
    -- ROMA (Primary Cluster) - Main civic center
    -- ============================================

    -- Forum plaza (large nymphaeum) - offset from road intersection
    -- Placed at (40, 40) to avoid Via Appia (x=0) and Via Sacra (z=0)
    {
        position = Vector3.new(40, 0, 40),
        fountainType = "nymphaeum",
        name = "Roma_Forum_Nymphaeum",
    },
    -- Near player spawn area (accessible water)
    -- Spawn path runs through (200,200)->(400,400), placed offset at (280, 150)
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
        name = "Roma_Colosseum_PublicFountain",
    },
    -- Corner basins - at street corners, NOT on roads
    -- WestRoad: offset from Via Appia and Via Sacra intersection
    {
        position = Vector3.new(-30, 0, -30),
        fountainType = "basin",
        name = "Roma_WestRoad_Basin",
    },
    -- EastRoad: opposite corner from WestRoad
    {
        position = Vector3.new(30, 0, -30),
        fountainType = "basin",
        name = "Roma_EastRoad_Basin",
    },
    -- NorthWest corner basin
    {
        position = Vector3.new(-30, 0, 30),
        fountainType = "basin",
        name = "Roma_NorthWest_Basin",
    },
    -- NorthEast corner basin
    {
        position = Vector3.new(30, 0, 30),
        fountainType = "basin",
        name = "Roma_NorthEast_Basin",
    },
    -- Thermae plaza fountain - near Thermae at (-80, 60)
    -- Placed in plaza area near the baths
    {
        position = Vector3.new(-120, 0, 80),
        fountainType = "publicFountain",
        name = "Roma_Thermae_PublicFountain",
    },
    -- Temple plaza fountain - near Temple at (-50, -100)
    -- Placed in plaza area near the temple
    {
        position = Vector3.new(-80, 0, -130),
        fountainType = "publicFountain",
        name = "Roma_Temple_PublicFountain",
    },
    -- Additional Roma urban zone basins
    {
        position = Vector3.new(-60, 0, 60),
        fountainType = "basin",
        name = "Roma_West_Basin",
    },
    {
        position = Vector3.new(60, 0, 60),
        fountainType = "basin",
        name = "Roma_East_Basin",
    },

    -- ============================================
    -- CASTRA (Northeast) - Military District
    -- Center: (312, -332), civicRadius 40, urbanRadius 80
    -- ============================================

    -- Civic center nymphaeum (near Castrum landmark)
    {
        position = Vector3.new(312, 0, -360),
        fountainType = "nymphaeum",
        name = "Castra_Civic_Nymphaeum",
    },
    -- Training grounds fountain (near PalaestraMinor at center + (40, 30))
    {
        position = Vector3.new(360, 0, -310),
        fountainType = "publicFountain",
        name = "Castra_Palaestra_PublicFountain",
    },
    -- Temple of Mars plaza basin (near TempleMars at center + (-30, -20))
    {
        position = Vector3.new(270, 0, -360),
        fountainType = "basin",
        name = "Castra_Mars_Basin",
    },
    -- Barracks corner basins
    {
        position = Vector3.new(340, 0, -370),
        fountainType = "basin",
        name = "Castra_North_Basin",
    },
    {
        position = Vector3.new(280, 0, -300),
        fountainType = "basin",
        name = "Castra_South_Basin",
    },

    -- ============================================
    -- MERCATUM (Northwest) - Merchant District
    -- Center: (-332, -312), civicRadius 35, urbanRadius 70
    -- ============================================

    -- Market center nymphaeum (near Macellum landmark)
    {
        position = Vector3.new(-332, 0, -340),
        fountainType = "nymphaeum",
        name = "Mercatum_Civic_Nymphaeum",
    },
    -- Warehouse district fountain (near Horreum at center + (35, 25))
    {
        position = Vector3.new(-290, 0, -280),
        fountainType = "publicFountain",
        name = "Mercatum_Horreum_PublicFountain",
    },
    -- Minor baths basin (near ThermaeMinor at center + (-25, -30))
    {
        position = Vector3.new(-365, 0, -350),
        fountainType = "basin",
        name = "Mercatum_Thermae_Basin",
    },
    -- Market corner basins
    {
        position = Vector3.new(-360, 0, -280),
        fountainType = "basin",
        name = "Mercatum_West_Basin",
    },
    {
        position = Vector3.new(-300, 0, -340),
        fountainType = "basin",
        name = "Mercatum_East_Basin",
    },

    -- ============================================
    -- RUS (Southwest) - Agricultural Town
    -- Center: (-292, 292), civicRadius 30, urbanRadius 60
    -- ============================================

    -- Villa Rustica plaza fountain (near VillaRustica landmark)
    {
        position = Vector3.new(-292, 0, 320),
        fountainType = "publicFountain",
        name = "Rus_Villa_PublicFountain",
    },
    -- Granary area basin (near Granarium at center + (25, 20))
    {
        position = Vector3.new(-260, 0, 320),
        fountainType = "basin",
        name = "Rus_Granarium_Basin",
    },
    -- Shrine of Ceres basin (near SacellumCeres at center + (-20, -25))
    {
        position = Vector3.new(-320, 0, 260),
        fountainType = "basin",
        name = "Rus_Ceres_Basin",
    },
    -- Rural town corner basins
    {
        position = Vector3.new(-330, 0, 320),
        fountainType = "basin",
        name = "Rus_West_Basin",
    },

    -- ============================================
    -- PORTUS (Southeast) - Port/Trade Hub
    -- Center: (292, 312), civicRadius 45, urbanRadius 90
    -- ============================================

    -- Harbor center nymphaeum (near Emporium landmark)
    {
        position = Vector3.new(292, 0, 340),
        fountainType = "nymphaeum",
        name = "Portus_Civic_Nymphaeum",
    },
    -- Temple of Neptune plaza fountain (near TempleNeptune at center + (-30, -35))
    {
        position = Vector3.new(255, 0, 270),
        fountainType = "publicFountain",
        name = "Portus_Neptune_PublicFountain",
    },
    -- Fish market fountain (near ForumPiscarium at center + (20, -25))
    {
        position = Vector3.new(320, 0, 280),
        fountainType = "publicFountain",
        name = "Portus_Market_PublicFountain",
    },
    -- Harbor area basins
    {
        position = Vector3.new(340, 0, 350),
        fountainType = "basin",
        name = "Portus_East_Basin",
    },
    {
        position = Vector3.new(250, 0, 350),
        fountainType = "basin",
        name = "Portus_West_Basin",
    },
    {
        position = Vector3.new(320, 0, 380),
        fountainType = "basin",
        name = "Portus_North_Basin",
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
