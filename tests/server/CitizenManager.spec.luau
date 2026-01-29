--!strict
--[[
    Tests for CitizenManager module
    Tests module structure, VERSION constant, and citizen spawning methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/CitizenManager.luau")

describe("CitizenManager", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define CitizenManager table
        expect(string.find(moduleSource, "local CitizenManager = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "CitizenManager.__index = CitizenManager", 1, true)).toNotBeNil()

        -- Should return CitizenManager
        expect(string.find(moduleSource, "return CitizenManager", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function CitizenManager.new", 1, true)).toNotBeNil()
    end)

    it("should have start() method", function()
        expect(string.find(moduleSource, "function CitizenManager:start()", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function CitizenManager:destroy()", 1, true)).toNotBeNil()
    end)

    it("should have getCitizenCount() method", function()
        expect(string.find(moduleSource, "function CitizenManager:getCitizenCount()", 1, true)).toNotBeNil()
    end)

    it("should have getCitizens() method", function()
        expect(string.find(moduleSource, "function CitizenManager:getCitizens()", 1, true)).toNotBeNil()
    end)

    -- Private methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function CitizenManager:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _createCitizenModel() method", function()
        expect(string.find(moduleSource, "function CitizenManager:_createCitizenModel", 1, true)).toNotBeNil()
    end)

    it("should have _getSpawnPosition() method", function()
        expect(string.find(moduleSource, "function CitizenManager:_getSpawnPosition", 1, true)).toNotBeNil()
    end)

    it("should have _spawnCitizensAtLandmark() method", function()
        expect(string.find(moduleSource, "function CitizenManager:_spawnCitizensAtLandmark", 1, true)).toNotBeNil()
    end)

    -- Required modules
    it("should require TerrainUtils module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("TerrainUtils"))', 1, true)).toNotBeNil()
    end)

    it("should require WorldPlan module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("WorldPlan"))', 1, true)).toNotBeNil()
    end)

    -- Query terrain height (CRITICAL)
    it("should query terrain height using TerrainUtils", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
    end)

    -- River exclusion zone check
    it("should check river exclusion zone before spawning", function()
        expect(string.find(moduleSource, "isInRiverExclusionZone", 1, true)).toNotBeNil()
    end)

    -- Parts must be anchored
    it("should set Anchored = true on parts", function()
        expect(string.find(moduleSource, "Anchored = true", 1, true)).toNotBeNil()
    end)

    -- NPCs should not block player movement
    it("should set CanCollide = false on parts", function()
        expect(string.find(moduleSource, "CanCollide = false", 1, true)).toNotBeNil()
    end)

    -- Roman naming for folder
    it("should use Roman naming for citizens folder (Cives)", function()
        expect(string.find(moduleSource, "Citizens_Cives", 1, true)).toNotBeNil()
    end)

    -- Citizen body parts
    it("should create Head part for citizen", function()
        expect(string.find(moduleSource, '"Head"', 1, true)).toNotBeNil()
    end)

    it("should create Torso part for citizen", function()
        expect(string.find(moduleSource, '"Torso"', 1, true)).toNotBeNil()
    end)

    it("should create Legs part for citizen", function()
        expect(string.find(moduleSource, '"Legs"', 1, true)).toNotBeNil()
    end)

    it("should create Arms for citizen", function()
        expect(string.find(moduleSource, '"LeftArm"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"RightArm"', 1, true)).toNotBeNil()
    end)

    it("should create Hair part for citizen", function()
        expect(string.find(moduleSource, '"Hair"', 1, true)).toNotBeNil()
    end)

    -- Color variety
    it("should have TUNIC_COLORS for variety", function()
        expect(string.find(moduleSource, "local TUNIC_COLORS", 1, true)).toNotBeNil()
    end)

    it("should have SKIN_COLORS for variety", function()
        expect(string.find(moduleSource, "local SKIN_COLORS", 1, true)).toNotBeNil()
    end)

    it("should have HAIR_COLORS for variety", function()
        expect(string.find(moduleSource, "local HAIR_COLORS", 1, true)).toNotBeNil()
    end)

    -- Configuration constants
    it("should have CITIZENS_PER_LANDMARK constant", function()
        expect(string.find(moduleSource, "local CITIZENS_PER_LANDMARK", 1, true)).toNotBeNil()
    end)

    it("should have SPAWN_RADIUS constant", function()
        expect(string.find(moduleSource, "local SPAWN_RADIUS", 1, true)).toNotBeNil()
    end)

    it("should have maxCitizens configuration", function()
        expect(string.find(moduleSource, "maxCitizens", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export CitizenManagerConfig type", function()
        expect(string.find(moduleSource, "export type CitizenManagerConfig", 1, true)).toNotBeNil()
    end)

    it("should export CitizenManagerInstance type", function()
        expect(string.find(moduleSource, "export type CitizenManagerInstance", 1, true)).toNotBeNil()
    end)

    it("should export Citizen type", function()
        expect(string.find(moduleSource, "export type Citizen", 1, true)).toNotBeNil()
    end)

    -- Model creation
    it("should set PrimaryPart on citizen model", function()
        expect(string.find(moduleSource, "model.PrimaryPart", 1, true)).toNotBeNil()
    end)

    -- Random facing direction for variety
    it("should apply random facing direction", function()
        expect(string.find(moduleSource, "facingAngle", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PivotTo", 1, true)).toNotBeNil()
    end)

    -- Performance: yield during spawn
    it("should yield periodically during spawn to avoid timeout", function()
        expect(string.find(moduleSource, "task.wait()", 1, true)).toNotBeNil()
    end)

    it("should use strict mode", function()
        expect(string.find(moduleSource, "--!strict", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return CitizenManager")
    end)
end)
