--!strict
--[[
    Tests for WorldPlanGenerator module
    Tests module structure, VERSION constant, and generation methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/WorldPlanGenerator.luau")

describe("WorldPlanGenerator", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define WorldPlanGenerator table
        expect(string.find(moduleSource, "local WorldPlanGenerator = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "WorldPlanGenerator.__index = WorldPlanGenerator", 1, true)).toNotBeNil()

        -- Should return WorldPlanGenerator
        expect(string.find(moduleSource, "return WorldPlanGenerator", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function WorldPlanGenerator.new", 1, true)).toNotBeNil()
    end)

    it("should have generate() method", function()
        expect(string.find(moduleSource, "function WorldPlanGenerator.generate", 1, true)).toNotBeNil()
    end)

    -- Private generation methods
    it("should have _generateRiverPath() method", function()
        expect(string.find(moduleSource, "function WorldPlanGenerator._generateRiverPath", 1, true)).toNotBeNil()
    end)

    it("should have _generateZones() method", function()
        expect(string.find(moduleSource, "function WorldPlanGenerator._generateZones", 1, true)).toNotBeNil()
    end)

    it("should have _generateLandmarks() method", function()
        expect(string.find(moduleSource, "function WorldPlanGenerator._generateLandmarks", 1, true)).toNotBeNil()
    end)

    it("should have _generateRoads() method", function()
        expect(string.find(moduleSource, "function WorldPlanGenerator._generateRoads", 1, true)).toNotBeNil()
    end)

    it("should have _generatePlayerPlots() method", function()
        expect(string.find(moduleSource, "function WorldPlanGenerator._generatePlayerPlots", 1, true)).toNotBeNil()
    end)

    -- Configuration
    it("should have mapSize configuration", function()
        expect(string.find(moduleSource, "mapSize", 1, true)).toNotBeNil()
    end)

    it("should have seed configuration", function()
        expect(string.find(moduleSource, "seed", 1, true)).toNotBeNil()
    end)

    it("should have riverWidth configuration", function()
        expect(string.find(moduleSource, "riverWidth", 1, true)).toNotBeNil()
    end)

    -- Landmark types (Roman theme)
    it("should include Forum landmark", function()
        expect(string.find(moduleSource, '"Forum"', 1, true)).toNotBeNil()
    end)

    it("should include Colosseum landmark", function()
        expect(string.find(moduleSource, '"Colosseum"', 1, true)).toNotBeNil()
    end)

    it("should include Thermae landmark", function()
        expect(string.find(moduleSource, '"Thermae"', 1, true)).toNotBeNil()
    end)

    it("should include Temple landmark", function()
        expect(string.find(moduleSource, '"Temple"', 1, true)).toNotBeNil()
    end)

    -- Zone types
    it("should include civic zone type", function()
        expect(string.find(moduleSource, '"civic"', 1, true)).toNotBeNil()
    end)

    it("should include urban zone type", function()
        expect(string.find(moduleSource, '"urban"', 1, true)).toNotBeNil()
    end)

    it("should include rural zone type", function()
        expect(string.find(moduleSource, '"rural"', 1, true)).toNotBeNil()
    end)

    -- Road types
    it("should include via road type", function()
        expect(string.find(moduleSource, '"via"', 1, true)).toNotBeNil()
    end)

    it("should include path road type", function()
        expect(string.find(moduleSource, '"path"', 1, true)).toNotBeNil()
    end)

    -- Should require WorldPlan module
    it("should require WorldPlan module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("WorldPlan"))', 1, true)).toNotBeNil()
    end)

    -- Should use noise for procedural generation
    it("should use math.noise for procedural generation", function()
        expect(string.find(moduleSource, "math.noise", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export WorldPlanGeneratorConfig type", function()
        expect(string.find(moduleSource, "export type WorldPlanGeneratorConfig", 1, true)).toNotBeNil()
    end)

    it("should export WorldPlanGeneratorInstance type", function()
        expect(string.find(moduleSource, "export type WorldPlanGeneratorInstance", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return WorldPlanGenerator")
    end)
end)
