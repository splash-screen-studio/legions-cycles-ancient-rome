--!strict
--[[
    CurrencyService - Server-side currency management with anti-cheat validation
    Manages player Denarii balances and validates all transactions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CurrencyConfig = require(Shared:WaitForChild("CurrencyConfig"))

local CurrencyService = {}
CurrencyService.__index = CurrencyService
CurrencyService.VERSION = "1.0.0"

-- Type definitions
export type Transaction = {
    amount: number,
    source: string,
    transactionType: string,
    timestamp: number,
    previousBalance: number,
    newBalance: number,
}

export type PlayerData = {
    balance: number,
    transactions: { Transaction },
    lastDailyLogin: number?,
}

function CurrencyService.new()
    local self = setmetatable({}, CurrencyService)

    -- In-memory storage (will be replaced with DataStore in #31)
    self._playerData = {} :: { [number]: PlayerData }

    -- Remote instances (created on start)
    self._getBalanceFunction = nil :: RemoteFunction?
    self._balanceUpdatedEvent = nil :: RemoteEvent?
    self._spendRequestFunction = nil :: RemoteFunction?

    print(string.format("[CurrencyService v%s] Initializing...", CurrencyService.VERSION))

    return self
end

function CurrencyService:start()
    -- Create Remotes folder if it doesn't exist
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    -- Create RemoteFunction for getting balance
    self._getBalanceFunction = Instance.new("RemoteFunction")
    self._getBalanceFunction.Name = CurrencyConfig.REMOTES.GET_BALANCE
    self._getBalanceFunction.Parent = remotesFolder
    self._getBalanceFunction.OnServerInvoke = function(player: Player)
        return self:getBalance(player)
    end

    -- Create RemoteEvent for balance updates
    self._balanceUpdatedEvent = Instance.new("RemoteEvent")
    self._balanceUpdatedEvent.Name = CurrencyConfig.REMOTES.BALANCE_UPDATED
    self._balanceUpdatedEvent.Parent = remotesFolder

    -- Create RemoteFunction for spend requests
    self._spendRequestFunction = Instance.new("RemoteFunction")
    self._spendRequestFunction.Name = CurrencyConfig.REMOTES.SPEND_REQUEST
    self._spendRequestFunction.Parent = remotesFolder
    self._spendRequestFunction.OnServerInvoke = function(player: Player, amount: number, purpose: string)
        return self:spendCurrency(player, amount, purpose)
    end

    -- Handle player join/leave
    Players.PlayerAdded:Connect(function(player)
        self:_initializePlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_savePlayerData(player)
    end)

    -- Initialize already-present players
    for _, player in Players:GetPlayers() do
        self:_initializePlayer(player)
    end

    print(string.format("[CurrencyService v%s] Started - Remotes created", CurrencyService.VERSION))
end

function CurrencyService:_initializePlayer(player: Player)
    local userId = player.UserId

    -- TODO: Load from DataStore (#31)
    -- For now, create fresh data with starting balance
    self._playerData[userId] = {
        balance = CurrencyConfig.STARTING_BALANCE,
        transactions = {},
        lastDailyLogin = nil,
    }

    -- Log initial transaction
    self:_recordTransaction(
        player,
        CurrencyConfig.STARTING_BALANCE,
        CurrencyConfig.TRANSACTION_SOURCES.STARTING_BALANCE,
        CurrencyConfig.TRANSACTION_TYPES.EARN,
        0
    )

    print(string.format("[CurrencyService] Player %s initialized with %d %s",
        player.Name,
        CurrencyConfig.STARTING_BALANCE,
        CurrencyConfig.CURRENCY_NAME
    ))

    -- Notify client of initial balance
    self:_notifyBalanceUpdate(player)
end

function CurrencyService:_savePlayerData(player: Player)
    local userId = player.UserId
    local data = self._playerData[userId]

    if data then
        -- TODO: Save to DataStore (#31)
        print(string.format("[CurrencyService] Player %s data saved (balance: %d)",
            player.Name,
            data.balance
        ))

        -- Clean up memory
        self._playerData[userId] = nil
    end
end

function CurrencyService:_recordTransaction(
    player: Player,
    amount: number,
    source: string,
    transactionType: string,
    previousBalance: number
)
    local userId = player.UserId
    local data = self._playerData[userId]

    if not data then
        return
    end

    local transaction: Transaction = {
        amount = amount,
        source = source,
        transactionType = transactionType,
        timestamp = os.time(),
        previousBalance = previousBalance,
        newBalance = data.balance,
    }

    table.insert(data.transactions, transaction)

    -- Keep only last 100 transactions in memory
    if #data.transactions > 100 then
        table.remove(data.transactions, 1)
    end
end

function CurrencyService:_notifyBalanceUpdate(player: Player)
    if self._balanceUpdatedEvent then
        local balance = self:getBalance(player)
        self._balanceUpdatedEvent:FireClient(player, balance)
    end
end

function CurrencyService:_validateAmount(amount: number): boolean
    if typeof(amount) ~= "number" then
        return false
    end

    if amount ~= amount then -- NaN check
        return false
    end

    if amount <= 0 then
        return false
    end

    if amount > CurrencyConfig.LIMITS.MAX_TRANSACTION then
        return false
    end

    if math.floor(amount) ~= amount then -- Must be integer
        return false
    end

    return true
end

--[[
    Get the current balance for a player
    @param player The player to get balance for
    @return The player's current Denarii balance
]]
function CurrencyService:getBalance(player: Player): number
    local userId = player.UserId
    local data = self._playerData[userId]

    if not data then
        return 0
    end

    return data.balance
end

--[[
    Check if a player can afford a purchase
    @param player The player to check
    @param cost The cost to check against
    @return true if the player can afford it
]]
function CurrencyService:canAfford(player: Player, cost: number): boolean
    if not self:_validateAmount(cost) then
        return false
    end

    return self:getBalance(player) >= cost
end

--[[
    Add currency to a player's balance (server-side only)
    @param player The player to add currency to
    @param amount The amount to add
    @param source The source of the currency (from CurrencyConfig.TRANSACTION_SOURCES)
    @return success, newBalance
]]
function CurrencyService:addCurrency(player: Player, amount: number, source: string): (boolean, number)
    if not self:_validateAmount(amount) then
        warn(string.format("[CurrencyService] Invalid amount: %s", tostring(amount)))
        return false, self:getBalance(player)
    end

    local userId = player.UserId
    local data = self._playerData[userId]

    if not data then
        warn(string.format("[CurrencyService] No data for player %s", player.Name))
        return false, 0
    end

    local previousBalance = data.balance
    local newBalance = math.min(data.balance + amount, CurrencyConfig.LIMITS.MAX_BALANCE)
    data.balance = newBalance

    self:_recordTransaction(
        player,
        amount,
        source,
        CurrencyConfig.TRANSACTION_TYPES.EARN,
        previousBalance
    )

    print(string.format("[CurrencyService] %s earned %d %s from %s (balance: %d -> %d)",
        player.Name,
        amount,
        CurrencyConfig.CURRENCY_NAME,
        source,
        previousBalance,
        newBalance
    ))

    self:_notifyBalanceUpdate(player)

    return true, newBalance
end

--[[
    Spend currency from a player's balance
    @param player The player spending currency
    @param amount The amount to spend
    @param purpose The reason for spending (e.g., structure name)
    @return success, newBalance
]]
function CurrencyService:spendCurrency(player: Player, amount: number, purpose: string): (boolean, number)
    if not self:_validateAmount(amount) then
        warn(string.format("[CurrencyService] Invalid spend amount: %s", tostring(amount)))
        return false, self:getBalance(player)
    end

    local userId = player.UserId
    local data = self._playerData[userId]

    if not data then
        warn(string.format("[CurrencyService] No data for player %s", player.Name))
        return false, 0
    end

    if not self:canAfford(player, amount) then
        warn(string.format("[CurrencyService] %s cannot afford %d (balance: %d)",
            player.Name,
            amount,
            data.balance
        ))
        return false, data.balance
    end

    local previousBalance = data.balance
    local newBalance = math.max(data.balance - amount, CurrencyConfig.LIMITS.MIN_BALANCE)
    data.balance = newBalance

    self:_recordTransaction(
        player,
        amount,
        purpose,
        CurrencyConfig.TRANSACTION_TYPES.SPEND,
        previousBalance
    )

    print(string.format("[CurrencyService] %s spent %d %s on %s (balance: %d -> %d)",
        player.Name,
        amount,
        CurrencyConfig.CURRENCY_NAME,
        purpose,
        previousBalance,
        newBalance
    ))

    self:_notifyBalanceUpdate(player)

    return true, newBalance
end

--[[
    Get the transaction history for a player
    @param player The player to get history for
    @return Array of recent transactions
]]
function CurrencyService:getTransactionHistory(player: Player): { Transaction }
    local userId = player.UserId
    local data = self._playerData[userId]

    if not data then
        return {}
    end

    return data.transactions
end

function CurrencyService:destroy()
    -- Save all player data
    for _, player in Players:GetPlayers() do
        self:_savePlayerData(player)
    end

    -- Clean up remotes
    if self._getBalanceFunction then
        self._getBalanceFunction:Destroy()
    end
    if self._balanceUpdatedEvent then
        self._balanceUpdatedEvent:Destroy()
    end
    if self._spendRequestFunction then
        self._spendRequestFunction:Destroy()
    end

    print(string.format("[CurrencyService v%s] Destroyed", CurrencyService.VERSION))
end

return CurrencyService
