--!strict
--[[
    Tests for PlacementPreview module
    Verifies placement preview structure and behavior
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/PlacementPreview.luau")

describe("PlacementPreview", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define PlacementPreview table
        expect(string.find(moduleSource, "local PlacementPreview = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "PlacementPreview.__index = PlacementPreview", 1, true)).toNotBeNil()

        -- Should return PlacementPreview
        expect(string.find(moduleSource, "return PlacementPreview", 1, true)).toNotBeNil()
    end)

    it("should require BuildConfig from shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("BuildConfig"))', 1, true)).toNotBeNil()
    end)

    it("should require TerrainUtils from shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("TerrainUtils"))', 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function PlacementPreview.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function PlacementPreview:start()", 1, true)).toNotBeNil()
    end)

    it("should have enterPlacementMode method", function()
        expect(string.find(moduleSource, "function PlacementPreview:enterPlacementMode(", 1, true)).toNotBeNil()
    end)

    it("should have exitPlacementMode method", function()
        expect(string.find(moduleSource, "function PlacementPreview:exitPlacementMode()", 1, true)).toNotBeNil()
    end)

    it("should have confirmPlacement method", function()
        expect(string.find(moduleSource, "function PlacementPreview:confirmPlacement()", 1, true)).toNotBeNil()
    end)

    it("should have cancelPlacement method", function()
        expect(string.find(moduleSource, "function PlacementPreview:cancelPlacement()", 1, true)).toNotBeNil()
    end)

    it("should have isActive method", function()
        expect(string.find(moduleSource, "function PlacementPreview:isActive()", 1, true)).toNotBeNil()
    end)

    it("should have isValidPlacement method", function()
        expect(string.find(moduleSource, "function PlacementPreview:isValidPlacement()", 1, true)).toNotBeNil()
    end)

    it("should have getPosition method", function()
        expect(string.find(moduleSource, "function PlacementPreview:getPosition()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function PlacementPreview:destroy()", 1, true)).toNotBeNil()
    end)

    it("should create preview model", function()
        expect(string.find(moduleSource, "_createPreviewModel", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PlacementPreview", 1, true)).toNotBeNil()
    end)

    it("should use semi-transparent preview", function()
        expect(string.find(moduleSource, "PREVIEW_TRANSPARENCY", 1, true)).toNotBeNil()
    end)

    it("should create preview part with correct properties", function()
        expect(string.find(moduleSource, "Anchored = true", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "CanCollide = false", 1, true)).toNotBeNil()
    end)

    it("should add SelectionBox for visibility", function()
        expect(string.find(moduleSource, "SelectionBox", 1, true)).toNotBeNil()
    end)

    it("should update preview position on render", function()
        expect(string.find(moduleSource, "_updatePreviewPosition", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "RenderStepped", 1, true)).toNotBeNil()
    end)

    it("should get pointer position from touch or mouse", function()
        expect(string.find(moduleSource, "_getPointerPosition", 1, true)).toNotBeNil()
        -- GetMouseLocation works for both mouse and touch input
        expect(string.find(moduleSource, "GetMouseLocation", 1, true)).toNotBeNil()
    end)

    it("should raycast to terrain for position", function()
        expect(string.find(moduleSource, "_raycastToTerrain", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "ViewportPointToRay", 1, true)).toNotBeNil()
    end)

    it("should validate placement position", function()
        expect(string.find(moduleSource, "_validatePlacement", 1, true)).toNotBeNil()
    end)

    it("should check terrain slope using TerrainUtils", function()
        expect(string.find(moduleSource, "isFlatEnoughDegrees", 1, true)).toNotBeNil()
    end)

    it("should check water level", function()
        expect(string.find(moduleSource, "WATER_LEVEL", 1, true)).toNotBeNil()
    end)

    it("should use green color for valid placement", function()
        expect(string.find(moduleSource, "VALID", 1, true)).toNotBeNil()
    end)

    it("should use red color for invalid placement", function()
        expect(string.find(moduleSource, "INVALID", 1, true)).toNotBeNil()
    end)

    it("should query terrain height using TerrainUtils", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
    end)

    it("should clean up connections on destroy", function()
        expect(string.find(moduleSource, "_connections", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, ":Disconnect()", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return PlacementPreview")
    end)
end)
