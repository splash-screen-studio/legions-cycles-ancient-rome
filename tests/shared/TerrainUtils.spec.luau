--!strict
--[[
    Tests for TerrainUtils module
]]

local TerrainUtils = require("../../src/shared/TerrainUtils")

type DescribeFn = (name: string, fn: () -> ()) -> ()
type ItFn = (name: string, fn: () -> ()) -> ()
type ExpectFn = (value: any) -> any

return function(describe: DescribeFn, it: ItFn, expect: ExpectFn)
    describe("TerrainUtils", function()
        it("should have a VERSION constant", function()
            expect(TerrainUtils.VERSION).to.be.ok()
            expect(type(TerrainUtils.VERSION)).to.equal("string")
        end)

        it("should export getHeightAt function", function()
            expect(type(TerrainUtils.getHeightAt)).to.equal("function")
        end)

        it("should export getHeightAtWithWorkspace function", function()
            expect(type(TerrainUtils.getHeightAtWithWorkspace)).to.equal("function")
        end)

        it("should export getSlopeAt function", function()
            expect(type(TerrainUtils.getSlopeAt)).to.equal("function")
        end)

        it("should export getSlopeXZ function", function()
            expect(type(TerrainUtils.getSlopeXZ)).to.equal("function")
        end)

        it("should export getNormalAt function", function()
            expect(type(TerrainUtils.getNormalAt)).to.equal("function")
        end)

        it("should export getCFrameAlignedToTerrain function", function()
            expect(type(TerrainUtils.getCFrameAlignedToTerrain)).to.equal("function")
        end)

        it("should export isFlatEnough function", function()
            expect(type(TerrainUtils.isFlatEnough)).to.equal("function")
        end)

        it("should export getAverageHeight function", function()
            expect(type(TerrainUtils.getAverageHeight)).to.equal("function")
        end)

        it("should export isFlatEnoughDegrees function", function()
            expect(type(TerrainUtils.isFlatEnoughDegrees)).to.equal("function")
        end)

        it("should export getMaxSlopeDegrees function", function()
            expect(type(TerrainUtils.getMaxSlopeDegrees)).to.equal("function")
        end)
    end)
end
