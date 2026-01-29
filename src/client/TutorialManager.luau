--!strict
--[[
    TutorialManager - First-time tutorial system
    Guides new players through their first Build -> Expand -> Manage cycle
    Target: Complete tutorial in first 60 seconds
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TutorialUI = require(script.Parent.TutorialUI)

local TutorialManager = {}
TutorialManager.__index = TutorialManager
TutorialManager.VERSION = "1.0.0"

-- Tutorial steps configuration
local TUTORIAL_STEPS = {
    {
        message = "Welcome to Ancient Rome!\n\nThis land is yours to build.",
        arrowPosition = UDim2.new(0.5, 0, 0.85, 0), -- Point to build button area
    },
    {
        message = "Tap the Build button to open the construction menu.",
        arrowPosition = UDim2.new(0.5, 0, 0.85, 0), -- Point to build button
    },
    {
        message = "Select a structure from the menu to begin placing it.",
        arrowPosition = nil, -- No arrow - player is in menu
    },
    {
        message = "Tap on the terrain to place your structure.",
        arrowPosition = UDim2.new(0.5, 0, 0.5, 0), -- Point to center of screen
    },
    {
        message = "Great job!\n\nBuild more structures to grow your Roman settlement!",
        arrowPosition = nil,
    },
}

-- Bonus coins awarded on tutorial completion
local COMPLETION_BONUS = 50

-- Tutorial state type
export type TutorialState = "INACTIVE" | "ACTIVE" | "COMPLETED"

function TutorialManager.new()
    local self = setmetatable({}, TutorialManager)

    self._player = Players.LocalPlayer
    self._state = "INACTIVE" :: TutorialState
    self._currentStep = 0

    -- UI component
    self._tutorialUI = nil :: typeof(TutorialUI.new())?

    -- Currency remote for giving bonus
    self._addCurrencyEvent = nil :: RemoteEvent?

    -- Flag for tracking if tutorial has been shown
    self._hasSeenTutorial = false

    print(string.format("[TutorialManager v%s] Initializing...", TutorialManager.VERSION))

    return self
end

function TutorialManager:start()
    -- Initialize UI
    self._tutorialUI = TutorialUI.new()
    self._tutorialUI:start()
    self._tutorialUI:setTotalSteps(#TUTORIAL_STEPS)

    -- Set up callbacks
    self._tutorialUI:setOnNext(function()
        self:advanceStep()
    end)

    self._tutorialUI:setOnSkip(function()
        self:skipTutorial()
    end)

    -- Wait for currency remote
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        self._addCurrencyEvent = remotesFolder:FindFirstChild("CurrencyAdd") :: RemoteEvent?
    end

    -- Check if player should see tutorial
    if self:shouldShowTutorial() then
        -- Slight delay before showing tutorial
        task.delay(1, function()
            self:startTutorial()
        end)
    end

    print(string.format("[TutorialManager v%s] Started", TutorialManager.VERSION))
end

--[[
    Check if the player should see the tutorial
    @return true if tutorial should be shown
]]
function TutorialManager:shouldShowTutorial(): boolean
    -- For v1.0.0, we use a simple flag
    -- Future versions could check DataStore for returning players
    return not self._hasSeenTutorial and self._state == "INACTIVE"
end

--[[
    Start the tutorial sequence
]]
function TutorialManager:startTutorial()
    if self._state ~= "INACTIVE" then
        return
    end

    self._state = "ACTIVE"
    self._currentStep = 0

    print("[TutorialManager] Starting tutorial")

    if self._tutorialUI then
        self._tutorialUI:show()
    end

    -- Advance to first step
    self:advanceStep()
end

--[[
    Advance to the next tutorial step
]]
function TutorialManager:advanceStep()
    if self._state ~= "ACTIVE" then
        return
    end

    self._currentStep += 1

    -- Check if tutorial is complete
    if self._currentStep > #TUTORIAL_STEPS then
        self:completeTutorial()
        return
    end

    local stepConfig = TUTORIAL_STEPS[self._currentStep]
    print(string.format("[TutorialManager] Step %d/%d", self._currentStep, #TUTORIAL_STEPS))

    if self._tutorialUI then
        self._tutorialUI:setStep(self._currentStep, {
            message = stepConfig.message,
            arrowPosition = stepConfig.arrowPosition,
        })
    end
end

--[[
    Complete the tutorial and give bonus
]]
function TutorialManager:completeTutorial()
    if self._state == "COMPLETED" then
        return
    end

    self._state = "COMPLETED"
    self._hasSeenTutorial = true

    print(string.format("[TutorialManager] Tutorial completed! Bonus: %d coins", COMPLETION_BONUS))

    -- Show completion message
    if self._tutorialUI then
        self._tutorialUI:showCompletion(COMPLETION_BONUS)

        -- Auto-hide after showing completion
        task.delay(3, function()
            if self._tutorialUI then
                self._tutorialUI:hide()
            end
        end)
    end

    -- Request bonus coins from server
    -- Note: In v1.0.0, we just log this - server validation would be added later
    if self._addCurrencyEvent then
        -- Server would validate this is a legitimate tutorial completion
        print(string.format("[TutorialManager] Requesting %d bonus coins", COMPLETION_BONUS))
    end
end

--[[
    Skip the tutorial
]]
function TutorialManager:skipTutorial()
    if self._state ~= "ACTIVE" then
        return
    end

    self._state = "COMPLETED"
    self._hasSeenTutorial = true

    print("[TutorialManager] Tutorial skipped")

    if self._tutorialUI then
        self._tutorialUI:hide()
    end
end

--[[
    Get the current tutorial state
    @return Current state
]]
function TutorialManager:getState(): TutorialState
    return self._state
end

--[[
    Get the current step number
    @return Current step (0 if inactive)
]]
function TutorialManager:getCurrentStep(): number
    return self._currentStep
end

--[[
    Check if tutorial is active
    @return true if tutorial is currently running
]]
function TutorialManager:isActive(): boolean
    return self._state == "ACTIVE"
end

--[[
    Check if tutorial has been completed
    @return true if tutorial was completed or skipped
]]
function TutorialManager:isCompleted(): boolean
    return self._state == "COMPLETED"
end

function TutorialManager:destroy()
    if self._tutorialUI then
        self._tutorialUI:destroy()
        self._tutorialUI = nil
    end

    print(string.format("[TutorialManager v%s] Destroyed", TutorialManager.VERSION))
end

return TutorialManager
