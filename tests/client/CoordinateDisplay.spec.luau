--!strict
--[[
    Tests for CoordinateDisplay module
    Verifies client-side coordinate UI structure for debugging
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/CoordinateDisplay.luau")

describe("CoordinateDisplay", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define CoordinateDisplay table
        expect(string.find(moduleSource, "local CoordinateDisplay = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "CoordinateDisplay.__index = CoordinateDisplay", 1, true)).toNotBeNil()

        -- Should return CoordinateDisplay
        expect(string.find(moduleSource, "return CoordinateDisplay", 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function CoordinateDisplay.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function CoordinateDisplay:start()", 1, true)).toNotBeNil()
    end)

    it("should have stop method", function()
        expect(string.find(moduleSource, "function CoordinateDisplay:stop()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function CoordinateDisplay:destroy()", 1, true)).toNotBeNil()
    end)

    it("should create ScreenGui for UI", function()
        expect(string.find(moduleSource, "ScreenGui", 1, true)).toNotBeNil()
    end)

    it("should create main frame for coordinate display", function()
        expect(string.find(moduleSource, "CoordinateFrame", 1, true)).toNotBeNil()
    end)

    it("should create X,Z label", function()
        expect(string.find(moduleSource, "XZLabel", 1, true)).toNotBeNil()
    end)

    it("should create Y label", function()
        expect(string.find(moduleSource, "YLabel", 1, true)).toNotBeNil()
    end)

    it("should display X, Z format", function()
        expect(string.find(moduleSource, 'X: %d  Z: %d', 1, true)).toNotBeNil()
    end)

    it("should display Y format", function()
        expect(string.find(moduleSource, 'Y: %d', 1, true)).toNotBeNil()
    end)

    it("should use RunService for updates", function()
        expect(string.find(moduleSource, "RunService", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Heartbeat", 1, true)).toNotBeNil()
    end)

    it("should track HumanoidRootPart position", function()
        expect(string.find(moduleSource, "HumanoidRootPart", 1, true)).toNotBeNil()
    end)

    it("should round coordinates to integers", function()
        expect(string.find(moduleSource, "math.floor", 1, true)).toNotBeNil()
    end)

    it("should use Roman gold/bronze color aesthetic", function()
        -- Check for bronze/gold color values matching CurrencyDisplay
        expect(string.find(moduleSource, "BACKGROUND_COLOR", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BORDER_COLOR", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TEXT_COLOR", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "bronze", 1, true)).toNotBeNil()
    end)

    it("should position UI in top-right corner (mobile-friendly)", function()
        expect(string.find(moduleSource, "FRAME_POSITION", 1, true)).toNotBeNil()
    end)

    it("should have rounded corners for modern look", function()
        expect(string.find(moduleSource, "UICorner", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return CoordinateDisplay")
    end)

    it("should connect to CharacterAdded event", function()
        expect(string.find(moduleSource, "CharacterAdded", 1, true)).toNotBeNil()
    end)
end)
