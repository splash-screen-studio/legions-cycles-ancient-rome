--!strict
--[[
    CurrencyDisplay - Client-side UI showing the player's Denarii balance
    Displays coin count with Roman aesthetic, mobile-first design
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CurrencyConfig = require(Shared:WaitForChild("CurrencyConfig"))

local CurrencyDisplay = {}
CurrencyDisplay.__index = CurrencyDisplay
CurrencyDisplay.VERSION = "1.0.0"

-- UI Constants (mobile-first design)
local UI_CONSTANTS = {
    FRAME_SIZE = UDim2.new(0, 180, 0, 50),
    FRAME_POSITION = UDim2.new(1, -190, 0, 10), -- Top-right corner
    CORNER_RADIUS = UDim.new(0, 12),
    PADDING = 10,

    -- Colors (Roman gold/bronze aesthetic)
    BACKGROUND_COLOR = Color3.fromRGB(45, 35, 25), -- Dark bronze
    BORDER_COLOR = Color3.fromRGB(205, 127, 50), -- Bronze
    TEXT_COLOR = Color3.fromRGB(255, 215, 0), -- Gold
    COIN_COLOR = Color3.fromRGB(212, 175, 55), -- Gold coin

    -- Animation
    UPDATE_TWEEN_TIME = 0.3,
    PULSE_SCALE = 1.1,
}

function CurrencyDisplay.new()
    local self = setmetatable({}, CurrencyDisplay)

    self._player = Players.LocalPlayer
    self._balance = 0
    self._displayedBalance = 0

    -- UI elements (created on start)
    self._screenGui = nil :: ScreenGui?
    self._mainFrame = nil :: Frame?
    self._coinIcon = nil :: Frame?
    self._balanceLabel = nil :: TextLabel?

    -- Remote references
    self._getBalanceFunction = nil :: RemoteFunction?
    self._balanceUpdatedEvent = nil :: RemoteEvent?

    -- Connections
    self._connections = {} :: { RBXScriptConnection }

    print(string.format("[CurrencyDisplay v%s] Initializing...", CurrencyDisplay.VERSION))

    return self
end

function CurrencyDisplay:start()
    -- Wait for Remotes folder
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
    if not remotesFolder then
        warn("[CurrencyDisplay] Remotes folder not found - currency system unavailable")
        return
    end

    -- Get remote references
    self._getBalanceFunction = remotesFolder:WaitForChild(CurrencyConfig.REMOTES.GET_BALANCE, 10) :: RemoteFunction?
    self._balanceUpdatedEvent = remotesFolder:WaitForChild(CurrencyConfig.REMOTES.BALANCE_UPDATED, 10) :: RemoteEvent?

    if not self._getBalanceFunction or not self._balanceUpdatedEvent then
        warn("[CurrencyDisplay] Currency remotes not found")
        return
    end

    -- Create UI
    self:_createUI()

    -- Get initial balance
    self:_fetchBalance()

    -- Listen for balance updates
    local updateConnection = self._balanceUpdatedEvent.OnClientEvent:Connect(function(newBalance: number)
        self:_onBalanceUpdated(newBalance)
    end)
    table.insert(self._connections, updateConnection)

    print(string.format("[CurrencyDisplay v%s] Started", CurrencyDisplay.VERSION))
end

function CurrencyDisplay:_createUI()
    local playerGui = self._player:WaitForChild("PlayerGui")

    -- Create ScreenGui
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "CurrencyDisplay"
    self._screenGui.ResetOnSpawn = false
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.Parent = playerGui

    -- Main frame (container)
    self._mainFrame = Instance.new("Frame")
    self._mainFrame.Name = "CurrencyFrame"
    self._mainFrame.Size = UI_CONSTANTS.FRAME_SIZE
    self._mainFrame.Position = UI_CONSTANTS.FRAME_POSITION
    self._mainFrame.AnchorPoint = Vector2.new(0, 0)
    self._mainFrame.BackgroundColor3 = UI_CONSTANTS.BACKGROUND_COLOR
    self._mainFrame.BorderSizePixel = 0
    self._mainFrame.Parent = self._screenGui

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UI_CONSTANTS.CORNER_RADIUS
    corner.Parent = self._mainFrame

    -- Border/stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = UI_CONSTANTS.BORDER_COLOR
    stroke.Thickness = 2
    stroke.Parent = self._mainFrame

    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, UI_CONSTANTS.PADDING)
    layout.Parent = self._mainFrame

    -- Padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, UI_CONSTANTS.PADDING)
    padding.PaddingRight = UDim.new(0, UI_CONSTANTS.PADDING)
    padding.Parent = self._mainFrame

    -- Coin icon (simple circular representation)
    self._coinIcon = Instance.new("Frame")
    self._coinIcon.Name = "CoinIcon"
    self._coinIcon.Size = UDim2.new(0, 32, 0, 32)
    self._coinIcon.BackgroundColor3 = UI_CONSTANTS.COIN_COLOR
    self._coinIcon.BorderSizePixel = 0
    self._coinIcon.Parent = self._mainFrame

    -- Coin icon rounded (make it circular)
    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(1, 0)
    coinCorner.Parent = self._coinIcon

    -- Coin inner detail (smaller circle for depth)
    local coinInner = Instance.new("Frame")
    coinInner.Name = "Inner"
    coinInner.Size = UDim2.new(0.7, 0, 0.7, 0)
    coinInner.Position = UDim2.new(0.5, 0, 0.5, 0)
    coinInner.AnchorPoint = Vector2.new(0.5, 0.5)
    coinInner.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    coinInner.BorderSizePixel = 0
    coinInner.Parent = self._coinIcon

    local coinInnerCorner = Instance.new("UICorner")
    coinInnerCorner.CornerRadius = UDim.new(1, 0)
    coinInnerCorner.Parent = coinInner

    -- "D" symbol on coin (for Denarii)
    local coinSymbol = Instance.new("TextLabel")
    coinSymbol.Name = "Symbol"
    coinSymbol.Size = UDim2.new(1, 0, 1, 0)
    coinSymbol.BackgroundTransparency = 1
    coinSymbol.Text = CurrencyConfig.CURRENCY_SYMBOL
    coinSymbol.TextColor3 = Color3.fromRGB(139, 90, 43)
    coinSymbol.TextScaled = true
    coinSymbol.Font = Enum.Font.GothamBold
    coinSymbol.Parent = coinInner

    -- Balance text
    self._balanceLabel = Instance.new("TextLabel")
    self._balanceLabel.Name = "BalanceLabel"
    self._balanceLabel.Size = UDim2.new(0, 100, 1, 0)
    self._balanceLabel.BackgroundTransparency = 1
    self._balanceLabel.Text = "0"
    self._balanceLabel.TextColor3 = UI_CONSTANTS.TEXT_COLOR
    self._balanceLabel.TextSize = 24
    self._balanceLabel.Font = Enum.Font.GothamBold
    self._balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._balanceLabel.Parent = self._mainFrame

    print("[CurrencyDisplay] UI created")
end

function CurrencyDisplay:_fetchBalance()
    if not self._getBalanceFunction then
        return
    end

    local success, result = pcall(function()
        return self._getBalanceFunction:InvokeServer()
    end)

    if success and typeof(result) == "number" then
        self._balance = result
        self._displayedBalance = result
        self:_updateDisplay(false)
    else
        warn("[CurrencyDisplay] Failed to fetch balance")
    end
end

function CurrencyDisplay:_onBalanceUpdated(newBalance: number)
    local previousBalance = self._balance
    self._balance = newBalance

    -- Determine if this is a gain or loss for animation
    local isGain = newBalance > previousBalance

    self:_updateDisplay(true, isGain)
end

function CurrencyDisplay:_updateDisplay(animate: boolean, isGain: boolean?)
    if not self._balanceLabel then
        return
    end

    local targetBalance = self._balance

    if animate then
        -- Animate the number counting up/down
        local startBalance = self._displayedBalance
        local difference = targetBalance - startBalance
        local duration = UI_CONSTANTS.UPDATE_TWEEN_TIME

        -- Pulse animation on the coin
        if self._coinIcon then
            self:_pulseAnimation(self._coinIcon, isGain)
        end

        -- Count animation
        local startTime = tick()
        local connection
        connection = game:GetService("RunService").RenderStepped:Connect(function()
            local elapsed = tick() - startTime
            local progress = math.min(elapsed / duration, 1)

            -- Ease out quad
            local easedProgress = 1 - (1 - progress) ^ 2

            self._displayedBalance = math.floor(startBalance + (difference * easedProgress))
            self._balanceLabel.Text = self:_formatNumber(self._displayedBalance)

            if progress >= 1 then
                if connection then
                    connection:Disconnect()
                end
                self._displayedBalance = targetBalance
                self._balanceLabel.Text = self:_formatNumber(targetBalance)
            end
        end)
    else
        self._displayedBalance = targetBalance
        self._balanceLabel.Text = self:_formatNumber(targetBalance)
    end
end

function CurrencyDisplay:_pulseAnimation(element: GuiObject, isGain: boolean?)
    -- Color flash based on gain/loss
    local flashColor = if isGain then Color3.fromRGB(100, 255, 100) else Color3.fromRGB(255, 100, 100)
    local originalColor = UI_CONSTANTS.COIN_COLOR

    -- Scale pulse
    local tweenInfo = TweenInfo.new(
        UI_CONSTANTS.UPDATE_TWEEN_TIME / 2,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    -- Scale up
    local scaleUpTween = TweenService:Create(element, tweenInfo, {
        Size = UDim2.new(0, 32 * UI_CONSTANTS.PULSE_SCALE, 0, 32 * UI_CONSTANTS.PULSE_SCALE),
        BackgroundColor3 = flashColor,
    })

    -- Scale back
    local scaleDownTween = TweenService:Create(element, tweenInfo, {
        Size = UDim2.new(0, 32, 0, 32),
        BackgroundColor3 = originalColor,
    })

    scaleUpTween:Play()
    scaleUpTween.Completed:Connect(function()
        scaleDownTween:Play()
    end)
end

function CurrencyDisplay:_formatNumber(number: number): string
    -- Format large numbers with commas
    local formatted = tostring(number)
    local k

    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then
            break
        end
    end

    return formatted
end

--[[
    Get the current balance (cached value)
    @return The player's current Denarii balance
]]
function CurrencyDisplay:getBalance(): number
    return self._balance
end

--[[
    Check if the player can afford a cost (client-side check)
    Note: Server performs the actual validation
    @param cost The cost to check
    @return true if the player appears to be able to afford it
]]
function CurrencyDisplay:canAfford(cost: number): boolean
    return self._balance >= cost
end

function CurrencyDisplay:destroy()
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

    print(string.format("[CurrencyDisplay v%s] Destroyed", CurrencyDisplay.VERSION))
end

return CurrencyDisplay
