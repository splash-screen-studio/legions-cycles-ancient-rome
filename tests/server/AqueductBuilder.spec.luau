--!strict
--[[
    Tests for AqueductBuilder module
    Tests module structure, VERSION constant, and aqueduct construction methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/AqueductBuilder.luau")

describe("AqueductBuilder", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define AqueductBuilder table
        expect(string.find(moduleSource, "local AqueductBuilder = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "AqueductBuilder.__index = AqueductBuilder", 1, true)).toNotBeNil()

        -- Should return AqueductBuilder
        expect(string.find(moduleSource, "return AqueductBuilder", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function AqueductBuilder.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:destroy", 1, true)).toNotBeNil()
    end)

    -- Private methods
    it("should have _generatePath() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_generatePath", 1, true)).toNotBeNil()
    end)

    it("should have _determineSectionType() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_determineSectionType", 1, true)).toNotBeNil()
    end)

    it("should have _calculateTiers() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_calculateTiers", 1, true)).toNotBeNil()
    end)

    it("should have _buildArch() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_buildArch", 1, true)).toNotBeNil()
    end)

    it("should have _buildPillar() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_buildPillar", 1, true)).toNotBeNil()
    end)

    it("should have _buildWaterChannel() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_buildWaterChannel", 1, true)).toNotBeNil()
    end)

    it("should have _buildDebris() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_buildDebris", 1, true)).toNotBeNil()
    end)

    it("should have _buildSegment() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_buildSegment", 1, true)).toNotBeNil()
    end)

    -- Part creation methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _createPartRotated() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:_createPartRotated", 1, true)).toNotBeNil()
    end)

    -- Public query methods
    it("should have getSegmentCount() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:getSegmentCount", 1, true)).toNotBeNil()
    end)

    it("should have getSegments() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:getSegments", 1, true)).toNotBeNil()
    end)

    it("should have getParts() method", function()
        expect(string.find(moduleSource, "function AqueductBuilder:getParts", 1, true)).toNotBeNil()
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

    -- Roman colors
    it("should have STONE_GRAY color constant", function()
        expect(string.find(moduleSource, "local STONE_GRAY", 1, true)).toNotBeNil()
    end)

    it("should have STONE_DARK color constant", function()
        expect(string.find(moduleSource, "local STONE_DARK", 1, true)).toNotBeNil()
    end)

    it("should have STONE_WEATHERED color constant", function()
        expect(string.find(moduleSource, "local STONE_WEATHERED", 1, true)).toNotBeNil()
    end)

    it("should have STONE_RUINS color constant", function()
        expect(string.find(moduleSource, "local STONE_RUINS", 1, true)).toNotBeNil()
    end)

    it("should have MOSS_GREEN color constant for vegetation", function()
        expect(string.find(moduleSource, "local MOSS_GREEN", 1, true)).toNotBeNil()
    end)

    -- Construction constants
    it("should have SEGMENT_LENGTH constant", function()
        expect(string.find(moduleSource, "local SEGMENT_LENGTH", 1, true)).toNotBeNil()
    end)

    it("should have ARCH_HEIGHT constant", function()
        expect(string.find(moduleSource, "local ARCH_HEIGHT", 1, true)).toNotBeNil()
    end)

    it("should have PILLAR_WIDTH constant", function()
        expect(string.find(moduleSource, "local PILLAR_WIDTH", 1, true)).toNotBeNil()
    end)

    it("should have CHANNEL_WIDTH constant", function()
        expect(string.find(moduleSource, "local CHANNEL_WIDTH", 1, true)).toNotBeNil()
    end)

    it("should have LANDMARK_AVOIDANCE_RADIUS constant", function()
        expect(string.find(moduleSource, "local LANDMARK_AVOIDANCE_RADIUS", 1, true)).toNotBeNil()
    end)

    -- Section types
    it("should export SectionType type", function()
        expect(string.find(moduleSource, "export type SectionType", 1, true)).toNotBeNil()
    end)

    it("should define functional section type", function()
        expect(string.find(moduleSource, '"functional"', 1, true)).toNotBeNil()
    end)

    it("should define weathered section type", function()
        expect(string.find(moduleSource, '"weathered"', 1, true)).toNotBeNil()
    end)

    it("should define crumbling section type", function()
        expect(string.find(moduleSource, '"crumbling"', 1, true)).toNotBeNil()
    end)

    it("should define ruined section type", function()
        expect(string.find(moduleSource, '"ruined"', 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export AqueductBuilderConfig type", function()
        expect(string.find(moduleSource, "export type AqueductBuilderConfig", 1, true)).toNotBeNil()
    end)

    it("should export AqueductBuilderInstance type", function()
        expect(string.find(moduleSource, "export type AqueductBuilderInstance", 1, true)).toNotBeNil()
    end)

    it("should export AqueductSegment type", function()
        expect(string.find(moduleSource, "export type AqueductSegment", 1, true)).toNotBeNil()
    end)

    -- Roman naming for folder
    it("should use Roman naming for aqueduct folder (Aquaeductus)", function()
        expect(string.find(moduleSource, "Aqueduct_Aquaeductus", 1, true)).toNotBeNil()
    end)

    -- Query terrain height
    it("should query terrain height using TerrainUtils", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
    end)

    -- Landmark avoidance
    it("should check landmark proximity using WorldPlan", function()
        expect(string.find(moduleSource, "isNearLandmark", 1, true)).toNotBeNil()
    end)

    -- Use Brick material for aqueduct
    it("should use Brick material for aqueduct structure", function()
        expect(string.find(moduleSource, "Enum.Material.Brick", 1, true)).toNotBeNil()
    end)

    -- Use Grass material for moss
    it("should use Grass material for moss/vegetation", function()
        expect(string.find(moduleSource, "Enum.Material.Grass", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return AqueductBuilder")
    end)
end)
