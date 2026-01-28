--!strict
--[[
    Tests for WaterPool module
    Tests module structure, VERSION constant, and critical water architecture
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/WaterPool.luau")

describe("WaterPool", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define WaterPool table
        expect(string.find(moduleSource, "local WaterPool = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "WaterPool.__index = WaterPool", 1, true)).toNotBeNil()

        -- Should return WaterPool
        expect(string.find(moduleSource, "return WaterPool", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function WaterPool.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function WaterPool:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method for cleanup", function()
        expect(string.find(moduleSource, "function WaterPool:destroy", 1, true)).toNotBeNil()
    end)

    it("should have _createWall() private method", function()
        expect(string.find(moduleSource, "function WaterPool:_createWall", 1, true)).toNotBeNil()
    end)

    it("should query terrain height using TerrainUtils", function()
        -- CRITICAL: Must use TerrainUtils.getHeightAt - NEVER hardcode Y
        expect(string.find(moduleSource, "getHeightAt", 1, true)).toNotBeNil()
    end)

    it("should create anchored parts", function()
        -- CRITICAL: All parts must be anchored
        expect(string.find(moduleSource, "Anchored = true", 1, true)).toNotBeNil()
    end)

    it("should use terrain FillRegion for water", function()
        -- Water should be filled inside part walls using terrain
        expect(string.find(moduleSource, "FillRegion", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Enum.Material.Water", 1, true)).toNotBeNil()
    end)

    it("should create bottom wall", function()
        expect(string.find(moduleSource, '"Bottom"', 1, true)).toNotBeNil()
    end)

    it("should create north wall", function()
        expect(string.find(moduleSource, '"NorthWall"', 1, true)).toNotBeNil()
    end)

    it("should create south wall", function()
        expect(string.find(moduleSource, '"SouthWall"', 1, true)).toNotBeNil()
    end)

    it("should create east wall", function()
        expect(string.find(moduleSource, '"EastWall"', 1, true)).toNotBeNil()
    end)

    it("should create west wall", function()
        expect(string.find(moduleSource, '"WestWall"', 1, true)).toNotBeNil()
    end)

    it("should use PoolConfig type with position", function()
        expect(string.find(moduleSource, "position: Vector3", 1, true)).toNotBeNil()
    end)

    it("should use PoolConfig type with size", function()
        expect(string.find(moduleSource, "size: Vector3", 1, true)).toNotBeNil()
    end)

    it("should use PoolConfig type with wallMaterial", function()
        expect(string.find(moduleSource, "wallMaterial: Enum.Material", 1, true)).toNotBeNil()
    end)

    it("should use PoolConfig type with wallColor", function()
        expect(string.find(moduleSource, "wallColor: Color3", 1, true)).toNotBeNil()
    end)

    it("should clear water on destroy", function()
        -- Should fill with Air to remove water when destroyed
        expect(string.find(moduleSource, "Enum.Material.Air", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return WaterPool")
    end)
end)
