--!strict
--[[
    Tests for BuildUI module
    Verifies client-side building interface structure
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/BuildUI.luau")

describe("BuildUI", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define BuildUI table
        expect(string.find(moduleSource, "local BuildUI = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "BuildUI.__index = BuildUI", 1, true)).toNotBeNil()

        -- Should return BuildUI
        expect(string.find(moduleSource, "return BuildUI", 1, true)).toNotBeNil()
    end)

    it("should require BuildConfig from shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("BuildConfig"))', 1, true)).toNotBeNil()
    end)

    it("should require StructureMenu", function()
        expect(string.find(moduleSource, "require(script.Parent.StructureMenu)", 1, true)).toNotBeNil()
    end)

    it("should require PlacementPreview", function()
        expect(string.find(moduleSource, "require(script.Parent.PlacementPreview)", 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function BuildUI.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function BuildUI:start()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function BuildUI:destroy()", 1, true)).toNotBeNil()
    end)

    it("should export BuildState type", function()
        expect(string.find(moduleSource, "export type BuildState", 1, true)).toNotBeNil()
    end)

    it("should have state management (IDLE, MENU, PLACING)", function()
        expect(string.find(moduleSource, '"IDLE"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"MENU"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"PLACING"', 1, true)).toNotBeNil()
    end)

    it("should have getState method", function()
        expect(string.find(moduleSource, "function BuildUI:getState()", 1, true)).toNotBeNil()
    end)

    it("should have isPlacing method", function()
        expect(string.find(moduleSource, "function BuildUI:isPlacing()", 1, true)).toNotBeNil()
    end)

    it("should create ScreenGui for UI", function()
        expect(string.find(moduleSource, "ScreenGui", 1, true)).toNotBeNil()
    end)

    it("should create build button", function()
        expect(string.find(moduleSource, "_createBuildButton", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BuildButton", 1, true)).toNotBeNil()
    end)

    it("should create placement controls (Confirm/Cancel)", function()
        expect(string.find(moduleSource, "_createPlacementControls", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "ConfirmButton", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "CancelButton", 1, true)).toNotBeNil()
    end)

    it("should position build button at bottom-center (thumb-accessible)", function()
        expect(string.find(moduleSource, "BUILD_BUTTON_SIZE", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BUILD_BUTTON_OFFSET_Y", 1, true)).toNotBeNil()
    end)

    it("should have circular build button", function()
        -- UICorner with CornerRadius of 1 makes it circular
        expect(string.find(moduleSource, "UICorner", 1, true)).toNotBeNil()
    end)

    it("should connect to PlaceStructure remote", function()
        expect(string.find(moduleSource, "PLACE_STRUCTURE", 1, true)).toNotBeNil()
    end)

    it("should handle menu opening", function()
        expect(string.find(moduleSource, "_openMenu", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_closeMenu", 1, true)).toNotBeNil()
    end)

    it("should handle placement mode", function()
        expect(string.find(moduleSource, "_onPlaceRequested", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_onConfirmPlacement", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_onCancelPlacement", 1, true)).toNotBeNil()
    end)

    it("should use TweenService for animations", function()
        expect(string.find(moduleSource, "TweenService", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return BuildUI")
    end)
end)
