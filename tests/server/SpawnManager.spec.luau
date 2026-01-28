--!strict
--[[
    Tests for SpawnManager module
    Tests module structure, VERSION constant, and configuration
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/SpawnManager.luau")

describe("SpawnManager", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define SpawnManager table
        expect(string.find(moduleSource, "local SpawnManager = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "SpawnManager.__index = SpawnManager", 1, true)).toNotBeNil()

        -- Should return SpawnManager
        expect(string.find(moduleSource, "return SpawnManager", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function SpawnManager.new", 1, true)).toNotBeNil()
    end)

    it("should have start() method", function()
        expect(string.find(moduleSource, "function SpawnManager:start", 1, true)).toNotBeNil()
    end)

    it("should have getSpawnCFrame() method", function()
        expect(string.find(moduleSource, "function SpawnManager:getSpawnCFrame", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method for cleanup", function()
        expect(string.find(moduleSource, "function SpawnManager:destroy", 1, true)).toNotBeNil()
    end)

    it("should query terrain height using TerrainUtils", function()
        -- Must use TerrainUtils.getHeightAt - NEVER hardcode Y
        expect(string.find(moduleSource, "getHeightAt", 1, true)).toNotBeNil()
    end)

    it("should have _removeDefaults method", function()
        expect(string.find(moduleSource, "function SpawnManager:_removeDefaults", 1, true)).toNotBeNil()
    end)

    it("should remove Baseplate in _removeDefaults", function()
        expect(string.find(moduleSource, '"Baseplate"', 1, true)).toNotBeNil()
    end)

    it("should remove SpawnLocation in _removeDefaults", function()
        expect(string.find(moduleSource, '"SpawnLocation"', 1, true)).toNotBeNil()
    end)

    it("should have spawn configuration with position", function()
        expect(string.find(moduleSource, "position = Vector3.new", 1, true)).toNotBeNil()
    end)

    it("should have spawn configuration with facingDirection", function()
        expect(string.find(moduleSource, "facingDirection", 1, true)).toNotBeNil()
    end)

    it("should have spawn configuration with spawnRadius", function()
        expect(string.find(moduleSource, "spawnRadius", 1, true)).toNotBeNil()
    end)

    it("should use CFrame.lookAt for spawn orientation", function()
        expect(string.find(moduleSource, "CFrame.lookAt", 1, true)).toNotBeNil()
    end)

    it("should handle Players service", function()
        expect(string.find(moduleSource, 'Players = game:GetService("Players")', 1, true)).toNotBeNil()
    end)

    it("should connect to PlayerAdded event", function()
        expect(string.find(moduleSource, "Players.PlayerAdded:Connect", 1, true)).toNotBeNil()
    end)

    it("should connect to CharacterAdded event", function()
        expect(string.find(moduleSource, "CharacterAdded:Connect", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return SpawnManager")
    end)
end)
