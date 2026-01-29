--!strict
--[[
    Tests for TutorialUI module
    Verifies tutorial overlay UI structure
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/TutorialUI.luau")

describe("TutorialUI", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define TutorialUI table
        expect(string.find(moduleSource, "local TutorialUI = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "TutorialUI.__index = TutorialUI", 1, true)).toNotBeNil()

        -- Should return TutorialUI
        expect(string.find(moduleSource, "return TutorialUI", 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function TutorialUI.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function TutorialUI:start()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function TutorialUI:destroy()", 1, true)).toNotBeNil()
    end)

    it("should export StepConfig type", function()
        expect(string.find(moduleSource, "export type StepConfig", 1, true)).toNotBeNil()
    end)

    it("should have show method", function()
        expect(string.find(moduleSource, "function TutorialUI:show()", 1, true)).toNotBeNil()
    end)

    it("should have hide method", function()
        expect(string.find(moduleSource, "function TutorialUI:hide()", 1, true)).toNotBeNil()
    end)

    it("should have setStep method", function()
        expect(string.find(moduleSource, "function TutorialUI:setStep", 1, true)).toNotBeNil()
    end)

    it("should have setOnNext callback setter", function()
        expect(string.find(moduleSource, "function TutorialUI:setOnNext", 1, true)).toNotBeNil()
    end)

    it("should have setOnSkip callback setter", function()
        expect(string.find(moduleSource, "function TutorialUI:setOnSkip", 1, true)).toNotBeNil()
    end)

    it("should have setTotalSteps method", function()
        expect(string.find(moduleSource, "function TutorialUI:setTotalSteps", 1, true)).toNotBeNil()
    end)

    it("should have showCompletion method", function()
        expect(string.find(moduleSource, "function TutorialUI:showCompletion", 1, true)).toNotBeNil()
    end)

    it("should create ScreenGui for UI", function()
        expect(string.find(moduleSource, "ScreenGui", 1, true)).toNotBeNil()
    end)

    it("should create semi-transparent backdrop", function()
        expect(string.find(moduleSource, "Backdrop", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BackgroundTransparency", 1, true)).toNotBeNil()
    end)

    it("should create message box", function()
        expect(string.find(moduleSource, "MessageBox", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "MessageLabel", 1, true)).toNotBeNil()
    end)

    it("should create step indicator", function()
        expect(string.find(moduleSource, "StepIndicator", 1, true)).toNotBeNil()
    end)

    it("should create Next button", function()
        expect(string.find(moduleSource, "NextButton", 1, true)).toNotBeNil()
    end)

    it("should create Skip button", function()
        expect(string.find(moduleSource, "SkipButton", 1, true)).toNotBeNil()
    end)

    it("should create arrow indicator", function()
        expect(string.find(moduleSource, "Arrow", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "_createArrow", 1, true)).toNotBeNil()
    end)

    it("should animate arrow", function()
        expect(string.find(moduleSource, "_animateArrow", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return TutorialUI")
    end)
end)
