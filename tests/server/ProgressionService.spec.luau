--!strict
--[[
    Tests for ProgressionService module
    Verifies server-side XP and level management
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/ProgressionService.luau")

describe("ProgressionService", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define ProgressionService table
        expect(string.find(moduleSource, "local ProgressionService = {}", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "ProgressionService.__index = ProgressionService", 1, true)).toNotBeNil()

        -- Should return ProgressionService
        expect(string.find(moduleSource, "return ProgressionService", 1, true)).toNotBeNil()
    end)

    -- Constructor and lifecycle
    it("should have new constructor function", function()
        expect(string.find(moduleSource, "function ProgressionService.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function ProgressionService:start()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function ProgressionService:destroy()", 1, true)).toNotBeNil()
    end)

    -- Core XP/Level methods
    it("should have getLevel method", function()
        expect(string.find(moduleSource, "function ProgressionService:getLevel", 1, true)).toNotBeNil()
    end)

    it("should have getXP method", function()
        expect(string.find(moduleSource, "function ProgressionService:getXP", 1, true)).toNotBeNil()
    end)

    it("should have addXP method", function()
        expect(string.find(moduleSource, "function ProgressionService:addXP", 1, true)).toNotBeNil()
    end)

    it("should have getUnlocks method", function()
        expect(string.find(moduleSource, "function ProgressionService:getUnlocks", 1, true)).toNotBeNil()
    end)

    it("should have getRank method", function()
        expect(string.find(moduleSource, "function ProgressionService:getRank", 1, true)).toNotBeNil()
    end)

    it("should have hasUnlock method", function()
        expect(string.find(moduleSource, "function ProgressionService:hasUnlock", 1, true)).toNotBeNil()
    end)

    -- Progress tracking methods
    it("should have getXPForNextLevel method", function()
        expect(string.find(moduleSource, "function ProgressionService:getXPForNextLevel", 1, true)).toNotBeNil()
    end)

    it("should have getProgressToNextLevel method", function()
        expect(string.find(moduleSource, "function ProgressionService:getProgressToNextLevel", 1, true)).toNotBeNil()
    end)

    -- RemoteEvents
    it("should create XPChanged RemoteEvent", function()
        expect(string.find(moduleSource, 'XPChanged', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "RemoteEvent", 1, true)).toNotBeNil()
    end)

    it("should create LevelUp RemoteEvent", function()
        expect(string.find(moduleSource, 'LevelUp', 1, true)).toNotBeNil()
    end)

    it("should create RequestProgress RemoteFunction", function()
        expect(string.find(moduleSource, 'RequestProgress', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "RemoteFunction", 1, true)).toNotBeNil()
    end)

    -- Event handling
    it("should handle player joining", function()
        expect(string.find(moduleSource, "PlayerAdded", 1, true)).toNotBeNil()
    end)

    it("should handle player leaving", function()
        expect(string.find(moduleSource, "PlayerRemoving", 1, true)).toNotBeNil()
    end)

    it("should fire events to client", function()
        expect(string.find(moduleSource, "FireClient", 1, true)).toNotBeNil()
    end)

    -- Server validation
    it("should validate XP amount is positive", function()
        expect(string.find(moduleSource, "amount <= 0", 1, true)).toNotBeNil()
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

    -- Type exports
    it("should export PlayerProgress type", function()
        expect(string.find(moduleSource, "export type PlayerProgress", 1, true)).toNotBeNil()
    end)

    it("should export ProgressionServiceInstance type", function()
        expect(string.find(moduleSource, "export type ProgressionServiceInstance", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return ProgressionService")
    end)
end)
