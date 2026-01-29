--!strict
--[[
    Tests for MaterialConfig module
    Tests module structure, VERSION constant, and configuration values
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/shared/MaterialConfig.luau")

describe("MaterialConfig", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define MaterialConfig table
        expect(string.find(moduleSource, "local MaterialConfig = {}", 1, true)).toNotBeNil()

        -- Should return MaterialConfig
        expect(string.find(moduleSource, "return MaterialConfig", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export AltitudeBand type", function()
        expect(string.find(moduleSource, "export type AltitudeBand", 1, true)).toNotBeNil()
    end)

    it("should export ZoneMaterialOverride type", function()
        expect(string.find(moduleSource, "export type ZoneMaterialOverride", 1, true)).toNotBeNil()
    end)

    it("should export ProximityRule type", function()
        expect(string.find(moduleSource, "export type ProximityRule", 1, true)).toNotBeNil()
    end)

    it("should export SlopeBand type for Mediterranean terrain", function()
        expect(string.find(moduleSource, "export type SlopeBand", 1, true)).toNotBeNil()
    end)

    -- Altitude bands
    it("should define ALTITUDE_BANDS configuration", function()
        expect(string.find(moduleSource, "ALTITUDE_BANDS", 1, true)).toNotBeNil()
    end)

    it("should have altitude bands for Mediterranean terrain zones", function()
        -- Hilltops: >50
        expect(string.find(moduleSource, "minAltitude = 50", 1, true)).toNotBeNil()
        -- Upper hillsides: 40-50
        expect(string.find(moduleSource, "minAltitude = 40", 1, true)).toNotBeNil()
        -- Lower hillsides: 30-40
        expect(string.find(moduleSource, "minAltitude = 30", 1, true)).toNotBeNil()
        -- Flat areas: 20-30
        expect(string.find(moduleSource, "minAltitude = 20", 1, true)).toNotBeNil()
    end)

    -- Slope bands (Issue #70)
    it("should define SLOPE_BANDS configuration for arid hillsides", function()
        expect(string.find(moduleSource, "SLOPE_BANDS", 1, true)).toNotBeNil()
    end)

    it("should have slope bands for steep, moderate, and gentle terrain", function()
        -- Very steep: >35 degrees
        expect(string.find(moduleSource, "minSlope = 35", 1, true)).toNotBeNil()
        -- Steep: 25-35 degrees
        expect(string.find(moduleSource, "minSlope = 25", 1, true)).toNotBeNil()
        -- Moderate: 15-25 degrees
        expect(string.find(moduleSource, "minSlope = 15", 1, true)).toNotBeNil()
        -- Gentle: 0-15 degrees
        expect(string.find(moduleSource, "minSlope = 0", 1, true)).toNotBeNil()
    end)

    -- Zone materials
    it("should define ZONE_MATERIALS configuration", function()
        expect(string.find(moduleSource, "ZONE_MATERIALS", 1, true)).toNotBeNil()
    end)

    it("should have material overrides for all zone types", function()
        expect(string.find(moduleSource, 'civic = {', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'urban = {', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'rural = {', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'wilderness = {', 1, true)).toNotBeNil()
    end)

    -- Proximity rules
    it("should define PROXIMITY_RULES configuration", function()
        expect(string.find(moduleSource, "PROXIMITY_RULES", 1, true)).toNotBeNil()
    end)

    it("should have proximity rules for roads, rivers, structures, and fountains", function()
        expect(string.find(moduleSource, "road = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "river = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "structure = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "fountain = {", 1, true)).toNotBeNil()
    end)

    it("should have grass proximity rules for water features (Issue #70)", function()
        expect(string.find(moduleSource, "riverGrass = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "fountainGrass = {", 1, true)).toNotBeNil()
    end)

    -- Landmark materials
    it("should define LANDMARK_MATERIALS configuration", function()
        expect(string.find(moduleSource, "LANDMARK_MATERIALS", 1, true)).toNotBeNil()
    end)

    it("should have landmark materials for major structures", function()
        expect(string.find(moduleSource, "Forum = ", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Colosseum = ", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Thermae = ", 1, true)).toNotBeNil()
    end)

    -- Allowed materials
    it("should define ALLOWED_MATERIALS list", function()
        expect(string.find(moduleSource, "ALLOWED_MATERIALS", 1, true)).toNotBeNil()
    end)

    it("should include Mediterranean-appropriate materials", function()
        expect(string.find(moduleSource, "Material.Grass", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Material.Ground", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Material.Rock", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Material.Sand", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Material.Sandstone", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Material.Cobblestone", 1, true)).toNotBeNil()
    end)

    it("should NOT include non-Mediterranean materials (Snow, Ice)", function()
        -- These should NOT be in allowed materials
        expect(string.find(moduleSource, "Material.Snow")).toBeNil()
        expect(string.find(moduleSource, "Material.Ice")).toBeNil()
    end)

    -- Target coverage (Issue #70)
    it("should define TARGET_COVERAGE for validation", function()
        expect(string.find(moduleSource, "TARGET_COVERAGE", 1, true)).toNotBeNil()
    end)

    it("should have Mediterranean target coverage (40% Grass, 30% Ground)", function()
        expect(string.find(moduleSource, "Grass = 0.40", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Ground = 0.30", 1, true)).toNotBeNil()
    end)

    -- Helper functions
    it("should have getAltitudeBand helper function", function()
        expect(string.find(moduleSource, "function MaterialConfig.getAltitudeBand", 1, true)).toNotBeNil()
    end)

    it("should have getSlopeBand helper function for Mediterranean terrain", function()
        expect(string.find(moduleSource, "function MaterialConfig.getSlopeBand", 1, true)).toNotBeNil()
    end)

    it("should have getZoneMaterial helper function", function()
        expect(string.find(moduleSource, "function MaterialConfig.getZoneMaterial", 1, true)).toNotBeNil()
    end)

    it("should have isAllowedMaterial helper function", function()
        expect(string.find(moduleSource, "function MaterialConfig.isAllowedMaterial", 1, true)).toNotBeNil()
    end)

    it("should have getLandmarkMaterial helper function", function()
        expect(string.find(moduleSource, "function MaterialConfig.getLandmarkMaterial", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return MaterialConfig")
    end)
end)
