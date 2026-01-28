--!strict
--[[
    Tests for FountainConfig module
    Verifies fountain type definitions and placement configurations
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/shared/FountainConfig.luau")

describe("FountainConfig", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define FountainConfig table
        expect(string.find(moduleSource, "local FountainConfig = {}", 1, true)).toNotBeNil()

        -- Should return FountainConfig
        expect(string.find(moduleSource, "return FountainConfig", 1, true)).toNotBeNil()
    end)

    it("should have COLORS table with Roman palette", function()
        expect(string.find(moduleSource, "FountainConfig.COLORS", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "MARBLE_WHITE", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "MARBLE_CREAM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TERRACOTTA", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BRICK", 1, true)).toNotBeNil()
    end)

    it("should have TYPES table", function()
        expect(string.find(moduleSource, "FountainConfig.TYPES", 1, true)).toNotBeNil()
    end)

    it("should define basin fountain type", function()
        expect(string.find(moduleSource, "basin = {", 1, true)).toNotBeNil()
    end)

    it("should define impluvium fountain type", function()
        expect(string.find(moduleSource, "impluvium = {", 1, true)).toNotBeNil()
    end)

    it("should define publicFountain type", function()
        expect(string.find(moduleSource, "publicFountain = {", 1, true)).toNotBeNil()
    end)

    it("should define nymphaeum fountain type", function()
        expect(string.find(moduleSource, "nymphaeum = {", 1, true)).toNotBeNil()
    end)

    it("should have DEFAULT_PLACEMENTS array", function()
        expect(string.find(moduleSource, "FountainConfig.DEFAULT_PLACEMENTS", 1, true)).toNotBeNil()
    end)

    it("should have forum nymphaeum placement", function()
        expect(string.find(moduleSource, "Forum_Nymphaeum", 1, true)).toNotBeNil()
    end)

    it("should have spawn area fountain placement", function()
        expect(string.find(moduleSource, "SpawnArea_PublicFountain", 1, true)).toNotBeNil()
    end)

    it("should have colosseum fountain placement", function()
        expect(string.find(moduleSource, "Colosseum_PublicFountain", 1, true)).toNotBeNil()
    end)

    it("should have basin placements at road intersections", function()
        expect(string.find(moduleSource, "WestRoad_Basin", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "EastRoad_Basin", 1, true)).toNotBeNil()
    end)

    it("should have getTypeConfig function", function()
        expect(string.find(moduleSource, "function FountainConfig.getTypeConfig", 1, true)).toNotBeNil()
    end)

    it("should have getDefaultPlacements function", function()
        expect(string.find(moduleSource, "function FountainConfig.getDefaultPlacements", 1, true)).toNotBeNil()
    end)

    it("should have getPlacementsByType function", function()
        expect(string.find(moduleSource, "function FountainConfig.getPlacementsByType", 1, true)).toNotBeNil()
    end)

    it("should export FountainType type", function()
        expect(string.find(moduleSource, "export type FountainType", 1, true)).toNotBeNil()
    end)

    it("should export FountainTypeConfig type", function()
        expect(string.find(moduleSource, "export type FountainTypeConfig", 1, true)).toNotBeNil()
    end)

    it("should export FountainPlacement type", function()
        expect(string.find(moduleSource, "export type FountainPlacement", 1, true)).toNotBeNil()
    end)

    it("should define fountain types with size property", function()
        expect(string.find(moduleSource, "size: Vector3", 1, true)).toNotBeNil()
    end)

    it("should define fountain types with wallMaterial property", function()
        expect(string.find(moduleSource, "wallMaterial: Enum.Material", 1, true)).toNotBeNil()
    end)

    it("should define fountain types with wallColor property", function()
        expect(string.find(moduleSource, "wallColor: Color3", 1, true)).toNotBeNil()
    end)

    it("should define fountain types with wallThickness property", function()
        expect(string.find(moduleSource, "wallThickness: number", 1, true)).toNotBeNil()
    end)

    it("should define fountain types with rimHeight property", function()
        expect(string.find(moduleSource, "rimHeight: number", 1, true)).toNotBeNil()
    end)

    it("should use Marble material for fountains", function()
        expect(string.find(moduleSource, "Enum.Material.Marble", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return FountainConfig")
    end)
end)
