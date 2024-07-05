local AddOnName, AddOn
--- @type Models.Encounter
local Encounter
--- @type LibUtil
local Util

describe("Encounter", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Encounter')
		Encounter = AddOn.Package('Models').Encounter
		Util = AddOn:GetLibrary('Util')
	end)

	teardown(function()
		After()
	end)

	describe("functional", function()
		it("is created from start parameters", function()
			local e = Encounter.Start(1, "encounterName1", 1, 40)
			assert(e.id == 1)
			assert(e.name == "encounterName1")
			assert(e.difficultyId == 1)
			assert(e.groupSize == 40)
			assert(e:IsSuccess():isEmpty())
		end)
		it("is created from end parameters", function()
			local e = Encounter.End(2, "encounterName2", 9, 40, 1)
			assert(e.id == 2)
			assert(e.name == "encounterName2")
			assert(e.difficultyId == 9)
			assert(e.groupSize == 40)
			assert(e:IsSuccess():isPresent())
			assert(e:IsSuccess():get())

			e = Encounter.End(2, "encounterName2", 9, 40)
			assert(e:IsSuccess():isPresent())
			assert(not e:IsSuccess():get())
		end)
		it("is created from start instance", function()
			_G.TempInstanceInfo =
				{"Blackwing Descent", "raid", 6, "25 Player (Heroic)", 25, 0, true, 669, 25, nil}

			local es = Encounter.Start(1, "encounterName1", 1, 40)
			local ee = Encounter.End(es, 2, "encounterName1", 4, 40, 0)

			assert(ee.id == 1)
			assert(ee.name == "encounterName1")
			assert(ee.difficultyId == 4)
			assert(ee.groupSize == 40)
			assert(ee.instanceId == es.instanceId)
			assert(ee:IsSuccess():isPresent())
			assert(not ee:IsSuccess():get())

			finally(function()
				_G.TempInstanceInfo = nil
			end)
		end)
		it("comparable to none", function()
			local e1 = Encounter.None
			local e2 = Encounter.End(2, "encounterName2", 9, 40, 1)
			assert(e1 == Encounter.None)
			assert(e2 ~= Encounter.None)
		end)
	end)
end)