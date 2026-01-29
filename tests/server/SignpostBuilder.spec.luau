--!strict
--[[
    Tests for SignpostBuilder module
    Tests module structure, VERSION constant, and signpost construction methods
]]

local fs = require("@lune/fs")

local describe = _G.describe :: (name: string, fn: () -> ()) -> ()
local it = _G.it :: (name: string, fn: () -> ()) -> ()
local expect = _G.expect :: (value: any) -> any

-- Read the module source to verify structure
local moduleSource = fs.readFile("src/server/SignpostBuilder.luau")

describe("SignpostBuilder", function()
    it("should have VERSION constant", function()
        expect(string.find(moduleSource, 'VERSION = "', 1, true)).toNotBeNil()
    end)

    it("should have correct module structure", function()
        -- Should define SignpostBuilder table
        expect(string.find(moduleSource, "local SignpostBuilder = {}", 1, true)).toNotBeNil()

        -- Should set metatable index
        expect(string.find(moduleSource, "SignpostBuilder.__index = SignpostBuilder", 1, true)).toNotBeNil()

        -- Should return SignpostBuilder
        expect(string.find(moduleSource, "return SignpostBuilder", 1, true)).toNotBeNil()
    end)

    it("should have new() constructor", function()
        expect(string.find(moduleSource, "function SignpostBuilder.new", 1, true)).toNotBeNil()
    end)

    it("should have build() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:build", 1, true)).toNotBeNil()
    end)

    it("should have destroy() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:destroy", 1, true)).toNotBeNil()
    end)

    -- Private helper methods
    it("should have _createPart() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_createPart", 1, true)).toNotBeNil()
    end)

    it("should have _createSurfaceText() method for text labels", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_createSurfaceText", 1, true)).toNotBeNil()
    end)

    it("should have _createBillboardText() method for readable signs", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_createBillboardText", 1, true)).toNotBeNil()
    end)

    it("should have _createPillarBase() method for signpost structure", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_createPillarBase", 1, true)).toNotBeNil()
    end)

    it("should have _createDirectionalArm() method for pointing arms", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_createDirectionalArm", 1, true)).toNotBeNil()
    end)

    -- Signpost type methods
    it("should have _createDirectionPost() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_createDirectionPost", 1, true)).toNotBeNil()
    end)

    it("should have _createMilestone() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_createMilestone", 1, true)).toNotBeNil()
    end)

    it("should have _createDistrictSign() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_createDistrictSign", 1, true)).toNotBeNil()
    end)

    -- Road intersection detection
    it("should have _findRoadIntersections() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_findRoadIntersections", 1, true)).toNotBeNil()
    end)

    it("should have _findSegmentIntersection() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_findSegmentIntersection", 1, true)).toNotBeNil()
    end)

    -- Placement methods
    it("should have _placeMilestones() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_placeMilestones", 1, true)).toNotBeNil()
    end)

    it("should have _placeMilestonesAlongPath() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_placeMilestonesAlongPath", 1, true)).toNotBeNil()
    end)

    it("should have _placeDistrictSigns() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_placeDistrictSigns", 1, true)).toNotBeNil()
    end)

    -- Display name methods
    it("should have _getLandmarkDisplayName() method for Latin names", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_getLandmarkDisplayName", 1, true)).toNotBeNil()
    end)

    it("should have _getZoneDisplayName() method for zone names", function()
        expect(string.find(moduleSource, "function SignpostBuilder:_getZoneDisplayName", 1, true)).toNotBeNil()
    end)

    -- Public query methods
    it("should have getSignpostCount() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:getSignpostCount", 1, true)).toNotBeNil()
    end)

    it("should have getParts() method", function()
        expect(string.find(moduleSource, "function SignpostBuilder:getParts", 1, true)).toNotBeNil()
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

    -- Roman colors
    it("should have MARBLE_WHITE color constant", function()
        expect(string.find(moduleSource, "local MARBLE_WHITE", 1, true)).toNotBeNil()
    end)

    it("should have STONE_GRAY color constant", function()
        expect(string.find(moduleSource, "local STONE_GRAY", 1, true)).toNotBeNil()
    end)

    it("should have BRONZE color constant", function()
        expect(string.find(moduleSource, "local BRONZE", 1, true)).toNotBeNil()
    end)

    it("should have WOOD_BROWN color constant for directional arms", function()
        expect(string.find(moduleSource, "local WOOD_BROWN", 1, true)).toNotBeNil()
    end)

    -- Signpost dimensions
    it("should have PILLAR_WIDTH constant", function()
        expect(string.find(moduleSource, "local PILLAR_WIDTH", 1, true)).toNotBeNil()
    end)

    it("should have PILLAR_HEIGHT constant", function()
        expect(string.find(moduleSource, "local PILLAR_HEIGHT", 1, true)).toNotBeNil()
    end)

    it("should have ARM_LENGTH constant", function()
        expect(string.find(moduleSource, "local ARM_LENGTH", 1, true)).toNotBeNil()
    end)

    -- Placement configuration
    it("should have MILESTONE_SPACING constant", function()
        expect(string.find(moduleSource, "local MILESTONE_SPACING", 1, true)).toNotBeNil()
    end)

    it("should have DIRECTION_POST_SEARCH_RADIUS constant", function()
        expect(string.find(moduleSource, "local DIRECTION_POST_SEARCH_RADIUS", 1, true)).toNotBeNil()
    end)

    -- Type exports
    it("should export SignpostBuilderConfig type", function()
        expect(string.find(moduleSource, "export type SignpostBuilderConfig", 1, true)).toNotBeNil()
    end)

    it("should export SignpostBuilderInstance type", function()
        expect(string.find(moduleSource, "export type SignpostBuilderInstance", 1, true)).toNotBeNil()
    end)

    -- Roman naming for folder
    it("should use Roman naming for signposts folder (Columnae)", function()
        expect(string.find(moduleSource, "Signposts_Columnae", 1, true)).toNotBeNil()
    end)

    -- Query terrain height
    it("should query terrain height using TerrainUtils", function()
        expect(string.find(moduleSource, "TerrainUtils.getHeightAt", 1, true)).toNotBeNil()
    end)

    -- Uses SurfaceGui or BillboardGui for text
    it("should use SurfaceGui for sign text", function()
        expect(string.find(moduleSource, "Instance.new(\"SurfaceGui\")", 1, true)).toNotBeNil()
    end)

    it("should use BillboardGui for milestone text", function()
        expect(string.find(moduleSource, "Instance.new(\"BillboardGui\")", 1, true)).toNotBeNil()
    end)

    -- Uses TextLabel for readable text
    it("should use TextLabel for text display", function()
        expect(string.find(moduleSource, "Instance.new(\"TextLabel\")", 1, true)).toNotBeNil()
    end)

    -- Uses Antique font for Roman aesthetic
    it("should use Antique font for Roman aesthetic", function()
        expect(string.find(moduleSource, "Font.Antique", 1, true)).toNotBeNil()
    end)

    -- Latin landmark names
    it("should use Latin names for landmarks (FORUM, AMPHITHEATRVM)", function()
        expect(string.find(moduleSource, "FORUM", 1, true)).toNotBeNil()
        expect(string.find(moduleSource, "AMPHITHEATRVM", 1, true)).toNotBeNil()
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

        expect(lastLine).toBe("return SignpostBuilder")
    end)
end)
