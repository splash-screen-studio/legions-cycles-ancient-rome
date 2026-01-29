--!strict
--[[
    Tests for TutorialManager module
    Verifies first-time tutorial system structure
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/TutorialManager.luau")

describe("TutorialManager", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define TutorialManager table
        expect(string.find(moduleSource, "local TutorialManager = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "TutorialManager.__index = TutorialManager", 1, true)).toNotBeNil()

        -- Should return TutorialManager
        expect(string.find(moduleSource, "return TutorialManager", 1, true)).toNotBeNil()
    end)

    it("should require TutorialUI", function()
        expect(string.find(moduleSource, "require(script.Parent.TutorialUI)", 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function TutorialManager.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function TutorialManager:start()", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function TutorialManager:destroy()", 1, true)).toNotBeNil()
    end)

    it("should export TutorialState type", function()
        expect(string.find(moduleSource, "export type TutorialState", 1, true)).toNotBeNil()
    end)

    it("should have shouldShowTutorial method", function()
        expect(string.find(moduleSource, "function TutorialManager:shouldShowTutorial", 1, true)).toNotBeNil()
    end)

    it("should have startTutorial method", function()
        expect(string.find(moduleSource, "function TutorialManager:startTutorial()", 1, true)).toNotBeNil()
    end)

    it("should have advanceStep method", function()
        expect(string.find(moduleSource, "function TutorialManager:advanceStep()", 1, true)).toNotBeNil()
    end)

    it("should have completeTutorial method", function()
        expect(string.find(moduleSource, "function TutorialManager:completeTutorial()", 1, true)).toNotBeNil()
    end)

    it("should have skipTutorial method", function()
        expect(string.find(moduleSource, "function TutorialManager:skipTutorial()", 1, true)).toNotBeNil()
    end)

    it("should have getState method", function()
        expect(string.find(moduleSource, "function TutorialManager:getState", 1, true)).toNotBeNil()
    end)

    it("should have getCurrentStep method", function()
        expect(string.find(moduleSource, "function TutorialManager:getCurrentStep", 1, true)).toNotBeNil()
    end)

    it("should have isActive method", function()
        expect(string.find(moduleSource, "function TutorialManager:isActive", 1, true)).toNotBeNil()
    end)

    it("should have isCompleted method", function()
        expect(string.find(moduleSource, "function TutorialManager:isCompleted", 1, true)).toNotBeNil()
    end)

    it("should have state management (INACTIVE, ACTIVE, COMPLETED)", function()
        expect(string.find(moduleSource, '"INACTIVE"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"ACTIVE"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, '"COMPLETED"', 1, true)).toNotBeNil()
    end)

    it("should define tutorial steps", function()
        expect(string.find(moduleSource, "TUTORIAL_STEPS", 1, true)).toNotBeNil()
    end)

    it("should have 5 tutorial steps", function()
        -- Check that TUTORIAL_STEPS has entries (5 steps defined in the array)
        -- We verify by checking for step-specific content
        expect(string.find(moduleSource, "arrowPosition = UDim2", 1, true)).toNotBeNil()
        -- Count step indicator boundaries (}, {) to approximate steps
        -- Instead, just verify the key step messages exist
        expect(string.find(moduleSource, "Welcome to Ancient Rome", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Build button", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "construction menu", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "place your structure", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "Great job", 1, true)).toNotBeNil()
    end)

    it("should define completion bonus", function()
        expect(string.find(moduleSource, "COMPLETION_BONUS", 1, true)).toNotBeNil()
    end)

    it("should give 50 coin bonus on completion", function()
        expect(string.find(moduleSource, "COMPLETION_BONUS = 50", 1, true)).toNotBeNil()
    end)

    it("should track current step", function()
        expect(string.find(moduleSource, "_currentStep", 1, true)).toNotBeNil()
    end)

    it("should have welcome message in step 1", function()
        expect(string.find(moduleSource, "Welcome to Ancient Rome", 1, true)).toNotBeNil()
    end)

    it("should mention Build button", function()
        expect(string.find(moduleSource, "Build button", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return TutorialManager")
    end)
end)
