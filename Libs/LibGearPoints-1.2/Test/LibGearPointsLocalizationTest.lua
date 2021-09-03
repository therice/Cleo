--local pl = require('pl.path')
--local this = pl.abspath(pl.abspath('.') .. '/' .. debug.getinfo(1).source:match("@(.*)$"))
--
--
--local gearPoints
--describe("LibGearPoints (localized to 'deDE')", function()
--    setup(function()
--        loadfile(pl.abspath(pl.dirname(this) .. '/LibGearPointsTestData.lua'))()
--        loadfile(pl.abspath(pl.dirname(this) .. '/../../../Test/TestSetup.lua'))(
--                this,
--                {
--                    function() SetLocale("deDE") end
--                }
--        )
--        gearPoints, _ = LibStub('LibGearPoints-1.2')
--    end)
--    teardown(function()
--        After()
--    end)
--    describe("scaling factor", function()
--        it("key can be determined from equipment location", function()
--            assert.equal("ranged", gearPoints:GetScaleKey(nil, "Bögen"))
--        end)
--    end)
--end)

local gearPoints
describe("LibGearPoints", function()
    setup(function()
        loadfile("Test/TestSetup.lua")(false, 'LibGearPoints')
        SetLocale("deDE")
        loadfile("Libs/LibGearPoints-1.2/Test/BaseTest.lua")()
        LoadDependencies()
        loadfile("Libs/LibGearPoints-1.2/Test/LibGearPointsTestData.lua")()
        ConfigureLogging()
        gearPoints = LibStub('LibGearPoints-1.2')
        gearPoints:SetToStringFn(LibStub('LibUtil-1.1').Objects.ToString)
    end)
    teardown(function()
        After()
    end)
    describe("scaling factor", function()
        it("key can be determined from equipment location", function()
            assert.equal("ranged", gearPoints:GetScaleKey(nil, "Bögen"))
        end)
    end)
end)
