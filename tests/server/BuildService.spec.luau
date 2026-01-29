--!strict
--[[
    Tests for BuildService module
    Verifies server-side structure placement handling
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/BuildService.luau")

describe("BuildService", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define BuildService table
        expect(string.find(moduleSource, "local BuildService = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "BuildService.__index = BuildService", 1, true)).toNotBeNil()

        -- Should return BuildService
        expect(string.find(moduleSource, "return BuildService", 1, true)).toNotBeNil()
    end)

    it("should require BuildConfig from shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("BuildConfig"))', 1, true)).toNotBeNil()
    end)

    it("should require TerrainUtils from shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("TerrainUtils"))', 1, true)).toNotBeNil()
    end)

    it("should export PlacedStructure type", function()
        expect(string.find(moduleSource, "export type PlacedStructure", 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function BuildService.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function BuildService:start()", 1, true)).toNotBeNil()
    end)

    it("should have setCurrencyService method", function()
        expect(string.find(moduleSource, "function BuildService:setCurrencyService(", 1, true)).toNotBeNil()
    end)

    it("should have getPlayerStructures method", function()
        expect(string.find(moduleSource, "function BuildService:getPlayerStructures(", 1, true)).toNotBeNil()
    end)

    it("should have getStructureCount method", function()
        expect(string.find(moduleSource, "function BuildService:getStructureCount()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function BuildService:destroy()", 1, true)).toNotBeNil()
    end)

    it("should create RemoteFunction for place requests", function()
        expect(string.find(moduleSource, "RemoteFunction", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PLACE_STRUCTURE", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "OnServerInvoke", 1, true)).toNotBeNil()
    end)

    it("should create RemoteEvent for placement results", function()
        expect(string.find(moduleSource, "RemoteEvent", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PLACEMENT_RESULT", 1, true)).toNotBeNil()
    end)

    it("should create folder for player structures", function()
        expect(string.find(moduleSource, "PlayerStructures", 1, true)).toNotBeNil()
    end)

    it("should handle place request with validation", function()
        expect(string.find(moduleSource, "_handlePlaceRequest", 1, true)).toNotBeNil()
    end)

    it("should validate input types in place request", function()
        expect(string.find(moduleSource, 'typeof(structureId) ~= "string"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'typeof(position) ~= "Vector3"', 1, true)).toNotBeNil()
    end)

    it("should validate placement position server-side", function()
        expect(string.find(moduleSource, "_validatePlacement", 1, true)).toNotBeNil()
    end)

    it("should check terrain slope", function()
        expect(string.find(moduleSource, "isFlatEnoughDegrees", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Terrain too steep", 1, true)).toNotBeNil()
    end)

    it("should check water level", function()
        expect(string.find(moduleSource, "WATER_LEVEL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Cannot build in water", 1, true)).toNotBeNil()
    end)

    it("should check map bounds", function()
        expect(string.find(moduleSource, "Position out of bounds", 1, true)).toNotBeNil()
    end)

    it("should check if player can afford structure", function()
        expect(string.find(moduleSource, "canAfford", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Insufficient Denarii", 1, true)).toNotBeNil()
    end)

    it("should deduct cost from currency service", function()
        expect(string.find(moduleSource, "spendCurrency", 1, true)).toNotBeNil()
    end)

    it("should refund if structure creation fails", function()
        expect(string.find(moduleSource, "addCurrency", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "refund_placement_failed", 1, true)).toNotBeNil()
    end)

    it("should create structure model", function()
        expect(string.find(moduleSource, "_createStructure", 1, true)).toNotBeNil()
    end)

    it("should create anchored parts", function()
        expect(string.find(moduleSource, "Anchored = true", 1, true)).toNotBeNil()
    end)

    it("should query terrain height for structure placement", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
    end)

    it("should add name tag billboard GUI", function()
        expect(string.find(moduleSource, "BillboardGui", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "NameTag", 1, true)).toNotBeNil()
    end)

    it("should track structure owner", function()
        expect(string.find(moduleSource, "owner", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "UserId", 1, true)).toNotBeNil()
    end)

    it("should track placed timestamp", function()
        expect(string.find(moduleSource, "placedAt", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "os.time()", 1, true)).toNotBeNil()
    end)

    it("should generate unique structure IDs", function()
        expect(string.find(moduleSource, "_structureCounter", 1, true)).toNotBeNil()
    end)

    it("should have structure colors based on type", function()
        expect(string.find(moduleSource, "_getStructureColor", 1, true)).toNotBeNil()
    end)

    it("should require StructureModels module", function()
        expect(string.find(moduleSource, "require(script.Parent.StructureModels)", 1, true)).toNotBeNil()
    end)

    it("should use StructureModels.getBuilder for structure creation", function()
        expect(string.find(moduleSource, "StructureModels.getBuilder", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return BuildService")
    end)
end)
