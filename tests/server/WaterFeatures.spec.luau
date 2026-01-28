--!strict
--[[
    Tests for WaterFeatures module
    Tests module structure, VERSION constant, and water feature creation
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/WaterFeatures.luau")

describe("WaterFeatures", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define WaterFeatures table
        expect(string.find(moduleSource, "local WaterFeatures = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "WaterFeatures.__index = WaterFeatures", 1, true)).toNotBeNil()

        -- Should return WaterFeatures
        expect(string.find(moduleSource, "return WaterFeatures", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function WaterFeatures.new", 1, true)).toNotBeNil()
    end)

    it("should have start() method", function()
        expect(string.find(moduleSource, "function WaterFeatures:start", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method for cleanup", function()
        expect(string.find(moduleSource, "function WaterFeatures:destroy", 1, true)).toNotBeNil()
    end)

    it("should have _createFountain() private method", function()
        expect(string.find(moduleSource, "function WaterFeatures:_createFountain", 1, true)).toNotBeNil()
    end)

    it("should have _createRiver() private method", function()
        expect(string.find(moduleSource, "function WaterFeatures:_createRiver", 1, true)).toNotBeNil()
    end)

    it("should require WaterPool module", function()
        expect(string.find(moduleSource, "require(script.Parent.WaterPool)", 1, true)).toNotBeNil()
    end)

    it("should use marble material for fountain", function()
        expect(string.find(moduleSource, "Enum.Material.Marble", 1, true)).toNotBeNil()
    end)

    it("should use rock material for river", function()
        expect(string.find(moduleSource, "Enum.Material.Rock", 1, true)).toNotBeNil()
    end)

    it("should create fountain with Roman name", function()
        expect(string.find(moduleSource, "RomanFountain_Impluvium", 1, true)).toNotBeNil()
    end)

    it("should create river segments", function()
        expect(string.find(moduleSource, "River_Segment_", 1, true)).toNotBeNil()
    end)

    it("should use marble white color", function()
        expect(string.find(moduleSource, "MARBLE_WHITE", 1, true)).toNotBeNil()
    end)

    it("should use rock gray color", function()
        expect(string.find(moduleSource, "ROCK_GRAY", 1, true)).toNotBeNil()
    end)

    it("should have configurable fountain position", function()
        expect(string.find(moduleSource, "fountainPosition", 1, true)).toNotBeNil()
    end)

    it("should have configurable river start position", function()
        expect(string.find(moduleSource, "riverStartPosition", 1, true)).toNotBeNil()
    end)

    it("should have enableFountain option", function()
        expect(string.find(moduleSource, "enableFountain", 1, true)).toNotBeNil()
    end)

    it("should have enableRiver option", function()
        expect(string.find(moduleSource, "enableRiver", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return WaterFeatures")
    end)
end)
