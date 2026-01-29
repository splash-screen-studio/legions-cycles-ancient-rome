--!strict
--[[
    MaterialConfig - Configuration for context-aware terrain materials
    Defines material rules for Mediterranean/Roman terrain.

    Material selection follows a priority chain:
    1. Road proximity (cobblestone)
    2. Water proximity (sand beach + grass ring)
    3. Structure/landmark proximity (cobblestone/marble)
    4. Zone overlay (urban = paved, rural = grass)
    5. Slope-based (steep = rocky/arid)
    6. Base altitude (high = rock, low = grass)
]]

local MaterialConfig = {}
MaterialConfig.VERSION = "2.0.0"

-- Export types for material configuration
export type AltitudeBand = {
    minAltitude: number,
    maxAltitude: number,
    primaryMaterial: Enum.Material,
    secondaryMaterial: Enum.Material,
    grassPercentage: number,
}

export type ZoneMaterialOverride = {
    primaryMaterial: Enum.Material,
    secondaryMaterial: Enum.Material,
    grassPercentage: number,
}

export type ProximityRule = {
    material: Enum.Material,
    radius: number,
}

export type SlopeBand = {
    minSlope: number,
    maxSlope: number,
    primaryMaterial: Enum.Material,
    secondaryMaterial: Enum.Material,
    grassPercentage: number,
}

-- Altitude bands for base material selection
-- Heights are in studs, based on TerrainManager's baseHeight=20, amplitude=40
-- Mediterranean climate: rocky hilltops, grassy valleys
MaterialConfig.ALTITUDE_BANDS = {
    -- Hilltops: Rocky and arid
    {
        minAltitude = 50,
        maxAltitude = math.huge,
        primaryMaterial = Enum.Material.Rock,
        secondaryMaterial = Enum.Material.Slate,
        grassPercentage = 0.05,
    },
    -- Upper hillsides: Mix of rock and sandstone, sparse grass
    {
        minAltitude = 40,
        maxAltitude = 50,
        primaryMaterial = Enum.Material.Sandstone,
        secondaryMaterial = Enum.Material.Rock,
        grassPercentage = 0.10,
    },
    -- Lower hillsides: Ground with some grass
    {
        minAltitude = 30,
        maxAltitude = 40,
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Sandstone,
        grassPercentage = 0.25,
    },
    -- Flat areas: Balanced ground and grass
    {
        minAltitude = 20,
        maxAltitude = 30,
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Grass,
        grassPercentage = 0.45,
    },
    -- Valleys: Lush grass, concentrated vegetation
    {
        minAltitude = -math.huge,
        maxAltitude = 20,
        primaryMaterial = Enum.Material.Grass,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.65,
    },
}

-- Slope bands for material selection (degrees)
-- Steeper slopes = more rocky/arid materials
MaterialConfig.SLOPE_BANDS = {
    -- Very steep: Rocky outcrops
    {
        minSlope = 35,
        maxSlope = math.huge,
        primaryMaterial = Enum.Material.Rock,
        secondaryMaterial = Enum.Material.Slate,
        grassPercentage = 0.0,
    },
    -- Steep hillsides: Sandstone and rock
    {
        minSlope = 25,
        maxSlope = 35,
        primaryMaterial = Enum.Material.Sandstone,
        secondaryMaterial = Enum.Material.Rock,
        grassPercentage = 0.05,
    },
    -- Moderate slopes: Ground with sparse vegetation
    {
        minSlope = 15,
        maxSlope = 25,
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Sandstone,
        grassPercentage = 0.15,
    },
    -- Gentle slopes: Normal material selection
    {
        minSlope = 0,
        maxSlope = 15,
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Grass,
        grassPercentage = 0.40,
    },
}

-- Zone material overrides (higher priority than altitude)
-- Mediterranean zones: urban areas paved, wilderness is arid
MaterialConfig.ZONE_MATERIALS = {
    -- Civic areas: Heavy paving with minimal vegetation
    civic = {
        primaryMaterial = Enum.Material.Cobblestone,
        secondaryMaterial = Enum.Material.Brick,
        grassPercentage = 0.02,
    },
    -- Urban areas: Mostly paved with some dirt paths
    urban = {
        primaryMaterial = Enum.Material.Cobblestone,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.08,
    },
    -- Rural areas: Balanced ground and grass for farmland
    rural = {
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Grass,
        grassPercentage = 0.40,
    },
    -- Wilderness: Sandy/arid with sparse vegetation
    wilderness = {
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Sandstone,
        grassPercentage = 0.30,
    },
}

-- Proximity rules (highest priority)
-- Water proximity creates lush vegetation bands
MaterialConfig.PROXIMITY_RULES = {
    road = {
        material = Enum.Material.Cobblestone,
        radius = 5,
    } :: ProximityRule,
    river = {
        material = Enum.Material.Sand,
        radius = 8, -- Narrow sand beach at water edge
    } :: ProximityRule,
    riverGrass = {
        material = Enum.Material.Grass,
        radius = 25, -- Lush grass band near water
    } :: ProximityRule,
    structure = {
        material = Enum.Material.Cobblestone,
        radius = 10,
    } :: ProximityRule,
    fountain = {
        material = Enum.Material.Sand,
        radius = 8, -- Narrow sand around fountains
    } :: ProximityRule,
    fountainGrass = {
        material = Enum.Material.Grass,
        radius = 18, -- Grass ring around fountain sand
    } :: ProximityRule,
}

-- Landmark-specific material overrides
MaterialConfig.LANDMARK_MATERIALS = {
    Forum = Enum.Material.Cobblestone,
    Colosseum = Enum.Material.Sand,
    Thermae = Enum.Material.Cobblestone,
    Temple = Enum.Material.Cobblestone,
    CircusMaximus = Enum.Material.Sand,
}

-- Materials allowed in Mediterranean climate (NOT allowed: Snow, Ice, Mud, LeafyGrass)
MaterialConfig.ALLOWED_MATERIALS = {
    Enum.Material.Grass,
    Enum.Material.Ground,
    Enum.Material.Rock,
    Enum.Material.Sand,
    Enum.Material.Sandstone,
    Enum.Material.Cobblestone,
    Enum.Material.Slate,
    Enum.Material.Brick,
}

-- Target overall map coverage (for reference/validation)
-- Mediterranean balance: ~40% Grass, ~30% Ground, ~20% Rock/Sandstone, ~10% Sand
MaterialConfig.TARGET_COVERAGE = {
    Grass = 0.40, -- Concentrated in valleys, near water
    Ground = 0.30, -- Paths, transitions, flat areas
    Rock = 0.10, -- Hilltops, steep slopes
    Sandstone = 0.08, -- Hillsides, arid zones
    Slate = 0.02, -- Rocky outcrops
    Sand = 0.05, -- Beaches, water edges
    Cobblestone = 0.05, -- Roads, urban areas
}

-- Helper functions

-- Get altitude band for a given height
function MaterialConfig.getAltitudeBand(altitude: number): AltitudeBand
    for _, band in ipairs(MaterialConfig.ALTITUDE_BANDS) do
        if altitude >= band.minAltitude and altitude < band.maxAltitude then
            return band
        end
    end
    -- Default to lowest band if no match
    return MaterialConfig.ALTITUDE_BANDS[#MaterialConfig.ALTITUDE_BANDS]
end

-- Get slope band for a given slope in degrees
function MaterialConfig.getSlopeBand(slopeDegrees: number): SlopeBand
    for _, band in ipairs(MaterialConfig.SLOPE_BANDS) do
        if slopeDegrees >= band.minSlope and slopeDegrees < band.maxSlope then
            return band
        end
    end
    -- Default to gentlest slope band if no match
    return MaterialConfig.SLOPE_BANDS[#MaterialConfig.SLOPE_BANDS]
end

-- Get zone material override
function MaterialConfig.getZoneMaterial(zoneType: string): ZoneMaterialOverride?
    return MaterialConfig.ZONE_MATERIALS[zoneType]
end

-- Check if a material is allowed in Mediterranean climate
function MaterialConfig.isAllowedMaterial(material: Enum.Material): boolean
    for _, allowed in ipairs(MaterialConfig.ALLOWED_MATERIALS) do
        if material == allowed then
            return true
        end
    end
    return false
end

-- Get landmark material override
function MaterialConfig.getLandmarkMaterial(landmarkType: string): Enum.Material?
    return MaterialConfig.LANDMARK_MATERIALS[landmarkType]
end

return MaterialConfig
