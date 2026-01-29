--!strict
--[[
    ProgressionService - Server-side XP and level management

    Responsibilities:
    - Track player XP and levels (server-authoritative)
    - Validate XP gains
    - Send XP updates to clients via RemoteEvents
    - Check unlock availability

    All XP modifications MUST go through this service to prevent exploits.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProgressionConfig = require(Shared:WaitForChild("ProgressionConfig"))

local ProgressionService = {}
ProgressionService.__index = ProgressionService
ProgressionService.VERSION = "1.0.0"

-- Type definitions
export type PlayerProgress = {
    xp: number,
    level: number,
    rank: ProgressionConfig.RankInfo,
}

export type ProgressionServiceInstance = {
    _playerData: { [Player]: PlayerProgress },
    _xpChangedEvent: RemoteEvent,
    _levelUpEvent: RemoteEvent,
    _requestProgressEvent: RemoteFunction,
    _connections: { RBXScriptConnection },
}

function ProgressionService.new(): ProgressionServiceInstance
    print(string.format("[ProgressionService v%s] Initializing...", ProgressionService.VERSION))

    local self = setmetatable({}, ProgressionService) :: ProgressionServiceInstance
    self._playerData = {}
    self._connections = {}

    -- Create RemoteEvents folder in ReplicatedStorage
    local eventsFolder = ReplicatedStorage:FindFirstChild("ProgressionEvents")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "ProgressionEvents"
        eventsFolder.Parent = ReplicatedStorage
    end

    -- Create RemoteEvent for XP changes
    local xpChangedEvent = eventsFolder:FindFirstChild("XPChanged")
    if not xpChangedEvent then
        xpChangedEvent = Instance.new("RemoteEvent")
        xpChangedEvent.Name = "XPChanged"
        xpChangedEvent.Parent = eventsFolder
    end
    self._xpChangedEvent = xpChangedEvent :: RemoteEvent

    -- Create RemoteEvent for level ups
    local levelUpEvent = eventsFolder:FindFirstChild("LevelUp")
    if not levelUpEvent then
        levelUpEvent = Instance.new("RemoteEvent")
        levelUpEvent.Name = "LevelUp"
        levelUpEvent.Parent = eventsFolder
    end
    self._levelUpEvent = levelUpEvent :: RemoteEvent

    -- Create RemoteFunction for requesting progress
    local requestProgressEvent = eventsFolder:FindFirstChild("RequestProgress")
    if not requestProgressEvent then
        requestProgressEvent = Instance.new("RemoteFunction")
        requestProgressEvent.Name = "RequestProgress"
        requestProgressEvent.Parent = eventsFolder
    end
    self._requestProgressEvent = requestProgressEvent :: RemoteFunction

    return self
end

function ProgressionService:start()
    print(string.format("[ProgressionService v%s] Starting...", ProgressionService.VERSION))

    -- Handle player joining
    local playerAddedConn = Players.PlayerAdded:Connect(function(player: Player)
        self:_initializePlayer(player)
    end)
    table.insert(self._connections, playerAddedConn)

    -- Handle player leaving
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player: Player)
        self:_cleanupPlayer(player)
    end)
    table.insert(self._connections, playerRemovingConn)

    -- Handle progress requests
    self._requestProgressEvent.OnServerInvoke = function(player: Player)
        return self:_getPlayerProgressData(player)
    end

    -- Initialize already-connected players (for late initialization)
    for _, player in ipairs(Players:GetPlayers()) do
        if not self._playerData[player] then
            self:_initializePlayer(player)
        end
    end

    print(string.format("[ProgressionService v%s] Started successfully", ProgressionService.VERSION))
end

function ProgressionService:_initializePlayer(player: Player)
    print(string.format("[ProgressionService] Initializing player: %s", player.Name))

    -- TODO: Load saved data from DataStore in future implementation
    -- For now, start players at level 1 with 0 XP
    local startingXP = 0
    local startingLevel = 1
    local startingRank = ProgressionConfig.getRankForLevel(startingLevel)

    self._playerData[player] = {
        xp = startingXP,
        level = startingLevel,
        rank = startingRank,
    }

    -- Send initial progress to client
    self._xpChangedEvent:FireClient(player, self:_getPlayerProgressData(player))
end

function ProgressionService:_cleanupPlayer(player: Player)
    print(string.format("[ProgressionService] Cleaning up player: %s", player.Name))

    -- TODO: Save data to DataStore in future implementation
    self._playerData[player] = nil
end

function ProgressionService:_getPlayerProgressData(player: Player): PlayerProgress?
    return self._playerData[player]
end

-- Get current level for a player
function ProgressionService:getLevel(player: Player): number
    local data = self._playerData[player]
    if data then
        return data.level
    end
    return 1 -- Default level
end

-- Get current XP for a player
function ProgressionService:getXP(player: Player): number
    local data = self._playerData[player]
    if data then
        return data.xp
    end
    return 0 -- Default XP
end

-- Get current rank for a player
function ProgressionService:getRank(player: Player): ProgressionConfig.RankInfo
    local data = self._playerData[player]
    if data then
        return data.rank
    end
    return ProgressionConfig.getRankForLevel(1) -- Default rank
end

-- Add XP to a player (server-authoritative)
function ProgressionService:addXP(player: Player, amount: number, reason: string?)
    if amount <= 0 then
        warn(string.format("[ProgressionService] Invalid XP amount: %d", amount))
        return
    end

    local data = self._playerData[player]
    if not data then
        warn(string.format("[ProgressionService] No data for player: %s", player.Name))
        return
    end

    local oldLevel = data.level
    local oldXP = data.xp

    -- Add XP
    data.xp = data.xp + amount

    -- Recalculate level
    data.level = ProgressionConfig.getLevelFromXP(data.xp)

    -- Update rank if level changed
    if data.level ~= oldLevel then
        data.rank = ProgressionConfig.getRankForLevel(data.level)
    end

    local reasonText = reason or "unspecified"
    print(string.format(
        "[ProgressionService] %s gained %d XP (%s): %d -> %d (Level %d)",
        player.Name, amount, reasonText, oldXP, data.xp, data.level
    ))

    -- Notify client of XP change
    self._xpChangedEvent:FireClient(player, self:_getPlayerProgressData(player))

    -- Check for level up
    if data.level > oldLevel then
        self:_onLevelUp(player, oldLevel, data.level)
    end
end

function ProgressionService:_onLevelUp(player: Player, oldLevel: number, newLevel: number)
    print(string.format(
        "[ProgressionService] %s leveled up: %d -> %d",
        player.Name, oldLevel, newLevel
    ))

    local newRank = ProgressionConfig.getRankForLevel(newLevel)
    local oldRank = ProgressionConfig.getRankForLevel(oldLevel)

    -- Collect all new unlocks
    local newUnlocks: { ProgressionConfig.Unlock } = {}
    for level = oldLevel + 1, newLevel do
        local levelUnlocks = ProgressionConfig.getUnlocksForLevel(level)
        for _, unlock in ipairs(levelUnlocks) do
            table.insert(newUnlocks, unlock)
        end
    end

    -- Notify client of level up with details
    self._levelUpEvent:FireClient(player, {
        oldLevel = oldLevel,
        newLevel = newLevel,
        oldRank = oldRank,
        newRank = newRank,
        rankChanged = oldRank.name ~= newRank.name,
        newUnlocks = newUnlocks,
    })
end

-- Get all unlocks available to a player
function ProgressionService:getUnlocks(player: Player): { ProgressionConfig.Unlock }
    local level = self:getLevel(player)
    return ProgressionConfig.getUnlocksUpToLevel(level)
end

-- Check if a player has unlocked a specific item
function ProgressionService:hasUnlock(player: Player, unlockId: string): boolean
    local level = self:getLevel(player)
    return ProgressionConfig.isUnlockAvailable(unlockId, level)
end

-- Get XP needed for next level
function ProgressionService:getXPForNextLevel(player: Player): number
    local data = self._playerData[player]
    if not data then
        return ProgressionConfig.getXPForLevel(2) -- XP to reach level 2
    end

    return ProgressionConfig.getXPForLevel(data.level + 1)
end

-- Get progress percentage to next level
function ProgressionService:getProgressToNextLevel(player: Player): number
    local data = self._playerData[player]
    if not data then
        return 0
    end

    local currentLevelXP = ProgressionConfig.getXPForLevel(data.level)
    local nextLevelXP = ProgressionConfig.getXPForLevel(data.level + 1)
    local xpIntoLevel = data.xp - currentLevelXP
    local xpNeeded = nextLevelXP - currentLevelXP

    if xpNeeded <= 0 then
        return 1 -- At max level
    end

    return math.clamp(xpIntoLevel / xpNeeded, 0, 1)
end

function ProgressionService:destroy()
    print(string.format("[ProgressionService v%s] Destroying...", ProgressionService.VERSION))

    -- Disconnect all connections
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}

    -- Clear player data
    self._playerData = {}
end

return ProgressionService
