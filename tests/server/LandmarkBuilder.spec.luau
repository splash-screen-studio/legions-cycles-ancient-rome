--!strict
--[[
    Tests for LandmarkBuilder module
    Tests module structure, VERSION constant, and landmark construction methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/LandmarkBuilder.luau")

describe("LandmarkBuilder", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define LandmarkBuilder table
        expect(string.find(moduleSource, "local LandmarkBuilder = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "LandmarkBuilder.__index = LandmarkBuilder", 1, true)).toNotBeNil()

        -- Should return LandmarkBuilder
        expect(string.find(moduleSource, "return LandmarkBuilder", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function LandmarkBuilder.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:destroy", 1, true)).toNotBeNil()
    end)

    -- Private methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _createCylinder() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createCylinder", 1, true)).toNotBeNil()
    end)

    it("should have _createColumn() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createColumn", 1, true)).toNotBeNil()
    end)

    it("should have _createPlatform() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createPlatform", 1, true)).toNotBeNil()
    end)

    it("should have _createColonnade() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createColonnade", 1, true)).toNotBeNil()
    end)

    -- Major landmark builders
    it("should have _buildForum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildForum", 1, true)).toNotBeNil()
    end)

    it("should have _buildColosseum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildColosseum", 1, true)).toNotBeNil()
    end)

    it("should have _buildThermae() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildThermae", 1, true)).toNotBeNil()
    end)

    it("should have _buildTemple() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildTemple", 1, true)).toNotBeNil()
    end)

    it("should have _buildCircusMaximus() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildCircusMaximus", 1, true)).toNotBeNil()
    end)

    -- Minor landmark builders
    it("should have _buildCastrum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildCastrum", 1, true)).toNotBeNil()
    end)

    it("should have _buildMacellum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildMacellum", 1, true)).toNotBeNil()
    end)

    it("should have _buildHorreum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildHorreum", 1, true)).toNotBeNil()
    end)

    it("should have _buildPharos() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildPharos", 1, true)).toNotBeNil()
    end)

    it("should have _buildEmporium() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildEmporium", 1, true)).toNotBeNil()
    end)

    it("should have _buildVillaRustica() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildVillaRustica", 1, true)).toNotBeNil()
    end)

    it("should have _buildSacellum() method for shrines", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildSacellum", 1, true)).toNotBeNil()
    end)

    -- Type mapper
    it("should have _buildLandmarkByType() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildLandmarkByType", 1, true)).toNotBeNil()
    end)

    -- Public query methods
    it("should have getLandmarkCount() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:getLandmarkCount", 1, true)).toNotBeNil()
    end)

    it("should have getParts() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:getParts", 1, true)).toNotBeNil()
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

    -- Should use Marble material for Roman aesthetic
    it("should use Marble material for classical look", function()
        expect(string.find(moduleSource, "Material = Enum.Material.Marble", 1, true)).toNotBeNil()
    end)

    -- Roman colors
    it("should have MARBLE_WHITE color constant", function()
        expect(string.find(moduleSource, "local MARBLE_WHITE", 1, true)).toNotBeNil()
    end)

    it("should have TERRACOTTA color constant", function()
        expect(string.find(moduleSource, "local TERRACOTTA", 1, true)).toNotBeNil()
    end)

    it("should have STONE_GRAY color constant", function()
        expect(string.find(moduleSource, "local STONE_GRAY", 1, true)).toNotBeNil()
    end)

    -- Column dimensions
    it("should have COLUMN_RADIUS constants", function()
        expect(string.find(moduleSource, "local COLUMN_RADIUS_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local COLUMN_RADIUS_MEDIUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local COLUMN_RADIUS_LARGE", 1, true)).toNotBeNil()
    end)

    it("should have COLUMN_HEIGHT constants", function()
        expect(string.find(moduleSource, "local COLUMN_HEIGHT_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local COLUMN_HEIGHT_MEDIUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local COLUMN_HEIGHT_LARGE", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export LandmarkBuilderConfig type", function()
        expect(string.find(moduleSource, "export type LandmarkBuilderConfig", 1, true)).toNotBeNil()
    end)

    it("should export LandmarkBuilderInstance type", function()
        expect(string.find(moduleSource, "export type LandmarkBuilderInstance", 1, true)).toNotBeNil()
    end)

    -- Roman naming for folder
    it("should use Roman naming for landmarks folder (Monumenta)", function()
        expect(string.find(moduleSource, "Landmarks_Monumenta", 1, true)).toNotBeNil()
    end)

    -- Query terrain height
    it("should query terrain height using TerrainUtils", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return LandmarkBuilder")
    end)
end)
