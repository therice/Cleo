local AddOnName, AddOn

describe("Launchpad", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true)
	end)
	teardown(function()
		After()
	end)

	describe("is", function()
		it("created", function()
			AddOnLoaded(AddOnName, true)
			AddOn:ToggleLaunchpad()
		end)
	end)
end)