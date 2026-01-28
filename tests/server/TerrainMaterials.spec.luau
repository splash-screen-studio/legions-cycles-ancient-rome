--!strict
--[[
    Tests for TerrainMaterials module
    Tests module structure, VERSION constant, and material application interface
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/TerrainMaterials.luau")

describe("TerrainMaterials", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define TerrainMaterials table
        expect(string.find(moduleSource, "local TerrainMaterials = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "TerrainMaterials.__index = TerrainMaterials", 1, true)).toNotBeNil()

        -- Should return TerrainMaterials
        expect(string.find(moduleSource, "return TerrainMaterials", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function TerrainMaterials.new", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export TerrainMaterialsConfig type", function()
        expect(string.find(moduleSource, "export type TerrainMaterialsConfig", 1, true)).toNotBeNil()
    end)

    it("should export TerrainMaterialsInstance type", function()
        expect(string.find(moduleSource, "export type TerrainMaterialsInstance", 1, true)).toNotBeNil()
    end)

    -- Core methods
    it("should have setWorldPlan method", function()
        expect(string.find(moduleSource, "function TerrainMaterials:setWorldPlan", 1, true)).toNotBeNil()
    end)

    it("should have getMaterialAt method", function()
        expect(string.find(moduleSource, "function TerrainMaterials:getMaterialAt", 1, true)).toNotBeNil()
    end)

    it("should have applyToRegion method", function()
        expect(string.find(moduleSource, "function TerrainMaterials:applyToRegion", 1, true)).toNotBeNil()
    end)

    it("should have applyAll method", function()
        expect(string.find(moduleSource, "function TerrainMaterials:applyAll", 1, true)).toNotBeNil()
    end)

    it("should have getMaterialStats method", function()
        expect(string.find(moduleSource, "function TerrainMaterials:getMaterialStats", 1, true)).toNotBeNil()
    end)

    -- Private helper methods
    it("should have _getMaterialByAltitude private method", function()
        expect(string.find(moduleSource, "function TerrainMaterials:_getMaterialByAltitude", 1, true)).toNotBeNil()
    end)

    it("should have _getZoneMaterial private method", function()
        expect(string.find(moduleSource, "function TerrainMaterials:_getZoneMaterial", 1, true)).toNotBeNil()
    end)

    -- Dependencies
    it("should require MaterialConfig", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("MaterialConfig"))', 1, true)).toNotBeNil()
    end)

    it("should require WorldPlan", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("WorldPlan"))', 1, true)).toNotBeNil()
    end)

    it("should require TerrainUtils", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("TerrainUtils"))', 1, true)).toNotBeNil()
    end)

    -- Priority chain implementation
    it("should check zone override in getMaterialAt", function()
        expect(string.find(moduleSource, "getZoneAt", 1, true)).toNotBeNil()
    end)

    it("should check landmark proximity in getMaterialAt", function()
        expect(string.find(moduleSource, "getNearestLandmark", 1, true)).toNotBeNil()
    end)

    it("should check water proximity in getMaterialAt", function()
        expect(string.find(moduleSource, "getDistanceToRiver", 1, true)).toNotBeNil()
    end)

    it("should check road proximity in getMaterialAt", function()
        expect(string.find(moduleSource, "isOnRoad", 1, true)).toNotBeNil()
    end)

    -- Yield for performance
    it("should yield periodically to prevent timeout", function()
        expect(string.find(moduleSource, "task.wait()", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return TerrainMaterials")
    end)
end)
