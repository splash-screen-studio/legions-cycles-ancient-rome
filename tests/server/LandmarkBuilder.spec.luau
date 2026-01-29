--!strict
--[[
    Tests for LandmarkBuilder module
    Tests module structure, VERSION constant, and landmark construction methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/LandmarkBuilder.luau")

describe("LandmarkBuilder", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define LandmarkBuilder table
        expect(string.find(moduleSource, "local LandmarkBuilder = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "LandmarkBuilder.__index = LandmarkBuilder", 1, true)).toNotBeNil()

        -- Should return LandmarkBuilder
        expect(string.find(moduleSource, "return LandmarkBuilder", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function LandmarkBuilder.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:destroy", 1, true)).toNotBeNil()
    end)

    -- Private methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _createCylinder() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createCylinder", 1, true)).toNotBeNil()
    end)

    it("should have _createColumn() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createColumn", 1, true)).toNotBeNil()
    end)

    it("should have _createPlatform() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createPlatform", 1, true)).toNotBeNil()
    end)

    it("should have _createColonnade() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createColonnade", 1, true)).toNotBeNil()
    end)

    -- Major landmark builders
    it("should have _buildForum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildForum", 1, true)).toNotBeNil()
    end)

    it("should have _buildColosseum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildColosseum", 1, true)).toNotBeNil()
    end)

    it("should have _buildThermae() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildThermae", 1, true)).toNotBeNil()
    end)

    it("should have _buildTemple() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildTemple", 1, true)).toNotBeNil()
    end)

    it("should have _buildCircusMaximus() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildCircusMaximus", 1, true)).toNotBeNil()
    end)

    -- Minor landmark builders
    it("should have _buildCastrum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildCastrum", 1, true)).toNotBeNil()
    end)

    it("should have _buildMacellum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildMacellum", 1, true)).toNotBeNil()
    end)

    it("should have _buildHorreum() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildHorreum", 1, true)).toNotBeNil()
    end)

    it("should have _buildPharos() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildPharos", 1, true)).toNotBeNil()
    end)

    it("should have _buildEmporium() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildEmporium", 1, true)).toNotBeNil()
    end)

    it("should have _buildVillaRustica() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildVillaRustica", 1, true)).toNotBeNil()
    end)

    it("should have _buildSacellum() method for shrines", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildSacellum", 1, true)).toNotBeNil()
    end)

    -- Type mapper
    it("should have _buildLandmarkByType() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_buildLandmarkByType", 1, true)).toNotBeNil()
    end)

    -- Public query methods
    it("should have getLandmarkCount() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:getLandmarkCount", 1, true)).toNotBeNil()
    end)

    it("should have getParts() method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:getParts", 1, true)).toNotBeNil()
    end)

    -- Should require shared modules
    it("should require TerrainUtils module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("TerrainUtils"))', 1, true)).toNotBeNil()
    end)

    it("should require WorldPlan module", function()
        expect(string.find(moduleSource, 'require(Shared:WaitForChild("WorldPlan"))', 1, true)).toNotBeNil()
    end)

    -- Critical: Parts must be anchored
    it("should set Anchored = true on parts", function()
        expect(string.find(moduleSource, "Anchored = true", 1, true)).toNotBeNil()
    end)

    -- Should use Marble material for Roman aesthetic
    it("should use Marble material for classical look", function()
        expect(string.find(moduleSource, "Material = Enum.Material.Marble", 1, true)).toNotBeNil()
    end)

    -- Roman colors
    it("should have MARBLE_WHITE color constant", function()
        expect(string.find(moduleSource, "local MARBLE_WHITE", 1, true)).toNotBeNil()
    end)

    it("should have TERRACOTTA color constant", function()
        expect(string.find(moduleSource, "local TERRACOTTA", 1, true)).toNotBeNil()
    end)

    it("should have STONE_GRAY color constant", function()
        expect(string.find(moduleSource, "local STONE_GRAY", 1, true)).toNotBeNil()
    end)

    -- Column dimensions
    it("should have COLUMN_RADIUS constants", function()
        expect(string.find(moduleSource, "local COLUMN_RADIUS_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local COLUMN_RADIUS_MEDIUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local COLUMN_RADIUS_LARGE", 1, true)).toNotBeNil()
    end)

    it("should have COLUMN_HEIGHT constants", function()
        expect(string.find(moduleSource, "local COLUMN_HEIGHT_SMALL", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local COLUMN_HEIGHT_MEDIUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "local COLUMN_HEIGHT_LARGE", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export LandmarkBuilderConfig type", function()
        expect(string.find(moduleSource, "export type LandmarkBuilderConfig", 1, true)).toNotBeNil()
    end)

    it("should export LandmarkBuilderInstance type", function()
        expect(string.find(moduleSource, "export type LandmarkBuilderInstance", 1, true)).toNotBeNil()
    end)

    -- Roman naming for folder
    it("should use Roman naming for landmarks folder (Monumenta)", function()
        expect(string.find(moduleSource, "Landmarks_Monumenta", 1, true)).toNotBeNil()
    end)

    -- Query terrain height
    it("should query terrain height using TerrainUtils", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
    end)

    -- River exclusion zone validation
    it("should check river exclusion zone before building landmarks", function()
        expect(string.find(moduleSource, "isInRiverExclusionZone", 1, true)).toNotBeNil()
    end)

    it("should skip landmarks in river exclusion zone", function()
        -- Should have continue statement to skip invalid landmarks
        expect(string.find(moduleSource, "in river exclusion zone", 1, true)).toNotBeNil()
    end)

    it("should warn when skipping landmarks in river exclusion zone", function()
        -- Should use warn() for skipped landmarks
        expect(string.find(moduleSource, "warn(string.format", 1, true)).toNotBeNil()
    end)

    it("should track skipped landmark count", function()
        expect(string.find(moduleSource, "skippedCount", 1, true)).toNotBeNil()
    end)

    it("should report skipped landmarks in final summary", function()
        expect(string.find(moduleSource, "skipped for river", 1, true)).toNotBeNil()
    end)

    -- Walkable interior tests
    it("should have _createWallWithDoorway helper method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createWallWithDoorway", 1, true)).toNotBeNil()
    end)

    it("should have _createSolidWall helper method", function()
        expect(string.find(moduleSource, "function LandmarkBuilder:_createSolidWall", 1, true)).toNotBeNil()
    end)

    -- Thermae walkable interior
    it("should create interior floor in Thermae", function()
        expect(string.find(moduleSource, '"InteriorFloor"', 1, true)).toNotBeNil()
    end)

    it("should create doorways in Thermae for north and south walls", function()
        -- Thermae uses _createWallWithDoorway for front and back
        local thermaeSection = string.match(moduleSource, "function LandmarkBuilder:_buildThermae.-end\n")
        expect(thermaeSection).toNotBeNil()
        -- Should call _createWallWithDoorway
        expect(string.find(thermaeSection :: string, "_createWallWithDoorway", 1, true)).toNotBeNil()
    end)

    -- Temple walkable cella
    it("should create cella interior floor in Temple", function()
        expect(string.find(moduleSource, '"CellaFloor"', 1, true)).toNotBeNil()
    end)

    it("should create doorway in Temple cella facing columns", function()
        local templeSection = string.match(moduleSource, "function LandmarkBuilder:_buildTemple.-end\n")
        expect(templeSection).toNotBeNil()
        expect(string.find(templeSection :: string, "_createWallWithDoorway", 1, true)).toNotBeNil()
    end)

    -- Castrum Principia walkable interior
    it("should create Principia interior floor in Castrum", function()
        expect(string.find(moduleSource, '"PrincipiaFloor"', 1, true)).toNotBeNil()
    end)

    it("should create doorways in Castrum Principia", function()
        -- Find start of _buildCastrum and end (start of next function)
        local castrumStart = string.find(moduleSource, "function LandmarkBuilder:_buildCastrum", 1, true)
        local castrumEnd = string.find(moduleSource, "function LandmarkBuilder:_buildMacellum", 1, true)
        expect(castrumStart).toNotBeNil()
        expect(castrumEnd).toNotBeNil()
        local castrumSection = string.sub(moduleSource, castrumStart :: number, castrumEnd :: number)
        expect(string.find(castrumSection, "_createWallWithDoorway", 1, true)).toNotBeNil()
    end)

    -- Horreum walkable interior
    it("should create interior floor in Horreum", function()
        local horreumSection = string.match(moduleSource, "function LandmarkBuilder:_buildHorreum.-end\n")
        expect(horreumSection).toNotBeNil()
        expect(string.find(horreumSection :: string, '"InteriorFloor"', 1, true)).toNotBeNil()
    end)

    it("should create cargo doorways in Horreum", function()
        local horreumSection = string.match(moduleSource, "function LandmarkBuilder:_buildHorreum.-end\n")
        expect(horreumSection).toNotBeNil()
        expect(string.find(horreumSection :: string, "cargoDoorwayWidth", 1, true)).toNotBeNil()
        expect(string.find(horreumSection :: string, "_createWallWithDoorway", 1, true)).toNotBeNil()
    end)

    -- VillaRustica walkable interior
    it("should create interior floor in VillaRustica", function()
        local villaSection = string.match(moduleSource, "function LandmarkBuilder:_buildVillaRustica.-end\n")
        expect(villaSection).toNotBeNil()
        expect(string.find(villaSection :: string, '"InteriorFloor"', 1, true)).toNotBeNil()
    end)

    it("should create doorways in VillaRustica main house", function()
        local villaSection = string.match(moduleSource, "function LandmarkBuilder:_buildVillaRustica.-end\n")
        expect(villaSection).toNotBeNil()
        expect(string.find(villaSection :: string, "_createWallWithDoorway", 1, true)).toNotBeNil()
    end)

    -- Version check
    it("should have VERSION 1.3.0 for enhanced Circus Maximus", function()
        expect(string.find(moduleSource, 'VERSION = "1.3.0"', 1, true)).toNotBeNil()
    end)

    -- Circus Maximus specific tests
    describe("Circus Maximus", function()
        it("should create RaceTrack with Sand material", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, '"RaceTrack"', 1, true)).toNotBeNil()
            expect(string.find(circusSection :: string, "Enum.Material.Sand", 1, true)).toNotBeNil()
        end)

        it("should create Spina (central barrier)", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, '"Spina"', 1, true)).toNotBeNil()
        end)

        it("should create Obelisk on the spina", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, '"Obelisk"', 1, true)).toNotBeNil()
        end)

        it("should create lap counters (7 markers)", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            -- Uses string.format("LapCounter_%d", i) pattern
            expect(string.find(circusSection :: string, 'LapCounter_', 1, true)).toNotBeNil()
            expect(string.find(circusSection :: string, "for i = 1, 7 do", 1, true)).toNotBeNil()
        end)

        it("should create Metae (turning posts) at both ends", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            -- Uses string.format pattern for MetaWest and MetaEast
            expect(string.find(circusSection :: string, 'MetaWest_', 1, true)).toNotBeNil()
            expect(string.find(circusSection :: string, 'MetaEast_', 1, true)).toNotBeNil()
        end)

        it("should create tiered seating (Cavea) on both sides", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            -- Uses string.format("Seating_%s_Tier%d", sideName, tier) pattern
            expect(string.find(circusSection :: string, 'Seating_%s_Tier', 1, true)).toNotBeNil()
            expect(string.find(circusSection :: string, 'sideName', 1, true)).toNotBeNil()
        end)

        it("should create multiple tiers of seating", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, "numTiers = 3", 1, true)).toNotBeNil()
        end)

        it("should create Carceres (starting gates)", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, 'Carceres_Back', 1, true)).toNotBeNil()
            -- Uses string.format("Gate_%d_...", i) pattern
            expect(string.find(circusSection :: string, 'Gate_%d', 1, true)).toNotBeNil()
        end)

        it("should create 12 starting gates for chariots", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, "numGates = 12", 1, true)).toNotBeNil()
        end)

        it("should create Imperial Box (Pulvinar)", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, '"Pulvinar_Base"', 1, true)).toNotBeNil()
            expect(string.find(circusSection :: string, '"Pulvinar_Roof"', 1, true)).toNotBeNil()
        end)

        it("should use impressive dimensions (~200 studs long minimum)", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            -- Should have math.max to ensure minimum size
            expect(string.find(circusSection :: string, "math.max(radius", 1, true)).toNotBeNil()
            expect(string.find(circusSection :: string, "200", 1, true)).toNotBeNil()
        end)

        it("should use Concrete material for seating stands", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, "Enum.Material.Concrete", 1, true)).toNotBeNil()
        end)

        it("should use Bronze material for metae and decorations", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, "BRONZE", 1, true)).toNotBeNil()
        end)

        it("should create decorative fountains on spina", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            -- Uses string.format("SpinaFountain_%d", i) pattern
            expect(string.find(circusSection :: string, 'SpinaFountain_', 1, true)).toNotBeNil()
        end)

        it("should create colonnades along top of seating", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, "_createColonnade", 1, true)).toNotBeNil()
        end)

        it("should create curved seating at west turning end", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            expect(string.find(circusSection :: string, '"Seating_West_Curved"', 1, true)).toNotBeNil()
        end)

        it("should create tower structures at carceres corners", function()
            local circusSection = string.match(moduleSource, "function LandmarkBuilder:_buildCircusMaximus.-\nend\n")
            expect(circusSection).toNotBeNil()
            -- Uses string.format("Carceres_Tower_%s", ...) pattern
            expect(string.find(circusSection :: string, 'Carceres_Tower_', 1, true)).toNotBeNil()
        end)
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

        expect(lastLine).toBe("return LandmarkBuilder")
    end)
end)
