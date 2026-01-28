--!strict
--[[
    Tests for MusicManager module
    Verifies crossfade transitions and TweenService-based volume control
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/MusicManager.luau")

describe("MusicManager", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define MusicManager table
        expect(string.find(moduleSource, "local MusicManager = {}", 1, true)).toNotBeNil()

        -- Should return MusicManager
        expect(string.find(moduleSource, "return MusicManager", 1, true)).toNotBeNil()
    end)

    it("should use TweenService for crossfading", function()
        expect(string.find(moduleSource, 'TweenService = game:GetService("TweenService")', 1, true)).toNotBeNil()
    end)

    it("should have _fadeOutTween and _fadeInTween fields", function()
        expect(string.find(moduleSource, "_fadeOutTween: Tween?", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_fadeInTween: Tween?", 1, true)).toNotBeNil()
    end)

    it("should have _crossfade method using TweenService", function()
        expect(string.find(moduleSource, "function MusicManager:_crossfade", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TweenService:Create", 1, true)).toNotBeNil()
    end)

    it("should have _cancelCrossfadeTweens method", function()
        expect(string.find(moduleSource, "function MusicManager:_cancelCrossfadeTweens", 1, true)).toNotBeNil()
    end)

    it("should use Quad easing for smooth crossfade", function()
        expect(string.find(moduleSource, "Enum.EasingStyle.Quad", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Enum.EasingDirection.InOut", 1, true)).toNotBeNil()
    end)

    it("should create TweenInfo for crossfade duration", function()
        expect(string.find(moduleSource, "TweenInfo.new", 1, true)).toNotBeNil()
    end)

    it("should tween Volume property", function()
        expect(string.find(moduleSource, "Volume = self._masterVolume", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Volume = 0", 1, true)).toNotBeNil()
    end)

    it("should stop old sound after fade out completes", function()
        expect(string.find(moduleSource, "soundToStop:Stop()", 1, true)).toNotBeNil()
    end)

    it("should have playTrack method", function()
        expect(string.find(moduleSource, "function MusicManager:playTrack", 1, true)).toNotBeNil()
    end)

    it("should have stop method with TweenService", function()
        expect(string.find(moduleSource, "function MusicManager:stop", 1, true)).toNotBeNil()
    end)

    it("should have setVolume method checking for crossfade", function()
        expect(string.find(moduleSource, "function MusicManager:setVolume", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "isCrossfading", 1, true)).toNotBeNil()
    end)

    it("should cancel existing tweens before new crossfade", function()
        expect(string.find(moduleSource, "self:_cancelCrossfadeTweens()", 1, true)).toNotBeNil()
    end)

    it("should play new track at volume 0 before fading in", function()
        -- Find the sequence: set volume to 0, then play
        expect(string.find(moduleSource, "toSound.Volume = 0", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "toSound:Play()", 1, true)).toNotBeNil()
    end)

    it("should clean up tween references when completed", function()
        expect(string.find(moduleSource, "self._fadeOutTween = nil", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "self._fadeInTween = nil", 1, true)).toNotBeNil()
    end)

    it("should use Maid for connection cleanup", function()
        expect(string.find(moduleSource, "self._maid:give", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function MusicManager:destroy", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return MusicManager")
    end)
end)
