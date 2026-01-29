--!strict
--[[
    ProgressionConfig - Level thresholds, unlocks, and Roman rank definitions

    Roman Rank Progression:
    - Citizen (1-5): Basic access, starter buildings
    - Merchant (6-10): Trade buildings, market access
    - Senator (11-15): Government buildings, civic structures
    - Consul (16-20): Military buildings, advanced structures
    - Imperator (21+): All buildings, legendary structures

    XP is earned through gameplay activities and used to level up.
    Each level unlocks new building types and features.
]]

local ProgressionConfig = {}
ProgressionConfig.VERSION = "1.0.0"

-- Roman rank definitions with Latin names
export type RankName = "Citizen" | "Merchant" | "Senator" | "Consul" | "Imperator"

export type RankInfo = {
    name: RankName,
    latinName: string,
    minLevel: number,
    maxLevel: number,
    color: Color3,
}

-- Rank definitions
ProgressionConfig.RANKS = {
    {
        name = "Citizen",
        latinName = "Civis",
        minLevel = 1,
        maxLevel = 5,
        color = Color3.fromRGB(194, 178, 128), -- Sand/tan
    },
    {
        name = "Merchant",
        latinName = "Mercator",
        minLevel = 6,
        maxLevel = 10,
        color = Color3.fromRGB(205, 127, 50), -- Bronze
    },
    {
        name = "Senator",
        latinName = "Senator",
        minLevel = 11,
        maxLevel = 15,
        color = Color3.fromRGB(192, 192, 192), -- Silver
    },
    {
        name = "Consul",
        latinName = "Consul",
        minLevel = 16,
        maxLevel = 20,
        color = Color3.fromRGB(212, 175, 55), -- Gold
    },
    {
        name = "Imperator",
        latinName = "Imperator",
        minLevel = 21,
        maxLevel = 999, -- No upper limit
        color = Color3.fromRGB(128, 0, 128), -- Imperial purple
    },
}

-- XP required to reach each level
-- Formula: Base XP + (Level - 1) * XP per level
-- Level 1 = 0 XP (starting level)
-- Level 2 = 100 XP
-- Level 3 = 250 XP
-- etc.
ProgressionConfig.BASE_XP = 0
ProgressionConfig.XP_PER_LEVEL = 100
ProgressionConfig.XP_GROWTH_RATE = 1.5 -- Multiplier for each level

-- Calculate XP required for a specific level
function ProgressionConfig.getXPForLevel(level: number): number
    if level <= 1 then
        return 0
    end

    -- XP grows exponentially: base + sum of (XP_PER_LEVEL * growth^(i-1)) for i = 1 to level-1
    local totalXP = 0
    for i = 1, level - 1 do
        totalXP = totalXP + math.floor(ProgressionConfig.XP_PER_LEVEL * math.pow(ProgressionConfig.XP_GROWTH_RATE, i - 1))
    end
    return totalXP
end

-- Calculate level from total XP
function ProgressionConfig.getLevelFromXP(xp: number): number
    local level = 1

    while true do
        local nextLevelXP = ProgressionConfig.getXPForLevel(level + 1)
        if xp < nextLevelXP then
            break
        end
        level = level + 1

        -- Safety cap at level 100
        if level >= 100 then
            break
        end
    end

    return level
end

-- Get rank info for a specific level
function ProgressionConfig.getRankForLevel(level: number): RankInfo
    for _, rank in ipairs(ProgressionConfig.RANKS) do
        if level >= rank.minLevel and level <= rank.maxLevel then
            return rank
        end
    end
    -- Default to highest rank if level exceeds all
    return ProgressionConfig.RANKS[#ProgressionConfig.RANKS]
end

-- Unlock types
export type UnlockType = "building" | "feature" | "decoration" | "ability"

export type Unlock = {
    id: string,
    name: string,
    description: string,
    unlockType: UnlockType,
    requiredLevel: number,
}

-- All unlocks in the game, sorted by level requirement
ProgressionConfig.UNLOCKS = {
    -- Level 1 - Citizen starter unlocks
    {
        id = "domus_basic",
        name = "Basic Domus",
        description = "A simple Roman house",
        unlockType = "building",
        requiredLevel = 1,
    },
    {
        id = "well",
        name = "Well",
        description = "A simple water well",
        unlockType = "building",
        requiredLevel = 1,
    },
    {
        id = "garden_small",
        name = "Small Garden",
        description = "A small Roman garden",
        unlockType = "decoration",
        requiredLevel = 1,
    },

    -- Level 2
    {
        id = "workshop_basic",
        name = "Basic Workshop",
        description = "A simple crafting workshop",
        unlockType = "building",
        requiredLevel = 2,
    },

    -- Level 3
    {
        id = "fence_wood",
        name = "Wooden Fence",
        description = "Wooden perimeter fence",
        unlockType = "decoration",
        requiredLevel = 3,
    },
    {
        id = "storage_small",
        name = "Small Storage",
        description = "Basic goods storage",
        unlockType = "building",
        requiredLevel = 3,
    },

    -- Level 4
    {
        id = "statue_citizen",
        name = "Citizen Statue",
        description = "A modest statue",
        unlockType = "decoration",
        requiredLevel = 4,
    },

    -- Level 5
    {
        id = "domus_medium",
        name = "Medium Domus",
        description = "An upgraded Roman house with atrium",
        unlockType = "building",
        requiredLevel = 5,
    },

    -- Level 6 - Merchant tier begins
    {
        id = "taberna",
        name = "Taberna",
        description = "A Roman shop for trade",
        unlockType = "building",
        requiredLevel = 6,
    },
    {
        id = "trade_ability",
        name = "Trade",
        description = "Ability to trade with other players",
        unlockType = "ability",
        requiredLevel = 6,
    },

    -- Level 7
    {
        id = "horreum_small",
        name = "Small Horreum",
        description = "A small warehouse",
        unlockType = "building",
        requiredLevel = 7,
    },

    -- Level 8
    {
        id = "fountain_basin",
        name = "Basin Fountain",
        description = "A decorative water basin",
        unlockType = "decoration",
        requiredLevel = 8,
    },

    -- Level 9
    {
        id = "insula",
        name = "Insula",
        description = "A Roman apartment block",
        unlockType = "building",
        requiredLevel = 9,
    },

    -- Level 10
    {
        id = "macellum",
        name = "Macellum",
        description = "A Roman market hall",
        unlockType = "building",
        requiredLevel = 10,
    },

    -- Level 11 - Senator tier begins
    {
        id = "curia_minor",
        name = "Minor Curia",
        description = "A small senate house",
        unlockType = "building",
        requiredLevel = 11,
    },
    {
        id = "civic_planning",
        name = "Civic Planning",
        description = "Plan larger city layouts",
        unlockType = "feature",
        requiredLevel = 11,
    },

    -- Level 12
    {
        id = "thermae_minor",
        name = "Minor Thermae",
        description = "A small public bath house",
        unlockType = "building",
        requiredLevel = 12,
    },

    -- Level 13
    {
        id = "domus_large",
        name = "Large Domus",
        description = "A grand Roman house with garden",
        unlockType = "building",
        requiredLevel = 13,
    },

    -- Level 14
    {
        id = "fountain_public",
        name = "Public Fountain",
        description = "A large public fountain",
        unlockType = "decoration",
        requiredLevel = 14,
    },

    -- Level 15
    {
        id = "basilica",
        name = "Basilica",
        description = "A Roman public building",
        unlockType = "building",
        requiredLevel = 15,
    },

    -- Level 16 - Consul tier begins
    {
        id = "castrum_small",
        name = "Small Castrum",
        description = "A small military fort",
        unlockType = "building",
        requiredLevel = 16,
    },
    {
        id = "military_command",
        name = "Military Command",
        description = "Command military units",
        unlockType = "ability",
        requiredLevel = 16,
    },

    -- Level 17
    {
        id = "palaestra",
        name = "Palaestra",
        description = "A wrestling and training ground",
        unlockType = "building",
        requiredLevel = 17,
    },

    -- Level 18
    {
        id = "triumphal_arch",
        name = "Triumphal Arch",
        description = "A monumental arch",
        unlockType = "decoration",
        requiredLevel = 18,
    },

    -- Level 19
    {
        id = "horreum_large",
        name = "Large Horreum",
        description = "A large warehouse complex",
        unlockType = "building",
        requiredLevel = 19,
    },

    -- Level 20
    {
        id = "temple",
        name = "Temple",
        description = "A Roman temple",
        unlockType = "building",
        requiredLevel = 20,
    },

    -- Level 21+ - Imperator tier
    {
        id = "amphitheatre",
        name = "Amphitheatre",
        description = "A grand arena for games",
        unlockType = "building",
        requiredLevel = 21,
    },
    {
        id = "imperial_decree",
        name = "Imperial Decree",
        description = "Issue server-wide edicts",
        unlockType = "ability",
        requiredLevel = 21,
    },

    -- Level 22
    {
        id = "thermae_major",
        name = "Major Thermae",
        description = "A grand bath complex",
        unlockType = "building",
        requiredLevel = 22,
    },

    -- Level 23
    {
        id = "aqueduct",
        name = "Aqueduct",
        description = "Build aqueduct sections",
        unlockType = "building",
        requiredLevel = 23,
    },

    -- Level 24
    {
        id = "nymphaeum",
        name = "Nymphaeum",
        description = "A monumental fountain shrine",
        unlockType = "decoration",
        requiredLevel = 24,
    },

    -- Level 25
    {
        id = "colosseum",
        name = "Colosseum",
        description = "A legendary arena",
        unlockType = "building",
        requiredLevel = 25,
    },
}

-- Get all unlocks for a specific level
function ProgressionConfig.getUnlocksForLevel(level: number): { Unlock }
    local unlocks = {}
    for _, unlock in ipairs(ProgressionConfig.UNLOCKS) do
        if unlock.requiredLevel == level then
            table.insert(unlocks, unlock)
        end
    end
    return unlocks
end

-- Get all unlocks up to and including a specific level
function ProgressionConfig.getUnlocksUpToLevel(level: number): { Unlock }
    local unlocks = {}
    for _, unlock in ipairs(ProgressionConfig.UNLOCKS) do
        if unlock.requiredLevel <= level then
            table.insert(unlocks, unlock)
        end
    end
    return unlocks
end

-- Check if a specific unlock is available at a level
function ProgressionConfig.isUnlockAvailable(unlockId: string, level: number): boolean
    for _, unlock in ipairs(ProgressionConfig.UNLOCKS) do
        if unlock.id == unlockId then
            return level >= unlock.requiredLevel
        end
    end
    return false
end

-- Get unlock by ID
function ProgressionConfig.getUnlockById(unlockId: string): Unlock?
    for _, unlock in ipairs(ProgressionConfig.UNLOCKS) do
        if unlock.id == unlockId then
            return unlock
        end
    end
    return nil
end

-- XP reward values for various activities
ProgressionConfig.XP_REWARDS = {
    BUILD_SMALL = 10,
    BUILD_MEDIUM = 25,
    BUILD_LARGE = 50,
    COMPLETE_QUEST = 100,
    DISCOVER_LANDMARK = 20,
    TRADE_COMPLETE = 15,
    DAILY_LOGIN = 50,
    FIRST_BUILD_OF_DAY = 25,
}

return ProgressionConfig
