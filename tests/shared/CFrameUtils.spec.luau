--!strict
--[[
    Tests for CFrameUtils module
]]

local CFrameUtils = require("../../src/shared/CFrameUtils")

type DescribeFn = (name: string, fn: () -> ()) -> ()
type ItFn = (name: string, fn: () -> ()) -> ()
type ExpectFn = (value: any) -> any

return function(describe: DescribeFn, it: ItFn, expect: ExpectFn)
    describe("CFrameUtils", function()
        it("should have a VERSION constant", function()
            expect(CFrameUtils.VERSION).to.be.ok()
            expect(type(CFrameUtils.VERSION)).to.equal("string")
        end)

        it("should export chain function", function()
            expect(type(CFrameUtils.chain)).to.equal("function")
        end)

        it("should export toLocal function", function()
            expect(type(CFrameUtils.toLocal)).to.equal("function")
        end)

        it("should export toWorld function", function()
            expect(type(CFrameUtils.toWorld)).to.equal("function")
        end)

        it("should export rotateY function", function()
            expect(type(CFrameUtils.rotateY)).to.equal("function")
        end)

        it("should export rotateX function", function()
            expect(type(CFrameUtils.rotateX)).to.equal("function")
        end)

        it("should export rotateZ function", function()
            expect(type(CFrameUtils.rotateZ)).to.equal("function")
        end)

        it("should export getForward function", function()
            expect(type(CFrameUtils.getForward)).to.equal("function")
        end)

        it("should export getUp function", function()
            expect(type(CFrameUtils.getUp)).to.equal("function")
        end)

        it("should export getRight function", function()
            expect(type(CFrameUtils.getRight)).to.equal("function")
        end)

        it("should export lookAt function", function()
            expect(type(CFrameUtils.lookAt)).to.equal("function")
        end)

        it("should export lerp function", function()
            expect(type(CFrameUtils.lerp)).to.equal("function")
        end)

        it("should export fromPositionAndAngles function", function()
            expect(type(CFrameUtils.fromPositionAndAngles)).to.equal("function")
        end)

        it("should chain CFrames correctly", function()
            local parent = CFrame.new(10, 0, 0)
            local offset = CFrame.new(5, 0, 0)
            local result = CFrameUtils.chain(parent, offset)
            expect(result.Position.X).to.be.closeTo(15, 0.001)
        end)

        it("should convert to local space correctly", function()
            local world = CFrame.new(15, 0, 0)
            local relativeTo = CFrame.new(10, 0, 0)
            local result = CFrameUtils.toLocal(world, relativeTo)
            expect(result.Position.X).to.be.closeTo(5, 0.001)
        end)

        it("should convert to world space correctly", function()
            local localCf = CFrame.new(5, 0, 0)
            local relativeTo = CFrame.new(10, 0, 0)
            local result = CFrameUtils.toWorld(localCf, relativeTo)
            expect(result.Position.X).to.be.closeTo(15, 0.001)
        end)
    end)
end
