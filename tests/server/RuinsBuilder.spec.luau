--!strict
--[[
    Tests for RuinsBuilder module
    Tests module structure, VERSION constant, and ruin generation methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/RuinsBuilder.luau")

describe("RuinsBuilder", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define RuinsBuilder table
        expect(string.find(moduleSource, "local RuinsBuilder = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "RuinsBuilder.__index = RuinsBuilder", 1, true)).toNotBeNil()

        -- Should return RuinsBuilder
        expect(string.find(moduleSource, "return RuinsBuilder", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function RuinsBuilder.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:destroy", 1, true)).toNotBeNil()
    end)

    -- Private helper methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _createCylinder() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createCylinder", 1, true)).toNotBeNil()
    end)

    -- Fallen column ruin types
    it("should have _createFallenColumn() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createFallenColumn", 1, true)).toNotBeNil()
    end)

    it("should have _createColumnFragment() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createColumnFragment", 1, true)).toNotBeNil()
    end)

    it("should have _createColumnBase() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createColumnBase", 1, true)).toNotBeNil()
    end)

    it("should have _createFallenColonnade() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createFallenColonnade", 1, true)).toNotBeNil()
    end)

    -- Crumbling wall ruin types
    it("should have _createPartialWall() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createPartialWall", 1, true)).toNotBeNil()
    end)

    it("should have _createWallFoundation() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createWallFoundation", 1, true)).toNotBeNil()
    end)

    it("should have _createBrokenArchway() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createBrokenArchway", 1, true)).toNotBeNil()
    end)

    -- Foundation/platform ruin types
    it("should have _createBuildingFoundation() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createBuildingFoundation", 1, true)).toNotBeNil()
    end)

    it("should have _createStepsToNothing() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createStepsToNothing", 1, true)).toNotBeNil()
    end)

    it("should have _createPlatform() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createPlatform", 1, true)).toNotBeNil()
    end)

    -- Debris ruin types
    it("should have _createRubblePile() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createRubblePile", 1, true)).toNotBeNil()
    end)

    it("should have _createDebrisScatter() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createDebrisScatter", 1, true)).toNotBeNil()
    end)

    it("should have _createBrokenStatuary() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_createBrokenStatuary", 1, true)).toNotBeNil()
    end)

    -- Type mapper and placement methods
    it("should have _buildRuinByType() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_buildRuinByType", 1, true)).toNotBeNil()
    end)

    it("should have _isValidRuinPosition() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_isValidRuinPosition", 1, true)).toNotBeNil()
    end)

    it("should have _selectRuinType() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:_selectRuinType", 1, true)).toNotBeNil()
    end)

    -- Public query methods
    it("should have getRuinCount() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:getRuinCount", 1, true)).toNotBeNil()
    end)

    it("should have getParts() method", function()
        expect(string.find(moduleSource, "function RuinsBuilder:getParts", 1, true)).toNotBeNil()
    end)

    -- Should require shared modules
    it("should require TerrainUtils module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("TerrainUtils"))', 1, true)).toNotBeNil()
    end)

    it("should require WorldPlan module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("WorldPlan"))', 1, true)).toNotBeNil()
    end)

    -- Critical: Parts must be anchored
    it("should set Anchored = true on parts", function()
        expect(string.find(moduleSource, "Anchored = true", 1, true)).toNotBeNil()
    end)

    -- Materials for weathered Roman look
    it("should use Marble material for columns", function()
        expect(string.find(moduleSource, "Material = Enum.Material.Marble", 1, true)).toNotBeNil()
    end)

    it("should use Concrete material for weathered structures", function()
        expect(string.find(moduleSource, "Enum.Material.Concrete", 1, true)).toNotBeNil()
    end)

    it("should use Brick material for walls", function()
        expect(string.find(moduleSource, "Enum.Material.Brick", 1, true)).toNotBeNil()
    end)

    it("should use Slate material for foundations", function()
        expect(string.find(moduleSource, "Enum.Material.Slate", 1, true)).toNotBeNil()
    end)

    -- Weathered Roman colors
    it("should have WEATHERED_MARBLE color constant", function()
        expect(string.find(moduleSource, "local WEATHERED_MARBLE", 1, true)).toNotBeNil()
    end)

    it("should have MOSSY_STONE color constant", function()
        expect(string.find(moduleSource, "local MOSSY_STONE", 1, true)).toNotBeNil()
    end)

    it("should have CRACKED_BRICK color constant", function()
        expect(string.find(moduleSource, "local CRACKED_BRICK", 1, true)).toNotBeNil()
    end)

    it("should have AGED_CONCRETE color constant", function()
        expect(string.find(moduleSource, "local AGED_CONCRETE", 1, true)).toNotBeNil()
    end)

    it("should have DARK_STONE color constant", function()
        expect(string.find(moduleSource, "local DARK_STONE", 1, true)).toNotBeNil()
    end)

    -- Column dimensions
    it("should have RUIN_COLUMN_RADIUS constants", function()
        expect(string.find(moduleSource, "local RUIN_COLUMN_RADIUS_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local RUIN_COLUMN_RADIUS_MEDIUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local RUIN_COLUMN_RADIUS_LARGE", 1, true)).toNotBeNil()
    end)

    it("should have RUIN_COLUMN_HEIGHT constants", function()
        expect(string.find(moduleSource, "local RUIN_COLUMN_HEIGHT_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local RUIN_COLUMN_HEIGHT_MEDIUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local RUIN_COLUMN_HEIGHT_LARGE", 1, true)).toNotBeNil()
    end)

    -- Placement constraints
    it("should have MIN_LANDMARK_DISTANCE constant", function()
        expect(string.find(moduleSource, "local MIN_LANDMARK_DISTANCE", 1, true)).toNotBeNil()
    end)

    it("should have MIN_ROAD_DISTANCE constant", function()
        expect(string.find(moduleSource, "local MIN_ROAD_DISTANCE", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export RuinType type", function()
        expect(string.find(moduleSource, "export type RuinType", 1, true)).toNotBeNil()
    end)

    it("should export RuinsBuilderConfig type", function()
        expect(string.find(moduleSource, "export type RuinsBuilderConfig", 1, true)).toNotBeNil()
    end)

    it("should export RuinsBuilderInstance type", function()
        expect(string.find(moduleSource, "export type RuinsBuilderInstance", 1, true)).toNotBeNil()
    end)

    -- Roman naming for folder
    it("should use Roman naming for ruins folder (Ruinae)", function()
        expect(string.find(moduleSource, "Ruins_Ruinae", 1, true)).toNotBeNil()
    end)

    -- Query terrain height
    it("should query terrain height using TerrainUtils", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
    end)

    -- Check zone types for placement
    it("should check zone types using WorldPlan:getZoneAt", function()
        expect(string.find(moduleSource, "getZoneAt", 1, true)).toNotBeNil()
    end)

    it("should check landmark proximity using WorldPlan:isNearLandmark", function()
        expect(string.find(moduleSource, "isNearLandmark", 1, true)).toNotBeNil()
    end)

    it("should check river using WorldPlan:isOnRiver", function()
        expect(string.find(moduleSource, "isOnRiver", 1, true)).toNotBeNil()
    end)

    it("should check river exclusion zone", function()
        expect(string.find(moduleSource, "isInRiverExclusionZone", 1, true)).toNotBeNil()
    end)

    it("should check player plot using WorldPlan:isInPlayerPlot", function()
        expect(string.find(moduleSource, "isInPlayerPlot", 1, true)).toNotBeNil()
    end)

    it("should check distance to roads using WorldPlan:getDistanceToRoad", function()
        expect(string.find(moduleSource, "getDistanceToRoad", 1, true)).toNotBeNil()
    end)

    -- Avoid civic zones
    it("should avoid civic zones", function()
        expect(string.find(moduleSource, '"civic"', 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return RuinsBuilder")
    end)
end)
