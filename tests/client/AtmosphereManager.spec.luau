--!strict
--[[
    Tests for AtmosphereManager module
    Verifies lighting, atmosphere, and sky configuration for Roman atmosphere
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/AtmosphereManager.luau")

describe("AtmosphereManager", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define AtmosphereManager table
        expect(string.find(moduleSource, "local AtmosphereManager = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "AtmosphereManager.__index = AtmosphereManager", 1, true)).toNotBeNil()

        -- Should return AtmosphereManager
        expect(string.find(moduleSource, "return AtmosphereManager", 1, true)).toNotBeNil()
    end)

    it("should use Lighting service", function()
        expect(string.find(moduleSource, 'Lighting = game:GetService("Lighting")', 1, true)).toNotBeNil()
    end)

    it("should use TweenService for smooth transitions", function()
        expect(string.find(moduleSource, 'TweenService = game:GetService("TweenService")', 1, true)).toNotBeNil()
    end)

    it("should use Maid for cleanup", function()
        expect(string.find(moduleSource, "Maid.new()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_maid:give", 1, true)).toNotBeNil()
    end)

    it("should have time presets for different times of day", function()
        expect(string.find(moduleSource, "TIME_PRESETS", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "dawn = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "morning = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "midday = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "goldenHour = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "dusk = {", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "night = {", 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function AtmosphereManager.new()", 1, true)).toNotBeNil()
    end)

    it("should setup lighting in constructor", function()
        expect(string.find(moduleSource, "self:_setupLighting()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "function AtmosphereManager:_setupLighting()", 1, true)).toNotBeNil()
    end)

    it("should setup atmosphere in constructor", function()
        expect(string.find(moduleSource, "self:_setupAtmosphere()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "function AtmosphereManager:_setupAtmosphere()", 1, true)).toNotBeNil()
    end)

    it("should setup sky in constructor", function()
        expect(string.find(moduleSource, "self:_setupSky()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "function AtmosphereManager:_setupSky()", 1, true)).toNotBeNil()
    end)

    it("should configure Rome geographic latitude", function()
        -- Rome is at approximately 42 degrees latitude
        expect(string.find(moduleSource, "GeographicLatitude = 42", 1, true)).toNotBeNil()
    end)

    it("should create Atmosphere instance", function()
        expect(string.find(moduleSource, 'Instance.new("Atmosphere")', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "RomanAtmosphere", 1, true)).toNotBeNil()
    end)

    it("should configure Mediterranean haze in Atmosphere", function()
        -- Verify atmosphere properties for Mediterranean climate
        expect(string.find(moduleSource, "atmosphere.Density", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "atmosphere.Color", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "atmosphere.Haze", 1, true)).toNotBeNil()
    end)

    it("should create Sky instance", function()
        expect(string.find(moduleSource, 'Instance.new("Sky")', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "MediterraneanSky", 1, true)).toNotBeNil()
    end)

    it("should configure sky with celestial bodies", function()
        expect(string.find(moduleSource, "sky.CelestialBodiesShown = true", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "sky.SunAngularSize", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "sky.MoonAngularSize", 1, true)).toNotBeNil()
    end)

    it("should have setTimePreset method with transitions", function()
        expect(string.find(moduleSource, "function AtmosphereManager:setTimePreset", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TweenService:Create", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TweenInfo.new", 1, true)).toNotBeNil()
    end)

    it("should have applyGoldenHour method for immediate application", function()
        expect(string.find(moduleSource, "function AtmosphereManager:applyGoldenHour()", 1, true)).toNotBeNil()
    end)

    it("should have getCurrentPreset method", function()
        expect(string.find(moduleSource, "function AtmosphereManager:getCurrentPreset()", 1, true)).toNotBeNil()
    end)

    it("should have getCurrentAmbientLevel method for other systems", function()
        expect(string.find(moduleSource, "function AtmosphereManager:getCurrentAmbientLevel()", 1, true)).toNotBeNil()
    end)

    it("should have getClockTime method", function()
        expect(string.find(moduleSource, "function AtmosphereManager:getClockTime()", 1, true)).toNotBeNil()
    end)

    it("should have setClockTime method", function()
        expect(string.find(moduleSource, "function AtmosphereManager:setClockTime", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function AtmosphereManager:start()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function AtmosphereManager:destroy()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_maid:destroy()", 1, true)).toNotBeNil()
    end)

    it("should configure lighting technology to Future", function()
        expect(string.find(moduleSource, "Lighting.Technology = Enum.Technology.Future", 1, true)).toNotBeNil()
    end)

    it("should enable global shadows", function()
        expect(string.find(moduleSource, "Lighting.GlobalShadows = true", 1, true)).toNotBeNil()
    end)

    it("should configure fog properties in presets", function()
        expect(string.find(moduleSource, "fogColor", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "fogStart", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "fogEnd", 1, true)).toNotBeNil()
    end)

    it("should use Quad easing for smooth transitions", function()
        expect(string.find(moduleSource, "Enum.EasingStyle.Quad", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Enum.EasingDirection.InOut", 1, true)).toNotBeNil()
    end)

    it("should cancel existing tween before new transition", function()
        expect(string.find(moduleSource, "_currentTween:Cancel()", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return AtmosphereManager")
    end)
end)
