--!strict
--[[
    Tests for MusicConfig module
]]

local MusicConfig = require("../../src/shared/MusicConfig")

type DescribeFn = (name: string, fn: () -> ()) -> ()
type ItFn = (name: string, fn: () -> ()) -> ()
type ExpectFn = (value: any) -> any

return function(describe: DescribeFn, it: ItFn, expect: ExpectFn)
    describe("MusicConfig", function()
        it("should have a VERSION constant", function()
            expect(MusicConfig.VERSION).to.be.ok()
            expect(type(MusicConfig.VERSION)).to.equal("string")
        end)

        it("should have TRACKS table", function()
            expect(MusicConfig.TRACKS).to.be.ok()
            expect(type(MusicConfig.TRACKS)).to.equal("table")
        end)

        it("should have dawn track", function()
            expect(MusicConfig.TRACKS.dawn).to.be.ok()
            expect(MusicConfig.TRACKS.dawn.id).to.be.ok()
            expect(MusicConfig.TRACKS.dawn.name).to.equal("Dawn")
        end)

        it("should have forum track", function()
            expect(MusicConfig.TRACKS.forum).to.be.ok()
            expect(MusicConfig.TRACKS.forum.name).to.equal("Forum")
        end)

        it("should have march track", function()
            expect(MusicConfig.TRACKS.march).to.be.ok()
            expect(MusicConfig.TRACKS.march.name).to.equal("March")
        end)

        it("should have colosseum track", function()
            expect(MusicConfig.TRACKS.colosseum).to.be.ok()
            expect(MusicConfig.TRACKS.colosseum.name).to.equal("Colosseum")
        end)

        it("should have caesar track", function()
            expect(MusicConfig.TRACKS.caesar).to.be.ok()
            expect(MusicConfig.TRACKS.caesar.name).to.equal("Caesar")
        end)

        it("should have eternal track", function()
            expect(MusicConfig.TRACKS.eternal).to.be.ok()
            expect(MusicConfig.TRACKS.eternal.name).to.equal("Eternal")
        end)

        it("should have PLAYLIST_ORDER array", function()
            expect(MusicConfig.PLAYLIST_ORDER).to.be.ok()
            expect(type(MusicConfig.PLAYLIST_ORDER)).to.equal("table")
            expect(#MusicConfig.PLAYLIST_ORDER).to.equal(6)
        end)

        it("should have CROSSFADE_DURATION setting", function()
            expect(MusicConfig.CROSSFADE_DURATION).to.be.ok()
            expect(type(MusicConfig.CROSSFADE_DURATION)).to.equal("number")
        end)

        it("should have DEFAULT_VOLUME setting", function()
            expect(MusicConfig.DEFAULT_VOLUME).to.be.ok()
            expect(type(MusicConfig.DEFAULT_VOLUME)).to.equal("number")
        end)

        it("should have valid volume range", function()
            expect(MusicConfig.MIN_VOLUME).to.equal(0)
            expect(MusicConfig.MAX_VOLUME).to.equal(1)
            expect(MusicConfig.DEFAULT_VOLUME).to.be.greaterThan(MusicConfig.MIN_VOLUME - 0.001)
            expect(MusicConfig.DEFAULT_VOLUME).to.be.lessThan(MusicConfig.MAX_VOLUME + 0.001)
        end)

        it("should have tracks with valid asset IDs", function()
            for trackName, track in MusicConfig.TRACKS do
                expect(track.id).to.be.ok()
                expect(string.match(track.id, "^rbxassetid://")).to.be.ok()
            end
        end)
    end)
end
