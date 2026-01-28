--!strict
--[[
    Tests for Maid module
]]

local Maid = require("../../src/shared/Maid")

type DescribeFn = (name: string, fn: () -> ()) -> ()
type ItFn = (name: string, fn: () -> ()) -> ()
type ExpectFn = (value: any) -> any

return function(describe: DescribeFn, it: ItFn, expect: ExpectFn)
    describe("Maid", function()
        it("should have a VERSION constant", function()
            expect(Maid.VERSION).to.be.ok()
            expect(type(Maid.VERSION)).to.equal("string")
        end)

        it("should have new constructor", function()
            expect(type(Maid.new)).to.equal("function")
        end)

        it("should create a new Maid instance", function()
            local maid = Maid.new()
            expect(maid).to.be.ok()
        end)

        it("should have give method", function()
            local maid = Maid.new()
            expect(type(maid.give)).to.equal("function")
        end)

        it("should have cleanup method", function()
            local maid = Maid.new()
            expect(type(maid.cleanup)).to.equal("function")
        end)

        it("should have destroy method", function()
            local maid = Maid.new()
            expect(type(maid.destroy)).to.equal("function")
        end)

        it("should have getTaskCount method", function()
            local maid = Maid.new()
            expect(type(maid.getTaskCount)).to.equal("function")
        end)

        it("should start with zero tasks", function()
            local maid = Maid.new()
            expect(maid:getTaskCount()).to.equal(0)
        end)

        it("should track function tasks", function()
            local maid = Maid.new()
            maid:give(function() end)
            expect(maid:getTaskCount()).to.equal(1)
        end)

        it("should return given task", function()
            local maid = Maid.new()
            local fn = function() end
            local result = maid:give(fn)
            expect(result).to.equal(fn)
        end)

        it("should call function tasks on cleanup", function()
            local maid = Maid.new()
            local called = false
            maid:give(function()
                called = true
            end)
            maid:cleanup()
            expect(called).to.equal(true)
        end)

        it("should clear tasks after cleanup", function()
            local maid = Maid.new()
            maid:give(function() end)
            maid:cleanup()
            expect(maid:getTaskCount()).to.equal(0)
        end)

        it("should track multiple tasks", function()
            local maid = Maid.new()
            maid:give(function() end)
            maid:give(function() end)
            maid:give(function() end)
            expect(maid:getTaskCount()).to.equal(3)
        end)
    end)
end
