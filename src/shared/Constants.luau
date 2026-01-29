--!strict
--[[
    Constants - Shared constants for Legions & Cycles: Ancient Rome
    Roman-themed values for grid sizes, tree parameters, colors, and materials
]]

local Constants = {}
Constants.VERSION = "1.0.0"

-- Grid sizes for placement system (studs)
Constants.GRID_SIZES = { 0, 1, 2, 4, 8 }

-- Tree type configurations for procedural generation
Constants.TREE_TYPES = {
    CYPRESS = {
        maxIterations = 8,
        branchAngle = 15,
        lengthMultiplier = 0.85,
        radiusMultiplier = 0.7,
        trunkColor = Color3.fromRGB(101, 67, 33),
        leafColor = Color3.fromRGB(34, 85, 51),
        leafMaterial = Enum.Material.Grass,
    },
    OLIVE = {
        maxIterations = 5,
        branchAngle = 45,
        lengthMultiplier = 0.75,
        radiusMultiplier = 0.65,
        trunkColor = Color3.fromRGB(139, 119, 101),
        leafColor = Color3.fromRGB(128, 128, 105),
        leafMaterial = Enum.Material.Grass,
    },
    STONE_PINE = {
        maxIterations = 6,
        branchAngle = 60,
        lengthMultiplier = 0.8,
        radiusMultiplier = 0.6,
        trunkColor = Color3.fromRGB(139, 90, 43),
        leafColor = Color3.fromRGB(46, 125, 50),
        leafMaterial = Enum.Material.Grass,
    },
}

-- Light colors
Constants.TORCH_COLOR = Color3.fromRGB(255, 147, 41)
Constants.BRAZIER_COLOR = Color3.fromRGB(255, 100, 20)
Constants.OIL_LAMP_COLOR = Color3.fromRGB(255, 180, 100)

-- Roman material colors
Constants.MARBLE_WHITE = Color3.fromRGB(240, 234, 214)
Constants.MARBLE_GRAY = Color3.fromRGB(180, 180, 180)
Constants.TERRACOTTA = Color3.fromRGB(178, 92, 53)
Constants.TERRACOTTA_DARK = Color3.fromRGB(150, 75, 45)
Constants.BRONZE = Color3.fromRGB(205, 127, 50)
Constants.BRONZE_AGED = Color3.fromRGB(102, 93, 30)
Constants.OLIVE_GREEN = Color3.fromRGB(128, 128, 0)
Constants.SAND = Color3.fromRGB(194, 178, 128)
Constants.STONE_GRAY = Color3.fromRGB(136, 140, 141)
Constants.WOOD_BROWN = Color3.fromRGB(139, 90, 43)
Constants.GOLD = Color3.fromRGB(212, 175, 55)
Constants.IRON = Color3.fromRGB(82, 82, 82)
Constants.LEATHER = Color3.fromRGB(139, 69, 19)

-- Roman building materials (Roblox Material enum values)
Constants.MATERIALS = {
    MARBLE = Enum.Material.Marble,
    BRICK = Enum.Material.Brick,
    CONCRETE = Enum.Material.Concrete,
    WOOD = Enum.Material.Wood,
    SAND = Enum.Material.Sand,
    SLATE = Enum.Material.Slate,
    COBBLESTONE = Enum.Material.Cobblestone,
    GRANITE = Enum.Material.Granite,
}

-- Roman architecture dimensions (in studs)
Constants.ARCHITECTURE = {
    COLUMN_HEIGHT_SMALL = 8,
    COLUMN_HEIGHT_MEDIUM = 12,
    COLUMN_HEIGHT_LARGE = 16,
    COLUMN_RADIUS_SMALL = 0.5,
    COLUMN_RADIUS_MEDIUM = 0.75,
    COLUMN_RADIUS_LARGE = 1,
    ARCH_HEIGHT = 10,
    ARCH_WIDTH = 8,
    WALL_THICKNESS = 1,
    ROOF_PITCH = 15, -- degrees
}

-- Water and pool constraints
-- CRITICAL: Water terrain must ONLY exist within part-built pool walls
Constants.POOL = {
    WALL_THICKNESS = 0.5,
    MIN_DEPTH = 2,
    MAX_DEPTH = 6,
    WATER_OFFSET = 0.1, -- How far below wall top water sits
}

-- Projectile parameters (Pilum, Ballista, Scorpio)
Constants.PROJECTILES = {
    PILUM = {
        speed = 100,
        gravity = workspace.Gravity,
        damage = 50,
    },
    BALLISTA_BOLT = {
        speed = 200,
        gravity = workspace.Gravity * 0.5,
        damage = 150,
    },
    SCORPIO_BOLT = {
        speed = 250,
        gravity = workspace.Gravity * 0.3,
        damage = 100,
    },
}

-- AI state machine parameters
Constants.AI = {
    PATROL_SPEED = 8,
    ALERT_SPEED = 12,
    PURSUE_SPEED = 16,
    DETECTION_RANGE = 50,
    ALERT_RANGE = 100,
    LOSE_INTEREST_TIME = 10,
}

-- Terrain slope constraints for placement
-- Slopes are in degrees for readability
Constants.SLOPE = {
    MAX_URBAN_SLOPE = 30, -- Urban zones should avoid terrain steeper than 30 degrees
    MAX_FOUNTAIN_SLOPE = 20, -- Fountains need flatter ground (max 20 degrees)
    RIVER_CLIFF_MARGIN = 30, -- Extra margin around river to avoid cliff edges
    SAMPLE_DISTANCE = 4, -- Distance to sample terrain for slope calculation
}

return Constants
