--!strict
--[[
    Tests for CurrencyConfig module
    Verifies currency system constants and structure definitions
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/shared/CurrencyConfig.luau")

describe("CurrencyConfig", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define CurrencyConfig table
        expect(string.find(moduleSource, "local CurrencyConfig = {}", 1, true)).toNotBeNil()

        -- Should return CurrencyConfig
        expect(string.find(moduleSource, "return CurrencyConfig", 1, true)).toNotBeNil()
    end)

    it("should use Denarii as currency name", function()
        expect(string.find(moduleSource, 'CURRENCY_NAME = "Denarii"', 1, true)).toNotBeNil()
    end)

    it("should have currency symbol", function()
        expect(string.find(moduleSource, "CURRENCY_SYMBOL", 1, true)).toNotBeNil()
    end)

    it("should have starting balance of 100", function()
        expect(string.find(moduleSource, "STARTING_BALANCE = 100", 1, true)).toNotBeNil()
    end)

    it("should have EARNING table", function()
        expect(string.find(moduleSource, "CurrencyConfig.EARNING", 1, true)).toNotBeNil()
    end)

    it("should have TABERNA_INCOME earning config", function()
        expect(string.find(moduleSource, "TABERNA_INCOME", 1, true)).toNotBeNil()
    end)

    it("should have TABERNA_INTERVAL of 30 seconds", function()
        expect(string.find(moduleSource, "TABERNA_INTERVAL = 30", 1, true)).toNotBeNil()
    end)

    it("should have DAILY_LOGIN earning config", function()
        expect(string.find(moduleSource, "DAILY_LOGIN = 50", 1, true)).toNotBeNil()
    end)

    it("should have STRUCTURE_COMPLETION earning config", function()
        expect(string.find(moduleSource, "STRUCTURE_COMPLETION", 1, true)).toNotBeNil()
    end)

    it("should have COSTS table with structure categories", function()
        expect(string.find(moduleSource, "CurrencyConfig.COSTS", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "SMALL =", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "MEDIUM =", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "LARGE =", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "LANDMARK =", 1, true)).toNotBeNil()
    end)

    it("should have STRUCTURE_COSTS table", function()
        expect(string.find(moduleSource, "CurrencyConfig.STRUCTURE_COSTS", 1, true)).toNotBeNil()
    end)

    it("should have free first TABERNA (tutorial)", function()
        expect(string.find(moduleSource, "TABERNA = 0", 1, true)).toNotBeNil()
    end)

    it("should have DOMUS structure costs", function()
        expect(string.find(moduleSource, "DOMUS_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "DOMUS_MEDIUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "DOMUS_LARGE", 1, true)).toNotBeNil()
    end)

    it("should have TEMPLE structure costs", function()
        expect(string.find(moduleSource, "TEMPLE_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "TEMPLE_LARGE", 1, true)).toNotBeNil()
    end)

    it("should have LIMITS table for anti-cheat", function()
        expect(string.find(moduleSource, "CurrencyConfig.LIMITS", 1, true)).toNotBeNil()
    end)

    it("should have MAX_BALANCE limit", function()
        expect(string.find(moduleSource, "MAX_BALANCE =", 1, true)).toNotBeNil()
    end)

    it("should have MAX_TRANSACTION limit", function()
        expect(string.find(moduleSource, "MAX_TRANSACTION =", 1, true)).toNotBeNil()
    end)

    it("should have MIN_BALANCE of 0", function()
        expect(string.find(moduleSource, "MIN_BALANCE = 0", 1, true)).toNotBeNil()
    end)

    it("should have TRANSACTION_SOURCES table", function()
        expect(string.find(moduleSource, "CurrencyConfig.TRANSACTION_SOURCES", 1, true)).toNotBeNil()
    end)

    it("should have all required transaction sources", function()
        expect(string.find(moduleSource, 'STARTING_BALANCE = "starting_balance"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'TABERNA_INCOME = "taberna_income"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'STRUCTURE_COMPLETION = "structure_completion"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'DAILY_LOGIN = "daily_login"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'ACHIEVEMENT = "achievement"', 1, true)).toNotBeNil()
    end)

    it("should have TRANSACTION_TYPES table", function()
        expect(string.find(moduleSource, "CurrencyConfig.TRANSACTION_TYPES", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'EARN = "earn"', 1, true)).toNotBeNil()
        expect(string.find(moduleSource, 'SPEND = "spend"', 1, true)).toNotBeNil()
    end)

    it("should have REMOTES table for client-server communication", function()
        expect(string.find(moduleSource, "CurrencyConfig.REMOTES", 1, true)).toNotBeNil()
    end)

    it("should have all required remote names", function()
        expect(string.find(moduleSource, "GET_BALANCE =", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "BALANCE_UPDATED =", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "SPEND_REQUEST =", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return CurrencyConfig")
    end)
end)
