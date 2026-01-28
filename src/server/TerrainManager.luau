--!strict
--[[
    TerrainManager - Undulating terrain generation for Italian peninsula landscape
    Based on BRicey procedural generation techniques adapted for terrain

    Generates rolling hills and valleys using Perlin noise with multiple octaves
    for natural-looking Mediterranean terrain.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

local TerrainManager = {}
TerrainManager.__index = TerrainManager
TerrainManager.VERSION = "1.0.0"

-- Terrain generation constants
local TERRAIN_SIZE = 1024 -- Total terrain size in studs (1024x1024)
local RESOLUTION = 4 -- Studs per terrain voxel (Roblox terrain resolution)
local BASE_HEIGHT = 20 -- Base elevation above sea level
local HEIGHT_AMPLITUDE = 40 -- Maximum height variation for hills
local NOISE_SCALE = 0.01 -- Controls hill frequency (smaller = larger hills)
local OCTAVES = 4 -- Number of noise layers for detail
local PERSISTENCE = 0.5 -- How much each octave contributes
local LACUNARITY = 2 -- Frequency multiplier between octaves

-- Material thresholds based on height and slope
local CLIFF_SLOPE_THRESHOLD = 0.6 -- Radians - steeper than this = rock
local HILLTOP_HEIGHT_RATIO = 0.7 -- Above this ratio of max height = rock

type TerrainConfig = {
    size: number?,
    baseHeight: number?,
    heightAmplitude: number?,
    noiseScale: number?,
    seed: number?,
}

function TerrainManager.new(config: TerrainConfig?)
    local self = setmetatable({}, TerrainManager)

    local cfg = config or {}
    self.size = cfg.size or TERRAIN_SIZE
    self.baseHeight = cfg.baseHeight or BASE_HEIGHT
    self.heightAmplitude = cfg.heightAmplitude or HEIGHT_AMPLITUDE
    self.noiseScale = cfg.noiseScale or NOISE_SCALE
    self.seed = cfg.seed or math.random(1, 100000)
    self.terrain = workspace.Terrain

    return self
end

-- Generate multi-octave Perlin noise for natural terrain
function TerrainManager:_sampleNoise(x: number, z: number): number
    local total = 0
    local frequency = 1
    local amplitude = 1
    local maxValue = 0

    for _ = 1, OCTAVES do
        local nx = (x + self.seed) * self.noiseScale * frequency
        local nz = (z + self.seed * 1.5) * self.noiseScale * frequency

        total = total + math.noise(nx, nz) * amplitude
        maxValue = maxValue + amplitude

        amplitude = amplitude * PERSISTENCE
        frequency = frequency * LACUNARITY
    end

    -- Normalize to 0-1 range
    return (total / maxValue + 1) / 2
end

-- Calculate height at a given world position
function TerrainManager:_calculateHeight(x: number, z: number): number
    local noiseValue = self:_sampleNoise(x, z)
    return self.baseHeight + noiseValue * self.heightAmplitude
end

-- Determine terrain material based on height and slope
function TerrainManager:_getMaterial(x: number, z: number, height: number, _maxHeight: number): Enum.Material
    -- Sample slope using neighboring heights
    local h1 = self:_calculateHeight(x - RESOLUTION, z)
    local h2 = self:_calculateHeight(x + RESOLUTION, z)
    local h3 = self:_calculateHeight(x, z - RESOLUTION)
    local h4 = self:_calculateHeight(x, z + RESOLUTION)

    local slopeX = math.abs(h2 - h1) / (RESOLUTION * 2)
    local slopeZ = math.abs(h4 - h3) / (RESOLUTION * 2)
    local maxSlope = math.max(slopeX, slopeZ)

    -- Steep slopes get rock material (cliffs, hillsides)
    if maxSlope > CLIFF_SLOPE_THRESHOLD then
        return Enum.Material.Rock
    end

    -- High elevations get rock (hilltops, exposed areas)
    local heightRatio = (height - self.baseHeight) / self.heightAmplitude
    if heightRatio > HILLTOP_HEIGHT_RATIO then
        return Enum.Material.Rock
    end

    -- Low areas near base get ground (paths, worn areas)
    if heightRatio < 0.2 then
        -- Mix of ground and sand for variety
        local varietyNoise = math.noise(x * 0.05 + 1000, z * 0.05)
        if varietyNoise > 0.3 then
            return Enum.Material.Sand
        end
        return Enum.Material.Ground
    end

    -- Default: grass for lowlands and gentle slopes
    return Enum.Material.Grass
end

-- Clear existing terrain in the generation area
function TerrainManager:_clearTerrain()
    local maxHeight = self.baseHeight + self.heightAmplitude + 10

    self.terrain:FillBlock(
        CFrame.new(0, maxHeight / 2, 0),
        Vector3.new(self.size + 20, maxHeight + 20, self.size + 20),
        Enum.Material.Air
    )
end

-- Generate the undulating terrain
function TerrainManager:generate()
    print("[TerrainManager v" .. TerrainManager.VERSION .. "] Starting terrain generation...")
    print(string.format("[TerrainManager v" .. TerrainManager.VERSION .. "] Size: %d, Seed: %d", self.size, self.seed))

    local startTime = tick()

    -- Clear existing terrain
    self:_clearTerrain()

    local halfSize = self.size / 2
    local maxHeight = self.baseHeight + self.heightAmplitude
    local voxelCount = 0

    -- Generate terrain using FillBlock for each column
    -- We iterate through the terrain in chunks for better performance
    for x = -halfSize, halfSize - RESOLUTION, RESOLUTION do
        for z = -halfSize, halfSize - RESOLUTION, RESOLUTION do
            local height = self:_calculateHeight(x, z)
            local material = self:_getMaterial(x, z, height, maxHeight)

            -- Fill from bottom to calculated height
            local columnHeight = height
            local centerY = columnHeight / 2

            self.terrain:FillBlock(
                CFrame.new(x + RESOLUTION / 2, centerY, z + RESOLUTION / 2),
                Vector3.new(RESOLUTION, columnHeight, RESOLUTION),
                material
            )

            voxelCount = voxelCount + 1
        end

        -- Yield periodically to prevent script timeout
        if x % 64 == 0 then
            task.wait()
        end
    end

    local elapsed = tick() - startTime
    print(string.format("[TerrainManager v" .. TerrainManager.VERSION .. "] Terrain generated in %.2f seconds", elapsed))
    print(string.format("[TerrainManager v" .. TerrainManager.VERSION .. "] Generated %d terrain columns", voxelCount))

    return true
end

-- Get height at position using raycasting (delegates to TerrainUtils)
function TerrainManager:getHeightAt(x: number, z: number): number
    return TerrainUtils.getHeightAt(self.terrain, x, z)
end

-- Get slope at position (delegates to TerrainUtils)
function TerrainManager:getSlopeAt(x: number, z: number): number
    return TerrainUtils.getSlopeAt(self.terrain, x, z)
end

-- Get CFrame aligned to terrain surface (delegates to TerrainUtils)
function TerrainManager:getCFrameAlignedToTerrain(x: number, z: number): CFrame
    return TerrainUtils.getCFrameAlignedToTerrain(self.terrain, x, z)
end

return TerrainManager
