--!strict
--[[
    Tests for LanternManager module
    Verifies automatic lantern activation/deactivation based on ambient light
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/LanternManager.luau")

describe("LanternManager", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define LanternManager table
        expect(string.find(moduleSource, "local LanternManager = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "LanternManager.__index = LanternManager", 1, true)).toNotBeNil()

        -- Should return LanternManager
        expect(string.find(moduleSource, "return LanternManager", 1, true)).toNotBeNil()
    end)

    it("should use Players service", function()
        expect(string.find(moduleSource, 'Players = game:GetService("Players")', 1, true)).toNotBeNil()
    end)

    it("should use TweenService for smooth transitions", function()
        expect(string.find(moduleSource, 'TweenService = game:GetService("TweenService")', 1, true)).toNotBeNil()
    end)

    it("should use RunService for flicker effect", function()
        expect(string.find(moduleSource, 'RunService = game:GetService("RunService")', 1, true)).toNotBeNil()
    end)

    it("should use Maid for cleanup", function()
        expect(string.find(moduleSource, "Maid.new()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_maid:give", 1, true)).toNotBeNil()
    end)

    it("should have activation threshold constant", function()
        expect(string.find(moduleSource, "ACTIVATION_THRESHOLD = 0.3", 1, true)).toNotBeNil()
    end)

    it("should have deactivation threshold for hysteresis", function()
        expect(string.find(moduleSource, "DEACTIVATION_THRESHOLD = 0.4", 1, true)).toNotBeNil()
    end)

    it("should have fade duration constants", function()
        expect(string.find(moduleSource, "FADE_IN_DURATION", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "FADE_OUT_DURATION", 1, true)).toNotBeNil()
    end)

    it("should have warm oil lamp light color", function()
        -- Warm orange/amber color for Roman oil lamp
        expect(string.find(moduleSource, "LIGHT_COLOR = Color3.fromRGB(255, 200, 150)", 1, true)).toNotBeNil()
    end)

    it("should have light brightness and range constants", function()
        expect(string.find(moduleSource, "LIGHT_BRIGHTNESS = 1.5", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "LIGHT_RANGE = 25", 1, true)).toNotBeNil()
    end)

    it("should enable shadows on the light", function()
        expect(string.find(moduleSource, "LIGHT_SHADOWS = true", 1, true)).toNotBeNil()
    end)

    it("should have flicker configuration", function()
        expect(string.find(moduleSource, "FLICKER_MIN", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "FLICKER_MAX", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "FLICKER_SPEED", 1, true)).toNotBeNil()
    end)

    it("should have new constructor accepting AtmosphereManager", function()
        expect(string.find(moduleSource, "function LanternManager.new(atmosphereManager", 1, true)).toNotBeNil()
    end)

    it("should have activate method", function()
        expect(string.find(moduleSource, "function LanternManager:activate()", 1, true)).toNotBeNil()
    end)

    it("should have deactivate method", function()
        expect(string.find(moduleSource, "function LanternManager:deactivate()", 1, true)).toNotBeNil()
    end)

    it("should create PointLight instance", function()
        expect(string.find(moduleSource, 'Instance.new("PointLight")', 1, true)).toNotBeNil()
    end)

    it("should name the light RomanLantern", function()
        expect(string.find(moduleSource, '"RomanLantern"', 1, true)).toNotBeNil()
    end)

    it("should attach light to torso area", function()
        -- Check for attachment to UpperTorso, Torso, or HumanoidRootPart
        expect(string.find(moduleSource, '"UpperTorso"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"Torso"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"HumanoidRootPart"', 1, true)).toNotBeNil()
    end)

    it("should have _checkAmbientLevel method", function()
        expect(string.find(moduleSource, "function LanternManager:_checkAmbientLevel()", 1, true)).toNotBeNil()
    end)

    it("should call getCurrentAmbientLevel on AtmosphereManager", function()
        expect(string.find(moduleSource, "_atmosphereManager:getCurrentAmbientLevel()", 1, true)).toNotBeNil()
    end)

    it("should use hysteresis to prevent flicker", function()
        -- Activation uses lower threshold, deactivation uses higher threshold
        expect(string.find(moduleSource, "ambientLevel < ACTIVATION_THRESHOLD", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "ambientLevel > DEACTIVATION_THRESHOLD", 1, true)).toNotBeNil()
    end)

    it("should have flicker effect using noise function", function()
        expect(string.find(moduleSource, "math.noise", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_flickerTime", 1, true)).toNotBeNil()
    end)

    it("should have setFlickerEnabled method", function()
        expect(string.find(moduleSource, "function LanternManager:setFlickerEnabled", 1, true)).toNotBeNil()
    end)

    it("should have isActive method", function()
        expect(string.find(moduleSource, "function LanternManager:isActive()", 1, true)).toNotBeNil()
    end)

    it("should have isFlickerEnabled method", function()
        expect(string.find(moduleSource, "function LanternManager:isFlickerEnabled()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function LanternManager:start()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function LanternManager:destroy()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_maid:destroy()", 1, true)).toNotBeNil()
    end)

    it("should handle character added events", function()
        expect(string.find(moduleSource, "CharacterAdded:Connect", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_onCharacterAdded", 1, true)).toNotBeNil()
    end)

    it("should use tweens for smooth fade in", function()
        expect(string.find(moduleSource, "TweenService:Create", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TweenInfo.new", 1, true)).toNotBeNil()
    end)

    it("should cancel existing tweens before new transitions", function()
        expect(string.find(moduleSource, "_currentTween:Cancel()", 1, true)).toNotBeNil()
    end)

    it("should use RenderStepped for flicker animation", function()
        expect(string.find(moduleSource, "RenderStepped:Connect", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return LanternManager")
    end)
end)
