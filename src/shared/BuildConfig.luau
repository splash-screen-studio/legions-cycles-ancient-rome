--!strict
--[[
    BuildConfig - Shared configuration for the building system
    Defines structure types, costs, and validation rules
]]

local BuildConfig = {}
BuildConfig.VERSION = "1.2.0"

-- RemoteEvent/Function names for client-server communication
BuildConfig.REMOTES = {
    PLACE_STRUCTURE = "BuildPlaceStructure",
    PLACEMENT_RESULT = "BuildPlacementResult",
}

-- Structure categories for menu organization
BuildConfig.CATEGORIES = {
    RESIDENTIAL = "Residential",
    COMMERCIAL = "Commercial",
    RELIGIOUS = "Religious",
    INFRASTRUCTURE = "Infrastructure",
}

-- Structure type definitions
-- Each structure has: id, name, category, cost, size (footprint in studs)
export type StructureType = {
    id: string,
    name: string,
    category: string,
    cost: number,
    size: Vector3,
    description: string,
}

-- Available structures for v1.0.0 (basic set)
BuildConfig.STRUCTURES = {
    DOMUS = {
        id = "DOMUS",
        name = "Domus",
        category = BuildConfig.CATEGORIES.RESIDENTIAL,
        cost = 200,
        size = Vector3.new(20, 12, 20),
        description = "Roman house for citizens",
    },
    TABERNA = {
        id = "TABERNA",
        name = "Taberna",
        category = BuildConfig.CATEGORIES.COMMERCIAL,
        cost = 75,
        size = Vector3.new(12, 8, 10),
        description = "Small shop or tavern",
    },
    TEMPLE = {
        id = "TEMPLE",
        name = "Temple",
        category = BuildConfig.CATEGORIES.RELIGIOUS,
        cost = 1000,
        size = Vector3.new(24, 20, 30),
        description = "Temple to honor the gods",
    },
    WALL = {
        id = "WALL",
        name = "Wall",
        category = BuildConfig.CATEGORIES.INFRASTRUCTURE,
        cost = 25,
        size = Vector3.new(8, 6, 2),
        description = "Defensive wall segment",
    },
    INSULA = {
        id = "INSULA",
        name = "Insula",
        category = BuildConfig.CATEGORIES.RESIDENTIAL,
        cost = 350,
        size = Vector3.new(16, 20, 16),
        description = "Multi-story apartment for common citizens",
    },
    FORUM_STALL = {
        id = "FORUM_STALL",
        name = "Forum Stall",
        category = BuildConfig.CATEGORIES.COMMERCIAL,
        cost = 50,
        size = Vector3.new(8, 6, 8),
        description = "Market stall for traders",
    },
    WATCHTOWER = {
        id = "WATCHTOWER",
        name = "Watchtower",
        category = BuildConfig.CATEGORIES.INFRASTRUCTURE,
        cost = 150,
        size = Vector3.new(6, 16, 6),
        description = "Guard tower for defense",
    },
    ARCH = {
        id = "ARCH",
        name = "Arch",
        category = BuildConfig.CATEGORIES.INFRASTRUCTURE,
        cost = 500,
        size = Vector3.new(12, 14, 4),
        description = "Triumphal arch celebrating victories",
    },
    THERMAE = {
        id = "THERMAE",
        name = "Thermae",
        category = BuildConfig.CATEGORIES.COMMERCIAL,
        cost = 800,
        size = Vector3.new(24, 10, 20),
        description = "Public bathhouse for citizens",
    },
}

-- Order of structures in the menu (by id)
BuildConfig.STRUCTURE_ORDER = {
    "DOMUS",
    "INSULA",
    "TABERNA",
    "FORUM_STALL",
    "THERMAE",
    "TEMPLE",
    "WALL",
    "WATCHTOWER",
    "ARCH",
}

-- UI Constants for mobile-first design
BuildConfig.UI = {
    -- Build button (circular, bottom-center, thumb-accessible)
    BUILD_BUTTON_SIZE = 70, -- Pixels, larger than 44pt minimum
    BUILD_BUTTON_OFFSET_Y = 100, -- Pixels from bottom

    -- Structure menu
    MENU_WIDTH = 320,
    MENU_HEIGHT = 400,
    GRID_CELL_SIZE = 72, -- Size of each structure icon cell
    GRID_PADDING = 8,

    -- Colors (Roman aesthetic)
    COLORS = {
        PRIMARY = Color3.fromRGB(139, 90, 43), -- Terracotta
        SECONDARY = Color3.fromRGB(205, 175, 125), -- Sand
        ACCENT = Color3.fromRGB(180, 160, 100), -- Gold/Bronze
        BACKGROUND = Color3.fromRGB(45, 35, 25), -- Dark wood
        TEXT = Color3.fromRGB(255, 248, 240), -- Off-white
        VALID = Color3.fromRGB(100, 200, 100), -- Green for valid placement
        INVALID = Color3.fromRGB(200, 100, 100), -- Red for invalid placement
    },

    -- Animation
    TWEEN_TIME = 0.2,
}

-- Placement validation rules
BuildConfig.PLACEMENT = {
    MAX_SLOPE_DEGREES = 15, -- Maximum terrain slope for building
    MIN_HEIGHT_ABOVE_WATER = 2, -- Minimum height above water level
    WATER_LEVEL = 5, -- Approximate water level (structures cannot be placed below)
}

-- Get a structure by its ID
function BuildConfig.getStructure(structureId: string): StructureType?
    return BuildConfig.STRUCTURES[structureId]
end

-- Get all structures in menu order
function BuildConfig.getStructuresInOrder(): { StructureType }
    local result = {}
    for _, id in ipairs(BuildConfig.STRUCTURE_ORDER) do
        local structure = BuildConfig.STRUCTURES[id]
        if structure then
            table.insert(result, structure)
        end
    end
    return result
end

-- Get the cost of a structure
function BuildConfig.getCost(structureId: string): number
    local structure = BuildConfig.STRUCTURES[structureId]
    return if structure then structure.cost else 0
end

return BuildConfig
