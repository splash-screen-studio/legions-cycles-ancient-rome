--!strict
--[[
    CoordinateDisplay - Client-side UI showing player's X, Z, Y coordinates
    Displays position for debugging and location reporting, mobile-first design
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CoordinateDisplay = {}
CoordinateDisplay.__index = CoordinateDisplay
CoordinateDisplay.VERSION = "1.0.0"

-- UI Constants (mobile-first design, matches CurrencyDisplay aesthetic)
local UI_CONSTANTS = {
    FRAME_SIZE = UDim2.new(0, 180, 0, 55),
    FRAME_POSITION = UDim2.new(1, -190, 0, 70), -- Below CurrencyDisplay (which is at y=10, height=50)
    CORNER_RADIUS = UDim.new(0, 12),
    PADDING = 10,

    -- Colors (Roman gold/bronze aesthetic, matching CurrencyDisplay)
    BACKGROUND_COLOR = Color3.fromRGB(45, 35, 25), -- Dark bronze
    BORDER_COLOR = Color3.fromRGB(205, 127, 50), -- Bronze
    TEXT_COLOR = Color3.fromRGB(255, 215, 0), -- Gold
    LABEL_COLOR = Color3.fromRGB(180, 160, 120), -- Muted gold for labels
}

function CoordinateDisplay.new()
    local self = setmetatable({}, CoordinateDisplay)

    self._player = Players.LocalPlayer
    self._character = nil :: Model?

    -- UI elements (created on start)
    self._screenGui = nil :: ScreenGui?
    self._mainFrame = nil :: Frame?
    self._xzLabel = nil :: TextLabel?
    self._yLabel = nil :: TextLabel?

    -- Connections
    self._connections = {} :: { RBXScriptConnection }

    print(string.format("[CoordinateDisplay v%s] Initializing...", CoordinateDisplay.VERSION))

    return self
end

function CoordinateDisplay:start()
    -- Create UI
    self:_createUI()

    -- Connect to character added
    local characterAddedConnection = self._player.CharacterAdded:Connect(function(character)
        self:_onCharacterAdded(character)
    end)
    table.insert(self._connections, characterAddedConnection)

    -- If character already exists, connect immediately
    if self._player.Character then
        self:_onCharacterAdded(self._player.Character)
    end

    -- Connect to Heartbeat for position updates
    local heartbeatConnection = RunService.Heartbeat:Connect(function()
        self:_updatePosition()
    end)
    table.insert(self._connections, heartbeatConnection)

    print(string.format("[CoordinateDisplay v%s] Started", CoordinateDisplay.VERSION))
end

function CoordinateDisplay:stop()
    -- Disconnect heartbeat only, keep UI visible
    for i = #self._connections, 1, -1 do
        self._connections[i]:Disconnect()
        table.remove(self._connections, i)
    end

    print(string.format("[CoordinateDisplay v%s] Stopped", CoordinateDisplay.VERSION))
end

function CoordinateDisplay:_onCharacterAdded(character: Model)
    self._character = character
end

function CoordinateDisplay:_createUI()
    local playerGui = self._player:WaitForChild("PlayerGui")

    -- Create ScreenGui
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "CoordinateDisplay"
    self._screenGui.ResetOnSpawn = false
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.Parent = playerGui

    -- Main frame (container)
    self._mainFrame = Instance.new("Frame")
    self._mainFrame.Name = "CoordinateFrame"
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
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 2)
    layout.Parent = self._mainFrame

    -- Padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, UI_CONSTANTS.PADDING)
    padding.PaddingRight = UDim.new(0, UI_CONSTANTS.PADDING)
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = self._mainFrame

    -- X, Z coordinates label (first line)
    self._xzLabel = Instance.new("TextLabel")
    self._xzLabel.Name = "XZLabel"
    self._xzLabel.Size = UDim2.new(1, 0, 0, 20)
    self._xzLabel.BackgroundTransparency = 1
    self._xzLabel.Text = "X: 0  Z: 0"
    self._xzLabel.TextColor3 = UI_CONSTANTS.TEXT_COLOR
    self._xzLabel.TextSize = 16
    self._xzLabel.Font = Enum.Font.GothamBold
    self._xzLabel.TextXAlignment = Enum.TextXAlignment.Center
    self._xzLabel.Parent = self._mainFrame

    -- Y coordinate label (second line)
    self._yLabel = Instance.new("TextLabel")
    self._yLabel.Name = "YLabel"
    self._yLabel.Size = UDim2.new(1, 0, 0, 18)
    self._yLabel.BackgroundTransparency = 1
    self._yLabel.Text = "Y: 0"
    self._yLabel.TextColor3 = UI_CONSTANTS.LABEL_COLOR
    self._yLabel.TextSize = 14
    self._yLabel.Font = Enum.Font.Gotham
    self._yLabel.TextXAlignment = Enum.TextXAlignment.Center
    self._yLabel.Parent = self._mainFrame

    print("[CoordinateDisplay] UI created")
end

function CoordinateDisplay:_updatePosition()
    if not self._character then
        return
    end

    local humanoidRootPart = self._character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then
        return
    end

    local position = humanoidRootPart.Position
    local x = math.floor(position.X + 0.5)
    local y = math.floor(position.Y + 0.5)
    local z = math.floor(position.Z + 0.5)

    if self._xzLabel then
        self._xzLabel.Text = string.format("X: %d  Z: %d", x, z)
    end

    if self._yLabel then
        self._yLabel.Text = string.format("Y: %d", y)
    end
end

function CoordinateDisplay:destroy()
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

    self._character = nil

    print(string.format("[CoordinateDisplay v%s] Destroyed", CoordinateDisplay.VERSION))
end

return CoordinateDisplay
