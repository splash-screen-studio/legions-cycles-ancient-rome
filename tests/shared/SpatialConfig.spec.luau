--!strict
--[[
    Tests for SpatialConfig module
    Tests module structure, VERSION constant, and configuration values
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/shared/SpatialConfig.luau")

describe("SpatialConfig", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "1.0.0"', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define SpatialConfig table
        expect(string.find(moduleSource, "local SpatialConfig = {}", 1, true)).toNotBeNil()

        -- Should return SpatialConfig
        expect(string.find(moduleSource, "return SpatialConfig", 1, true)).toNotBeNil()
    end)

    -- Grid configuration
    it("should have CELL_SIZE constant", function()
        expect(string.find(moduleSource, "SpatialConfig.CELL_SIZE", 1, true)).toNotBeNil()
    end)

    it("should have DEFAULT_MAP_SIZE constant", function()
        expect(string.find(moduleSource, "SpatialConfig.DEFAULT_MAP_SIZE", 1, true)).toNotBeNil()
    end)

    -- Placement configuration
    it("should have PLACEMENT configuration table", function()
        expect(string.find(moduleSource, "SpatialConfig.PLACEMENT", 1, true)).toNotBeNil()
    end)

    it("should have MIN_ROAD_DISTANCE in PLACEMENT", function()
        expect(string.find(moduleSource, "MIN_ROAD_DISTANCE", 1, true)).toNotBeNil()
    end)

    it("should have MAX_ROAD_DISTANCE in PLACEMENT", function()
        expect(string.find(moduleSource, "MAX_ROAD_DISTANCE", 1, true)).toNotBeNil()
    end)

    it("should have STRUCTURE_PADDING in PLACEMENT", function()
        expect(string.find(moduleSource, "STRUCTURE_PADDING", 1, true)).toNotBeNil()
    end)

    -- Query configuration
    it("should have QUERY configuration table", function()
        expect(string.find(moduleSource, "SpatialConfig.QUERY", 1, true)).toNotBeNil()
    end)

    it("should have DEFAULT_SEARCH_RADIUS in QUERY", function()
        expect(string.find(moduleSource, "DEFAULT_SEARCH_RADIUS", 1, true)).toNotBeNil()
    end)

    it("should have MAX_AREA_RESULTS in QUERY", function()
        expect(string.find(moduleSource, "MAX_AREA_RESULTS", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return SpatialConfig")
    end)
end)
