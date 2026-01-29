--!strict
--[[
    WaterPool - Reusable water pool module with part-built walls
    CRITICAL: Water terrain ONLY exists within part-built pool walls
    Based on BRicey techniques for terrain and part management

    Containment Rules:
    1. Walls extend ABOVE water surface (rimHeight studs above)
    2. Floor is solid part-based
    3. ALL terrain inside walls is cleared (including above water)
    4. Water terrain fills only up to water surface level
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaterPool = {}
WaterPool.__index = WaterPool
WaterPool.VERSION = "2.2.0"

-- Type definitions
export type PoolConfig = {
    position: Vector3, -- Center X, Z (Y determined from terrain)
    size: Vector3, -- Width (X), Depth (Y), Length (Z)
    wallMaterial: Enum.Material,
    wallColor: Color3,
    wallThickness: number?,
    rimHeight: number?, -- How much walls extend above water surface (default: 2)
    name: string?,
}

export type WaterPoolInstance = typeof(setmetatable(
    {} :: {
        config: PoolConfig,
        parts: { Part },
        folder: Folder?,
        terrain: Terrain,
        terrainUtils: any,
    },
    WaterPool
))

function WaterPool.new(config: PoolConfig): WaterPoolInstance
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

    local self = setmetatable({}, WaterPool)
    self.config = config
    self.parts = {} :: { Part }
    self.folder = nil :: Folder?
    self.terrain = workspace.Terrain
    self.terrainUtils = TerrainUtils

    print(string.format("[WaterPool v%s] Created pool config at %.0f, %.0f", WaterPool.VERSION, config.position.X, config.position.Z))
    return self
end

function WaterPool:build(): Folder
    local config = self.config
    local pos = config.position
    local size = config.size
    local thickness = config.wallThickness or 2
    local rimHeight = config.rimHeight or 2 -- Walls extend above water

    -- CRITICAL: Query terrain height at center position
    local terrainY = self.terrainUtils.getHeightAt(self.terrain, pos.X, pos.Z)
    local poolBottom = terrainY - size.Y
    local wallTop = terrainY + rimHeight -- Walls extend above terrain
    -- Water surface should be near the rim (1-2 studs below wall top) so fountain looks full
    local waterSurface = wallTop - 1 -- Water fills to 1 stud below rim

    -- Create folder for organization
    local folderName = config.name or string.format("WaterPool_%.0f_%.0f", pos.X, pos.Z)
    local folder = Instance.new("Folder")
    folder.Name = folderName
    folder.Parent = workspace
    self.folder = folder

    -- Total wall height (from pool bottom to above water)
    local totalWallHeight = size.Y + rimHeight

    -- Create bottom (floor of pool)
    local bottom = self:_createWall(
        "Bottom",
        Vector3.new(pos.X, poolBottom - thickness / 2, pos.Z),
        Vector3.new(size.X + thickness * 2, thickness, size.Z + thickness * 2)
    )
    bottom.Parent = folder

    -- Create 4 walls (extend from pool bottom to above water surface)
    -- North wall (+Z side)
    local northWall = self:_createWall(
        "NorthWall",
        Vector3.new(pos.X, poolBottom + totalWallHeight / 2, pos.Z + size.Z / 2 + thickness / 2),
        Vector3.new(size.X + thickness * 2, totalWallHeight, thickness)
    )
    northWall.Parent = folder

    -- South wall (-Z side)
    local southWall = self:_createWall(
        "SouthWall",
        Vector3.new(pos.X, poolBottom + totalWallHeight / 2, pos.Z - size.Z / 2 - thickness / 2),
        Vector3.new(size.X + thickness * 2, totalWallHeight, thickness)
    )
    southWall.Parent = folder

    -- East wall (+X side)
    local eastWall = self:_createWall(
        "EastWall",
        Vector3.new(pos.X + size.X / 2 + thickness / 2, poolBottom + totalWallHeight / 2, pos.Z),
        Vector3.new(thickness, totalWallHeight, size.Z)
    )
    eastWall.Parent = folder

    -- West wall (-X side)
    local westWall = self:_createWall(
        "WestWall",
        Vector3.new(pos.X - size.X / 2 - thickness / 2, poolBottom + totalWallHeight / 2, pos.Z),
        Vector3.new(thickness, totalWallHeight, size.Z)
    )
    westWall.Parent = folder

    -- CRITICAL: Clear ALL terrain inside walls (including air above water)
    -- This ensures no terrain leaks through the walls
    -- NOTE: Clear below floor part (poolBottom - thickness) to prevent grass showing through
    local clearMinCorner = Vector3.new(
        pos.X - size.X / 2,
        poolBottom - thickness,
        pos.Z - size.Z / 2
    )
    local clearMaxCorner = Vector3.new(
        pos.X + size.X / 2,
        wallTop, -- Clear up to top of walls
        pos.Z + size.Z / 2
    )
    local clearRegion = Region3.new(clearMinCorner, clearMaxCorner)
    self.terrain:FillRegion(clearRegion, 4, Enum.Material.Air)

    -- Fill water region only (from pool bottom to water surface near rim)
    local waterMinCorner = Vector3.new(
        pos.X - size.X / 2,
        poolBottom,
        pos.Z - size.Z / 2
    )
    local waterMaxCorner = Vector3.new(
        pos.X + size.X / 2,
        waterSurface, -- Water fills to near the rim so fountain looks full
        pos.Z + size.Z / 2
    )
    local waterRegion = Region3.new(waterMinCorner, waterMaxCorner)

    -- Resolution of 4 studs for terrain filling
    self.terrain:FillRegion(waterRegion, 4, Enum.Material.Water)

    print(string.format(
        "[WaterPool v%s] Built pool '%s' at (%.0f, %.0f, %.0f), size (%.0f, %.0f, %.0f), depth %.0f, rim %.0f",
        WaterPool.VERSION,
        folderName,
        pos.X,
        terrainY,
        pos.Z,
        size.X,
        size.Y,
        size.Z,
        size.Y,
        rimHeight
    ))

    return folder
end

function WaterPool:_createWall(name: string, position: Vector3, size: Vector3): Part
    local wall = Instance.new("Part")
    wall.Name = name
    wall.Size = size
    wall.Position = position
    wall.Anchored = true -- CRITICAL: All parts must be anchored
    wall.Material = self.config.wallMaterial
    wall.Color = self.config.wallColor
    wall.CanCollide = true
    table.insert(self.parts, wall)
    return wall
end

function WaterPool:destroy()
    -- Clear water terrain in the pool region
    if self.folder then
        local config = self.config
        local pos = config.position
        local size = config.size
        local thickness = config.wallThickness or 2
        local rimHeight = config.rimHeight or 2
        local terrainY = self.terrainUtils.getHeightAt(self.terrain, pos.X, pos.Z)
        local poolBottom = terrainY - size.Y
        local wallTop = terrainY + rimHeight

        -- Clear from below floor part (poolBottom - thickness) to wallTop
        local clearMinCorner = Vector3.new(
            pos.X - size.X / 2,
            poolBottom - thickness,
            pos.Z - size.Z / 2
        )
        local clearMaxCorner = Vector3.new(
            pos.X + size.X / 2,
            wallTop,
            pos.Z + size.Z / 2
        )
        local clearRegion = Region3.new(clearMinCorner, clearMaxCorner)
        self.terrain:FillRegion(clearRegion, 4, Enum.Material.Air)

        -- Destroy all parts
        self.folder:Destroy()
        self.folder = nil
    end

    self.parts = {}
    print(string.format("[WaterPool v%s] Destroyed pool", WaterPool.VERSION))
end

return WaterPool
