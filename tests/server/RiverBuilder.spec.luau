--!strict
--[[
    Tests for RiverBuilder module
    Tests module structure, VERSION constant, and river construction methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/RiverBuilder.luau")

describe("RiverBuilder", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define RiverBuilder table
        expect(string.find(moduleSource, "local RiverBuilder = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "RiverBuilder.__index = RiverBuilder", 1, true)).toNotBeNil()

        -- Should return RiverBuilder
        expect(string.find(moduleSource, "return RiverBuilder", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function RiverBuilder.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function RiverBuilder:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function RiverBuilder:destroy", 1, true)).toNotBeNil()
    end)

    -- Private methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function RiverBuilder:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _buildSegment() method", function()
        expect(string.find(moduleSource, "function RiverBuilder:_buildSegment", 1, true)).toNotBeNil()
    end)

    it("should have _clearTerrainInRiver() method", function()
        expect(string.find(moduleSource, "function RiverBuilder:_clearTerrainInRiver", 1, true)).toNotBeNil()
    end)

    it("should have _fillWithWater() method", function()
        expect(string.find(moduleSource, "function RiverBuilder:_fillWithWater", 1, true)).toNotBeNil()
    end)

    -- River construction constants
    it("should have WALL_HEIGHT constant", function()
        expect(string.find(moduleSource, "local WALL_HEIGHT", 1, true)).toNotBeNil()
    end)

    it("should have WALL_THICKNESS constant", function()
        expect(string.find(moduleSource, "local WALL_THICKNESS", 1, true)).toNotBeNil()
    end)

    it("should have FLOOR_THICKNESS constant", function()
        expect(string.find(moduleSource, "local FLOOR_THICKNESS", 1, true)).toNotBeNil()
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

    -- Should use Rock material for natural look
    it("should use Rock material for walls", function()
        expect(string.find(moduleSource, "Material = Enum.Material.Rock", 1, true)).toNotBeNil()
    end)

    -- Should clear terrain inside river
    it("should clear terrain to Air", function()
        expect(string.find(moduleSource, "Enum.Material.Air", 1, true)).toNotBeNil()
    end)

    -- Should fill with Water
    it("should fill river with Water terrain", function()
        expect(string.find(moduleSource, "Enum.Material.Water", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export RiverBuilderConfig type", function()
        expect(string.find(moduleSource, "export type RiverBuilderConfig", 1, true)).toNotBeNil()
    end)

    it("should export RiverBuilderInstance type", function()
        expect(string.find(moduleSource, "export type RiverBuilderInstance", 1, true)).toNotBeNil()
    end)

    -- Roman naming
    it("should use Roman naming for river folder (Tiberis)", function()
        expect(string.find(moduleSource, "River_Tiberis", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return RiverBuilder")
    end)
end)
