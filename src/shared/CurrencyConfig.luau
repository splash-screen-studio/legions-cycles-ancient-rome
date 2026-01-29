--!strict
--[[
    CurrencyConfig - Shared types and constants for the Roman currency system
    Uses Denarii as the primary currency unit
]]

local CurrencyConfig = {}
CurrencyConfig.VERSION = "1.0.0"

-- Currency name (Roman silver coins)
CurrencyConfig.CURRENCY_NAME = "Denarii"
CurrencyConfig.CURRENCY_SYMBOL = "D" -- Shorthand symbol

-- Starting balance for new players
CurrencyConfig.STARTING_BALANCE = 100

-- Earning rates
CurrencyConfig.EARNING = {
    TABERNA_INCOME = { min = 1, max = 5 }, -- Per 30 seconds
    TABERNA_INTERVAL = 30, -- Seconds between income
    STRUCTURE_COMPLETION = { min = 10, max = 50 }, -- One-time bonus
    DAILY_LOGIN = 50, -- Once per day
}

-- Structure costs by category
CurrencyConfig.COSTS = {
    SMALL = { min = 50, max = 100 }, -- Taberna, small shops
    MEDIUM = { min = 200, max = 500 }, -- Domus, larger buildings
    LARGE = { min = 1000, max = 2500 }, -- Temples, public buildings
    LANDMARK = { min = 5000, max = 10000 }, -- Major monuments
}

-- Specific structure costs (expanded as structures are implemented)
CurrencyConfig.STRUCTURE_COSTS = {
    TABERNA = 0, -- First one is FREE (tutorial)
    TABERNA_ADDITIONAL = 75,
    DOMUS_SMALL = 200,
    DOMUS_MEDIUM = 350,
    DOMUS_LARGE = 500,
    TEMPLE_SMALL = 1000,
    TEMPLE_LARGE = 2500,
    FORUM = 5000,
    COLOSSEUM = 10000,
}

-- Validation limits (anti-cheat)
CurrencyConfig.LIMITS = {
    MAX_BALANCE = 999999999, -- ~1 billion max
    MAX_TRANSACTION = 100000, -- Max single transaction
    MIN_BALANCE = 0, -- Cannot go negative
}

-- Transaction sources (for logging/analytics)
CurrencyConfig.TRANSACTION_SOURCES = {
    STARTING_BALANCE = "starting_balance",
    TABERNA_INCOME = "taberna_income",
    STRUCTURE_COMPLETION = "structure_completion",
    DAILY_LOGIN = "daily_login",
    ACHIEVEMENT = "achievement",
    ADMIN_GRANT = "admin_grant",
}

-- Transaction types
CurrencyConfig.TRANSACTION_TYPES = {
    EARN = "earn",
    SPEND = "spend",
}

-- RemoteEvent/Function names
CurrencyConfig.REMOTES = {
    GET_BALANCE = "CurrencyGetBalance",
    BALANCE_UPDATED = "CurrencyBalanceUpdated",
    SPEND_REQUEST = "CurrencySpendRequest",
}

return CurrencyConfig
