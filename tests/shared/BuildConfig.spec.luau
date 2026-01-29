--!strict
--[[
    Tests for BuildConfig module
    Verifies build system constants and structure definitions
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/shared/BuildConfig.luau")

describe("BuildConfig", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define BuildConfig table
        expect(string.find(moduleSource, "local BuildConfig = {}", 1, true)).toNotBeNil()

        -- Should return BuildConfig
        expect(string.find(moduleSource, "return BuildConfig", 1, true)).toNotBeNil()
    end)

    it("should have REMOTES table for client-server communication", function()
        expect(string.find(moduleSource, "BuildConfig.REMOTES", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PLACE_STRUCTURE", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PLACEMENT_RESULT", 1, true)).toNotBeNil()
    end)

    it("should have CATEGORIES table", function()
        expect(string.find(moduleSource, "BuildConfig.CATEGORIES", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "RESIDENTIAL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "COMMERCIAL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "RELIGIOUS", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "INFRASTRUCTURE", 1, true)).toNotBeNil()
    end)

    it("should export StructureType type", function()
        expect(string.find(moduleSource, "export type StructureType", 1, true)).toNotBeNil()
    end)

    it("should have STRUCTURES table with all basic structures", function()
        expect(string.find(moduleSource, "BuildConfig.STRUCTURES", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "DOMUS", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TABERNA", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TEMPLE", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "WALL", 1, true)).toNotBeNil()
    end)

    it("should have INSULA structure for apartments", function()
        expect(string.find(moduleSource, 'id = "INSULA"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'name = "Insula"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "cost = 350", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Multi-story apartment", 1, true)).toNotBeNil()
    end)

    it("should have FORUM_STALL structure for market", function()
        expect(string.find(moduleSource, 'id = "FORUM_STALL"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'name = "Forum Stall"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "cost = 50", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Market stall", 1, true)).toNotBeNil()
    end)

    it("should have WATCHTOWER structure for defense", function()
        expect(string.find(moduleSource, 'id = "WATCHTOWER"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'name = "Watchtower"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "cost = 150", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Guard tower", 1, true)).toNotBeNil()
    end)

    it("should have ARCH structure for triumphal arch", function()
        expect(string.find(moduleSource, 'id = "ARCH"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'name = "Arch"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "cost = 500", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Triumphal arch", 1, true)).toNotBeNil()
    end)

    it("should have THERMAE structure for public baths", function()
        expect(string.find(moduleSource, 'id = "THERMAE"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'name = "Thermae"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "cost = 800", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Public bathhouse", 1, true)).toNotBeNil()
    end)

    it("should have new structures in STRUCTURE_ORDER", function()
        expect(string.find(moduleSource, '"INSULA"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"FORUM_STALL"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"WATCHTOWER"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"ARCH"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"THERMAE"', 1, true)).toNotBeNil()
    end)

    it("should have STRUCTURE_ORDER for menu ordering", function()
        expect(string.find(moduleSource, "BuildConfig.STRUCTURE_ORDER", 1, true)).toNotBeNil()
    end)

    it("should have UI constants for mobile-first design", function()
        expect(string.find(moduleSource, "BuildConfig.UI", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BUILD_BUTTON_SIZE", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "MENU_WIDTH", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "GRID_CELL_SIZE", 1, true)).toNotBeNil()
    end)

    it("should have UI COLORS for Roman aesthetic", function()
        expect(string.find(moduleSource, "COLORS", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PRIMARY", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "VALID", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "INVALID", 1, true)).toNotBeNil()
    end)

    it("should have PLACEMENT validation rules", function()
        expect(string.find(moduleSource, "BuildConfig.PLACEMENT", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "MAX_SLOPE_DEGREES", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "WATER_LEVEL", 1, true)).toNotBeNil()
    end)

    it("should have getStructure function", function()
        expect(string.find(moduleSource, "function BuildConfig.getStructure(", 1, true)).toNotBeNil()
    end)

    it("should have getStructuresInOrder function", function()
        expect(string.find(moduleSource, "function BuildConfig.getStructuresInOrder(", 1, true)).toNotBeNil()
    end)

    it("should have getCost function", function()
        expect(string.find(moduleSource, "function BuildConfig.getCost(", 1, true)).toNotBeNil()
    end)

    it("should define structure properties (id, name, category, cost, size)", function()
        expect(string.find(moduleSource, "id:", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "name:", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "category:", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "cost:", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "size:", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "description:", 1, true)).toNotBeNil()
    end)

    it("should use strict mode", function()
        expect(string.find(moduleSource, "--!strict", 1, true)).toNotBeNil()
    end)

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

        expect(lastLine).toBe("return BuildConfig")
    end)
end)
