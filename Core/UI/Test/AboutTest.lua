local AddOnName, AddOn, Util

describe("About", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'About')
		Util = LibStub:GetLibrary('LibUtil-1.1')
	end)
	teardown(function()
		After()
	end)

	describe("changelog", function()
		it("is parsed", function()
			local cl = AddOn.GetParsedChangeLog()
			assert(cl)
			print(Util.Objects.ToString(cl))
		end)
	end)
end)