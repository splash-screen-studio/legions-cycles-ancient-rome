--!strict
--[[
    Test Runner - Simple test framework for Lune
    Provides describe/it/expect functions for BDD-style tests
]]

local TestRunner = {}

local results = {
    passed = 0,
    failed = 0,
    errors = {} :: { string },
}

local currentDescribe = ""
local currentIt = ""

-- Expect implementation
local function createExpectChain(value: any, isNegated: boolean)
    local function fail(message: string)
        local fullMessage = string.format("[FAIL] %s > %s: %s", currentDescribe, currentIt, message)
        table.insert(results.errors, fullMessage)
        results.failed += 1
    end

    local function pass()
        results.passed += 1
    end

    local function check(condition: boolean, message: string)
        local shouldPass = if isNegated then not condition else condition
        if shouldPass then
            pass()
        else
            local prefix = if isNegated then "Expected NOT to " else "Expected to "
            fail(prefix .. message)
        end
    end

    local beChain = {
        ok = function()
            check(value ~= nil, "be ok (not nil)")
        end,
        a = function(typeName: string)
            check(type(value) == typeName, string.format("be a %s, got %s", typeName, type(value)))
        end,
        truthy = function()
            check(value and true or false, "be truthy")
        end,
        falsy = function()
            check(not value, "be falsy")
        end,
        greaterThan = function(other: number)
            check(value > other, string.format("be greater than %s, got %s", tostring(other), tostring(value)))
        end,
        lessThan = function(other: number)
            check(value < other, string.format("be less than %s, got %s", tostring(other), tostring(value)))
        end,
        closeTo = function(other: number, tolerance: number?)
            local tol = tolerance or 0.001
            local diff = math.abs(value - other)
            check(diff <= tol, string.format("be close to %s (within %s), got %s (diff: %s)", tostring(other), tostring(tol), tostring(value), tostring(diff)))
        end,
    }

    local expectChain = {
        be = beChain,
        equal = function(other: any)
            check(value == other, string.format("equal %s, got %s", tostring(other), tostring(value)))
        end,
        throw = function()
            if type(value) ~= "function" then
                fail("Expected a function for throw check")
                return
            end
            local success = pcall(value)
            check(not success, "throw an error")
        end,
        beNil = function()
            check(value == nil, string.format("be nil, got %s", tostring(value)))
        end,
    }

    return expectChain
end

function TestRunner.expect(value: any)
    local toChain = createExpectChain(value, false)
    local neverChain = nil -- Lazy creation

    return {
        to = toChain,
        never = setmetatable({}, {
            __index = function(_, key)
                if not neverChain then
                    neverChain = createExpectChain(value, true)
                end
                return neverChain[key]
            end,
        }),
    }
end

function TestRunner.describe(name: string, fn: () -> ())
    currentDescribe = name
    print(string.format("\n  %s", name))
    local success, err = pcall(fn)
    if not success then
        table.insert(results.errors, string.format("[ERROR] %s: %s", name, tostring(err)))
        results.failed += 1
    end
    currentDescribe = ""
end

function TestRunner.it(name: string, fn: () -> ())
    currentIt = name
    local success, err = pcall(fn)
    if success then
        print(string.format("    ✓ %s", name))
    else
        print(string.format("    ✗ %s", name))
        table.insert(results.errors, string.format("[FAIL] %s > %s: %s", currentDescribe, currentIt, tostring(err)))
        results.failed += 1
    end
    currentIt = ""
end

function TestRunner.getResults(): { passed: number, failed: number, errors: { string } }
    return results
end

function TestRunner.reset()
    results.passed = 0
    results.failed = 0
    table.clear(results.errors)
end

function TestRunner.printSummary()
    print("\n" .. string.rep("─", 50))
    print(string.format("Tests: %d passed, %d failed", results.passed, results.failed))

    if #results.errors > 0 then
        print("\nErrors:")
        for _, err in results.errors do
            print("  " .. err)
        end
    end
    print(string.rep("─", 50))
end

return TestRunner
