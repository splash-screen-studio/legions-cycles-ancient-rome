--!strict
--[[
    StructureMenu - Touch-friendly structure selection menu
    Displays available structures in a grid layout
    Allows selection and shows preview before placement
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BuildConfig = require(Shared:WaitForChild("BuildConfig"))

local StructureMenu = {}
StructureMenu.__index = StructureMenu
StructureMenu.VERSION = "1.0.0"

function StructureMenu.new()
    local self = setmetatable({}, StructureMenu)

    self._player = Players.LocalPlayer
    self._isOpen = false
    self._selectedStructure = nil :: BuildConfig.StructureType?

    -- UI elements
    self._screenGui = nil :: ScreenGui?
    self._mainFrame = nil :: Frame?
    self._gridFrame = nil :: Frame?
    self._previewFrame = nil :: Frame?
    self._structureButtons = {} :: { [string]: TextButton }

    -- Callbacks
    self._onPlaceRequested = nil :: ((BuildConfig.StructureType) -> ())?
    self._onClose = nil :: (() -> ())?

    -- Connections
    self._connections = {} :: { RBXScriptConnection }

    print(string.format("[StructureMenu v%s] Initializing...", StructureMenu.VERSION))

    return self
end

function StructureMenu:start()
    self:_createUI()
    print(string.format("[StructureMenu v%s] Started", StructureMenu.VERSION))
end

--[[
    Set callback for when place is requested
    @param callback Function called with selected structure when Place is tapped
]]
function StructureMenu:setOnPlaceRequested(callback: (BuildConfig.StructureType) -> ())
    self._onPlaceRequested = callback
end

--[[
    Set callback for when menu is closed
    @param callback Function called when menu closes
]]
function StructureMenu:setOnClose(callback: () -> ())
    self._onClose = callback
end

--[[
    Open the structure menu
]]
function StructureMenu:open()
    if self._isOpen then
        return
    end

    self._isOpen = true
    self._selectedStructure = nil

    if self._mainFrame then
        self._mainFrame.Visible = true

        -- Animate in
        self._mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
        local tweenInfo = TweenInfo.new(BuildConfig.UI.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(self._mainFrame, tweenInfo, {
            Position = UDim2.new(0.5, 0, 0.5, 0),
        })
        tween:Play()
    end

    self:_updatePreview()
    print("[StructureMenu] Opened")
end

--[[
    Close the structure menu
]]
function StructureMenu:close()
    if not self._isOpen then
        return
    end

    self._isOpen = false

    if self._mainFrame then
        -- Animate out
        local tweenInfo = TweenInfo.new(BuildConfig.UI.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(self._mainFrame, tweenInfo, {
            Position = UDim2.new(0.5, 0, 1.5, 0),
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not self._isOpen and self._mainFrame then
                self._mainFrame.Visible = false
            end
        end)
    end

    if self._onClose then
        self._onClose()
    end

    print("[StructureMenu] Closed")
end

--[[
    Check if the menu is currently open
]]
function StructureMenu:isOpen(): boolean
    return self._isOpen
end

--[[
    Get the currently selected structure
]]
function StructureMenu:getSelectedStructure(): BuildConfig.StructureType?
    return self._selectedStructure
end

function StructureMenu:_createUI()
    local playerGui = self._player:WaitForChild("PlayerGui")

    -- Create ScreenGui
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "StructureMenu"
    self._screenGui.ResetOnSpawn = false
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.DisplayOrder = 10
    self._screenGui.Parent = playerGui

    -- Main frame (centered overlay)
    self._mainFrame = Instance.new("Frame")
    self._mainFrame.Name = "MenuFrame"
    self._mainFrame.Size = UDim2.new(0, BuildConfig.UI.MENU_WIDTH, 0, BuildConfig.UI.MENU_HEIGHT)
    self._mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    self._mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    self._mainFrame.BackgroundColor3 = BuildConfig.UI.COLORS.BACKGROUND
    self._mainFrame.BorderSizePixel = 0
    self._mainFrame.Visible = false
    self._mainFrame.Parent = self._screenGui

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = self._mainFrame

    -- Border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = BuildConfig.UI.COLORS.ACCENT
    stroke.Thickness = 3
    stroke.Parent = self._mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = BuildConfig.UI.COLORS.PRIMARY
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self._mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 16)
    titleCorner.Parent = titleBar

    -- Fix bottom corners of title bar
    local titleBottomFix = Instance.new("Frame")
    titleBottomFix.Name = "BottomFix"
    titleBottomFix.Size = UDim2.new(1, 0, 0, 16)
    titleBottomFix.Position = UDim2.new(0, 0, 1, -16)
    titleBottomFix.BackgroundColor3 = BuildConfig.UI.COLORS.PRIMARY
    titleBottomFix.BorderSizePixel = 0
    titleBottomFix.Parent = titleBar

    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Build Structure"
    titleLabel.TextColor3 = BuildConfig.UI.COLORS.TEXT
    titleLabel.TextSize = 22
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 44, 0, 44)
    closeButton.Position = UDim2.new(1, -47, 0.5, 0)
    closeButton.AnchorPoint = Vector2.new(0, 0.5)
    closeButton.BackgroundColor3 = BuildConfig.UI.COLORS.INVALID
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = BuildConfig.UI.COLORS.TEXT
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    local closeConnection = closeButton.Activated:Connect(function()
        self:close()
    end)
    table.insert(self._connections, closeConnection)

    -- Structure grid
    self:_createStructureGrid()

    -- Preview area
    self:_createPreviewArea()

    -- Place button
    self:_createPlaceButton()

    print("[StructureMenu] UI created")
end

function StructureMenu:_createStructureGrid()
    local gridFrame = Instance.new("ScrollingFrame")
    gridFrame.Name = "StructureGrid"
    gridFrame.Size = UDim2.new(1, -20, 0, 160)
    gridFrame.Position = UDim2.new(0, 10, 0, 60)
    gridFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
    gridFrame.BorderSizePixel = 0
    gridFrame.ScrollBarThickness = 6
    gridFrame.ScrollBarImageColor3 = BuildConfig.UI.COLORS.ACCENT
    gridFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    gridFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gridFrame.Parent = self._mainFrame

    local gridCorner = Instance.new("UICorner")
    gridCorner.CornerRadius = UDim.new(0, 8)
    gridCorner.Parent = gridFrame

    -- Grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, BuildConfig.UI.GRID_CELL_SIZE, 0, BuildConfig.UI.GRID_CELL_SIZE)
    gridLayout.CellPadding = UDim2.new(0, BuildConfig.UI.GRID_PADDING, 0, BuildConfig.UI.GRID_PADDING)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = gridFrame

    -- Padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, BuildConfig.UI.GRID_PADDING)
    padding.PaddingBottom = UDim.new(0, BuildConfig.UI.GRID_PADDING)
    padding.PaddingLeft = UDim.new(0, BuildConfig.UI.GRID_PADDING)
    padding.PaddingRight = UDim.new(0, BuildConfig.UI.GRID_PADDING)
    padding.Parent = gridFrame

    self._gridFrame = gridFrame

    -- Create buttons for each structure
    local structures = BuildConfig.getStructuresInOrder()
    for i, structure in ipairs(structures) do
        self:_createStructureButton(structure, i)
    end
end

function StructureMenu:_createStructureButton(structure: BuildConfig.StructureType, layoutOrder: number)
    local button = Instance.new("TextButton")
    button.Name = structure.id
    button.Size = UDim2.new(0, BuildConfig.UI.GRID_CELL_SIZE, 0, BuildConfig.UI.GRID_CELL_SIZE)
    button.BackgroundColor3 = BuildConfig.UI.COLORS.SECONDARY
    button.BorderSizePixel = 0
    button.LayoutOrder = layoutOrder
    button.Text = ""
    button.Parent = self._gridFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    -- Selection highlight (initially hidden)
    local highlight = Instance.new("UIStroke")
    highlight.Name = "Highlight"
    highlight.Color = BuildConfig.UI.COLORS.ACCENT
    highlight.Thickness = 3
    highlight.Transparency = 1
    highlight.Parent = button

    -- Icon placeholder (simple colored box representing structure type)
    local icon = Instance.new("Frame")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 36, 0, 36)
    icon.Position = UDim2.new(0.5, 0, 0, 8)
    icon.AnchorPoint = Vector2.new(0.5, 0)
    icon.BackgroundColor3 = self:_getCategoryColor(structure.category)
    icon.BorderSizePixel = 0
    icon.Parent = button

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 4)
    iconCorner.Parent = icon

    -- Structure name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -4, 0, 20)
    nameLabel.Position = UDim2.new(0, 2, 1, -22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = structure.name
    nameLabel.TextColor3 = BuildConfig.UI.COLORS.BACKGROUND
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = button

    -- Button interaction
    local buttonConnection = button.Activated:Connect(function()
        self:_selectStructure(structure)
    end)
    table.insert(self._connections, buttonConnection)

    self._structureButtons[structure.id] = button
end

function StructureMenu:_getCategoryColor(category: string): Color3
    if category == BuildConfig.CATEGORIES.RESIDENTIAL then
        return Color3.fromRGB(100, 140, 180) -- Blue
    elseif category == BuildConfig.CATEGORIES.COMMERCIAL then
        return Color3.fromRGB(180, 140, 80) -- Gold
    elseif category == BuildConfig.CATEGORIES.RELIGIOUS then
        return Color3.fromRGB(180, 100, 180) -- Purple
    elseif category == BuildConfig.CATEGORIES.INFRASTRUCTURE then
        return Color3.fromRGB(140, 140, 140) -- Gray
    end
    return Color3.fromRGB(150, 150, 150)
end

function StructureMenu:_createPreviewArea()
    local previewFrame = Instance.new("Frame")
    previewFrame.Name = "PreviewArea"
    previewFrame.Size = UDim2.new(1, -20, 0, 100)
    previewFrame.Position = UDim2.new(0, 10, 0, 230)
    previewFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
    previewFrame.BorderSizePixel = 0
    previewFrame.Parent = self._mainFrame

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = previewFrame

    -- Preview name
    local previewName = Instance.new("TextLabel")
    previewName.Name = "PreviewName"
    previewName.Size = UDim2.new(1, -20, 0, 24)
    previewName.Position = UDim2.new(0, 10, 0, 8)
    previewName.BackgroundTransparency = 1
    previewName.Text = "Select a structure"
    previewName.TextColor3 = BuildConfig.UI.COLORS.TEXT
    previewName.TextSize = 18
    previewName.Font = Enum.Font.GothamBold
    previewName.TextXAlignment = Enum.TextXAlignment.Left
    previewName.Parent = previewFrame

    -- Preview description
    local previewDesc = Instance.new("TextLabel")
    previewDesc.Name = "PreviewDesc"
    previewDesc.Size = UDim2.new(1, -20, 0, 36)
    previewDesc.Position = UDim2.new(0, 10, 0, 34)
    previewDesc.BackgroundTransparency = 1
    previewDesc.Text = ""
    previewDesc.TextColor3 = BuildConfig.UI.COLORS.SECONDARY
    previewDesc.TextSize = 14
    previewDesc.Font = Enum.Font.Gotham
    previewDesc.TextXAlignment = Enum.TextXAlignment.Left
    previewDesc.TextYAlignment = Enum.TextYAlignment.Top
    previewDesc.TextWrapped = true
    previewDesc.Parent = previewFrame

    -- Preview cost
    local previewCost = Instance.new("TextLabel")
    previewCost.Name = "PreviewCost"
    previewCost.Size = UDim2.new(1, -20, 0, 20)
    previewCost.Position = UDim2.new(0, 10, 1, -28)
    previewCost.BackgroundTransparency = 1
    previewCost.Text = ""
    previewCost.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    previewCost.TextSize = 16
    previewCost.Font = Enum.Font.GothamBold
    previewCost.TextXAlignment = Enum.TextXAlignment.Left
    previewCost.Parent = previewFrame

    self._previewFrame = previewFrame
end

function StructureMenu:_createPlaceButton()
    local placeButton = Instance.new("TextButton")
    placeButton.Name = "PlaceButton"
    placeButton.Size = UDim2.new(1, -20, 0, 50)
    placeButton.Position = UDim2.new(0, 10, 1, -60)
    placeButton.BackgroundColor3 = BuildConfig.UI.COLORS.VALID
    placeButton.BorderSizePixel = 0
    placeButton.Text = "Place"
    placeButton.TextColor3 = BuildConfig.UI.COLORS.TEXT
    placeButton.TextSize = 20
    placeButton.Font = Enum.Font.GothamBold
    placeButton.Parent = self._mainFrame

    local placeCorner = Instance.new("UICorner")
    placeCorner.CornerRadius = UDim.new(0, 12)
    placeCorner.Parent = placeButton

    local placeConnection = placeButton.Activated:Connect(function()
        if self._selectedStructure and self._onPlaceRequested then
            self._onPlaceRequested(self._selectedStructure)
        end
    end)
    table.insert(self._connections, placeConnection)
end

function StructureMenu:_selectStructure(structure: BuildConfig.StructureType)
    -- Deselect previous
    if self._selectedStructure then
        local prevButton = self._structureButtons[self._selectedStructure.id]
        if prevButton then
            local highlight = prevButton:FindFirstChild("Highlight") :: UIStroke?
            if highlight then
                highlight.Transparency = 1
            end
        end
    end

    -- Select new
    self._selectedStructure = structure

    local button = self._structureButtons[structure.id]
    if button then
        local highlight = button:FindFirstChild("Highlight") :: UIStroke?
        if highlight then
            highlight.Transparency = 0
        end
    end

    self:_updatePreview()
    print(string.format("[StructureMenu] Selected %s", structure.name))
end

function StructureMenu:_updatePreview()
    if not self._previewFrame then
        return
    end

    local nameLabel = self._previewFrame:FindFirstChild("PreviewName") :: TextLabel?
    local descLabel = self._previewFrame:FindFirstChild("PreviewDesc") :: TextLabel?
    local costLabel = self._previewFrame:FindFirstChild("PreviewCost") :: TextLabel?

    if self._selectedStructure then
        if nameLabel then
            nameLabel.Text = self._selectedStructure.name
        end
        if descLabel then
            descLabel.Text = self._selectedStructure.description
        end
        if costLabel then
            costLabel.Text = string.format("Cost: %d Denarii", self._selectedStructure.cost)
        end
    else
        if nameLabel then
            nameLabel.Text = "Select a structure"
        end
        if descLabel then
            descLabel.Text = ""
        end
        if costLabel then
            costLabel.Text = ""
        end
    end
end

function StructureMenu:destroy()
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

    self._structureButtons = {}

    print(string.format("[StructureMenu v%s] Destroyed", StructureMenu.VERSION))
end

return StructureMenu
