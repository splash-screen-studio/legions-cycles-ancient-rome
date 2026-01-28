--!strict
--[[
    Tests for Constants module
]]

local Constants = require("../../src/shared/Constants")

type DescribeFn = (name: string, fn: () -> ()) -> ()
type ItFn = (name: string, fn: () -> ()) -> ()
type ExpectFn = (value: any) -> any

return function(describe: DescribeFn, it: ItFn, expect: ExpectFn)
    describe("Constants", function()
        it("should have a VERSION constant", function()
            expect(Constants.VERSION).to.be.ok()
            expect(type(Constants.VERSION)).to.equal("string")
        end)

        it("should have GRID_SIZES array", function()
            expect(Constants.GRID_SIZES).to.be.ok()
            expect(type(Constants.GRID_SIZES)).to.equal("table")
            expect(#Constants.GRID_SIZES).to.be.greaterThan(0)
        end)

        it("should have TREE_TYPES table", function()
            expect(Constants.TREE_TYPES).to.be.ok()
            expect(type(Constants.TREE_TYPES)).to.equal("table")
        end)

        it("should have CYPRESS tree type", function()
            expect(Constants.TREE_TYPES.CYPRESS).to.be.ok()
            expect(Constants.TREE_TYPES.CYPRESS.maxIterations).to.be.ok()
        end)

        it("should have OLIVE tree type", function()
            expect(Constants.TREE_TYPES.OLIVE).to.be.ok()
            expect(Constants.TREE_TYPES.OLIVE.maxIterations).to.be.ok()
        end)

        it("should have STONE_PINE tree type", function()
            expect(Constants.TREE_TYPES.STONE_PINE).to.be.ok()
            expect(Constants.TREE_TYPES.STONE_PINE.maxIterations).to.be.ok()
        end)

        it("should have light color constants", function()
            expect(Constants.TORCH_COLOR).to.be.ok()
            expect(Constants.BRAZIER_COLOR).to.be.ok()
            expect(Constants.OIL_LAMP_COLOR).to.be.ok()
        end)

        it("should have Roman material color constants", function()
            expect(Constants.MARBLE_WHITE).to.be.ok()
            expect(Constants.MARBLE_GRAY).to.be.ok()
            expect(Constants.TERRACOTTA).to.be.ok()
            expect(Constants.BRONZE).to.be.ok()
            expect(Constants.SAND).to.be.ok()
        end)

        it("should have MATERIALS table", function()
            expect(Constants.MATERIALS).to.be.ok()
            expect(Constants.MATERIALS.MARBLE).to.be.ok()
            expect(Constants.MATERIALS.BRICK).to.be.ok()
        end)

        it("should have ARCHITECTURE dimensions", function()
            expect(Constants.ARCHITECTURE).to.be.ok()
            expect(Constants.ARCHITECTURE.COLUMN_HEIGHT_SMALL).to.be.ok()
            expect(type(Constants.ARCHITECTURE.COLUMN_HEIGHT_SMALL)).to.equal("number")
        end)

        it("should have POOL constraints", function()
            expect(Constants.POOL).to.be.ok()
            expect(Constants.POOL.WALL_THICKNESS).to.be.ok()
            expect(Constants.POOL.MIN_DEPTH).to.be.ok()
        end)

        it("should have PROJECTILES settings", function()
            expect(Constants.PROJECTILES).to.be.ok()
            expect(Constants.PROJECTILES.PILUM).to.be.ok()
            expect(Constants.PROJECTILES.BALLISTA_BOLT).to.be.ok()
        end)

        it("should have AI parameters", function()
            expect(Constants.AI).to.be.ok()
            expect(Constants.AI.PATROL_SPEED).to.be.ok()
            expect(Constants.AI.DETECTION_RANGE).to.be.ok()
        end)
    end)
end
