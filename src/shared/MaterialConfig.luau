--!strict
--[[
    MaterialConfig - Configuration for context-aware terrain materials
    Defines material rules for Mediterranean/Roman terrain.

    Material selection follows a priority chain:
    1. Road proximity (cobblestone)
    2. Water proximity (sand)
    3. Structure/landmark proximity (cobblestone/marble)
    4. Zone overlay (urban = paved, rural = grass)
    5. Base altitude (high = rock, low = grass)
]]

local MaterialConfig = {}
MaterialConfig.VERSION = "1.0.0"

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

-- Altitude bands for base material selection
-- Heights are in studs, based on TerrainManager's baseHeight=20, amplitude=40
MaterialConfig.ALTITUDE_BANDS: { AltitudeBand } = {
    {
        minAltitude = 50,
        maxAltitude = math.huge,
        primaryMaterial = Enum.Material.Rock,
        secondaryMaterial = Enum.Material.Slate,
        grassPercentage = 0.05,
    },
    {
        minAltitude = 35,
        maxAltitude = 50,
        primaryMaterial = Enum.Material.Rock,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.15,
    },
    {
        minAltitude = 20,
        maxAltitude = 35,
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Grass,
        grassPercentage = 0.40,
    },
    {
        minAltitude = -math.huge,
        maxAltitude = 20,
        primaryMaterial = Enum.Material.Grass,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.60,
    },
}

-- Zone material overrides (higher priority than altitude)
MaterialConfig.ZONE_MATERIALS: { [string]: ZoneMaterialOverride } = {
    civic = {
        primaryMaterial = Enum.Material.Cobblestone,
        secondaryMaterial = Enum.Material.Brick,
        grassPercentage = 0.05,
    },
    urban = {
        primaryMaterial = Enum.Material.Cobblestone,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.10,
    },
    rural = {
        primaryMaterial = Enum.Material.Ground,
        secondaryMaterial = Enum.Material.Grass,
        grassPercentage = 0.50,
    },
    wilderness = {
        primaryMaterial = Enum.Material.Grass,
        secondaryMaterial = Enum.Material.Ground,
        grassPercentage = 0.55,
    },
}

-- Proximity rules (highest priority)
MaterialConfig.PROXIMITY_RULES = {
    road = {
        material = Enum.Material.Cobblestone,
        radius = 5,
    } :: ProximityRule,
    river = {
        material = Enum.Material.Sand,
        radius = 20,
    } :: ProximityRule,
    structure = {
        material = Enum.Material.Cobblestone,
        radius = 10,
    } :: ProximityRule,
    fountain = {
        material = Enum.Material.Sand,
        radius = 15,
    } :: ProximityRule,
}

-- Landmark-specific material overrides
MaterialConfig.LANDMARK_MATERIALS: { [string]: Enum.Material } = {
    Forum = Enum.Material.Cobblestone,
    Colosseum = Enum.Material.Sand,
    Thermae = Enum.Material.Cobblestone,
    Temple = Enum.Material.Cobblestone,
    CircusMaximus = Enum.Material.Sand,
}

-- Materials allowed in Mediterranean climate (NOT allowed: Snow, Ice, Mud, LeafyGrass)
MaterialConfig.ALLOWED_MATERIALS: { Enum.Material } = {
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
MaterialConfig.TARGET_COVERAGE = {
    Ground = 0.35,
    Grass = 0.25,
    Rock = 0.15,
    Slate = 0.05,
    Sand = 0.05,
    Sandstone = 0.05,
    Cobblestone = 0.10,
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
