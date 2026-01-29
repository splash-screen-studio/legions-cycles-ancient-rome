--!strict
--[[
    TutorialUI - Tutorial overlay UI component
    Displays tutorial steps with message box, arrow indicator, and navigation buttons
    Mobile-first design with large touch targets
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TutorialUI = {}
TutorialUI.__index = TutorialUI
TutorialUI.VERSION = "1.0.0"

-- UI Constants
local BACKDROP_TRANSPARENCY = 0.6
local MESSAGE_BOX_WIDTH = 300
local MESSAGE_BOX_HEIGHT = 150
local BUTTON_WIDTH = 100
local BUTTON_HEIGHT = 44
local ARROW_SIZE = 40
local _ANIMATION_TIME = 0.3

-- Colors
local COLORS = {
    BACKDROP = Color3.fromRGB(0, 0, 0),
    MESSAGE_BG = Color3.fromRGB(45, 35, 25),
    MESSAGE_BORDER = Color3.fromRGB(180, 160, 100),
    TEXT = Color3.fromRGB(255, 248, 240),
    BUTTON_PRIMARY = Color3.fromRGB(139, 90, 43),
    BUTTON_SKIP = Color3.fromRGB(100, 80, 60),
    ARROW = Color3.fromRGB(255, 215, 0),
}

-- Tutorial step configuration type
export type StepConfig = {
    message: string,
    arrowTarget: string?, -- Name of UI element to point to (optional)
    arrowPosition: UDim2?, -- Manual arrow position if no target
}

function TutorialUI.new()
    local self = setmetatable({}, TutorialUI)

    self._player = Players.LocalPlayer
    self._screenGui = nil :: ScreenGui?
    self._backdrop = nil :: Frame?
    self._messageBox = nil :: Frame?
    self._messageLabel = nil :: TextLabel?
    self._stepIndicator = nil :: TextLabel?
    self._nextButton = nil :: TextButton?
    self._skipButton = nil :: TextButton?
    self._arrow = nil :: TextLabel?

    self._currentStep = 0
    self._totalSteps = 5

    self._onNext = nil :: (() -> ())?
    self._onSkip = nil :: (() -> ())?

    self._connections = {} :: { RBXScriptConnection }

    print(string.format("[TutorialUI v%s] Initializing...", TutorialUI.VERSION))

    return self
end

function TutorialUI:start()
    self:_createUI()
    self:hide()
    print(string.format("[TutorialUI v%s] Started", TutorialUI.VERSION))
end

function TutorialUI:_createUI()
    local playerGui = self._player:WaitForChild("PlayerGui")

    -- Create ScreenGui
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "TutorialUI"
    self._screenGui.ResetOnSpawn = false
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.DisplayOrder = 100 -- On top of other UI
    self._screenGui.Parent = playerGui

    -- Create semi-transparent backdrop
    self:_createBackdrop()

    -- Create message box
    self:_createMessageBox()

    -- Create arrow indicator
    self:_createArrow()

    print("[TutorialUI] UI created")
end

function TutorialUI:_createBackdrop()
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Position = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3 = COLORS.BACKDROP
    backdrop.BackgroundTransparency = BACKDROP_TRANSPARENCY
    backdrop.BorderSizePixel = 0
    backdrop.Parent = self._screenGui

    self._backdrop = backdrop
end

function TutorialUI:_createMessageBox()
    -- Message box container
    local messageBox = Instance.new("Frame")
    messageBox.Name = "MessageBox"
    messageBox.Size = UDim2.new(0, MESSAGE_BOX_WIDTH, 0, MESSAGE_BOX_HEIGHT)
    messageBox.Position = UDim2.new(0.5, 0, 0.4, 0)
    messageBox.AnchorPoint = Vector2.new(0.5, 0.5)
    messageBox.BackgroundColor3 = COLORS.MESSAGE_BG
    messageBox.BorderSizePixel = 0
    messageBox.Parent = self._screenGui

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = messageBox

    -- Border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.MESSAGE_BORDER
    stroke.Thickness = 3
    stroke.Parent = messageBox

    -- Message text
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -20, 0, 60)
    messageLabel.Position = UDim2.new(0, 10, 0, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = ""
    messageLabel.TextColor3 = COLORS.TEXT
    messageLabel.TextSize = 18
    messageLabel.Font = Enum.Font.GothamMedium
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Center
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.Parent = messageBox

    self._messageLabel = messageLabel

    -- Step indicator (1/5, 2/5, etc.)
    local stepIndicator = Instance.new("TextLabel")
    stepIndicator.Name = "StepIndicator"
    stepIndicator.Size = UDim2.new(0, 60, 0, 20)
    stepIndicator.Position = UDim2.new(0.5, 0, 0, 75)
    stepIndicator.AnchorPoint = Vector2.new(0.5, 0)
    stepIndicator.BackgroundTransparency = 1
    stepIndicator.Text = "1/5"
    stepIndicator.TextColor3 = COLORS.MESSAGE_BORDER
    stepIndicator.TextSize = 14
    stepIndicator.Font = Enum.Font.GothamBold
    stepIndicator.Parent = messageBox

    self._stepIndicator = stepIndicator

    -- Button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -20, 0, BUTTON_HEIGHT)
    buttonContainer.Position = UDim2.new(0, 10, 1, -BUTTON_HEIGHT - 10)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = messageBox

    -- Layout for buttons
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 20)
    layout.Parent = buttonContainer

    -- Skip button
    local skipButton = Instance.new("TextButton")
    skipButton.Name = "SkipButton"
    skipButton.Size = UDim2.new(0, BUTTON_WIDTH, 0, BUTTON_HEIGHT)
    skipButton.BackgroundColor3 = COLORS.BUTTON_SKIP
    skipButton.BorderSizePixel = 0
    skipButton.Text = "Skip"
    skipButton.TextColor3 = COLORS.TEXT
    skipButton.TextSize = 16
    skipButton.Font = Enum.Font.GothamBold
    skipButton.LayoutOrder = 1
    skipButton.Parent = buttonContainer

    local skipCorner = Instance.new("UICorner")
    skipCorner.CornerRadius = UDim.new(0, 8)
    skipCorner.Parent = skipButton

    local skipConnection = skipButton.Activated:Connect(function()
        if self._onSkip then
            self._onSkip()
        end
    end)
    table.insert(self._connections, skipConnection)

    self._skipButton = skipButton

    -- Next button
    local nextButton = Instance.new("TextButton")
    nextButton.Name = "NextButton"
    nextButton.Size = UDim2.new(0, BUTTON_WIDTH, 0, BUTTON_HEIGHT)
    nextButton.BackgroundColor3 = COLORS.BUTTON_PRIMARY
    nextButton.BorderSizePixel = 0
    nextButton.Text = "Next"
    nextButton.TextColor3 = COLORS.TEXT
    nextButton.TextSize = 16
    nextButton.Font = Enum.Font.GothamBold
    nextButton.LayoutOrder = 2
    nextButton.Parent = buttonContainer

    local nextCorner = Instance.new("UICorner")
    nextCorner.CornerRadius = UDim.new(0, 8)
    nextCorner.Parent = nextButton

    local nextConnection = nextButton.Activated:Connect(function()
        if self._onNext then
            self._onNext()
        end
    end)
    table.insert(self._connections, nextConnection)

    self._nextButton = nextButton
    self._messageBox = messageBox
end

function TutorialUI:_createArrow()
    -- Arrow pointing indicator (using text as placeholder for image)
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, ARROW_SIZE, 0, ARROW_SIZE)
    arrow.Position = UDim2.new(0.5, 0, 0.7, 0)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v" -- Downward arrow symbol
    arrow.TextColor3 = COLORS.ARROW
    arrow.TextSize = 36
    arrow.Font = Enum.Font.GothamBold
    arrow.Visible = false
    arrow.Parent = self._screenGui

    self._arrow = arrow
end

--[[
    Show the tutorial UI
]]
function TutorialUI:show()
    if self._screenGui then
        self._screenGui.Enabled = true
    end
end

--[[
    Hide the tutorial UI
]]
function TutorialUI:hide()
    if self._screenGui then
        self._screenGui.Enabled = false
    end
end

--[[
    Update the displayed step
    @param step Current step number (1-based)
    @param config Step configuration with message and arrow info
]]
function TutorialUI:setStep(step: number, config: StepConfig)
    self._currentStep = step

    -- Update message
    if self._messageLabel then
        self._messageLabel.Text = config.message
    end

    -- Update step indicator
    if self._stepIndicator then
        self._stepIndicator.Text = string.format("%d/%d", step, self._totalSteps)
    end

    -- Update button text on last step
    if self._nextButton then
        if step >= self._totalSteps then
            self._nextButton.Text = "Done"
        else
            self._nextButton.Text = "Next"
        end
    end

    -- Update arrow visibility and position
    if self._arrow then
        if config.arrowPosition then
            self._arrow.Position = config.arrowPosition
            self._arrow.Visible = true
            self:_animateArrow()
        else
            self._arrow.Visible = false
        end
    end
end

--[[
    Animate the arrow to pulse/bounce
]]
function TutorialUI:_animateArrow()
    if not self._arrow then
        return
    end

    -- Simple bounce animation
    local startPosition = self._arrow.Position
    local bounceOffset = UDim2.new(0, 0, 0, -10)

    local tweenInfo = TweenInfo.new(
        0.5,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1, -- Repeat forever
        true -- Reverse
    )

    local targetPosition = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + bounceOffset.X.Offset,
        startPosition.Y.Scale,
        startPosition.Y.Offset + bounceOffset.Y.Offset
    )

    local tween = TweenService:Create(self._arrow, tweenInfo, {
        Position = targetPosition,
    })
    tween:Play()
end

--[[
    Set total number of steps
    @param total Total steps in tutorial
]]
function TutorialUI:setTotalSteps(total: number)
    self._totalSteps = total
end

--[[
    Set callback for Next button
    @param callback Function to call when Next is pressed
]]
function TutorialUI:setOnNext(callback: () -> ())
    self._onNext = callback
end

--[[
    Set callback for Skip button
    @param callback Function to call when Skip is pressed
]]
function TutorialUI:setOnSkip(callback: () -> ())
    self._onSkip = callback
end

--[[
    Show completion message
    @param bonusCoins Number of bonus coins awarded
]]
function TutorialUI:showCompletion(bonusCoins: number)
    if self._messageLabel then
        self._messageLabel.Text = string.format(
            "Great job!\n\nYou earned +%d Denarii bonus!",
            bonusCoins
        )
    end

    if self._stepIndicator then
        self._stepIndicator.Text = "Complete!"
    end

    if self._arrow then
        self._arrow.Visible = false
    end

    if self._skipButton then
        self._skipButton.Visible = false
    end

    if self._nextButton then
        self._nextButton.Text = "Start"
    end
end

function TutorialUI:destroy()
    -- Disconnect all connections
    for _, connection in self._connections do
        connection:Disconnect()
    end
    self._connections = {}

    -- Destroy UI
    if self._screenGui then
        self._screenGui:Destroy()
        self._screenGui = nil
    end

    print(string.format("[TutorialUI v%s] Destroyed", TutorialUI.VERSION))
end

return TutorialUI
