--!strict
--[[
    Tests for LightingConfig module
    Tests module structure, VERSION constant, and configuration values
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/shared/LightingConfig.luau")

describe("LightingConfig", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define LightingConfig table
        expect(string.find(moduleSource, "local LightingConfig = {}", 1, true)).toNotBeNil()

        -- Should return LightingConfig
        expect(string.find(moduleSource, "return LightingConfig", 1, true)).toNotBeNil()
    end)

    -- Color constants
    it("should have Colors table", function()
        expect(string.find(moduleSource, "LightingConfig.Colors = {", 1, true)).toNotBeNil()
    end)

    it("should have torch color constants", function()
        expect(string.find(moduleSource, "TORCH_WARM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TORCH_HOT", 1, true)).toNotBeNil()
    end)

    it("should have lamp color constants", function()
        expect(string.find(moduleSource, "LAMP_WARM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "LAMP_SOFT", 1, true)).toNotBeNil()
    end)

    it("should have brazier color constants", function()
        expect(string.find(moduleSource, "BRAZIER_WARM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BRAZIER_HOT", 1, true)).toNotBeNil()
    end)

    it("should have daylight color constants", function()
        expect(string.find(moduleSource, "DAYLIGHT_WARM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "DAYLIGHT_COOL", 1, true)).toNotBeNil()
    end)

    -- Materials
    it("should have Materials table", function()
        expect(string.find(moduleSource, "LightingConfig.Materials = {", 1, true)).toNotBeNil()
    end)

    it("should have FixtureColors table", function()
        expect(string.find(moduleSource, "LightingConfig.FixtureColors = {", 1, true)).toNotBeNil()
    end)

    -- Light source types
    it("should export LightSourceType type", function()
        expect(string.find(moduleSource, "export type LightSourceType", 1, true)).toNotBeNil()
    end)

    it("should export LightSourceConfig type", function()
        expect(string.find(moduleSource, "export type LightSourceConfig", 1, true)).toNotBeNil()
    end)

    it("should have Sources table with light configurations", function()
        expect(string.find(moduleSource, "LightingConfig.Sources", 1, true)).toNotBeNil()
    end)

    it("should have torch light source config", function()
        expect(string.find(moduleSource, "torch = {", 1, true)).toNotBeNil()
    end)

    it("should have oilLamp light source config", function()
        expect(string.find(moduleSource, "oilLamp = {", 1, true)).toNotBeNil()
    end)

    it("should have brazier light source config", function()
        expect(string.find(moduleSource, "brazier = {", 1, true)).toNotBeNil()
    end)

    it("should have doorway light source config", function()
        expect(string.find(moduleSource, "doorway = {", 1, true)).toNotBeNil()
    end)

    -- Fixture configurations
    it("should have Fixtures table", function()
        expect(string.find(moduleSource, "LightingConfig.Fixtures = {", 1, true)).toNotBeNil()
    end)

    -- Landmark lighting configurations
    it("should export LandmarkLightingConfig type", function()
        expect(string.find(moduleSource, "export type LandmarkLightingConfig", 1, true)).toNotBeNil()
    end)

    it("should have LandmarkLighting table", function()
        expect(string.find(moduleSource, "LightingConfig.LandmarkLighting", 1, true)).toNotBeNil()
    end)

    -- Major landmarks
    it("should have Forum lighting config", function()
        expect(string.find(moduleSource, "Forum = {", 1, true)).toNotBeNil()
    end)

    it("should have Colosseum lighting config", function()
        expect(string.find(moduleSource, "Colosseum = {", 1, true)).toNotBeNil()
    end)

    it("should have Thermae lighting config", function()
        expect(string.find(moduleSource, "Thermae = {", 1, true)).toNotBeNil()
    end)

    it("should have Temple lighting config", function()
        expect(string.find(moduleSource, "Temple = {", 1, true)).toNotBeNil()
    end)

    -- Default configuration
    it("should have DefaultLandmarkLighting", function()
        expect(string.find(moduleSource, "LightingConfig.DefaultLandmarkLighting", 1, true)).toNotBeNil()
    end)

    -- Helper function
    it("should have getForLandmark() function", function()
        expect(string.find(moduleSource, "function LightingConfig.getForLandmark", 1, true)).toNotBeNil()
    end)

    -- Light source properties
    it("should configure brightness for light sources", function()
        expect(string.find(moduleSource, "brightness = ", 1, true)).toNotBeNil()
    end)

    it("should configure range for light sources", function()
        expect(string.find(moduleSource, "range = ", 1, true)).toNotBeNil()
    end)

    it("should configure shadows for light sources", function()
        expect(string.find(moduleSource, "shadows = ", 1, true)).toNotBeNil()
    end)

    it("should configure flickerEnabled for light sources", function()
        expect(string.find(moduleSource, "flickerEnabled = ", 1, true)).toNotBeNil()
    end)

    it("should configure flickerIntensity for light sources", function()
        expect(string.find(moduleSource, "flickerIntensity = ", 1, true)).toNotBeNil()
    end)

    -- Landmark config properties
    it("should configure torchCount for landmarks", function()
        expect(string.find(moduleSource, "torchCount = ", 1, true)).toNotBeNil()
    end)

    it("should configure oilLampCount for landmarks", function()
        expect(string.find(moduleSource, "oilLampCount = ", 1, true)).toNotBeNil()
    end)

    it("should configure brazierCount for landmarks", function()
        expect(string.find(moduleSource, "brazierCount = ", 1, true)).toNotBeNil()
    end)

    it("should configure hasDoorwayLight for landmarks", function()
        expect(string.find(moduleSource, "hasDoorwayLight = ", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return LightingConfig")
    end)
end)
