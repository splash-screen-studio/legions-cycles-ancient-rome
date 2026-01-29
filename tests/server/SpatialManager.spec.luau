--!strict
--[[
    Tests for SpatialManager module
    Tests module structure, VERSION constant, and spatial query interface
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/SpatialManager.luau")

describe("SpatialManager", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "1.0.0"', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define SpatialManager table
        expect(string.find(moduleSource, "local SpatialManager = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "SpatialManager.__index = SpatialManager", 1, true)).toNotBeNil()

        -- Should return SpatialManager
        expect(string.find(moduleSource, "return SpatialManager", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function SpatialManager.new", 1, true)).toNotBeNil()
    end)

    -- Core query methods
    it("should have queryPoint() method", function()
        expect(string.find(moduleSource, "function SpatialManager.queryPoint", 1, true)).toNotBeNil()
    end)

    it("should have registerStructure() method", function()
        expect(string.find(moduleSource, "function SpatialManager.registerStructure", 1, true)).toNotBeNil()
    end)

    it("should have unregisterStructure() method", function()
        expect(string.find(moduleSource, "function SpatialManager.unregisterStructure", 1, true)).toNotBeNil()
    end)

    it("should have canPlaceAt() method", function()
        expect(string.find(moduleSource, "function SpatialManager.canPlaceAt", 1, true)).toNotBeNil()
    end)

    it("should have isNearRoad() method", function()
        expect(string.find(moduleSource, "function SpatialManager.isNearRoad", 1, true)).toNotBeNil()
    end)

    it("should have getDistanceToRoad() method", function()
        expect(string.find(moduleSource, "function SpatialManager.getDistanceToRoad", 1, true)).toNotBeNil()
    end)

    -- Structure management methods
    it("should have getStructures() method", function()
        expect(string.find(moduleSource, "function SpatialManager.getStructures", 1, true)).toNotBeNil()
    end)

    it("should have getStructure() method", function()
        expect(string.find(moduleSource, "function SpatialManager.getStructure", 1, true)).toNotBeNil()
    end)

    it("should have getOccupiedCellCount() method", function()
        expect(string.find(moduleSource, "function SpatialManager.getOccupiedCellCount", 1, true)).toNotBeNil()
    end)

    it("should have getStructureCount() method", function()
        expect(string.find(moduleSource, "function SpatialManager.getStructureCount", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export Structure type", function()
        expect(string.find(moduleSource, "export type Structure", 1, true)).toNotBeNil()
    end)

    it("should export SpatialInfo type", function()
        expect(string.find(moduleSource, "export type SpatialInfo", 1, true)).toNotBeNil()
    end)

    it("should export SpatialManagerConfig type", function()
        expect(string.find(moduleSource, "export type SpatialManagerConfig", 1, true)).toNotBeNil()
    end)

    it("should export SpatialManagerInstance type", function()
        expect(string.find(moduleSource, "export type SpatialManagerInstance", 1, true)).toNotBeNil()
    end)

    -- Helper functions
    it("should have getCellKey helper function", function()
        expect(string.find(moduleSource, "local function getCellKey", 1, true)).toNotBeNil()
    end)

    it("should have getCellKeysForArea helper function", function()
        expect(string.find(moduleSource, "local function getCellKeysForArea", 1, true)).toNotBeNil()
    end)

    -- Internal methods
    it("should have _getOrCreateCell internal method", function()
        expect(string.find(moduleSource, "function SpatialManager._getOrCreateCell", 1, true)).toNotBeNil()
    end)

    -- Dependencies
    it("should require SpatialConfig from Shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("SpatialConfig"))', 1, true)).toNotBeNil()
    end)

    it("should require TerrainUtils from Shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("TerrainUtils"))', 1, true)).toNotBeNil()
    end)

    -- Integration with WorldPlan
    it("should call worldPlan:getZoneAt in queryPoint", function()
        expect(string.find(moduleSource, "self.worldPlan:getZoneAt", 1, true)).toNotBeNil()
    end)

    it("should call worldPlan:canPlaceStructure in canPlaceAt", function()
        expect(string.find(moduleSource, "self.worldPlan:canPlaceStructure", 1, true)).toNotBeNil()
    end)

    it("should call worldPlan:isOnRoad in canPlaceAt", function()
        expect(string.find(moduleSource, "self.worldPlan:isOnRoad", 1, true)).toNotBeNil()
    end)

    it("should call worldPlan:getDistanceToRoad in isNearRoad", function()
        expect(string.find(moduleSource, "self.worldPlan:getDistanceToRoad", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return SpatialManager")
    end)
end)
