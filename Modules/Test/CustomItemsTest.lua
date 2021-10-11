local AddOnName, AddOn, Util


describe("CustomItems", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_CustomItems')
		Util = AddOn:GetLibrary('Util')
		AddOnLoaded(AddOnName, true)
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local module = AddOn:CustomItemsModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("CustomItems")
			local module = AddOn:CustomItemsModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("CustomItems")
			local module = AddOn:CustomItemsModule()
			assert(module)
			assert(module:IsEnabled())
		end)
	end)

	describe("operations", function()
		local gpc

		before_each(function()
			if AddOn:IsModuleEnabled("CustomItems") then
				AddOn:ToggleModule("CustomItems")
			end
			AddOn:ToggleModule("CustomItems")
			gpc = AddOn:CustomItemsModule()
			PlayerEnteredWorld()
			GuildRosterUpdate()
		end)

		teardown(function()
			AddOn:ToggleModule("CustomItems")
			gpc = nil
		end)

	end)

	describe("ui", function()
		local gpc

		before_each(function()
			if AddOn:IsModuleEnabled("CustomItems") then
				AddOn:ToggleModule("CustomItems")
			end
			AddOn:ToggleModule("CustomItems")
			gpc = AddOn:CustomItemsModule()
			PlayerEnteredWorld()
			GuildRosterUpdate()
		end)

		teardown(function()
			AddOn:ToggleModule("CustomItems")
			gpc = nil
		end)

		it("builds add item frame", function()
			gpc:LayoutInterface(CreateFrame("Frame"))
			local f = gpc:GetAddItemFrame()
			assert(f)
			f.query:SetText(18832)
			f:Query()
			f.add:GetScript("OnClick")()
		end)
	end)
end)