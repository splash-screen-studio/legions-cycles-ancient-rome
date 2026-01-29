--!strict
--[[
    BuildService - Server-side handler for structure placement
    Validates placement requests and creates structures
    Integrates with CurrencyService for cost deduction
]]

local _Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BuildConfig = require(Shared:WaitForChild("BuildConfig"))
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

local StructureModels = require(script.StructureModels)

local BuildService = {}
BuildService.__index = BuildService
BuildService.VERSION = "1.1.0"

-- Structure storage
export type PlacedStructure = {
    id: string,
    structureType: string,
    position: Vector3,
    model: Model,
    owner: number, -- Player UserId
    placedAt: number, -- Timestamp
}

function BuildService.new()
    local self = setmetatable({}, BuildService)

    self._terrain = workspace.Terrain

    -- Storage for placed structures
    self._structures = {} :: { [string]: PlacedStructure }
    self._structureCounter = 0

    -- Folder for placed structures
    self._structuresFolder = nil :: Folder?

    -- Remotes
    self._placeStructureFunction = nil :: RemoteFunction?
    self._placementResultEvent = nil :: RemoteEvent?

    -- Reference to CurrencyService (injected via setCurrencyService)
    self._currencyService = nil :: any

    print(string.format("[BuildService v%s] Initializing...", BuildService.VERSION))

    return self
end

--[[
    Set reference to CurrencyService for cost deduction
    @param currencyService The CurrencyService instance
]]
function BuildService:setCurrencyService(currencyService: any)
    self._currencyService = currencyService
end

function BuildService:start()
    -- Create structures folder
    self._structuresFolder = Instance.new("Folder")
    self._structuresFolder.Name = "PlayerStructures"
    self._structuresFolder.Parent = workspace

    -- Create Remotes folder if needed
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    -- Create RemoteFunction for placement requests
    self._placeStructureFunction = Instance.new("RemoteFunction")
    self._placeStructureFunction.Name = BuildConfig.REMOTES.PLACE_STRUCTURE
    self._placeStructureFunction.Parent = remotesFolder
    self._placeStructureFunction.OnServerInvoke = function(player: Player, structureId: string, position: Vector3)
        return self:_handlePlaceRequest(player, structureId, position)
    end

    -- Create RemoteEvent for placement results
    self._placementResultEvent = Instance.new("RemoteEvent")
    self._placementResultEvent.Name = BuildConfig.REMOTES.PLACEMENT_RESULT
    self._placementResultEvent.Parent = remotesFolder

    print(string.format("[BuildService v%s] Started - Remotes created", BuildService.VERSION))
end

function BuildService:_handlePlaceRequest(player: Player, structureId: string, position: Vector3): (boolean, string?)
    -- Validate input types
    if typeof(structureId) ~= "string" then
        return false, "Invalid structure ID"
    end

    if typeof(position) ~= "Vector3" then
        return false, "Invalid position"
    end

    -- Get structure config
    local structure = BuildConfig.getStructure(structureId)
    if not structure then
        return false, string.format("Unknown structure: %s", structureId)
    end

    -- Validate position (server-side check)
    local isValid, validationError = self:_validatePlacement(position, structure)
    if not isValid then
        return false, validationError
    end

    -- Check if player can afford
    if self._currencyService then
        local canAfford = self._currencyService:canAfford(player, structure.cost)
        if not canAfford then
            return false, "Insufficient Denarii"
        end

        -- Deduct cost
        local success, _ = self._currencyService:spendCurrency(player, structure.cost, structure.name)
        if not success then
            return false, "Failed to deduct cost"
        end
    end

    -- Create the structure
    local placedStructure = self:_createStructure(player, structure, position)
    if not placedStructure then
        -- Refund if creation failed
        if self._currencyService then
            self._currencyService:addCurrency(player, structure.cost, "refund_placement_failed")
        end
        return false, "Failed to create structure"
    end

    print(string.format("[BuildService] %s placed %s at %s (cost: %d)",
        player.Name,
        structure.name,
        tostring(position),
        structure.cost
    ))

    return true, nil
end

function BuildService:_validatePlacement(position: Vector3, _structure: BuildConfig.StructureType): (boolean, string?)
    local x, z = position.X, position.Z

    -- Check terrain height
    local terrainHeight = TerrainUtils.getHeightAt(self._terrain, x, z)

    -- Check slope
    local isFlatEnough = TerrainUtils.isFlatEnoughDegrees(
        self._terrain,
        x,
        z,
        BuildConfig.PLACEMENT.MAX_SLOPE_DEGREES
    )
    if not isFlatEnough then
        return false, "Terrain too steep"
    end

    -- Check water level
    if terrainHeight < BuildConfig.PLACEMENT.WATER_LEVEL then
        return false, "Cannot build in water"
    end

    -- Check bounds (basic sanity check)
    local mapSize = 1024 -- Matches server init
    local halfSize = mapSize / 2
    if math.abs(x) > halfSize or math.abs(z) > halfSize then
        return false, "Position out of bounds"
    end

    return true, nil
end

function BuildService:_createStructure(
    player: Player,
    structure: BuildConfig.StructureType,
    position: Vector3
): PlacedStructure?
    -- Generate unique ID
    self._structureCounter = self._structureCounter + 1
    local structureId = string.format("%s_%d_%d", structure.id, player.UserId, self._structureCounter)

    -- Get terrain height at position
    local terrainHeight = TerrainUtils.getHeightAt(self._terrain, position.X, position.Z)

    -- Create model
    local model = Instance.new("Model")
    model.Name = structureId

    -- Position at terrain height
    local structurePosition = Vector3.new(position.X, terrainHeight, position.Z)

    -- Use StructureModels to create the actual Roman structure
    local builder = StructureModels.getBuilder(structure.id)
    if builder then
        builder(structurePosition, structure.size, model)
    else
        -- Fallback: Create simple placeholder part (colored box) for unknown types
        local part = Instance.new("Part")
        part.Name = "Foundation"
        part.Size = structure.size
        part.Anchored = true
        part.CanCollide = true
        part.CastShadow = true
        part.Material = Enum.Material.Brick
        part.Color = self:_getStructureColor(structure.id)
        part.CFrame = CFrame.new(position.X, terrainHeight + (structure.size.Y / 2), position.Z)
        part.Parent = model
    end

    -- Find a part to use as primary part (first part in model)
    local primaryPart: Part? = nil
    for _, child in model:GetChildren() do
        if child:IsA("Part") then
            primaryPart = child :: Part
            break
        end
    end

    -- Add name label to primary part if found
    if primaryPart then
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "NameTag"
        billboardGui.Size = UDim2.new(0, 100, 0, 30)
        billboardGui.StudsOffset = Vector3.new(0, structure.size.Y / 2 + 2, 0)
        billboardGui.AlwaysOnTop = false
        billboardGui.Parent = primaryPart

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 0.5
        nameLabel.BackgroundColor3 = Color3.new(0, 0, 0)
        nameLabel.Text = structure.name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = billboardGui

        model.PrimaryPart = primaryPart
    end

    model.Parent = self._structuresFolder

    -- Create record
    local placedStructure: PlacedStructure = {
        id = structureId,
        structureType = structure.id,
        position = structurePosition,
        model = model,
        owner = player.UserId,
        placedAt = os.time(),
    }

    self._structures[structureId] = placedStructure

    return placedStructure
end

function BuildService:_getStructureColor(structureId: string): Color3
    if structureId == "DOMUS" then
        return Color3.fromRGB(194, 178, 128) -- Sand/Beige
    elseif structureId == "TABERNA" then
        return Color3.fromRGB(139, 90, 43) -- Terracotta
    elseif structureId == "TEMPLE" then
        return Color3.fromRGB(240, 234, 214) -- Marble white
    elseif structureId == "WALL" then
        return Color3.fromRGB(128, 128, 128) -- Gray stone
    end
    return Color3.fromRGB(180, 160, 140) -- Default
end

--[[
    Get all structures placed by a player
]]
function BuildService:getPlayerStructures(player: Player): { PlacedStructure }
    local result = {}
    for _, structure in self._structures do
        if structure.owner == player.UserId then
            table.insert(result, structure)
        end
    end
    return result
end

--[[
    Get total structure count
]]
function BuildService:getStructureCount(): number
    local count = 0
    for _ in self._structures do
        count = count + 1
    end
    return count
end

function BuildService:destroy()
    -- Clean up structures
    if self._structuresFolder then
        self._structuresFolder:Destroy()
        self._structuresFolder = nil
    end

    -- Clean up remotes
    if self._placeStructureFunction then
        self._placeStructureFunction:Destroy()
    end
    if self._placementResultEvent then
        self._placementResultEvent:Destroy()
    end

    self._structures = {}

    print(string.format("[BuildService v%s] Destroyed", BuildService.VERSION))
end

return BuildService
