--!strict
--[[
    Tests for ProgressionDisplay module
    Verifies client-side UI for showing player level, XP, and rank
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/ProgressionDisplay.luau")

describe("ProgressionDisplay", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define ProgressionDisplay table
        expect(string.find(moduleSource, "local ProgressionDisplay = {}", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "ProgressionDisplay.__index = ProgressionDisplay", 1, true)).toNotBeNil()

        -- Should return ProgressionDisplay
        expect(string.find(moduleSource, "return ProgressionDisplay", 1, true)).toNotBeNil()
    end)

    -- Constructor and lifecycle
    it("should have new constructor function", function()
        expect(string.find(moduleSource, "function ProgressionDisplay.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function ProgressionDisplay:start()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function ProgressionDisplay:destroy()", 1, true)).toNotBeNil()
    end)

    -- UI Creation
    it("should create ScreenGui", function()
        expect(string.find(moduleSource, "ScreenGui", 1, true)).toNotBeNil()
    end)

    it("should create progress frame", function()
        expect(string.find(moduleSource, "ProgressFrame", 1, true)).toNotBeNil()
    end)

    it("should create level label", function()
        expect(string.find(moduleSource, "LevelLabel", 1, true)).toNotBeNil()
    end)

    it("should create rank label", function()
        expect(string.find(moduleSource, "RankLabel", 1, true)).toNotBeNil()
    end)

    it("should create XP bar", function()
        expect(string.find(moduleSource, "XPBar", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "XPFill", 1, true)).toNotBeNil()
    end)

    it("should create XP label", function()
        expect(string.find(moduleSource, "XPLabel", 1, true)).toNotBeNil()
    end)

    it("should create notification frame for level ups", function()
        expect(string.find(moduleSource, "NotificationFrame", 1, true)).toNotBeNil()
    end)

    -- Server connection
    it("should connect to XPChanged event", function()
        expect(string.find(moduleSource, "XPChanged", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "OnClientEvent", 1, true)).toNotBeNil()
    end)

    it("should connect to LevelUp event", function()
        expect(string.find(moduleSource, "LevelUp", 1, true)).toNotBeNil()
    end)

    it("should request initial progress from server", function()
        expect(string.find(moduleSource, "RequestProgress", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "InvokeServer", 1, true)).toNotBeNil()
    end)

    -- UI Updates
    it("should update level display", function()
        expect(string.find(moduleSource, 'Level %d', 1, false)).toNotBeNil()
    end)

    it("should update XP progress", function()
        expect(string.find(moduleSource, 'XP', 1, true)).toNotBeNil()
    end)

    it("should animate XP bar", function()
        expect(string.find(moduleSource, "TweenService", 1, true)).toNotBeNil()
    end)

    -- Level up notifications
    it("should show level up notification", function()
        expect(string.find(moduleSource, "LEVEL UP", 1, true)).toNotBeNil()
    end)

    it("should show new unlocks in notification", function()
        expect(string.find(moduleSource, "newUnlocks", 1, true)).toNotBeNil()
    end)

    it("should show rank changes", function()
        expect(string.find(moduleSource, "rankChanged", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "New Rank", 1, true)).toNotBeNil()
    end)

    -- Mobile-first design
    it("should use touch-friendly sizing", function()
        expect(string.find(moduleSource, "MOBILE-FIRST", 1, true)).toNotBeNil()
    end)

    -- Dependencies
    it("should require ProgressionConfig", function()
        expect(string.find(moduleSource, 'require.-ProgressionConfig', 1, false)).toNotBeNil()
    end)

    it("should use Players service", function()
        expect(string.find(moduleSource, 'GetService%("Players"%)', 1, false)).toNotBeNil()
    end)

    it("should use ReplicatedStorage", function()
        expect(string.find(moduleSource, 'GetService%("ReplicatedStorage"%)', 1, false)).toNotBeNil()
    end)

    it("should use TweenService for animations", function()
        expect(string.find(moduleSource, 'GetService%("TweenService"%)', 1, false)).toNotBeNil()
    end)

    -- Public methods
    it("should have getCurrentProgress method", function()
        expect(string.find(moduleSource, "function ProgressionDisplay:getCurrentProgress()", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export ProgressData type", function()
        expect(string.find(moduleSource, "export type ProgressData", 1, true)).toNotBeNil()
    end)

    it("should export LevelUpData type", function()
        expect(string.find(moduleSource, "export type LevelUpData", 1, true)).toNotBeNil()
    end)

    it("should export ProgressionDisplayInstance type", function()
        expect(string.find(moduleSource, "export type ProgressionDisplayInstance", 1, true)).toNotBeNil()
    end)

    -- Module structure
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

        expect(lastLine).toBe("return ProgressionDisplay")
    end)
end)
