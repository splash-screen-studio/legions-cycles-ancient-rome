--!strict
--[[
    Tests for StructureMenu module
    Verifies structure selection menu structure
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/StructureMenu.luau")

describe("StructureMenu", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define StructureMenu table
        expect(string.find(moduleSource, "local StructureMenu = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "StructureMenu.__index = StructureMenu", 1, true)).toNotBeNil()

        -- Should return StructureMenu
        expect(string.find(moduleSource, "return StructureMenu", 1, true)).toNotBeNil()
    end)

    it("should require BuildConfig from shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("BuildConfig"))', 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function StructureMenu.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function StructureMenu:start()", 1, true)).toNotBeNil()
    end)

    it("should have open method", function()
        expect(string.find(moduleSource, "function StructureMenu:open()", 1, true)).toNotBeNil()
    end)

    it("should have close method", function()
        expect(string.find(moduleSource, "function StructureMenu:close()", 1, true)).toNotBeNil()
    end)

    it("should have isOpen method", function()
        expect(string.find(moduleSource, "function StructureMenu:isOpen()", 1, true)).toNotBeNil()
    end)

    it("should have setOnPlaceRequested callback method", function()
        expect(string.find(moduleSource, "function StructureMenu:setOnPlaceRequested(", 1, true)).toNotBeNil()
    end)

    it("should have setOnClose callback method", function()
        expect(string.find(moduleSource, "function StructureMenu:setOnClose(", 1, true)).toNotBeNil()
    end)

    it("should have getSelectedStructure method", function()
        expect(string.find(moduleSource, "function StructureMenu:getSelectedStructure()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function StructureMenu:destroy()", 1, true)).toNotBeNil()
    end)

    it("should create ScreenGui for UI", function()
        expect(string.find(moduleSource, "ScreenGui", 1, true)).toNotBeNil()
    end)

    it("should create main menu frame", function()
        expect(string.find(moduleSource, "MenuFrame", 1, true)).toNotBeNil()
    end)

    it("should create structure grid", function()
        expect(string.find(moduleSource, "StructureGrid", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "UIGridLayout", 1, true)).toNotBeNil()
    end)

    it("should create preview area", function()
        expect(string.find(moduleSource, "PreviewArea", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PreviewName", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PreviewDesc", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "PreviewCost", 1, true)).toNotBeNil()
    end)

    it("should create place button", function()
        expect(string.find(moduleSource, "PlaceButton", 1, true)).toNotBeNil()
    end)

    it("should create close button", function()
        expect(string.find(moduleSource, "CloseButton", 1, true)).toNotBeNil()
    end)

    it("should create structure buttons", function()
        expect(string.find(moduleSource, "_createStructureButton", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_structureButtons", 1, true)).toNotBeNil()
    end)

    it("should have selection highlight for selected structure", function()
        expect(string.find(moduleSource, "Highlight", 1, true)).toNotBeNil()
    end)

    it("should display structure cost in preview", function()
        expect(string.find(moduleSource, "Denarii", 1, true)).toNotBeNil()
    end)

    it("should use TweenService for animations", function()
        expect(string.find(moduleSource, "TweenService", 1, true)).toNotBeNil()
    end)

    it("should have rounded corners for modern look", function()
        expect(string.find(moduleSource, "UICorner", 1, true)).toNotBeNil()
    end)

    it("should have category colors for structure types", function()
        expect(string.find(moduleSource, "_getCategoryColor", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return StructureMenu")
    end)
end)
