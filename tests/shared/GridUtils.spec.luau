--!strict
--[[
    Tests for GridUtils module
]]

local GridUtils = require("../../src/shared/GridUtils")

type DescribeFn = (name: string, fn: () -> ()) -> ()
type ItFn = (name: string, fn: () -> ()) -> ()
type ExpectFn = (value: any) -> any

return function(describe: DescribeFn, it: ItFn, expect: ExpectFn)
    describe("GridUtils", function()
        it("should have a VERSION constant", function()
            expect(GridUtils.VERSION).to.be.ok()
            expect(type(GridUtils.VERSION)).to.equal("string")
        end)

        it("should export snapToGrid function", function()
            expect(type(GridUtils.snapToGrid)).to.equal("function")
        end)

        it("should export snapToGridXZ function", function()
            expect(type(GridUtils.snapToGridXZ)).to.equal("function")
        end)

        it("should export isOnGrid function", function()
            expect(type(GridUtils.isOnGrid)).to.equal("function")
        end)

        it("should export getGridCell function", function()
            expect(type(GridUtils.getGridCell)).to.equal("function")
        end)

        it("should export getCellCenter function", function()
            expect(type(GridUtils.getCellCenter)).to.equal("function")
        end)

        it("should export getCellCorner function", function()
            expect(type(GridUtils.getCellCorner)).to.equal("function")
        end)

        it("should export iterateCells function", function()
            expect(type(GridUtils.iterateCells)).to.equal("function")
        end)

        it("should snap to grid correctly for X", function()
            local pos = Vector3.new(7.3, 10, 0)
            local snapped = GridUtils.snapToGridXZ(pos, 4)
            expect(snapped.X).to.be.closeTo(8, 0.001)
        end)

        it("should snap to grid correctly for Z", function()
            local pos = Vector3.new(0, 10, 5.2)
            local snapped = GridUtils.snapToGridXZ(pos, 4)
            expect(snapped.Z).to.be.closeTo(4, 0.001)
        end)

        it("should preserve Y when snapping XZ", function()
            local pos = Vector3.new(7.3, 25.5, 5.2)
            local snapped = GridUtils.snapToGridXZ(pos, 4)
            expect(snapped.Y).to.be.closeTo(25.5, 0.001)
        end)

        it("should handle zero grid size", function()
            local pos = Vector3.new(7.3, 10, 5.2)
            local snapped = GridUtils.snapToGridXZ(pos, 0)
            expect(snapped.X).to.be.closeTo(7.3, 0.001)
            expect(snapped.Z).to.be.closeTo(5.2, 0.001)
        end)

        it("should detect on-grid positions", function()
            local pos = Vector3.new(8, 10, 4)
            local isOn = GridUtils.isOnGrid(pos, 4)
            expect(isOn).to.equal(true)
        end)

        it("should detect off-grid positions", function()
            local pos = Vector3.new(7, 10, 3)
            local isOn = GridUtils.isOnGrid(pos, 4)
            expect(isOn).to.equal(false)
        end)

        it("should calculate grid cell correctly", function()
            local pos = Vector3.new(10, 0, 14)
            local cellX, cellZ = GridUtils.getGridCell(pos, 4)
            expect(cellX).to.equal(2)
            expect(cellZ).to.equal(3)
        end)
    end)
end
