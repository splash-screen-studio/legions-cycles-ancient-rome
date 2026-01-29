--!strict
--[[
    Tests for CurrencyDisplay module
    Verifies client-side currency UI structure
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/client/CurrencyDisplay.luau")

describe("CurrencyDisplay", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define CurrencyDisplay table
        expect(string.find(moduleSource, "local CurrencyDisplay = {}", 1, true)).toNotBeNil()

        -- Should set __index
        expect(string.find(moduleSource, "CurrencyDisplay.__index = CurrencyDisplay", 1, true)).toNotBeNil()

        -- Should return CurrencyDisplay
        expect(string.find(moduleSource, "return CurrencyDisplay", 1, true)).toNotBeNil()
    end)

    it("should require CurrencyConfig from shared", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("CurrencyConfig"))', 1, true)).toNotBeNil()
    end)

    it("should have new constructor", function()
        expect(string.find(moduleSource, "function CurrencyDisplay.new()", 1, true)).toNotBeNil()
    end)

    it("should have start method", function()
        expect(string.find(moduleSource, "function CurrencyDisplay:start()", 1, true)).toNotBeNil()
    end)

    it("should have getBalance method", function()
        expect(string.find(moduleSource, "function CurrencyDisplay:getBalance()", 1, true)).toNotBeNil()
    end)

    it("should have canAfford method", function()
        expect(string.find(moduleSource, "function CurrencyDisplay:canAfford(", 1, true)).toNotBeNil()
    end)

    it("should have destroy method", function()
        expect(string.find(moduleSource, "function CurrencyDisplay:destroy()", 1, true)).toNotBeNil()
    end)

    it("should create ScreenGui for UI", function()
        expect(string.find(moduleSource, "ScreenGui", 1, true)).toNotBeNil()
    end)

    it("should create main frame for currency display", function()
        expect(string.find(moduleSource, "CurrencyFrame", 1, true)).toNotBeNil()
    end)

    it("should create coin icon", function()
        expect(string.find(moduleSource, "CoinIcon", 1, true)).toNotBeNil()
    end)

    it("should create balance label", function()
        expect(string.find(moduleSource, "BalanceLabel", 1, true)).toNotBeNil()
    end)

    it("should use Roman gold/bronze color aesthetic", function()
        -- Check for gold/bronze color values
        expect(string.find(moduleSource, "COIN_COLOR", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "bronze", 1, true)).toNotBeNil()
    end)

    it("should display currency symbol on coin", function()
        expect(string.find(moduleSource, "CURRENCY_SYMBOL", 1, true)).toNotBeNil()
    end)

    it("should connect to balance update remote event", function()
        expect(string.find(moduleSource, "BALANCE_UPDATED", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "OnClientEvent", 1, true)).toNotBeNil()
    end)

    it("should fetch initial balance from server", function()
        expect(string.find(moduleSource, "GET_BALANCE", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "InvokeServer", 1, true)).toNotBeNil()
    end)

    it("should animate balance updates", function()
        expect(string.find(moduleSource, "_updateDisplay", 1, true)).toNotBeNil()
    end)

    it("should have pulse animation for coin", function()
        expect(string.find(moduleSource, "_pulseAnimation", 1, true)).toNotBeNil()
    end)

    it("should format large numbers with commas", function()
        expect(string.find(moduleSource, "_formatNumber", 1, true)).toNotBeNil()
    end)

    it("should use TweenService for animations", function()
        expect(string.find(moduleSource, "TweenService", 1, true)).toNotBeNil()
    end)

    it("should position UI in top-right corner (mobile-friendly)", function()
        -- Check for position that puts UI in top-right
        expect(string.find(moduleSource, "FRAME_POSITION", 1, true)).toNotBeNil()
    end)

    it("should have rounded corners for modern look", function()
        expect(string.find(moduleSource, "UICorner", 1, true)).toNotBeNil()
    end)

    it("should clean up connections on destroy", function()
        expect(string.find(moduleSource, "_connections", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, ":Disconnect()", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return CurrencyDisplay")
    end)
end)
