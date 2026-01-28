--!strict
--[[
    Mock Roblox globals for Lune testing
    Provides minimal implementations of Roblox types and services
]]

local mock = {}

-- Vector3 mock
local Vector3Mock = {}
Vector3Mock.__index = Vector3Mock

function Vector3Mock.new(x: number?, y: number?, z: number?)
    local self = setmetatable({
        X = x or 0,
        Y = y or 0,
        Z = z or 0,
    }, Vector3Mock)
    return self
end

function Vector3Mock.__add(a: any, b: any)
    return Vector3Mock.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end

function Vector3Mock.__sub(a: any, b: any)
    return Vector3Mock.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end

function Vector3Mock.__mul(a: any, b: any)
    if type(b) == "number" then
        return Vector3Mock.new(a.X * b, a.Y * b, a.Z * b)
    elseif type(a) == "number" then
        return Vector3Mock.new(a * b.X, a * b.Y, a * b.Z)
    end
    return Vector3Mock.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end

function Vector3Mock.__index(self: any, key: string)
    if key == "Magnitude" then
        return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
    elseif key == "Unit" then
        local mag = self.Magnitude
        if mag > 0 then
            return Vector3Mock.new(self.X / mag, self.Y / mag, self.Z / mag)
        end
        return Vector3Mock.new(0, 0, 0)
    end
    return rawget(Vector3Mock, key)
end

function Vector3Mock:Dot(other: any): number
    return self.X * other.X + self.Y * other.Y + self.Z * other.Z
end

function Vector3Mock:Cross(other: any)
    return Vector3Mock.new(
        self.Y * other.Z - self.Z * other.Y,
        self.Z * other.X - self.X * other.Z,
        self.X * other.Y - self.Y * other.X
    )
end

-- Add static properties
local Vector3 = setmetatable({
    new = Vector3Mock.new,
    yAxis = Vector3Mock.new(0, 1, 0),
    xAxis = Vector3Mock.new(1, 0, 0),
    zAxis = Vector3Mock.new(0, 0, 1),
    zero = Vector3Mock.new(0, 0, 0),
    one = Vector3Mock.new(1, 1, 1),
}, {
    __call = function(_, x, y, z)
        return Vector3Mock.new(x, y, z)
    end,
})

-- CFrame mock
local CFrameMock = {}
CFrameMock.__index = CFrameMock

function CFrameMock.new(x: number?, y: number?, z: number?)
    local self = setmetatable({
        Position = Vector3Mock.new(x or 0, y or 0, z or 0),
        LookVector = Vector3Mock.new(0, 0, -1),
        UpVector = Vector3Mock.new(0, 1, 0),
        RightVector = Vector3Mock.new(1, 0, 0),
    }, CFrameMock)
    return self
end

function CFrameMock.__mul(a: any, b: any)
    -- Simplified CFrame multiplication
    if getmetatable(b) == CFrameMock then
        return CFrameMock.new(
            a.Position.X + b.Position.X,
            a.Position.Y + b.Position.Y,
            a.Position.Z + b.Position.Z
        )
    end
    return a
end

function CFrameMock.Angles(rx: number?, ry: number?, rz: number?)
    return CFrameMock.new(0, 0, 0)
end

function CFrameMock.fromMatrix(pos: any, right: any, up: any, back: any)
    local cf = CFrameMock.new(pos.X, pos.Y, pos.Z)
    cf.RightVector = right
    cf.UpVector = up
    cf.LookVector = Vector3Mock.new(-back.X, -back.Y, -back.Z)
    return cf
end

function CFrameMock.lookAt(from: any, target: any, up: any?)
    local cf = CFrameMock.new(from.X, from.Y, from.Z)
    local lookDir = Vector3Mock.new(target.X - from.X, target.Y - from.Y, target.Z - from.Z)
    local mag = lookDir.Magnitude
    if mag > 0 then
        cf.LookVector = Vector3Mock.new(lookDir.X / mag, lookDir.Y / mag, lookDir.Z / mag)
    end
    return cf
end

function CFrameMock:ToObjectSpace(other: any)
    return CFrameMock.new(
        other.Position.X - self.Position.X,
        other.Position.Y - self.Position.Y,
        other.Position.Z - self.Position.Z
    )
end

function CFrameMock:ToWorldSpace(other: any)
    return CFrameMock.new(
        self.Position.X + other.Position.X,
        self.Position.Y + other.Position.Y,
        self.Position.Z + other.Position.Z
    )
end

function CFrameMock:Lerp(other: any, alpha: number)
    return CFrameMock.new(
        self.Position.X + (other.Position.X - self.Position.X) * alpha,
        self.Position.Y + (other.Position.Y - self.Position.Y) * alpha,
        self.Position.Z + (other.Position.Z - self.Position.Z) * alpha
    )
end

local CFrame = setmetatable({
    new = CFrameMock.new,
    Angles = CFrameMock.Angles,
    fromMatrix = CFrameMock.fromMatrix,
    lookAt = CFrameMock.lookAt,
}, {
    __call = function(_, x, y, z)
        return CFrameMock.new(x, y, z)
    end,
})

-- Color3 mock
local Color3Mock = {}
Color3Mock.__index = Color3Mock

function Color3Mock.new(r: number?, g: number?, b: number?)
    return setmetatable({
        R = r or 0,
        G = g or 0,
        B = b or 0,
    }, Color3Mock)
end

function Color3Mock.fromRGB(r: number?, g: number?, b: number?)
    return Color3Mock.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
end

local Color3 = setmetatable({
    new = Color3Mock.new,
    fromRGB = Color3Mock.fromRGB,
}, {
    __call = function(_, r, g, b)
        return Color3Mock.new(r, g, b)
    end,
})

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
local RaycastParams = {}
RaycastParams.__index = RaycastParams

function RaycastParams.new()
    return setmetatable({
        FilterType = Enum.RaycastFilterType.Exclude,
        FilterDescendantsInstances = {},
    }, RaycastParams)
end

-- Workspace mock
local workspace = {
    Gravity = 196.2,
    Terrain = {},
    Raycast = function(_, origin, direction, params)
        -- Return nil for mock raycasts (no terrain)
        return nil
    end,
}

-- game mock
local game = {
    GetService = function(_, serviceName: string)
        if serviceName == "Workspace" then
            return workspace
        end
        return {
            WaitForChild = function(_, name: string)
                return {}
            end,
        }
    end,
}

-- task mock
local taskMock = {
    wait = function(duration: number?)
        -- No-op in tests
    end,
    spawn = function(fn: () -> ())
        -- Execute immediately in tests
        fn()
    end,
    defer = function(fn: () -> ())
        fn()
    end,
    delay = function(duration: number, fn: () -> ())
        fn()
    end,
    cancel = function(thread: any)
        -- No-op
    end,
}

-- Export all mocks
mock.Vector3 = Vector3
mock.CFrame = CFrame
mock.Color3 = Color3
mock.Enum = Enum
mock.RaycastParams = RaycastParams
mock.workspace = workspace
mock.game = game
mock.task = taskMock

-- Function to inject mocks into global environment
function mock.inject()
    _G.Vector3 = Vector3
    _G.CFrame = CFrame
    _G.Color3 = Color3
    _G.Enum = Enum
    _G.RaycastParams = RaycastParams
    _G.workspace = workspace
    _G.game = game
    _G.task = taskMock
end

return mock
