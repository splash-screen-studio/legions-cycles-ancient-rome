--!strict
--[[
    LightingConfig - Configuration for interior lighting in Roman structures

    Defines light source types, colors, and placement rules for realistic
    Roman interior lighting with oil lamps, torches, and braziers.
]]

local LightingConfig = {}
LightingConfig.VERSION = "1.0.0"

-- Roman light colors (warm, fire-based)
LightingConfig.Colors = {
    -- Torch/fire colors (bright warm orange)
    TORCH_WARM = Color3.fromRGB(255, 147, 41),
    TORCH_HOT = Color3.fromRGB(255, 170, 80),

    -- Oil lamp colors (softer, more yellow)
    LAMP_WARM = Color3.fromRGB(255, 180, 100),
    LAMP_SOFT = Color3.fromRGB(255, 200, 130),

    -- Brazier colors (strong orange-red)
    BRAZIER_WARM = Color3.fromRGB(255, 130, 50),
    BRAZIER_HOT = Color3.fromRGB(255, 160, 70),

    -- Daylight for doorways/windows (varies by time)
    DAYLIGHT_WARM = Color3.fromRGB(255, 240, 220),
    DAYLIGHT_COOL = Color3.fromRGB(200, 210, 240),
}

-- Light fixture materials
LightingConfig.Materials = {
    BRONZE = Enum.Material.Metal,
    IRON = Enum.Material.Metal,
    TERRACOTTA = Enum.Material.Brick,
    STONE = Enum.Material.Slate,
}

-- Light fixture colors
LightingConfig.FixtureColors = {
    BRONZE = Color3.fromRGB(180, 140, 80),
    IRON = Color3.fromRGB(80, 75, 70),
    TERRACOTTA = Color3.fromRGB(180, 100, 70),
    STONE = Color3.fromRGB(160, 155, 145),
}

-- Light source type definitions
export type LightSourceType = "torch" | "oilLamp" | "brazier" | "doorway"

export type LightSourceConfig = {
    brightness: number,
    range: number,
    color: Color3,
    shadows: boolean,
    flickerEnabled: boolean,
    flickerIntensity: number?, -- 0.0 to 1.0
}

-- Light source configurations by type
LightingConfig.Sources = {
    torch = {
        brightness = 1.5,
        range = 20,
        color = LightingConfig.Colors.TORCH_WARM,
        shadows = true,
        flickerEnabled = true,
        flickerIntensity = 0.3,
    },
    oilLamp = {
        brightness = 0.8,
        range = 12,
        color = LightingConfig.Colors.LAMP_WARM,
        shadows = true,
        flickerEnabled = true,
        flickerIntensity = 0.15,
    },
    brazier = {
        brightness = 2.0,
        range = 30,
        color = LightingConfig.Colors.BRAZIER_WARM,
        shadows = true,
        flickerEnabled = true,
        flickerIntensity = 0.25,
    },
    doorway = {
        brightness = 2.0,
        range = 30,
        color = LightingConfig.Colors.DAYLIGHT_WARM,
        shadows = true,
        flickerEnabled = false,
        flickerIntensity = 0,
    },
}

-- Fixture dimensions
LightingConfig.Fixtures = {
    -- Wall torch holder
    torch = {
        holderSize = Vector3.new(0.5, 1.5, 0.5),
        bracketSize = Vector3.new(0.3, 0.2, 0.8),
        torchSize = Vector3.new(0.3, 2, 0.3),
        lightOffset = Vector3.new(0, 1.5, 0), -- Light position relative to fixture base
    },
    -- Oil lamp (tabletop or hanging)
    oilLamp = {
        baseSize = Vector3.new(0.6, 0.3, 0.6),
        bodySize = Vector3.new(0.4, 0.5, 0.4),
        lightOffset = Vector3.new(0, 0.6, 0),
    },
    -- Floor brazier
    brazier = {
        baseSize = Vector3.new(2, 0.5, 2),
        bowlSize = Vector3.new(1.5, 1, 1.5),
        legHeight = 1.5,
        lightOffset = Vector3.new(0, 2, 0),
    },
}

-- Landmark lighting configurations
-- Maps landmark types to their interior lighting needs
export type LandmarkLightingConfig = {
    torchCount: number,
    oilLampCount: number,
    brazierCount: number,
    hasDoorwayLight: boolean,
}

LightingConfig.LandmarkLighting = {
    -- Major landmarks
    Forum = {
        torchCount = 8,
        oilLampCount = 4,
        brazierCount = 2,
        hasDoorwayLight = true,
    },
    Colosseum = {
        torchCount = 12,
        oilLampCount = 0,
        brazierCount = 4,
        hasDoorwayLight = true,
    },
    Thermae = {
        torchCount = 6,
        oilLampCount = 4,
        brazierCount = 2,
        hasDoorwayLight = true,
    },
    Temple = {
        torchCount = 4,
        oilLampCount = 2,
        brazierCount = 1,
        hasDoorwayLight = true,
    },
    CircusMaximus = {
        torchCount = 8,
        oilLampCount = 0,
        brazierCount = 4,
        hasDoorwayLight = false,
    },
    -- Minor landmarks
    Castrum = {
        torchCount = 6,
        oilLampCount = 2,
        brazierCount = 2,
        hasDoorwayLight = true,
    },
    Macellum = {
        torchCount = 4,
        oilLampCount = 4,
        brazierCount = 0,
        hasDoorwayLight = true,
    },
    Horreum = {
        torchCount = 4,
        oilLampCount = 2,
        brazierCount = 0,
        hasDoorwayLight = true,
    },
    Pharos = {
        torchCount = 2,
        oilLampCount = 0,
        brazierCount = 1, -- Beacon brazier
        hasDoorwayLight = false,
    },
    Emporium = {
        torchCount = 6,
        oilLampCount = 4,
        brazierCount = 0,
        hasDoorwayLight = true,
    },
    VillaRustica = {
        torchCount = 2,
        oilLampCount = 4,
        brazierCount = 1,
        hasDoorwayLight = true,
    },
    PalaestraMinor = {
        torchCount = 4,
        oilLampCount = 0,
        brazierCount = 2,
        hasDoorwayLight = false,
    },
    Granarium = {
        torchCount = 2,
        oilLampCount = 2,
        brazierCount = 0,
        hasDoorwayLight = true,
    },
    ThermaeMinor = {
        torchCount = 4,
        oilLampCount = 2,
        brazierCount = 1,
        hasDoorwayLight = true,
    },
    ForumPiscarium = {
        torchCount = 4,
        oilLampCount = 4,
        brazierCount = 0,
        hasDoorwayLight = true,
    },
    -- Shrines/small temples
    TempleMars = {
        torchCount = 2,
        oilLampCount = 2,
        brazierCount = 1,
        hasDoorwayLight = true,
    },
    TempleNeptune = {
        torchCount = 2,
        oilLampCount = 2,
        brazierCount = 1,
        hasDoorwayLight = true,
    },
    SacellumCeres = {
        torchCount = 2,
        oilLampCount = 2,
        brazierCount = 1,
        hasDoorwayLight = true,
    },
}

-- Default configuration for unknown landmark types
LightingConfig.DefaultLandmarkLighting = {
    torchCount = 2,
    oilLampCount = 2,
    brazierCount = 0,
    hasDoorwayLight = true,
}

-- Get lighting config for a landmark type (with fallback to default)
function LightingConfig.getForLandmark(landmarkType: string): LandmarkLightingConfig
    return LightingConfig.LandmarkLighting[landmarkType] or LightingConfig.DefaultLandmarkLighting
end

return LightingConfig
