--!strict
--[[
    BuildUI - Main client-side building interface
    Provides touch-friendly UI for placing structures in the world
    Mobile-first design with large touch targets
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BuildConfig = require(Shared:WaitForChild("BuildConfig"))
local CurrencyConfig = require(Shared:WaitForChild("CurrencyConfig"))

local StructureMenu = require(script.Parent.StructureMenu)
local PlacementPreview = require(script.Parent.PlacementPreview)

local BuildUI = {}
BuildUI.__index = BuildUI
BuildUI.VERSION = "1.0.0"

-- UI State
export type BuildState = "IDLE" | "MENU" | "PLACING"

function BuildUI.new()
    local self = setmetatable({}, BuildUI)

    self._player = Players.LocalPlayer

    -- State
    self._state = "IDLE" :: BuildState
    self._selectedStructure = nil :: BuildConfig.StructureType?

    -- Sub-modules
    self._structureMenu = nil :: typeof(StructureMenu.new())?
    self._placementPreview = nil :: typeof(PlacementPreview.new())?

    -- UI elements
    self._screenGui = nil :: ScreenGui?
    self._buildButton = nil :: TextButton?
    self._placementControls = nil :: Frame?

    -- Remotes
    self._placeStructureFunction = nil :: RemoteFunction?
    self._spendRequestFunction = nil :: RemoteFunction?

    -- Connections
    self._connections = {} :: { RBXScriptConnection }

    print(string.format("[BuildUI v%s] Initializing...", BuildUI.VERSION))

    return self
end

function BuildUI:start()
    -- Wait for remotes
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
    if remotesFolder then
        self._placeStructureFunction = remotesFolder:WaitForChild(BuildConfig.REMOTES.PLACE_STRUCTURE, 10) :: RemoteFunction?
        self._spendRequestFunction = remotesFolder:WaitForChild(CurrencyConfig.REMOTES.SPEND_REQUEST, 10) :: RemoteFunction?
    end

    -- Initialize sub-modules
    self._structureMenu = StructureMenu.new()
    self._structureMenu:start()
    self._structureMenu:setOnPlaceRequested(function(structure)
        self:_onPlaceRequested(structure)
    end)
    self._structureMenu:setOnClose(function()
        self:_onMenuClosed()
    end)

    self._placementPreview = PlacementPreview.new()
    self._placementPreview:start()

    -- Create main UI
    self:_createUI()

    print(string.format("[BuildUI v%s] Started", BuildUI.VERSION))
end

function BuildUI:_createUI()
    local playerGui = self._player:WaitForChild("PlayerGui")

    -- Create ScreenGui
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "BuildUI"
    self._screenGui.ResetOnSpawn = false
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.DisplayOrder = 5
    self._screenGui.Parent = playerGui

    -- Create build button (large circular button, bottom-center)
    self:_createBuildButton()

    -- Create placement controls (Confirm/Cancel buttons during placement)
    self:_createPlacementControls()

    print("[BuildUI] UI created")
end

function BuildUI:_createBuildButton()
    local buttonSize = BuildConfig.UI.BUILD_BUTTON_SIZE
    local buttonOffset = BuildConfig.UI.BUILD_BUTTON_OFFSET_Y

    local button = Instance.new("TextButton")
    button.Name = "BuildButton"
    button.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    button.Position = UDim2.new(0.5, 0, 1, -buttonOffset)
    button.AnchorPoint = Vector2.new(0.5, 1)
    button.BackgroundColor3 = BuildConfig.UI.COLORS.PRIMARY
    button.BorderSizePixel = 0
    button.Text = ""
    button.Parent = self._screenGui

    -- Make it circular
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    -- Border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = BuildConfig.UI.COLORS.ACCENT
    stroke.Thickness = 3
    stroke.Parent = button

    -- Build icon (hammer symbol using text)
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "B"
    icon.TextColor3 = BuildConfig.UI.COLORS.TEXT
    icon.TextSize = 32
    icon.Font = Enum.Font.GothamBold
    icon.Parent = button

    -- "Build" label below button
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0, 60, 0, 20)
    label.Position = UDim2.new(0.5, 0, 1, 5)
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.BackgroundTransparency = 1
    label.Text = "Build"
    label.TextColor3 = BuildConfig.UI.COLORS.TEXT
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = button

    -- Button interaction
    local buttonConnection = button.Activated:Connect(function()
        self:_onBuildButtonTapped()
    end)
    table.insert(self._connections, buttonConnection)

    self._buildButton = button
end

function BuildUI:_createPlacementControls()
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "PlacementControls"
    controlsFrame.Size = UDim2.new(0, 200, 0, 60)
    controlsFrame.Position = UDim2.new(0.5, 0, 1, -20)
    controlsFrame.AnchorPoint = Vector2.new(0.5, 1)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Visible = false
    controlsFrame.Parent = self._screenGui

    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 20)
    layout.Parent = controlsFrame

    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0, 80, 0, 50)
    cancelButton.BackgroundColor3 = BuildConfig.UI.COLORS.INVALID
    cancelButton.BorderSizePixel = 0
    cancelButton.Text = "Cancel"
    cancelButton.TextColor3 = BuildConfig.UI.COLORS.TEXT
    cancelButton.TextSize = 16
    cancelButton.Font = Enum.Font.GothamBold
    cancelButton.LayoutOrder = 1
    cancelButton.Parent = controlsFrame

    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 10)
    cancelCorner.Parent = cancelButton

    local cancelConnection = cancelButton.Activated:Connect(function()
        self:_onCancelPlacement()
    end)
    table.insert(self._connections, cancelConnection)

    -- Confirm button
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.Size = UDim2.new(0, 80, 0, 50)
    confirmButton.BackgroundColor3 = BuildConfig.UI.COLORS.VALID
    confirmButton.BorderSizePixel = 0
    confirmButton.Text = "Confirm"
    confirmButton.TextColor3 = BuildConfig.UI.COLORS.TEXT
    confirmButton.TextSize = 16
    confirmButton.Font = Enum.Font.GothamBold
    confirmButton.LayoutOrder = 2
    confirmButton.Parent = controlsFrame

    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 10)
    confirmCorner.Parent = confirmButton

    local confirmConnection = confirmButton.Activated:Connect(function()
        self:_onConfirmPlacement()
    end)
    table.insert(self._connections, confirmConnection)

    self._placementControls = controlsFrame
end

function BuildUI:_onBuildButtonTapped()
    if self._state == "IDLE" then
        self:_openMenu()
    elseif self._state == "MENU" then
        self:_closeMenu()
    end
end

function BuildUI:_openMenu()
    if self._structureMenu then
        self._structureMenu:open()
        self._state = "MENU"

        -- Hide build button during menu
        if self._buildButton then
            self._buildButton.Visible = false
        end
    end
end

function BuildUI:_closeMenu()
    if self._structureMenu then
        self._structureMenu:close()
    end
end

function BuildUI:_onMenuClosed()
    if self._state == "MENU" then
        self._state = "IDLE"

        -- Show build button
        if self._buildButton then
            self._buildButton.Visible = true
        end
    end
end

function BuildUI:_onPlaceRequested(structure: BuildConfig.StructureType)
    self._selectedStructure = structure

    -- Close menu
    if self._structureMenu then
        self._structureMenu:close()
    end

    -- Enter placement mode
    self._state = "PLACING"

    if self._placementPreview then
        self._placementPreview:enterPlacementMode(
            structure,
            function(position)
                self:_onPlacementConfirmed(position)
            end,
            function()
                self:_onPlacementCancelled()
            end
        )
    end

    -- Show placement controls
    if self._placementControls then
        self._placementControls.Visible = true
    end

    print(string.format("[BuildUI] Entering placement mode for %s", structure.name))
end

function BuildUI:_onConfirmPlacement()
    if self._state ~= "PLACING" then
        return
    end

    if self._placementPreview and self._placementPreview:isValidPlacement() then
        self._placementPreview:confirmPlacement()
    else
        warn("[BuildUI] Cannot confirm - invalid placement position")
    end
end

function BuildUI:_onCancelPlacement()
    if self._state ~= "PLACING" then
        return
    end

    if self._placementPreview then
        self._placementPreview:cancelPlacement()
    end
end

function BuildUI:_onPlacementConfirmed(position: Vector3)
    local structure = self._selectedStructure
    if not structure then
        return
    end

    -- Send placement request to server
    if self._placeStructureFunction then
        local success, result = pcall(function()
            return self._placeStructureFunction:InvokeServer(structure.id, position)
        end)

        if success and result then
            print(string.format("[BuildUI] Successfully placed %s at %s", structure.name, tostring(position)))
        else
            warn(string.format("[BuildUI] Failed to place %s: %s", structure.name, tostring(result)))
        end
    else
        warn("[BuildUI] PlaceStructure remote not available")
    end

    self:_exitPlacementMode()
end

function BuildUI:_onPlacementCancelled()
    self:_exitPlacementMode()
end

function BuildUI:_exitPlacementMode()
    self._state = "IDLE"
    self._selectedStructure = nil

    -- Hide placement controls
    if self._placementControls then
        self._placementControls.Visible = false
    end

    -- Show build button
    if self._buildButton then
        self._buildButton.Visible = true
    end

    print("[BuildUI] Exited placement mode")
end

--[[
    Get the current build state
]]
function BuildUI:getState(): BuildState
    return self._state
end

--[[
    Check if the UI is currently in placement mode
]]
function BuildUI:isPlacing(): boolean
    return self._state == "PLACING"
end

function BuildUI:destroy()
    -- Disconnect all connections
    for _, connection in self._connections do
        connection:Disconnect()
    end
    self._connections = {}

    -- Destroy sub-modules
    if self._structureMenu then
        self._structureMenu:destroy()
        self._structureMenu = nil
    end

    if self._placementPreview then
        self._placementPreview:destroy()
        self._placementPreview = nil
    end

    -- Destroy UI
    if self._screenGui then
        self._screenGui:Destroy()
        self._screenGui = nil
    end

    print(string.format("[BuildUI v%s] Destroyed", BuildUI.VERSION))
end

return BuildUI
