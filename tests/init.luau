--!strict
--[[
    Test Runner Entry Point
    Discovers and runs all .spec.luau test files
    Uses Lune's luau library to load modules with mocked Roblox globals
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local luau = require("@lune/luau")

-- Import test runner
local testRunner = require("./helpers/testRunner")
local describe = testRunner.describe
local it = testRunner.it
local expect = testRunner.expect

print("╔══════════════════════════════════════════════════╗")
print("║  Legions & Cycles: Ancient Rome - Test Suite     ║")
print("╚══════════════════════════════════════════════════╝")

-- Create mock Roblox environment inline
local function createMockEnv()
    -- Vector3 mock
    local Vector3Mock = {}
    Vector3Mock.__index = function(self, key)
        if key == "Magnitude" then
            return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
        elseif key == "Unit" then
            local mag = math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
            if mag > 0 then
                return setmetatable({ X = self.X / mag, Y = self.Y / mag, Z = self.Z / mag }, Vector3Mock)
            end
            return setmetatable({ X = 0, Y = 0, Z = 0 }, Vector3Mock)
        end
        return rawget(Vector3Mock, key)
    end

    Vector3Mock.__add = function(a, b)
        return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, Vector3Mock)
    end

    Vector3Mock.__sub = function(a, b)
        return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }, Vector3Mock)
    end

    Vector3Mock.__mul = function(a, b)
        if type(b) == "number" then
            return setmetatable({ X = a.X * b, Y = a.Y * b, Z = a.Z * b }, Vector3Mock)
        elseif type(a) == "number" then
            return setmetatable({ X = a * b.X, Y = a * b.Y, Z = a * b.Z }, Vector3Mock)
        end
        return setmetatable({ X = a.X * b.X, Y = a.Y * b.Y, Z = a.Z * b.Z }, Vector3Mock)
    end

    Vector3Mock.Dot = function(self, other)
        return self.X * other.X + self.Y * other.Y + self.Z * other.Z
    end

    Vector3Mock.Cross = function(self, other)
        return setmetatable({
            X = self.Y * other.Z - self.Z * other.Y,
            Y = self.Z * other.X - self.X * other.Z,
            Z = self.X * other.Y - self.Y * other.X,
        }, Vector3Mock)
    end

    local Vector3 = {
        new = function(x, y, z)
            return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3Mock)
        end,
        yAxis = setmetatable({ X = 0, Y = 1, Z = 0 }, Vector3Mock),
        xAxis = setmetatable({ X = 1, Y = 0, Z = 0 }, Vector3Mock),
        zAxis = setmetatable({ X = 0, Y = 0, Z = 1 }, Vector3Mock),
        zero = setmetatable({ X = 0, Y = 0, Z = 0 }, Vector3Mock),
        one = setmetatable({ X = 1, Y = 1, Z = 1 }, Vector3Mock),
    }

    -- CFrame mock
    local CFrameMock = {}
    CFrameMock.__index = CFrameMock

    CFrameMock.__mul = function(a, b)
        if getmetatable(b) == CFrameMock then
            return setmetatable({
                Position = Vector3.new(a.Position.X + b.Position.X, a.Position.Y + b.Position.Y, a.Position.Z + b.Position.Z),
                LookVector = a.LookVector,
                UpVector = a.UpVector,
                RightVector = a.RightVector,
            }, CFrameMock)
        end
        return a
    end

    CFrameMock.ToObjectSpace = function(self, other)
        return setmetatable({
            Position = Vector3.new(other.Position.X - self.Position.X, other.Position.Y - self.Position.Y, other.Position.Z - self.Position.Z),
            LookVector = Vector3.new(0, 0, -1),
            UpVector = Vector3.new(0, 1, 0),
            RightVector = Vector3.new(1, 0, 0),
        }, CFrameMock)
    end

    CFrameMock.ToWorldSpace = function(self, other)
        return setmetatable({
            Position = Vector3.new(self.Position.X + other.Position.X, self.Position.Y + other.Position.Y, self.Position.Z + other.Position.Z),
            LookVector = self.LookVector,
            UpVector = self.UpVector,
            RightVector = self.RightVector,
        }, CFrameMock)
    end

    CFrameMock.Lerp = function(self, other, alpha)
        return setmetatable({
            Position = Vector3.new(
                self.Position.X + (other.Position.X - self.Position.X) * alpha,
                self.Position.Y + (other.Position.Y - self.Position.Y) * alpha,
                self.Position.Z + (other.Position.Z - self.Position.Z) * alpha
            ),
            LookVector = self.LookVector,
            UpVector = self.UpVector,
            RightVector = self.RightVector,
        }, CFrameMock)
    end

    local CFrame = {
        new = function(x, y, z)
            return setmetatable({
                Position = Vector3.new(x or 0, y or 0, z or 0),
                LookVector = Vector3.new(0, 0, -1),
                UpVector = Vector3.new(0, 1, 0),
                RightVector = Vector3.new(1, 0, 0),
            }, CFrameMock)
        end,
        Angles = function(rx, ry, rz)
            return setmetatable({
                Position = Vector3.new(0, 0, 0),
                LookVector = Vector3.new(0, 0, -1),
                UpVector = Vector3.new(0, 1, 0),
                RightVector = Vector3.new(1, 0, 0),
            }, CFrameMock)
        end,
        fromMatrix = function(pos, right, up, back)
            return setmetatable({
                Position = pos,
                RightVector = right,
                UpVector = up,
                LookVector = Vector3.new(-back.X, -back.Y, -back.Z),
            }, CFrameMock)
        end,
        lookAt = function(from, target, up)
            local lookDir = Vector3.new(target.X - from.X, target.Y - from.Y, target.Z - from.Z)
            local mag = math.sqrt(lookDir.X * lookDir.X + lookDir.Y * lookDir.Y + lookDir.Z * lookDir.Z)
            local lv = if mag > 0 then Vector3.new(lookDir.X / mag, lookDir.Y / mag, lookDir.Z / mag) else Vector3.new(0, 0, -1)
            return setmetatable({
                Position = from,
                LookVector = lv,
                UpVector = Vector3.new(0, 1, 0),
                RightVector = Vector3.new(1, 0, 0),
            }, CFrameMock)
        end,
    }

    -- Color3 mock
    local Color3Mock = {}
    Color3Mock.__index = Color3Mock

    local Color3 = {
        new = function(r, g, b)
            return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3Mock)
        end,
        fromRGB = function(r, g, b)
            return setmetatable({ R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 }, Color3Mock)
        end,
    }

    -- Enum mock
    local Enum = {
        Material = {
            Grass = { Name = "Grass", Value = 1 },
            Rock = { Name = "Rock", Value = 2 },
            Marble = { Name = "Marble", Value = 3 },
            Brick = { Name = "Brick", Value = 4 },
            Concrete = { Name = "Concrete", Value = 5 },
            Wood = { Name = "Wood", Value = 6 },
            Sand = { Name = "Sand", Value = 7 },
            Slate = { Name = "Slate", Value = 8 },
            Cobblestone = { Name = "Cobblestone", Value = 9 },
            Granite = { Name = "Granite", Value = 10 },
        },
        RaycastFilterType = {
            Include = { Name = "Include", Value = 0 },
            Exclude = { Name = "Exclude", Value = 1 },
        },
    }

    -- RaycastParams mock
    local RaycastParamsMock = {}
    RaycastParamsMock.__index = RaycastParamsMock

    local RaycastParams = {
        new = function()
            return setmetatable({
                FilterType = Enum.RaycastFilterType.Exclude,
                FilterDescendantsInstances = {},
            }, RaycastParamsMock)
        end,
    }

    -- Workspace mock
    local workspace = {
        Gravity = 196.2,
        Terrain = {},
        Raycast = function(_, origin, direction, params)
            return nil
        end,
    }

    -- game mock
    local game = {
        GetService = function(_, serviceName)
            if serviceName == "Workspace" then
                return workspace
            end
            return {
                WaitForChild = function(_, name)
                    return {}
                end,
            }
        end,
    }

    -- task mock
    local taskMock = {
        wait = function(duration) end,
        spawn = function(fn) fn() end,
        defer = function(fn) fn() end,
        delay = function(duration, fn) fn() end,
        cancel = function(thread) end,
    }

    return {
        Vector3 = Vector3,
        CFrame = CFrame,
        Color3 = Color3,
        Enum = Enum,
        RaycastParams = RaycastParams,
        workspace = workspace,
        game = game,
        task = taskMock,
    }
end

-- Module cache for loaded modules
local moduleCache: { [string]: any } = {}

-- Load a module with mocked environment
local function loadModuleWithMocks(modulePath: string, mocks: any): any
    if moduleCache[modulePath] then
        return moduleCache[modulePath]
    end

    local source = fs.readFile(modulePath)
    if not source then
        error("Could not read file: " .. modulePath)
    end

    local bytecode = luau.compile(source)
    local fn = luau.load(bytecode, {
        debugName = modulePath,
    })

    -- Create environment with mocks
    local env = setmetatable({
        -- Roblox globals
        Vector3 = mocks.Vector3,
        CFrame = mocks.CFrame,
        Color3 = mocks.Color3,
        Enum = mocks.Enum,
        RaycastParams = mocks.RaycastParams,
        workspace = mocks.workspace,
        game = mocks.game,
        task = mocks.task,

        -- Lua globals
        print = print,
        warn = warn,
        error = error,
        assert = assert,
        type = type,
        typeof = function(v)
            local t = type(v)
            if t == "table" then
                local mt = getmetatable(v)
                if mt and mt.__type then
                    return mt.__type
                end
            end
            return t
        end,
        tostring = tostring,
        tonumber = tonumber,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        select = select,
        unpack = unpack,
        table = table,
        string = string,
        math = math,
        pcall = pcall,
        xpcall = xpcall,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        rawget = rawget,
        rawset = rawset,
        rawequal = rawequal,
        require = function(path: any): any
            -- Handle relative requires
            if type(path) == "string" then
                local dir = string.match(modulePath, "(.*/)")
                if dir and string.sub(path, 1, 2) == "./" then
                    path = dir .. string.sub(path, 3)
                elseif dir and string.sub(path, 1, 3) == "../" then
                    local parentDir = string.match(dir, "(.*/).*/")
                    if parentDir then
                        path = parentDir .. string.sub(path, 4)
                    end
                end

                -- Add .luau extension if needed
                if not string.match(path, "%.luau$") then
                    path = path .. ".luau"
                end

                return loadModuleWithMocks(path, mocks)
            end
            return nil
        end,
    }, { __index = _G })

    setfenv(fn, env)
    local result = fn()
    moduleCache[modulePath] = result
    return result
end

-- Create mocks
local mocks = createMockEnv()

-- Clear module cache for fresh tests
local function clearModuleCache()
    moduleCache = {}
end

-- Collect all spec files
local function collectSpecFiles(dir: string): { string }
    local files: { string } = {}

    if not fs.isDir(dir) then
        return files
    end

    for _, entry in fs.readDir(dir) do
        local path = dir .. "/" .. entry
        if fs.isDir(path) then
            local subFiles = collectSpecFiles(path)
            for _, subFile in subFiles do
                table.insert(files, subFile)
            end
        elseif string.match(entry, "%.spec%.luau$") then
            table.insert(files, path)
        end
    end

    return files
end

-- Wrap require to use our mock-aware loader
local function createMockRequire(specDir: string): (path: string) -> any
    return function(path: string): any
        -- Handle relative paths from spec file
        if string.sub(path, 1, 6) == "../../" then
            -- Relative to project root
            local resolved = string.sub(path, 7) .. ".luau"
            return loadModuleWithMocks(resolved, mocks)
        elseif string.sub(path, 1, 3) == "../" then
            local resolved = specDir .. "/../" .. string.sub(path, 4) .. ".luau"
            return loadModuleWithMocks(resolved, mocks)
        elseif string.sub(path, 1, 2) == "./" then
            local resolved = specDir .. "/" .. string.sub(path, 3) .. ".luau"
            return loadModuleWithMocks(resolved, mocks)
        end
        return nil
    end
end

-- Run all spec files
local function runAllTests()
    local testsDir = "tests"
    local specFiles = collectSpecFiles(testsDir)

    if #specFiles == 0 then
        print("\n⚠ No spec files found!")
        return
    end

    print(string.format("\nFound %d spec file(s):\n", #specFiles))
    for _, file in specFiles do
        print("  • " .. file)
    end

    print("\n" .. string.rep("─", 50))
    print("Running tests...")
    print(string.rep("─", 50))

    for _, specFile in specFiles do
        -- Clear cache between spec files
        clearModuleCache()

        -- Get the directory of the spec file
        local specDir = string.match(specFile, "(.*/)")

        -- Read and compile the spec file
        local source = fs.readFile(specFile)
        if not source then
            print("Could not read spec file: " .. specFile)
            continue
        end

        local bytecode = luau.compile(source)
        local fn = luau.load(bytecode, {
            debugName = specFile,
        })

        -- Create environment for spec file
        local mockRequire = createMockRequire(specDir or "tests/")
        local env = setmetatable({
            require = mockRequire,
            print = print,
            warn = warn,
            error = error,
            assert = assert,
            type = type,
            typeof = function(v)
                return type(v)
            end,
            tostring = tostring,
            tonumber = tonumber,
            pairs = pairs,
            ipairs = ipairs,
            next = next,
            select = select,
            unpack = unpack,
            table = table,
            string = string,
            math = math,
            pcall = pcall,
            xpcall = xpcall,
            setmetatable = setmetatable,
            getmetatable = getmetatable,
            rawget = rawget,
            rawset = rawset,
            rawequal = rawequal,
            Vector3 = mocks.Vector3,
            CFrame = mocks.CFrame,
            Color3 = mocks.Color3,
            Enum = mocks.Enum,
        }, { __index = _G })

        setfenv(fn, env)

        local success, specModule = pcall(fn)
        if not success then
            print(string.format("  ✗ Error loading %s: %s", specFile, tostring(specModule)))
            testRunner.describe("ERROR: " .. specFile, function()
                testRunner.it("should load without errors", function()
                    error(tostring(specModule))
                end)
            end)
        elseif type(specModule) == "function" then
            specModule(describe, it, expect)
        end
    end

    testRunner.printSummary()

    local results = testRunner.getResults()
    if results.failed > 0 then
        process.exit(1)
    end
end

runAllTests()
