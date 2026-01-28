--!strict
--[[
    Tests for BridgeBuilder module
    Tests module structure, VERSION constant, and bridge construction methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/BridgeBuilder.luau")

describe("BridgeBuilder", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define BridgeBuilder table
        expect(string.find(moduleSource, "local BridgeBuilder = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "BridgeBuilder.__index = BridgeBuilder", 1, true)).toNotBeNil()

        -- Should return BridgeBuilder
        expect(string.find(moduleSource, "return BridgeBuilder", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function BridgeBuilder.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:destroy", 1, true)).toNotBeNil()
    end)

    -- Private methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _findIntersections() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:_findIntersections", 1, true)).toNotBeNil()
    end)

    it("should have _buildBridge() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:_buildBridge", 1, true)).toNotBeNil()
    end)

    it("should have _buildArch() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:_buildArch", 1, true)).toNotBeNil()
    end)

    it("should have _buildPillars() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:_buildPillars", 1, true)).toNotBeNil()
    end)

    -- Public query methods
    it("should have getBridgeCount() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:getBridgeCount", 1, true)).toNotBeNil()
    end)

    it("should have getIntersections() method", function()
        expect(string.find(moduleSource, "function BridgeBuilder:getIntersections", 1, true)).toNotBeNil()
    end)

    -- Bridge construction constants
    it("should have BRIDGE_HEIGHT constant", function()
        expect(string.find(moduleSource, "local BRIDGE_HEIGHT", 1, true)).toNotBeNil()
    end)

    it("should have DECK_THICKNESS constant", function()
        expect(string.find(moduleSource, "local DECK_THICKNESS", 1, true)).toNotBeNil()
    end)

    it("should have RAILING_HEIGHT constant", function()
        expect(string.find(moduleSource, "local RAILING_HEIGHT", 1, true)).toNotBeNil()
    end)

    it("should have PILLAR_WIDTH constant", function()
        expect(string.find(moduleSource, "local PILLAR_WIDTH", 1, true)).toNotBeNil()
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

    -- Should use Brick material for Roman aesthetic
    it("should use Brick material for stone look", function()
        expect(string.find(moduleSource, "Material = Enum.Material.Brick", 1, true)).toNotBeNil()
    end)

    -- Should have line segment intersection algorithm
    it("should have lineSegmentIntersection helper function", function()
        expect(string.find(moduleSource, "local function lineSegmentIntersection", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export BridgeBuilderConfig type", function()
        expect(string.find(moduleSource, "export type BridgeBuilderConfig", 1, true)).toNotBeNil()
    end)

    it("should export BridgeBuilderInstance type", function()
        expect(string.find(moduleSource, "export type BridgeBuilderInstance", 1, true)).toNotBeNil()
    end)

    it("should export Intersection type", function()
        expect(string.find(moduleSource, "export type Intersection", 1, true)).toNotBeNil()
    end)

    -- Roman naming for folder
    it("should use Roman naming for bridges folder (Pontes)", function()
        expect(string.find(moduleSource, "Bridges_Pontes", 1, true)).toNotBeNil()
    end)

    -- Stone colors for Roman aesthetic
    it("should have STONE_COLOR constant for Roman aesthetic", function()
        expect(string.find(moduleSource, "local STONE_COLOR", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return BridgeBuilder")
    end)
end)
