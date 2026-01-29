--!strict
--[[
    Tests for ProgressionConfig module
    Verifies level thresholds, unlocks, and Roman rank definitions
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/shared/ProgressionConfig.luau")

describe("ProgressionConfig", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define ProgressionConfig table
        expect(string.find(moduleSource, "local ProgressionConfig = {}", 1, true)).toNotBeNil()

        -- Should return ProgressionConfig
        expect(string.find(moduleSource, "return ProgressionConfig", 1, true)).toNotBeNil()
    end)

    -- Roman Ranks
    it("should have RANKS table with Roman rank definitions", function()
        expect(string.find(moduleSource, "ProgressionConfig.RANKS", 1, true)).toNotBeNil()
    end)

    it("should define Citizen rank (levels 1-5)", function()
        expect(string.find(moduleSource, '"Citizen"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"Civis"', 1, true)).toNotBeNil()
    end)

    it("should define Merchant rank (levels 6-10)", function()
        expect(string.find(moduleSource, '"Merchant"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"Mercator"', 1, true)).toNotBeNil()
    end)

    it("should define Senator rank (levels 11-15)", function()
        expect(string.find(moduleSource, '"Senator"', 1, true)).toNotBeNil()
    end)

    it("should define Consul rank (levels 16-20)", function()
        expect(string.find(moduleSource, '"Consul"', 1, true)).toNotBeNil()
    end)

    it("should define Imperator rank (level 21+)", function()
        expect(string.find(moduleSource, '"Imperator"', 1, true)).toNotBeNil()
    end)

    -- XP Configuration
    it("should have BASE_XP constant", function()
        expect(string.find(moduleSource, "ProgressionConfig.BASE_XP", 1, true)).toNotBeNil()
    end)

    it("should have XP_PER_LEVEL constant", function()
        expect(string.find(moduleSource, "ProgressionConfig.XP_PER_LEVEL", 1, true)).toNotBeNil()
    end)

    it("should have XP_GROWTH_RATE constant", function()
        expect(string.find(moduleSource, "ProgressionConfig.XP_GROWTH_RATE", 1, true)).toNotBeNil()
    end)

    -- XP Functions
    it("should have getXPForLevel function", function()
        expect(string.find(moduleSource, "function ProgressionConfig.getXPForLevel", 1, true)).toNotBeNil()
    end)

    it("should have getLevelFromXP function", function()
        expect(string.find(moduleSource, "function ProgressionConfig.getLevelFromXP", 1, true)).toNotBeNil()
    end)

    it("should have getRankForLevel function", function()
        expect(string.find(moduleSource, "function ProgressionConfig.getRankForLevel", 1, true)).toNotBeNil()
    end)

    -- Unlocks
    it("should have UNLOCKS table", function()
        expect(string.find(moduleSource, "ProgressionConfig.UNLOCKS", 1, true)).toNotBeNil()
    end)

    it("should define starter unlocks at level 1", function()
        expect(string.find(moduleSource, "domus_basic", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "well", 1, true)).toNotBeNil()
    end)

    it("should define merchant tier unlocks", function()
        expect(string.find(moduleSource, "taberna", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "trade_ability", 1, true)).toNotBeNil()
    end)

    it("should define senator tier unlocks", function()
        expect(string.find(moduleSource, "curia_minor", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "civic_planning", 1, true)).toNotBeNil()
    end)

    it("should define consul tier unlocks", function()
        expect(string.find(moduleSource, "castrum_small", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "military_command", 1, true)).toNotBeNil()
    end)

    it("should define imperator tier unlocks", function()
        expect(string.find(moduleSource, "amphitheatre", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "imperial_decree", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "colosseum", 1, true)).toNotBeNil()
    end)

    -- Unlock Functions
    it("should have getUnlocksForLevel function", function()
        expect(string.find(moduleSource, "function ProgressionConfig.getUnlocksForLevel", 1, true)).toNotBeNil()
    end)

    it("should have getUnlocksUpToLevel function", function()
        expect(string.find(moduleSource, "function ProgressionConfig.getUnlocksUpToLevel", 1, true)).toNotBeNil()
    end)

    it("should have isUnlockAvailable function", function()
        expect(string.find(moduleSource, "function ProgressionConfig.isUnlockAvailable", 1, true)).toNotBeNil()
    end)

    it("should have getUnlockById function", function()
        expect(string.find(moduleSource, "function ProgressionConfig.getUnlockById", 1, true)).toNotBeNil()
    end)

    -- XP Rewards
    it("should have XP_REWARDS table", function()
        expect(string.find(moduleSource, "ProgressionConfig.XP_REWARDS", 1, true)).toNotBeNil()
    end)

    it("should define XP rewards for building", function()
        expect(string.find(moduleSource, "BUILD_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BUILD_MEDIUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BUILD_LARGE", 1, true)).toNotBeNil()
    end)

    it("should define XP rewards for quests and exploration", function()
        expect(string.find(moduleSource, "COMPLETE_QUEST", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "DISCOVER_LANDMARK", 1, true)).toNotBeNil()
    end)

    -- Type Exports
    it("should export RankName type", function()
        expect(string.find(moduleSource, "export type RankName", 1, true)).toNotBeNil()
    end)

    it("should export RankInfo type", function()
        expect(string.find(moduleSource, "export type RankInfo", 1, true)).toNotBeNil()
    end)

    it("should export UnlockType type", function()
        expect(string.find(moduleSource, "export type UnlockType", 1, true)).toNotBeNil()
    end)

    it("should export Unlock type", function()
        expect(string.find(moduleSource, "export type Unlock", 1, true)).toNotBeNil()
    end)

    -- Module Structure
    it("should not have auto-executing code at module end", function()
        -- Check that module ends with return statement, not function calls
        local lines = {}
        for line in string.gmatch(moduleSource, "[^\n]+") do
            table.insert(lines, line)
        end

        -- Get last non-empty line
        local lastLine = ""
        for i = #lines, 1, -1 do
            local trimmed = string.match(lines[i], "^%s*(.-)%s*$") or ""
            if trimmed ~= "" then
                lastLine = trimmed
                break
            end
        end

        expect(lastLine).toBe("return ProgressionConfig")
    end)
end)
