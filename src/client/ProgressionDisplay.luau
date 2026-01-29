--!strict
--[[
    ProgressionDisplay - Client-side UI for showing player level, XP, and rank

    Displays:
    - Current level and Roman rank
    - XP progress bar to next level
    - Level up notifications with unlock announcements
    - Rank promotion celebrations

    MOBILE-FIRST: Uses large touch-friendly elements
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProgressionConfig = require(Shared:WaitForChild("ProgressionConfig"))

local ProgressionDisplay = {}
ProgressionDisplay.__index = ProgressionDisplay
ProgressionDisplay.VERSION = "1.0.0"

-- Type definitions
export type ProgressData = {
    xp: number,
    level: number,
    rank: ProgressionConfig.RankInfo,
}

export type LevelUpData = {
    oldLevel: number,
    newLevel: number,
    oldRank: ProgressionConfig.RankInfo,
    newRank: ProgressionConfig.RankInfo,
    rankChanged: boolean,
    newUnlocks: { ProgressionConfig.Unlock },
}

export type ProgressionDisplayInstance = {
    _player: Player,
    _screenGui: ScreenGui?,
    _progressFrame: Frame?,
    _levelLabel: TextLabel?,
    _rankLabel: TextLabel?,
    _xpBar: Frame?,
    _xpFill: Frame?,
    _xpLabel: TextLabel?,
    _notificationFrame: Frame?,
    _connections: { RBXScriptConnection },
    _currentProgress: ProgressData?,
}

-- UI Constants (mobile-first sizing)
local UI_PADDING = 10
local PROGRESS_FRAME_SIZE = UDim2.new(0, 200, 0, 80)
local PROGRESS_FRAME_POSITION = UDim2.new(0, UI_PADDING, 0, UI_PADDING)
local XP_BAR_HEIGHT = 16
local NOTIFICATION_SIZE = UDim2.new(0, 300, 0, 150)
local NOTIFICATION_POSITION = UDim2.new(0.5, -150, 0.3, 0)

function ProgressionDisplay.new(): ProgressionDisplayInstance
    print(string.format("[ProgressionDisplay v%s] Initializing...", ProgressionDisplay.VERSION))

    local self = setmetatable({}, ProgressionDisplay) :: ProgressionDisplayInstance
    self._player = Players.LocalPlayer
    self._connections = {}
    self._currentProgress = nil

    return self
end

function ProgressionDisplay:start()
    print(string.format("[ProgressionDisplay v%s] Starting...", ProgressionDisplay.VERSION))

    -- Create UI
    self:_createUI()

    -- Connect to server events
    self:_connectToServer()

    -- Request initial progress from server
    self:_requestProgress()

    print(string.format("[ProgressionDisplay v%s] Started successfully", ProgressionDisplay.VERSION))
end

function ProgressionDisplay:_createUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProgressionDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = self._player:WaitForChild("PlayerGui")
    self._screenGui = screenGui

    -- Create main progress frame (top-left corner)
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = PROGRESS_FRAME_SIZE
    progressFrame.Position = PROGRESS_FRAME_POSITION
    progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    progressFrame.BackgroundTransparency = 0.3
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = screenGui
    self._progressFrame = progressFrame

    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = progressFrame

    -- Level label (large, prominent)
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0.5, -UI_PADDING, 0, 30)
    levelLabel.Position = UDim2.new(0, UI_PADDING, 0, UI_PADDING)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.TextSize = 24
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Text = "Level 1"
    levelLabel.Parent = progressFrame
    self._levelLabel = levelLabel

    -- Rank label (Roman rank name)
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.Size = UDim2.new(0.5, -UI_PADDING, 0, 30)
    rankLabel.Position = UDim2.new(0.5, 0, 0, UI_PADDING)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Font = Enum.Font.GothamMedium
    rankLabel.TextSize = 18
    rankLabel.TextColor3 = Color3.fromRGB(194, 178, 128) -- Default citizen color
    rankLabel.TextXAlignment = Enum.TextXAlignment.Right
    rankLabel.Text = "Civis"
    rankLabel.Parent = progressFrame
    self._rankLabel = rankLabel

    -- XP bar background
    local xpBar = Instance.new("Frame")
    xpBar.Name = "XPBar"
    xpBar.Size = UDim2.new(1, -UI_PADDING * 2, 0, XP_BAR_HEIGHT)
    xpBar.Position = UDim2.new(0, UI_PADDING, 0, 45)
    xpBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    xpBar.BorderSizePixel = 0
    xpBar.Parent = progressFrame
    self._xpBar = xpBar

    local xpBarCorner = Instance.new("UICorner")
    xpBarCorner.CornerRadius = UDim.new(0, 4)
    xpBarCorner.Parent = xpBar

    -- XP bar fill
    local xpFill = Instance.new("Frame")
    xpFill.Name = "XPFill"
    xpFill.Size = UDim2.new(0, 0, 1, 0) -- Start at 0 width
    xpFill.Position = UDim2.new(0, 0, 0, 0)
    xpFill.BackgroundColor3 = Color3.fromRGB(0, 170, 127) -- Teal/green
    xpFill.BorderSizePixel = 0
    xpFill.Parent = xpBar
    self._xpFill = xpFill

    local xpFillCorner = Instance.new("UICorner")
    xpFillCorner.CornerRadius = UDim.new(0, 4)
    xpFillCorner.Parent = xpFill

    -- XP text label
    local xpLabel = Instance.new("TextLabel")
    xpLabel.Name = "XPLabel"
    xpLabel.Size = UDim2.new(1, 0, 1, 0)
    xpLabel.Position = UDim2.new(0, 0, 0, 0)
    xpLabel.BackgroundTransparency = 1
    xpLabel.Font = Enum.Font.GothamMedium
    xpLabel.TextSize = 12
    xpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    xpLabel.Text = "0 / 100 XP"
    xpLabel.Parent = xpBar
    self._xpLabel = xpLabel

    -- Create notification frame (hidden by default)
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = NOTIFICATION_SIZE
    notificationFrame.Position = NOTIFICATION_POSITION
    notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notificationFrame.BackgroundTransparency = 0.1
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Visible = false
    notificationFrame.Parent = screenGui
    self._notificationFrame = notificationFrame

    local notificationCorner = Instance.new("UICorner")
    notificationCorner.CornerRadius = UDim.new(0, 12)
    notificationCorner.Parent = notificationFrame

    -- Gold border for notification
    local notificationStroke = Instance.new("UIStroke")
    notificationStroke.Color = Color3.fromRGB(212, 175, 55) -- Gold
    notificationStroke.Thickness = 2
    notificationStroke.Parent = notificationFrame
end

function ProgressionDisplay:_connectToServer()
    -- Wait for events folder
    local eventsFolder = ReplicatedStorage:WaitForChild("ProgressionEvents", 10)
    if not eventsFolder then
        warn("[ProgressionDisplay] ProgressionEvents folder not found")
        return
    end

    -- Connect to XP changed event
    local xpChangedEvent = eventsFolder:WaitForChild("XPChanged", 5) :: RemoteEvent?
    if xpChangedEvent then
        local conn = xpChangedEvent.OnClientEvent:Connect(function(progressData: ProgressData)
            self:_onProgressUpdated(progressData)
        end)
        table.insert(self._connections, conn)
    end

    -- Connect to level up event
    local levelUpEvent = eventsFolder:WaitForChild("LevelUp", 5) :: RemoteEvent?
    if levelUpEvent then
        local conn = levelUpEvent.OnClientEvent:Connect(function(levelUpData: LevelUpData)
            self:_onLevelUp(levelUpData)
        end)
        table.insert(self._connections, conn)
    end
end

function ProgressionDisplay:_requestProgress()
    local eventsFolder = ReplicatedStorage:FindFirstChild("ProgressionEvents")
    if not eventsFolder then
        return
    end

    local requestProgress = eventsFolder:FindFirstChild("RequestProgress") :: RemoteFunction?
    if requestProgress then
        local progressData = requestProgress:InvokeServer()
        if progressData then
            self:_onProgressUpdated(progressData)
        end
    end
end

function ProgressionDisplay:_onProgressUpdated(progressData: ProgressData)
    self._currentProgress = progressData

    -- Update level label
    if self._levelLabel then
        self._levelLabel.Text = string.format("Level %d", progressData.level)
    end

    -- Update rank label with rank color
    if self._rankLabel then
        self._rankLabel.Text = progressData.rank.latinName
        self._rankLabel.TextColor3 = progressData.rank.color
    end

    -- Update XP bar
    local currentLevelXP = ProgressionConfig.getXPForLevel(progressData.level)
    local nextLevelXP = ProgressionConfig.getXPForLevel(progressData.level + 1)
    local xpIntoLevel = progressData.xp - currentLevelXP
    local xpNeeded = nextLevelXP - currentLevelXP

    -- Update XP label
    if self._xpLabel then
        self._xpLabel.Text = string.format("%d / %d XP", xpIntoLevel, xpNeeded)
    end

    -- Animate XP bar fill
    if self._xpFill then
        local progress = 0
        if xpNeeded > 0 then
            progress = math.clamp(xpIntoLevel / xpNeeded, 0, 1)
        end

        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(self._xpFill, tweenInfo, {
            Size = UDim2.new(progress, 0, 1, 0),
        })
        tween:Play()
    end
end

function ProgressionDisplay:_onLevelUp(levelUpData: LevelUpData)
    print(string.format(
        "[ProgressionDisplay] Level up! %d -> %d",
        levelUpData.oldLevel, levelUpData.newLevel
    ))

    -- Show level up notification
    self:_showLevelUpNotification(levelUpData)
end

function ProgressionDisplay:_showLevelUpNotification(levelUpData: LevelUpData)
    local frame = self._notificationFrame
    if not frame then
        return
    end

    -- Clear previous content
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("ScrollingFrame") then
            child:Destroy()
        end
    end

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 28
    titleLabel.TextColor3 = Color3.fromRGB(212, 175, 55) -- Gold
    titleLabel.Text = "LEVEL UP!"
    titleLabel.Parent = frame

    -- Level info
    local levelInfoLabel = Instance.new("TextLabel")
    levelInfoLabel.Name = "LevelInfo"
    levelInfoLabel.Size = UDim2.new(1, 0, 0, 25)
    levelInfoLabel.Position = UDim2.new(0, 0, 0, 50)
    levelInfoLabel.BackgroundTransparency = 1
    levelInfoLabel.Font = Enum.Font.GothamMedium
    levelInfoLabel.TextSize = 20
    levelInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelInfoLabel.Text = string.format("Level %d", levelUpData.newLevel)
    levelInfoLabel.Parent = frame

    -- Rank info (if changed)
    local yOffset = 80
    if levelUpData.rankChanged then
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Name = "RankInfo"
        rankLabel.Size = UDim2.new(1, 0, 0, 25)
        rankLabel.Position = UDim2.new(0, 0, 0, yOffset)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.TextSize = 18
        rankLabel.TextColor3 = levelUpData.newRank.color
        rankLabel.Text = string.format("New Rank: %s", levelUpData.newRank.name)
        rankLabel.Parent = frame
        yOffset = yOffset + 30
    end

    -- Show unlocks
    if #levelUpData.newUnlocks > 0 then
        local unlocksLabel = Instance.new("TextLabel")
        unlocksLabel.Name = "UnlocksTitle"
        unlocksLabel.Size = UDim2.new(1, 0, 0, 20)
        unlocksLabel.Position = UDim2.new(0, 0, 0, yOffset)
        unlocksLabel.BackgroundTransparency = 1
        unlocksLabel.Font = Enum.Font.GothamMedium
        unlocksLabel.TextSize = 14
        unlocksLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        unlocksLabel.Text = "New Unlocks:"
        unlocksLabel.Parent = frame

        yOffset = yOffset + 20
        for i, unlock in ipairs(levelUpData.newUnlocks) do
            if i <= 3 then -- Show max 3 unlocks
                local unlockLabel = Instance.new("TextLabel")
                unlockLabel.Name = "Unlock" .. i
                unlockLabel.Size = UDim2.new(1, -20, 0, 18)
                unlockLabel.Position = UDim2.new(0, 10, 0, yOffset)
                unlockLabel.BackgroundTransparency = 1
                unlockLabel.Font = Enum.Font.Gotham
                unlockLabel.TextSize = 14
                unlockLabel.TextColor3 = Color3.fromRGB(0, 200, 150)
                unlockLabel.TextXAlignment = Enum.TextXAlignment.Left
                unlockLabel.Text = string.format("+ %s", unlock.name)
                unlockLabel.Parent = frame
                yOffset = yOffset + 18
            end
        end
    end

    -- Show and animate notification
    frame.Visible = true
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0.5, -150, 0.2, 0)

    -- Fade in and slide down
    local showTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local showTween = TweenService:Create(frame, showTweenInfo, {
        BackgroundTransparency = 0.1,
        Position = NOTIFICATION_POSITION,
    })
    showTween:Play()

    -- Hide after delay
    task.delay(4, function()
        if frame and frame.Parent then
            local hideTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local hideTween = TweenService:Create(frame, hideTweenInfo, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, -150, 0.2, 0),
            })
            hideTween:Play()
            hideTween.Completed:Connect(function()
                frame.Visible = false
            end)
        end
    end)
end

-- Public method to get current progress
function ProgressionDisplay:getCurrentProgress(): ProgressData?
    return self._currentProgress
end

function ProgressionDisplay:destroy()
    print(string.format("[ProgressionDisplay v%s] Destroying...", ProgressionDisplay.VERSION))

    -- Disconnect all connections
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}

    -- Remove UI
    if self._screenGui then
        self._screenGui:Destroy()
        self._screenGui = nil
    end
end

return ProgressionDisplay
