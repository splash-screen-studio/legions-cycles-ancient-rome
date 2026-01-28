--!strict
--[[
    MapBoundary - Creates invisible glass walls around the map perimeter
    Prevents players from falling off the edges of the terrain.
]]

local MapBoundary = {}
MapBoundary.__index = MapBoundary
MapBoundary.VERSION = "1.0.0"

local WALL_HEIGHT = 200 -- Studs tall
local WALL_THICKNESS = 4 -- Studs thick
local WALL_TRANSPARENCY = 0.8 -- Mostly transparent
local WALL_COLOR = Color3.fromRGB(200, 230, 255) -- Light blue tint

type MapBoundaryConfig = {
    mapSize: number, -- Width/length of the map in studs
    wallHeight: number?,
    wallTransparency: number?,
}

function MapBoundary.new(config: MapBoundaryConfig)
    local self = setmetatable({}, MapBoundary)

    self.mapSize = config.mapSize
    self.wallHeight = config.wallHeight or WALL_HEIGHT
    self.wallTransparency = config.wallTransparency or WALL_TRANSPARENCY
    self.walls = {} :: {BasePart}

    print(string.format("[MapBoundary v%s] Initializing with map size %d", MapBoundary.VERSION, self.mapSize))

    return self
end

function MapBoundary:_createWall(name: string, position: Vector3, size: Vector3): BasePart
    local wall = Instance.new("Part")
    wall.Name = name
    wall.Size = size
    wall.Position = position
    wall.Anchored = true
    wall.CanCollide = true
    wall.Transparency = self.wallTransparency
    wall.Color = WALL_COLOR
    wall.Material = Enum.Material.Glass
    wall.CastShadow = false
    wall.Parent = workspace

    return wall
end

function MapBoundary:generate()
    print(string.format("[MapBoundary v%s] Creating boundary walls...", MapBoundary.VERSION))

    local halfSize = self.mapSize / 2
    local wallY = self.wallHeight / 2 -- Center the wall vertically

    -- Create folder for organization
    local boundaryFolder = Instance.new("Folder")
    boundaryFolder.Name = "MapBoundary"
    boundaryFolder.Parent = workspace

    -- North wall (positive Z)
    local northWall = self:_createWall(
        "NorthWall",
        Vector3.new(0, wallY, halfSize + WALL_THICKNESS / 2),
        Vector3.new(self.mapSize + WALL_THICKNESS * 2, self.wallHeight, WALL_THICKNESS)
    )
    northWall.Parent = boundaryFolder
    table.insert(self.walls, northWall)

    -- South wall (negative Z)
    local southWall = self:_createWall(
        "SouthWall",
        Vector3.new(0, wallY, -halfSize - WALL_THICKNESS / 2),
        Vector3.new(self.mapSize + WALL_THICKNESS * 2, self.wallHeight, WALL_THICKNESS)
    )
    southWall.Parent = boundaryFolder
    table.insert(self.walls, southWall)

    -- East wall (positive X)
    local eastWall = self:_createWall(
        "EastWall",
        Vector3.new(halfSize + WALL_THICKNESS / 2, wallY, 0),
        Vector3.new(WALL_THICKNESS, self.wallHeight, self.mapSize)
    )
    eastWall.Parent = boundaryFolder
    table.insert(self.walls, eastWall)

    -- West wall (negative X)
    local westWall = self:_createWall(
        "WestWall",
        Vector3.new(-halfSize - WALL_THICKNESS / 2, wallY, 0),
        Vector3.new(WALL_THICKNESS, self.wallHeight, self.mapSize)
    )
    westWall.Parent = boundaryFolder
    table.insert(self.walls, westWall)

    print(string.format("[MapBoundary v%s] Created 4 boundary walls (%d studs tall)", MapBoundary.VERSION, self.wallHeight))

    return true
end

function MapBoundary:destroy()
    for _, wall in self.walls do
        wall:Destroy()
    end
    self.walls = {}

    local boundaryFolder = workspace:FindFirstChild("MapBoundary")
    if boundaryFolder then
        boundaryFolder:Destroy()
    end
end

return MapBoundary
