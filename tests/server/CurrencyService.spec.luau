--!strict
--[[
    Tests for CurrencyService module
    Verifies server-side currency management structure
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/CurrencyService.luau")

describe("CurrencyService", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define CurrencyService table
        expect(string.find(moduleSource, "local CurrencyService = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "CurrencyService.__index = CurrencyService", 1, true)).toNotBeNil()

        -- Should return CurrencyService
        expect(string.find(moduleSource, "return CurrencyService", 1, true)).toNotBeNil()
    end)

    it("should require CurrencyConfig from shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("CurrencyConfig"))', 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function CurrencyService.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function CurrencyService:start()", 1, true)).toNotBeNil()
    end)

    it("should have getBalance method", function()
        expect(string.find(moduleSource, "function CurrencyService:getBalance(", 1, true)).toNotBeNil()
    end)

    it("should have canAfford method", function()
        expect(string.find(moduleSource, "function CurrencyService:canAfford(", 1, true)).toNotBeNil()
    end)

    it("should have addCurrency method", function()
        expect(string.find(moduleSource, "function CurrencyService:addCurrency(", 1, true)).toNotBeNil()
    end)

    it("should have spendCurrency method", function()
        expect(string.find(moduleSource, "function CurrencyService:spendCurrency(", 1, true)).toNotBeNil()
    end)

    it("should have getTransactionHistory method", function()
        expect(string.find(moduleSource, "function CurrencyService:getTransactionHistory(", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function CurrencyService:destroy()", 1, true)).toNotBeNil()
    end)

    it("should create RemoteFunction for getting balance", function()
        expect(string.find(moduleSource, "RemoteFunction", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "GET_BALANCE", 1, true)).toNotBeNil()
    end)

    it("should create RemoteEvent for balance updates", function()
        expect(string.find(moduleSource, "RemoteEvent", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BALANCE_UPDATED", 1, true)).toNotBeNil()
    end)

    it("should handle PlayerAdded event", function()
        expect(string.find(moduleSource, "PlayerAdded:Connect", 1, true)).toNotBeNil()
    end)

    it("should handle PlayerRemoving event", function()
        expect(string.find(moduleSource, "PlayerRemoving:Connect", 1, true)).toNotBeNil()
    end)

    it("should initialize players with starting balance", function()
        expect(string.find(moduleSource, "STARTING_BALANCE", 1, true)).toNotBeNil()
    end)

    it("should validate amounts for anti-cheat", function()
        expect(string.find(moduleSource, "_validateAmount", 1, true)).toNotBeNil()
    end)

    it("should check MAX_TRANSACTION limit", function()
        expect(string.find(moduleSource, "MAX_TRANSACTION", 1, true)).toNotBeNil()
    end)

    it("should check MAX_BALANCE limit", function()
        expect(string.find(moduleSource, "MAX_BALANCE", 1, true)).toNotBeNil()
    end)

    it("should check MIN_BALANCE limit", function()
        expect(string.find(moduleSource, "MIN_BALANCE", 1, true)).toNotBeNil()
    end)

    it("should record transactions", function()
        expect(string.find(moduleSource, "_recordTransaction", 1, true)).toNotBeNil()
    end)

    it("should notify clients of balance updates", function()
        expect(string.find(moduleSource, "_notifyBalanceUpdate", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "FireClient", 1, true)).toNotBeNil()
    end)

    it("should export Transaction type", function()
        expect(string.find(moduleSource, "export type Transaction", 1, true)).toNotBeNil()
    end)

    it("should export PlayerData type", function()
        expect(string.find(moduleSource, "export type PlayerData", 1, true)).toNotBeNil()
    end)

    it("should use strict mode", function()
        expect(string.find(moduleSource, "--!strict", 1, true)).toNotBeNil()
    end)

    it("should not have auto-executing code at module end", function()
        -- Check that module ends with return statement, not function calls
        local lines = {}
        for line in string.gmatch(moduleSource, "[^\n]+") do
            table.insert(lines, line)
        end

        -- Get last non-empty line
        local lastLine = ""
        for i = #lines, 1, -1 do
            local trimmed = string.match(lines[i], "^%s*(.-)%s*$") or ""
            if trimmed ~= "" then
                lastLine = trimmed
                break
            end
        end

        expect(lastLine).toBe("return CurrencyService")
    end)
end)
