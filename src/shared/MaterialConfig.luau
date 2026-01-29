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
MaterialConfig.VERSION = "2.1.0"

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
-- Rebalanced in v2.1.0: More grass throughout (issue #148)
MaterialConfig.ALTITUDE_BANDS = {
    -- Hilltops: Rocky and arid, but with some grass patches
    {
        minAltitude = 50,
        maxAltitude = math.huge,
        primaryMaterial = Enum.Material.Rock,
        secondaryMaterial = Enum.Material.Slate,
        grassPercentage = 0.15,
    },
    -- Upper hillsides: Mix of rock and sandstone, more grass
    {
        minAltitude = 40,
        maxAltitude = 50,
        primaryMaterial = Enum.Material.Sandstone,
        secondaryMaterial = Enum.Material.Rock,
        grassPercentage = 0.25,
    },
    -- Lower hillsides: Ground with grass
    {
        minAltitude = 30,
        maxAltitude = 40,
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Grass,
        grassPercentage = 0.40,
    },
    -- Flat areas: More grass-dominant
    {
        minAltitude = 20,
        maxAltitude = 30,
        primaryMaterial = Enum.Material.Grass,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.60,
    },
    -- Valleys: Lush grass, concentrated vegetation
    {
        minAltitude = -math.huge,
        maxAltitude = 20,
        primaryMaterial = Enum.Material.Grass,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.75,
    },
}

-- Slope bands for material selection (degrees)
-- Steeper slopes = more rocky/arid materials
-- Rebalanced in v2.1.0: Less aggressive rock on slopes (issue #148)
MaterialConfig.SLOPE_BANDS = {
    -- Very steep: Rocky outcrops, but some grass in crevices
    {
        minSlope = 40,
        maxSlope = math.huge,
        primaryMaterial = Enum.Material.Rock,
        secondaryMaterial = Enum.Material.Slate,
        grassPercentage = 0.10,
    },
    -- Steep hillsides: Sandstone and rock, with grass patches
    {
        minSlope = 30,
        maxSlope = 40,
        primaryMaterial = Enum.Material.Sandstone,
        secondaryMaterial = Enum.Material.Rock,
        grassPercentage = 0.20,
    },
    -- Moderate slopes: Ground with grass
    {
        minSlope = 18,
        maxSlope = 30,
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Grass,
        grassPercentage = 0.35,
    },
    -- Gentle slopes: Grass-dominant
    {
        minSlope = 0,
        maxSlope = 18,
        primaryMaterial = Enum.Material.Grass,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.55,
    },
}

-- Zone material overrides (higher priority than altitude)
-- Mediterranean zones: urban areas paved, wilderness has grass
-- Rebalanced in v2.1.0: More grass in wilderness/rural (issue #148)
MaterialConfig.ZONE_MATERIALS = {
    -- Civic areas: Heavy paving with minimal vegetation
    civic = {
        primaryMaterial = Enum.Material.Cobblestone,
        secondaryMaterial = Enum.Material.Brick,
        grassPercentage = 0.05,
    },
    -- Urban areas: Mostly paved with some dirt paths
    urban = {
        primaryMaterial = Enum.Material.Cobblestone,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.12,
    },
    -- Rural areas: Grass-dominant farmland
    rural = {
        primaryMaterial = Enum.Material.Grass,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.55,
    },
    -- Wilderness: Grass with ground/sandstone patches
    wilderness = {
        primaryMaterial = Enum.Material.Grass,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.50,
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
-- Rebalanced in v2.1.0: ~55% Grass (issue #148)
MaterialConfig.TARGET_COVERAGE = {
    Grass = 0.55, -- Dominant across valleys, flat areas, and wilderness
    Ground = 0.22, -- Paths, transitions, hillsides
    Rock = 0.07, -- Hilltops, very steep slopes only
    Sandstone = 0.05, -- Upper hillsides
    Slate = 0.01, -- Rocky outcrops
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
