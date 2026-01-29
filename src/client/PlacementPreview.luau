--!strict
--[[
    PlacementPreview - Shows ghost preview of structure during placement mode
    Creates a semi-transparent preview box that follows touch/mouse position
    Green = valid placement, Red = invalid placement
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BuildConfig = require(Shared:WaitForChild("BuildConfig"))
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

local PlacementPreview = {}
PlacementPreview.__index = PlacementPreview
PlacementPreview.VERSION = "1.0.0"

-- Preview constants
local PREVIEW_TRANSPARENCY = 0.5
local RAY_LENGTH = 1000

function PlacementPreview.new()
    local self = setmetatable({}, PlacementPreview)

    self._player = Players.LocalPlayer
    self._camera = workspace.CurrentCamera
    self._terrain = workspace.Terrain

    -- State
    self._isActive = false
    self._currentStructure = nil :: BuildConfig.StructureType?
    self._currentPosition = Vector3.new(0, 0, 0)
    self._isValidPlacement = false

    -- Preview model
    self._previewModel = nil :: Model?
    self._previewPart = nil :: Part?

    -- Connections
    self._connections = {} :: { RBXScriptConnection }

    -- Callbacks
    self._onConfirm = nil :: ((Vector3) -> ())?
    self._onCancel = nil :: (() -> ())?

    print(string.format("[PlacementPreview v%s] Initializing...", PlacementPreview.VERSION))

    return self
end

function PlacementPreview:start()
    print(string.format("[PlacementPreview v%s] Started", PlacementPreview.VERSION))
end

--[[
    Enter placement mode for a specific structure
    @param structure The structure type to place
    @param onConfirm Callback when placement is confirmed with position
    @param onCancel Callback when placement is cancelled
]]
function PlacementPreview:enterPlacementMode(
    structure: BuildConfig.StructureType,
    onConfirm: (Vector3) -> (),
    onCancel: () -> ()
)
    if self._isActive then
        self:exitPlacementMode()
    end

    self._currentStructure = structure
    self._onConfirm = onConfirm
    self._onCancel = onCancel
    self._isActive = true

    -- Create preview model
    self:_createPreviewModel(structure)

    -- Start update loop
    local updateConnection = RunService.RenderStepped:Connect(function()
        self:_updatePreviewPosition()
    end)
    table.insert(self._connections, updateConnection)

    print(string.format("[PlacementPreview] Entered placement mode for %s", structure.name))
end

--[[
    Exit placement mode and clean up
]]
function PlacementPreview:exitPlacementMode()
    self._isActive = false
    self._currentStructure = nil

    -- Disconnect all connections
    for _, connection in self._connections do
        connection:Disconnect()
    end
    self._connections = {}

    -- Destroy preview
    self:_destroyPreviewModel()

    print("[PlacementPreview] Exited placement mode")
end

--[[
    Confirm the current placement position
]]
function PlacementPreview:confirmPlacement()
    if not self._isActive or not self._isValidPlacement then
        return false
    end

    local position = self._currentPosition
    local onConfirm = self._onConfirm

    self:exitPlacementMode()

    if onConfirm then
        onConfirm(position)
    end

    return true
end

--[[
    Cancel placement mode
]]
function PlacementPreview:cancelPlacement()
    local onCancel = self._onCancel

    self:exitPlacementMode()

    if onCancel then
        onCancel()
    end
end

--[[
    Check if placement mode is active
]]
function PlacementPreview:isActive(): boolean
    return self._isActive
end

--[[
    Check if current position is valid for placement
]]
function PlacementPreview:isValidPlacement(): boolean
    return self._isValidPlacement
end

--[[
    Get the current placement position
]]
function PlacementPreview:getPosition(): Vector3
    return self._currentPosition
end

function PlacementPreview:_createPreviewModel(structure: BuildConfig.StructureType)
    -- Create a simple box preview model
    local model = Instance.new("Model")
    model.Name = "PlacementPreview"

    -- Create the main preview part
    local part = Instance.new("Part")
    part.Name = "PreviewPart"
    part.Size = structure.size
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Transparency = PREVIEW_TRANSPARENCY
    part.Material = Enum.Material.SmoothPlastic
    part.Color = BuildConfig.UI.COLORS.VALID
    part.Parent = model

    -- Add selection box for better visibility
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = part
    selectionBox.Color3 = BuildConfig.UI.COLORS.VALID
    selectionBox.LineThickness = 0.05
    selectionBox.Transparency = 0.3
    selectionBox.Parent = part

    model.PrimaryPart = part
    model.Parent = workspace

    self._previewModel = model
    self._previewPart = part
end

function PlacementPreview:_destroyPreviewModel()
    if self._previewModel then
        self._previewModel:Destroy()
        self._previewModel = nil
        self._previewPart = nil
    end
end

function PlacementPreview:_updatePreviewPosition()
    if not self._isActive or not self._previewModel or not self._previewPart then
        return
    end

    -- Get screen position from touch or mouse
    local screenPosition = self:_getPointerPosition()
    if not screenPosition then
        return
    end

    -- Raycast from camera through screen position to find terrain
    local worldPosition = self:_raycastToTerrain(screenPosition)
    if not worldPosition then
        return
    end

    -- Get terrain height at position
    local terrainHeight = TerrainUtils.getHeightAt(self._terrain, worldPosition.X, worldPosition.Z)

    -- Calculate structure position (center at terrain height + half height)
    local structure = self._currentStructure
    if not structure then
        return
    end

    local structureY = terrainHeight + (structure.size.Y / 2)
    local position = Vector3.new(worldPosition.X, structureY, worldPosition.Z)

    self._currentPosition = position

    -- Update preview position
    self._previewModel:PivotTo(CFrame.new(position))

    -- Validate placement
    self._isValidPlacement = self:_validatePlacement(worldPosition.X, worldPosition.Z, terrainHeight)

    -- Update preview color based on validity
    local color = if self._isValidPlacement then BuildConfig.UI.COLORS.VALID else BuildConfig.UI.COLORS.INVALID
    self._previewPart.Color = color

    -- Update selection box color
    local selectionBox = self._previewPart:FindFirstChild("SelectionBox") :: SelectionBox?
    if selectionBox then
        selectionBox.Color3 = color
    end
end

function PlacementPreview:_getPointerPosition(): Vector2?
    -- Check for touch input first (mobile-first)
    local touches = UserInputService:GetTouchPoints()
    if #touches > 0 then
        return Vector2.new(touches[1].X, touches[1].Y)
    end

    -- Fall back to mouse position (desktop)
    local mouse = self._player:GetMouse()
    if mouse then
        return Vector2.new(mouse.X, mouse.Y)
    end

    return nil
end

function PlacementPreview:_raycastToTerrain(screenPosition: Vector2): Vector3?
    local camera = self._camera
    if not camera then
        return nil
    end

    -- Create ray from camera through screen position
    local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)

    -- Raycast parameters - only hit terrain
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { self._terrain }

    local result = workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, raycastParams)

    if result then
        return result.Position
    end

    return nil
end

function PlacementPreview:_validatePlacement(x: number, z: number, terrainHeight: number): boolean
    -- Check terrain slope
    local isFlatEnough = TerrainUtils.isFlatEnoughDegrees(
        self._terrain,
        x,
        z,
        BuildConfig.PLACEMENT.MAX_SLOPE_DEGREES
    )

    if not isFlatEnough then
        return false
    end

    -- Check height above water level
    if terrainHeight < BuildConfig.PLACEMENT.WATER_LEVEL then
        return false
    end

    -- TODO: Add collision checks with other structures in future versions

    return true
end

function PlacementPreview:destroy()
    self:exitPlacementMode()

    print(string.format("[PlacementPreview v%s] Destroyed", PlacementPreview.VERSION))
end

return PlacementPreview
