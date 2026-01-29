--!strict
--[[
    Tests for WorldPlan module
    Tests module structure, VERSION constant, and query interface
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/shared/WorldPlan.luau")

describe("WorldPlan", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define WorldPlan table
        expect(string.find(moduleSource, "local WorldPlan = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "WorldPlan.__index = WorldPlan", 1, true)).toNotBeNil()

        -- Should return WorldPlan
        expect(string.find(moduleSource, "return WorldPlan", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function WorldPlan.new", 1, true)).toNotBeNil()
    end)

    -- River query interface
    it("should have getRiverPath() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getRiverPath", 1, true)).toNotBeNil()
    end)

    it("should have getRiverWidth() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getRiverWidth", 1, true)).toNotBeNil()
    end)

    it("should have isOnRiver() method", function()
        expect(string.find(moduleSource, "function WorldPlan.isOnRiver", 1, true)).toNotBeNil()
    end)

    it("should have getDistanceToRiver() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getDistanceToRiver", 1, true)).toNotBeNil()
    end)

    it("should have isInRiverExclusionZone() method", function()
        expect(string.find(moduleSource, "function WorldPlan.isInRiverExclusionZone", 1, true)).toNotBeNil()
    end)

    it("should have getRiverExclusionWidth() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getRiverExclusionWidth", 1, true)).toNotBeNil()
    end)

    it("should have getMaxUrbanSlope() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getMaxUrbanSlope", 1, true)).toNotBeNil()
    end)

    it("should have getMaxFountainSlope() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getMaxFountainSlope", 1, true)).toNotBeNil()
    end)

    -- Zone query interface
    it("should have getZoneAt() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getZoneAt", 1, true)).toNotBeNil()
    end)

    it("should have isUrban() method", function()
        expect(string.find(moduleSource, "function WorldPlan.isUrban", 1, true)).toNotBeNil()
    end)

    it("should have isRural() method", function()
        expect(string.find(moduleSource, "function WorldPlan.isRural", 1, true)).toNotBeNil()
    end)

    it("should have getZones() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getZones", 1, true)).toNotBeNil()
    end)

    -- Landmark query interface
    it("should have getLandmarks() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getLandmarks", 1, true)).toNotBeNil()
    end)

    it("should have getNearestLandmark() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getNearestLandmark", 1, true)).toNotBeNil()
    end)

    it("should have isNearLandmark() method", function()
        expect(string.find(moduleSource, "function WorldPlan.isNearLandmark", 1, true)).toNotBeNil()
    end)

    it("should have getLandmarkAt() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getLandmarkAt", 1, true)).toNotBeNil()
    end)

    -- Road query interface
    it("should have getRoads() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getRoads", 1, true)).toNotBeNil()
    end)

    it("should have isOnRoad() method", function()
        expect(string.find(moduleSource, "function WorldPlan.isOnRoad", 1, true)).toNotBeNil()
    end)

    it("should have getDistanceToRoad() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getDistanceToRoad", 1, true)).toNotBeNil()
    end)

    -- Player plot query interface
    it("should have getPlayerPlots() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getPlayerPlots", 1, true)).toNotBeNil()
    end)

    it("should have isInPlayerPlot() method", function()
        expect(string.find(moduleSource, "function WorldPlan.isInPlayerPlot", 1, true)).toNotBeNil()
    end)

    -- Combined query interface
    it("should have canPlaceStructure() method", function()
        expect(string.find(moduleSource, "function WorldPlan.canPlaceStructure", 1, true)).toNotBeNil()
    end)

    it("should have getTerrainContext() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getTerrainContext", 1, true)).toNotBeNil()
    end)

    it("should have getMapSize() method", function()
        expect(string.find(moduleSource, "function WorldPlan.getMapSize", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export ZoneType", function()
        expect(string.find(moduleSource, "export type ZoneType", 1, true)).toNotBeNil()
    end)

    it("should export Zone type", function()
        expect(string.find(moduleSource, "export type Zone", 1, true)).toNotBeNil()
    end)

    it("should export Landmark type", function()
        expect(string.find(moduleSource, "export type Landmark", 1, true)).toNotBeNil()
    end)

    it("should export Road type", function()
        expect(string.find(moduleSource, "export type Road", 1, true)).toNotBeNil()
    end)

    it("should export PlayerPlot type", function()
        expect(string.find(moduleSource, "export type PlayerPlot", 1, true)).toNotBeNil()
    end)

    it("should export TerrainContext type", function()
        expect(string.find(moduleSource, "export type TerrainContext", 1, true)).toNotBeNil()
    end)

    it("should export WorldPlanData type", function()
        expect(string.find(moduleSource, "export type WorldPlanData", 1, true)).toNotBeNil()
    end)

    it("should have riverExclusionWidth in WorldPlanData type", function()
        expect(string.find(moduleSource, "riverExclusionWidth", 1, true)).toNotBeNil()
    end)

    it("should have maxUrbanSlope in WorldPlanData type", function()
        expect(string.find(moduleSource, "maxUrbanSlope", 1, true)).toNotBeNil()
    end)

    it("should have maxFountainSlope in WorldPlanData type", function()
        expect(string.find(moduleSource, "maxFountainSlope", 1, true)).toNotBeNil()
    end)

    it("should export WorldPlanInstance type", function()
        expect(string.find(moduleSource, "export type WorldPlanInstance", 1, true)).toNotBeNil()
    end)

    -- Helper functions
    it("should have distanceToLineSegment helper", function()
        expect(string.find(moduleSource, "distanceToLineSegment", 1, true)).toNotBeNil()
    end)

    it("should have distanceToPath helper", function()
        expect(string.find(moduleSource, "distanceToPath", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return WorldPlan")
    end)
end)
