--!strict
--[[
    Tests for StructureModels module
    Verifies Roman structure building functions for player-placed buildings
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/StructureModels.luau")

describe("StructureModels", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define StructureModels table
        expect(string.find(moduleSource, "local StructureModels = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "StructureModels.__index = StructureModels", 1, true)).toNotBeNil()

        -- Should return StructureModels
        expect(string.find(moduleSource, "return StructureModels", 1, true)).toNotBeNil()
    end)

    -- Structure builder functions
    it("should have createDomus function", function()
        expect(string.find(moduleSource, "function StructureModels.createDomus", 1, true)).toNotBeNil()
    end)

    it("should have createTaberna function", function()
        expect(string.find(moduleSource, "function StructureModels.createTaberna", 1, true)).toNotBeNil()
    end)

    it("should have createTemple function", function()
        expect(string.find(moduleSource, "function StructureModels.createTemple", 1, true)).toNotBeNil()
    end)

    it("should have createWall function", function()
        expect(string.find(moduleSource, "function StructureModels.createWall", 1, true)).toNotBeNil()
    end)

    it("should have getBuilder function", function()
        expect(string.find(moduleSource, "function StructureModels.getBuilder", 1, true)).toNotBeNil()
    end)

    -- Helper functions
    it("should have createPart helper", function()
        expect(string.find(moduleSource, "local function createPart", 1, true)).toNotBeNil()
    end)

    it("should have createCylinder helper", function()
        expect(string.find(moduleSource, "local function createCylinder", 1, true)).toNotBeNil()
    end)

    it("should have createWallWithDoorway helper", function()
        expect(string.find(moduleSource, "local function createWallWithDoorway", 1, true)).toNotBeNil()
    end)

    it("should have createSolidWall helper", function()
        expect(string.find(moduleSource, "local function createSolidWall", 1, true)).toNotBeNil()
    end)

    it("should have createColumn helper", function()
        expect(string.find(moduleSource, "local function createColumn", 1, true)).toNotBeNil()
    end)

    -- Roman color constants
    it("should have MARBLE_WHITE color constant", function()
        expect(string.find(moduleSource, "local MARBLE_WHITE", 1, true)).toNotBeNil()
    end)

    it("should have MARBLE_CREAM color constant", function()
        expect(string.find(moduleSource, "local MARBLE_CREAM", 1, true)).toNotBeNil()
    end)

    it("should have TERRACOTTA color constant", function()
        expect(string.find(moduleSource, "local TERRACOTTA", 1, true)).toNotBeNil()
    end)

    it("should have STONE_GRAY color constant", function()
        expect(string.find(moduleSource, "local STONE_GRAY", 1, true)).toNotBeNil()
    end)

    it("should have SAND_BEIGE color constant", function()
        expect(string.find(moduleSource, "local SAND_BEIGE", 1, true)).toNotBeNil()
    end)

    -- Structure dimensions constants
    it("should have WALL_THICKNESS constant", function()
        expect(string.find(moduleSource, "local WALL_THICKNESS", 1, true)).toNotBeNil()
    end)

    it("should have DOORWAY_WIDTH constant", function()
        expect(string.find(moduleSource, "local DOORWAY_WIDTH", 1, true)).toNotBeNil()
    end)

    it("should have DOORWAY_HEIGHT constant", function()
        expect(string.find(moduleSource, "local DOORWAY_HEIGHT", 1, true)).toNotBeNil()
    end)

    it("should have COLUMN_RADIUS constant", function()
        expect(string.find(moduleSource, "local COLUMN_RADIUS", 1, true)).toNotBeNil()
    end)

    it("should have COLUMN_HEIGHT constant", function()
        expect(string.find(moduleSource, "local COLUMN_HEIGHT", 1, true)).toNotBeNil()
    end)

    -- Parts must be anchored
    it("should set Anchored = true on parts", function()
        expect(string.find(moduleSource, "Anchored = true", 1, true)).toNotBeNil()
    end)

    -- Domus structure components
    it("should create floor in Domus", function()
        local domusSection = string.match(moduleSource, "function StructureModels.createDomus.-end\n\n")
        expect(domusSection).toNotBeNil()
        expect(string.find(domusSection :: string, '"Floor"', 1, true)).toNotBeNil()
    end)

    it("should create roof in Domus", function()
        local domusSection = string.match(moduleSource, "function StructureModels.createDomus.-end\n\n")
        expect(domusSection).toNotBeNil()
        expect(string.find(domusSection :: string, '"Roof"', 1, true)).toNotBeNil()
    end)

    it("should create doorway in Domus", function()
        local domusSection = string.match(moduleSource, "function StructureModels.createDomus.-end\n\n")
        expect(domusSection).toNotBeNil()
        expect(string.find(domusSection :: string, "createWallWithDoorway", 1, true)).toNotBeNil()
    end)

    -- Taberna structure components
    it("should create floor in Taberna", function()
        local tabernaSection = string.match(moduleSource, "function StructureModels.createTaberna.-end\n\n")
        expect(tabernaSection).toNotBeNil()
        expect(string.find(tabernaSection :: string, '"Floor"', 1, true)).toNotBeNil()
    end)

    it("should create counter in Taberna", function()
        local tabernaSection = string.match(moduleSource, "function StructureModels.createTaberna.-end\n\n")
        expect(tabernaSection).toNotBeNil()
        expect(string.find(tabernaSection :: string, '"Counter"', 1, true)).toNotBeNil()
    end)

    it("should create roof in Taberna", function()
        local tabernaSection = string.match(moduleSource, "function StructureModels.createTaberna.-end\n\n")
        expect(tabernaSection).toNotBeNil()
        expect(string.find(tabernaSection :: string, '"Roof"', 1, true)).toNotBeNil()
    end)

    it("should have open front in Taberna (no front wall)", function()
        -- Taberna should NOT have a front wall (characteristic of Roman shops)
        local tabernaSection = string.match(moduleSource, "function StructureModels.createTaberna.-end\n\n")
        expect(tabernaSection).toNotBeNil()
        -- Should have comment about open front
        expect(string.find(tabernaSection :: string, "OPEN", 1, true)).toNotBeNil()
    end)

    -- Temple structure components
    it("should create platform in Temple", function()
        -- Temple should have Platform part
        expect(string.find(moduleSource, '"Platform"', 1, true)).toNotBeNil()
    end)

    it("should create steps in Temple", function()
        -- Temple should have Step parts
        expect(string.find(moduleSource, '"Step_%d"', 1, true)).toNotBeNil()
    end)

    it("should create cella floor in Temple", function()
        -- Temple should have CellaFloor part
        expect(string.find(moduleSource, '"CellaFloor"', 1, true)).toNotBeNil()
    end)

    it("should create columns in Temple", function()
        -- createTemple should use createColumn
        expect(string.find(moduleSource, "function StructureModels.createTemple", 1, true)).toNotBeNil()
        -- And module should have createColumn calls
        expect(string.find(moduleSource, "createColumn(columnX, platformTop, columnZ, model)", 1, true)).toNotBeNil()
    end)

    it("should create roof in Temple", function()
        -- Module should have Roof creation
        expect(string.find(moduleSource, '"Roof"', 1, true)).toNotBeNil()
    end)

    it("should create pediment in Temple", function()
        -- Temple should have Pediment part
        expect(string.find(moduleSource, '"Pediment"', 1, true)).toNotBeNil()
    end)

    -- Wall structure components
    it("should create wall body in Wall", function()
        local wallSection = string.match(moduleSource, "function StructureModels.createWall.-end\n\n")
        expect(wallSection).toNotBeNil()
        expect(string.find(wallSection :: string, '"WallBody"', 1, true)).toNotBeNil()
    end)

    it("should create crenellations (merlons) in Wall", function()
        local wallSection = string.match(moduleSource, "function StructureModels.createWall.-end\n\n")
        expect(wallSection).toNotBeNil()
        expect(string.find(wallSection :: string, '"Merlon_', 1, true)).toNotBeNil()
    end)

    -- Material usage
    it("should use Marble material", function()
        expect(string.find(moduleSource, "Material.Marble", 1, true)).toNotBeNil()
    end)

    it("should use Brick material", function()
        expect(string.find(moduleSource, "Material.Brick", 1, true)).toNotBeNil()
    end)

    it("should use Slate material for roofs", function()
        expect(string.find(moduleSource, "Material.Slate", 1, true)).toNotBeNil()
    end)

    -- getBuilder function returns correct builders
    it("should return createDomus for DOMUS", function()
        expect(string.find(moduleSource, '"DOMUS"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createDomus", 1, true)).toNotBeNil()
    end)

    it("should return createTaberna for TABERNA", function()
        expect(string.find(moduleSource, '"TABERNA"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createTaberna", 1, true)).toNotBeNil()
    end)

    it("should return createTemple for TEMPLE", function()
        expect(string.find(moduleSource, '"TEMPLE"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createTemple", 1, true)).toNotBeNil()
    end)

    it("should return createWall for WALL", function()
        expect(string.find(moduleSource, '"WALL"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createWall", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return StructureModels")
    end)
end)
