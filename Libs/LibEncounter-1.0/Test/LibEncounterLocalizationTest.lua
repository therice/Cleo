local Encounter, Util

describe("LibEncounter(Localized)", function()
	setup(function()
		loadfile("Test/TestSetup.lua")(false, 'LibEncounter')
		SetLocale("frFR")
		loadfile("Libs/LibEncounter-1.0/Test/BaseTest.lua")()
		LoadDependencies()
		ParseXmlAndLoad('Libs/LibEncounter-1.0/LibEncounter-1.0.xml')
		ConfigureLogging()
		Encounter = LibStub('LibEncounter-1.0', true)
		Util = LibStub('LibUtil-1.1', true)
	end)
	teardown(function()
		After()
	end)
    describe("map ids", function()
        it("resolved from map names", function()
            assert.equal(409, Encounter:GetMapId('Cœur du Magma'))
        end)
    end)
end)