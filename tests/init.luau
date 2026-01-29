--!strict
--[[
    Test Runner for Legions & Cycles
    Run with: lune run tests/init.luau
]]

local process = require("@lune/process")

-- Test tracking
local totalTests = 0
local passedTests = 0
local failedTests = 0
local currentSuite = ""

local function log(message: string)
    print(message)
end

local function describe(name: string, fn: () -> ())
    currentSuite = name
    log(string.format("\n[SUITE] %s", name))
    fn()
end

local function it(name: string, fn: () -> ())
    totalTests += 1
    local success, err = pcall(fn)
    if success then
        passedTests += 1
        log(string.format("  ✓ %s", name))
    else
        failedTests += 1
        log(string.format("  ✗ %s", name))
        log(string.format("    Error: %s", tostring(err)))
    end
end

local function expect(value: any)
    return {
        toBe = function(expected: any)
            if value ~= expected then
                error(string.format("Expected %s to be %s", tostring(value), tostring(expected)))
            end
        end,
        toEqual = function(expected: any)
            if value ~= expected then
                error(string.format("Expected %s to equal %s", tostring(value), tostring(expected)))
            end
        end,
        toBeTruthy = function()
            if not value then
                error(string.format("Expected %s to be truthy", tostring(value)))
            end
        end,
        toBeFalsy = function()
            if value then
                error(string.format("Expected %s to be falsy", tostring(value)))
            end
        end,
        toBeGreaterThan = function(expected: number)
            if typeof(value) ~= "number" or value <= expected then
                error(string.format("Expected %s to be greater than %s", tostring(value), tostring(expected)))
            end
        end,
        toBeLessThan = function(expected: number)
            if typeof(value) ~= "number" or value >= expected then
                error(string.format("Expected %s to be less than %s", tostring(value), tostring(expected)))
            end
        end,
        toContain = function(expected: string)
            if typeof(value) ~= "string" or not string.find(value, expected, 1, true) then
                error(string.format("Expected '%s' to contain '%s'", tostring(value), tostring(expected)))
            end
        end,
        toBeType = function(expected: string)
            if typeof(value) ~= expected then
                error(string.format("Expected type '%s' but got '%s'", expected, typeof(value)))
            end
        end,
        toBeNil = function()
            if value ~= nil then
                error(string.format("Expected nil but got %s", tostring(value)))
            end
        end,
        toNotBeNil = function()
            if value == nil then
                error("Expected value to not be nil")
            end
        end,
    }
end

-- Make test utilities global for test files
_G.describe = describe
_G.it = it
_G.expect = expect

log("===========================================")
log("  Legions & Cycles: Ancient Rome - Tests")
log("===========================================")

-- Run test suites
require("./shared/WorldPlan.spec")
require("./shared/FountainConfig.spec")
require("./shared/MaterialConfig.spec")
require("./server/WorldPlanGenerator.spec")
require("./server/SpawnManager.spec")
require("./server/WaterPool.spec")
require("./server/WaterFeatures.spec")
require("./server/RiverBuilder.spec")
require("./server/BridgeBuilder.spec")
require("./server/LandmarkBuilder.spec")
require("./server/AqueductBuilder.spec")
require("./server/RuinsBuilder.spec")
require("./server/SignpostBuilder.spec")
require("./server/TerrainMaterials.spec")
require("./client/MusicManager.spec")
require("./client/AtmosphereManager.spec")
require("./client/LanternManager.spec")

-- Print summary
log("\n===========================================")
log(string.format("  Results: %d/%d passed", passedTests, totalTests))
if failedTests > 0 then
    log(string.format("  FAILED: %d tests", failedTests))
    log("===========================================")
    process.exit(1)
else
    log("  All tests passed!")
    log("===========================================")
    process.exit(0)
end
