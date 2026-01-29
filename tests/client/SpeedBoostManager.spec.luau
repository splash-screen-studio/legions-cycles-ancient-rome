--!strict
--[[
    Tests for SpeedBoostManager module
    Verifies road speed boost functionality for player movement
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/SpeedBoostManager.luau")

describe("SpeedBoostManager", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define SpeedBoostManager table
        expect(string.find(moduleSource, "local SpeedBoostManager = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "SpeedBoostManager.__index = SpeedBoostManager", 1, true)).toNotBeNil()

        -- Should return SpeedBoostManager
        expect(string.find(moduleSource, "return SpeedBoostManager", 1, true)).toNotBeNil()
    end)

    it("should use Players service", function()
        expect(string.find(moduleSource, 'Players = game:GetService("Players")', 1, true)).toNotBeNil()
    end)

    it("should use RunService for position checks", function()
        expect(string.find(moduleSource, 'RunService = game:GetService("RunService")', 1, true)).toNotBeNil()
    end)

    it("should use TweenService for smooth speed transitions", function()
        expect(string.find(moduleSource, 'TweenService = game:GetService("TweenService")', 1, true)).toNotBeNil()
    end)

    it("should use Maid for cleanup", function()
        expect(string.find(moduleSource, "Maid.new()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_maid:give", 1, true)).toNotBeNil()
    end)

    it("should have default walk speed constant", function()
        expect(string.find(moduleSource, "DEFAULT_WALK_SPEED = 16", 1, true)).toNotBeNil()
    end)

    it("should have road walk speed constant (boosted)", function()
        expect(string.find(moduleSource, "ROAD_WALK_SPEED = 22", 1, true)).toNotBeNil()
    end)

    it("should have position check interval constant", function()
        expect(string.find(moduleSource, "POSITION_CHECK_INTERVAL", 1, true)).toNotBeNil()
    end)

    it("should have speed transition duration constant", function()
        expect(string.find(moduleSource, "SPEED_TRANSITION_DURATION", 1, true)).toNotBeNil()
    end)

    it("should have terrain check offset for checking below feet", function()
        expect(string.find(moduleSource, "TERRAIN_CHECK_OFFSET", 1, true)).toNotBeNil()
    end)

    it("should have terrain check region size", function()
        expect(string.find(moduleSource, "TERRAIN_CHECK_REGION_SIZE", 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function SpeedBoostManager.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function SpeedBoostManager:start()", 1, true)).toNotBeNil()
    end)

    it("should handle character added events", function()
        expect(string.find(moduleSource, "CharacterAdded:Connect", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_onCharacterAdded", 1, true)).toNotBeNil()
    end)

    it("should use Heartbeat for position monitoring", function()
        expect(string.find(moduleSource, "Heartbeat:Connect", 1, true)).toNotBeNil()
    end)

    it("should have _onHeartbeat method with throttling", function()
        expect(string.find(moduleSource, "function SpeedBoostManager:_onHeartbeat", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_timeSinceLastCheck", 1, true)).toNotBeNil()
    end)

    it("should check terrain material for road detection", function()
        expect(string.find(moduleSource, "_checkIfOnRoad", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "ReadVoxels", 1, true)).toNotBeNil()
    end)

    it("should detect Cobblestone as road material", function()
        expect(string.find(moduleSource, "Enum.Material.Cobblestone", 1, true)).toNotBeNil()
    end)

    it("should have _updateSpeed method with smooth transition", function()
        expect(string.find(moduleSource, "function SpeedBoostManager:_updateSpeed", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TweenService:Create", 1, true)).toNotBeNil()
    end)

    it("should tween WalkSpeed for smooth transition", function()
        expect(string.find(moduleSource, "WalkSpeed = targetSpeed", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TweenInfo.new", 1, true)).toNotBeNil()
    end)

    it("should cancel existing tween before creating new one", function()
        expect(string.find(moduleSource, "_currentTween:Cancel()", 1, true)).toNotBeNil()
    end)

    it("should have isOnRoad method", function()
        expect(string.find(moduleSource, "function SpeedBoostManager:isOnRoad()", 1, true)).toNotBeNil()
    end)

    it("should have getCurrentTargetSpeed method", function()
        expect(string.find(moduleSource, "function SpeedBoostManager:getCurrentTargetSpeed()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function SpeedBoostManager:destroy()", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_maid:destroy()", 1, true)).toNotBeNil()
    end)

    it("should reset humanoid speed on destroy", function()
        expect(string.find(moduleSource, "_humanoid.WalkSpeed = DEFAULT_WALK_SPEED", 1, true)).toNotBeNil()
    end)

    it("should track _isOnRoad state", function()
        expect(string.find(moduleSource, "_isOnRoad = false", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_isOnRoad = isOnRoad", 1, true)).toNotBeNil()
    end)

    it("should only update speed when road state changes", function()
        expect(string.find(moduleSource, "if isOnRoad ~= self._isOnRoad then", 1, true)).toNotBeNil()
    end)

    it("should use Region3 for terrain reading", function()
        expect(string.find(moduleSource, "Region3.new", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "ExpandToGrid", 1, true)).toNotBeNil()
    end)

    it("should use HumanoidRootPart for position", function()
        expect(string.find(moduleSource, '"HumanoidRootPart"', 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return SpeedBoostManager")
    end)
end)
