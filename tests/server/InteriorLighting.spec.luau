--!strict
--[[
    Tests for InteriorLighting module
    Tests module structure, VERSION constant, and light creation methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/InteriorLighting.luau")

describe("InteriorLighting", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define InteriorLighting table
        expect(string.find(moduleSource, "local InteriorLighting = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "InteriorLighting.__index = InteriorLighting", 1, true)).toNotBeNil()

        -- Should return InteriorLighting
        expect(string.find(moduleSource, "return InteriorLighting", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function InteriorLighting.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:destroy", 1, true)).toNotBeNil()
    end)

    -- Light source creation methods
    it("should have _createTorch() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_createTorch", 1, true)).toNotBeNil()
    end)

    it("should have _createOilLamp() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_createOilLamp", 1, true)).toNotBeNil()
    end)

    it("should have _createBrazier() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_createBrazier", 1, true)).toNotBeNil()
    end)

    -- Helper methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _createPointLight() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_createPointLight", 1, true)).toNotBeNil()
    end)

    it("should have _createFireEffect() method for particles", function()
        expect(string.find(moduleSource, "function InteriorLighting:_createFireEffect", 1, true)).toNotBeNil()
    end)

    -- Flicker effect methods
    it("should have _startFlickerEffect() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_startFlickerEffect", 1, true)).toNotBeNil()
    end)

    it("should have _stopFlickerEffect() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_stopFlickerEffect", 1, true)).toNotBeNil()
    end)

    -- Landmark lighting method
    it("should have _lightLandmark() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_lightLandmark", 1, true)).toNotBeNil()
    end)

    it("should have _calculateLightPositions() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:_calculateLightPositions", 1, true)).toNotBeNil()
    end)

    -- Public query methods
    it("should have getLightCount() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:getLightCount", 1, true)).toNotBeNil()
    end)

    it("should have getParts() method", function()
        expect(string.find(moduleSource, "function InteriorLighting:getParts", 1, true)).toNotBeNil()
    end)

    -- Should require shared modules
    it("should require TerrainUtils module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("TerrainUtils"))', 1, true)).toNotBeNil()
    end)

    it("should require WorldPlan module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("WorldPlan"))', 1, true)).toNotBeNil()
    end)

    it("should require LightingConfig module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("LightingConfig"))', 1, true)).toNotBeNil()
    end)

    -- Critical: Parts must be anchored
    it("should set Anchored = true on parts", function()
        expect(string.find(moduleSource, "Anchored = true", 1, true)).toNotBeNil()
    end)

    -- Light properties
    it("should create PointLight instances", function()
        expect(string.find(moduleSource, 'Instance.new("PointLight")', 1, true)).toNotBeNil()
    end)

    it("should enable shadows on lights", function()
        expect(string.find(moduleSource, "Shadows = config.shadows", 1, true)).toNotBeNil()
    end)

    -- Fire particle effects
    it("should create ParticleEmitter for fire effects", function()
        expect(string.find(moduleSource, 'Instance.new("ParticleEmitter")', 1, true)).toNotBeNil()
    end)

    -- Roman naming for folder
    it("should use Roman naming for lighting folder (Lucernae)", function()
        expect(string.find(moduleSource, "InteriorLighting_Lucernae", 1, true)).toNotBeNil()
    end)

    -- Query terrain height
    it("should query terrain height using TerrainUtils", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
    end)

    -- River exclusion zone check
    it("should check river exclusion zone before adding lights", function()
        expect(string.find(moduleSource, "isInRiverExclusionZone", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export InteriorLightingConfig type", function()
        expect(string.find(moduleSource, "export type InteriorLightingConfig", 1, true)).toNotBeNil()
    end)

    it("should export InteriorLightingInstance type", function()
        expect(string.find(moduleSource, "export type InteriorLightingInstance", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return InteriorLighting")
    end)
end)
