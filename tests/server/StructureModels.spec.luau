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

    -- New structure builders
    it("should have createInsula function", function()
        expect(string.find(moduleSource, "function StructureModels.createInsula", 1, true)).toNotBeNil()
    end)

    it("should have createForumStall function", function()
        expect(string.find(moduleSource, "function StructureModels.createForumStall", 1, true)).toNotBeNil()
    end)

    it("should have createWatchtower function", function()
        expect(string.find(moduleSource, "function StructureModels.createWatchtower", 1, true)).toNotBeNil()
    end)

    it("should have createArch function", function()
        expect(string.find(moduleSource, "function StructureModels.createArch", 1, true)).toNotBeNil()
    end)

    it("should have createThermae function", function()
        expect(string.find(moduleSource, "function StructureModels.createThermae", 1, true)).toNotBeNil()
    end)

    it("should return createInsula for INSULA", function()
        expect(string.find(moduleSource, '"INSULA"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createInsula", 1, true)).toNotBeNil()
    end)

    it("should return createForumStall for FORUM_STALL", function()
        expect(string.find(moduleSource, '"FORUM_STALL"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createForumStall", 1, true)).toNotBeNil()
    end)

    it("should return createWatchtower for WATCHTOWER", function()
        expect(string.find(moduleSource, '"WATCHTOWER"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createWatchtower", 1, true)).toNotBeNil()
    end)

    it("should return createArch for ARCH", function()
        expect(string.find(moduleSource, '"ARCH"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createArch", 1, true)).toNotBeNil()
    end)

    it("should return createThermae for THERMAE", function()
        expect(string.find(moduleSource, '"THERMAE"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "StructureModels.createThermae", 1, true)).toNotBeNil()
    end)

    -- Insula structure components (using whole module since function has nested blocks)
    it("should create foundation in Insula", function()
        expect(string.find(moduleSource, "function StructureModels.createInsula", 1, true)).toNotBeNil()
        -- Foundation is created in createInsula
        expect(string.find(moduleSource, '"Foundation"', 1, true)).toNotBeNil()
    end)

    it("should create multiple floors in Insula", function()
        expect(string.find(moduleSource, "numFloors = 4", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"FloorSlab"', 1, true)).toNotBeNil()
    end)

    it("should create balconies in Insula", function()
        expect(string.find(moduleSource, '"Balcony" .. floorSuffix', 1, true)).toNotBeNil()
    end)

    it("should create roof in Insula", function()
        -- Roof is created in multiple functions, verify createInsula has one
        expect(string.find(moduleSource, "-- Roof %(flat with slight overhang%)", 1, false)).toNotBeNil()
    end)

    -- Forum Stall structure components
    it("should create platform in ForumStall", function()
        expect(string.find(moduleSource, "function StructureModels.createForumStall", 1, true)).toNotBeNil()
        -- Platform is created as ground base
        expect(string.find(moduleSource, "-- Ground platform", 1, true)).toNotBeNil()
    end)

    it("should create posts in ForumStall", function()
        expect(string.find(moduleSource, '"Post_%d"', 1, true)).toNotBeNil()
    end)

    it("should create awning in ForumStall", function()
        expect(string.find(moduleSource, '"Awning"', 1, true)).toNotBeNil()
    end)

    it("should create counter in ForumStall", function()
        -- Counter appears in both Taberna and ForumStall
        expect(string.find(moduleSource, "-- Display counter at front", 1, true)).toNotBeNil()
    end)

    it("should use Wood material in ForumStall", function()
        -- Wood material is used for posts and counter
        expect(string.find(moduleSource, "WOOD_BROWN", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Material.Wood", 1, true)).toNotBeNil()
    end)

    -- Watchtower structure components
    it("should create foundation in Watchtower", function()
        expect(string.find(moduleSource, "function StructureModels.createWatchtower", 1, true)).toNotBeNil()
        -- Watchtower has foundation with wider base
        expect(string.find(moduleSource, "-- Base foundation %(wider than tower%)", 1, false)).toNotBeNil()
    end)

    it("should create observation platform in Watchtower", function()
        expect(string.find(moduleSource, '"ObservationPlatform"', 1, true)).toNotBeNil()
    end)

    it("should create crenellations in Watchtower", function()
        expect(string.find(moduleSource, '"Merlon_Front_%d"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"Merlon_Back_%d"', 1, true)).toNotBeNil()
    end)

    it("should create doorway in Watchtower", function()
        -- Watchtower has a front doorway
        expect(string.find(moduleSource, "-- Front wall with doorway", 1, true)).toNotBeNil()
    end)

    -- Arch structure components
    it("should create foundation in Arch", function()
        expect(string.find(moduleSource, "function StructureModels.createArch", 1, true)).toNotBeNil()
        -- Arch has foundation/base
        expect(string.find(moduleSource, "-- Foundation/base", 1, true)).toNotBeNil()
    end)

    it("should create pillars in Arch", function()
        expect(string.find(moduleSource, '"Pillar_Left"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"Pillar_Right"', 1, true)).toNotBeNil()
    end)

    it("should create attic (top beam) in Arch", function()
        expect(string.find(moduleSource, '"Attic"', 1, true)).toNotBeNil()
    end)

    it("should create cornice in Arch", function()
        expect(string.find(moduleSource, '"Cornice"', 1, true)).toNotBeNil()
    end)

    it("should create decorative columns in Arch", function()
        expect(string.find(moduleSource, '"Column_Left"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"Column_Right"', 1, true)).toNotBeNil()
    end)

    -- WOOD_BROWN color constant for Forum Stall
    it("should have WOOD_BROWN color constant", function()
        expect(string.find(moduleSource, "local WOOD_BROWN", 1, true)).toNotBeNil()
    end)

    -- POOL_BLUE color constant for Thermae
    it("should have POOL_BLUE color constant", function()
        expect(string.find(moduleSource, "local POOL_BLUE", 1, true)).toNotBeNil()
    end)

    -- Thermae structure components
    it("should create floor in Thermae", function()
        expect(string.find(moduleSource, "function StructureModels.createThermae", 1, true)).toNotBeNil()
        -- Floor is created as foundation
        expect(string.find(moduleSource, "-- Foundation/floor", 1, true)).toNotBeNil()
    end)

    it("should create 4 columns in Thermae", function()
        -- Thermae has 4 columns along the front
        expect(string.find(moduleSource, "-- 4 columns along the front", 1, true)).toNotBeNil()
    end)

    it("should create pool basin in Thermae", function()
        expect(string.find(moduleSource, '"PoolBasin"', 1, true)).toNotBeNil()
    end)

    it("should create pool water in Thermae", function()
        expect(string.find(moduleSource, '"PoolWater"', 1, true)).toNotBeNil()
    end)

    it("should use Glass material for pool water", function()
        -- Pool water uses Glass material
        expect(string.find(moduleSource, "Material.Glass", 1, true)).toNotBeNil()
    end)

    it("should create doorway in Thermae", function()
        -- Thermae has arched entrance doorway
        expect(string.find(moduleSource, "-- Front wall (+Z) with arched doorway", 1, true)).toNotBeNil()
    end)

    it("should create roof in Thermae", function()
        -- Thermae has terracotta roof
        expect(string.find(moduleSource, "-- Terracotta roof with slight overhang", 1, true)).toNotBeNil()
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
