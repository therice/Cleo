local AddOnName, AddOn, Util
--- @type UI.MoreInfo
local MI


describe("MoreInfo", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_MoreInfo')
		AddOnLoaded(AddOnName, true)
		Util = AddOn:GetLibrary('Util')
		MI = AddOn.Require('UI.MoreInfo')
	end)

	teardown(function()
		After()
	end)

	describe("operations", function()
		it("updates more info", function()
			local frame = {
				moreInfo = CreateFrame("Frame")
			}
			MI.UpdateMoreInfoWithLootStats(frame, nil, nil)
			assert(not frame.moreInfo:IsVisible())
			MI.UpdateMoreInfoWithLootStats(frame, { { name = 'Player101-Realm1'} }, 1)
			assert(frame.moreInfo:IsVisible())
		end)
	end)
end)