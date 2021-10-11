--- @type AddOn
local _, AddOn = ...
local L = AddOn.Locale
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')

local function LayoutGeneralConfig(container)
	container:Tooltip(L["general_desc"])
	container.minimizeInCombat =
		UI:New('Checkbox', container, L["minimize_in_combat"])
			:Point(20, -30)
			:Tooltip(L['minimize_in_combat_desc'])
			:Datasource(AddOn, AddOn.db.profile, "minimizeInCombat")
	container.test =
		UI:New("Button", container, L["test"])
			:Size(150, 20)
			:Point("TOPLEFT", container.minimizeInCombat, "BOTTOMLEFT", 0, -20)
			:Tooltip(L["test_desc"])
			:OnClick(function() end)
	container.versionCheck =
		UI:New("Button", container, L["version_check"])
			:Size(150, 20)
			:Point("TOPLEFT", container.test, "TOPRIGHT", 25, 0)
			:Tooltip(L["version_check_desc"])
			:OnClick(function() AddOn:CallModule("VersionCheck") end)
	container.sync =
		UI:New("Button", container, L["sync"])
			:Size(150, 20)
			:Point("TOPLEFT", container.versionCheck, "TOPRIGHT", 25, 0)
			:Tooltip(L["sync_desc"])
			:OnClick(function() end)
	container.clearPCache =
		UI:New("Button", container, L["clear_player_cache"])
			:Size(150, 20)
			:Point("TOPLEFT", container.test, "BOTTOMLEFT", 0, -20)
			:Tooltip(L["clear_player_cache_desc"])
			:OnClick(
				function()
					AddOn.Package('Models').Player.ClearCache()
					AddOn:Print("Player cache cleared")
				end
			)
	container.clearICache =
		UI:New("Button", container, L["clear_item_cache"])
			:Size(150, 20)
			:Point("TOPLEFT", container.clearPCache, "TOPRIGHT", 25, 0)
			:Tooltip(L["clear_item_cache_desc"])
			:OnClick(function() end)
			:OnClick(
				function()
					AddOn.Package('Models.Item').Item.ClearCache()
					AddOn:Print("Item cache cleared")
				end
			)
end

function AddOn:ApplyConfiguration(supplements)
	-- add the configuration settings to configuration module if launchpad has been created
	if not self.configUi and self.launchpad then
		supplements[L["general"]] = LayoutGeneralConfig

		local sorted = Util.Tables.Sort(Util.Tables.Keys(supplements))
		-- add a new module section to the launchpad
		local _, config = self.launchpad:AddModule(L["configuration"], L["configuration"], true)
		-- add grey decoration line for tab names
		local dl = UI:New('DecorationLine', config, true,"BACKGROUND",-5):Point("TOPLEFT",config,0,-16):Point("BOTTOMRIGHT",config,"TOPRIGHT", -2,-36)
		-- add enable/disable button
		config.enable =
			UI:New('Checkbox', config, L["enable"], AddOn.enabled)
				:Point("TOPRIGHT", dl, "TOPRIGHT", -75, -1)
				:Tooltip(L['enabled_desc'])
				:Size(18,18):AddColorState():OnClick(
					function(_)
						AddOn.enabled = not AddOn.enabled
						-- being disabled and currently master looter
						if not AddOn.enabled and AddOn:IsMasterLooter() then
							AddOn.masterLooter = nil
							AddOn:MasterLooterModule():Disable()
						else
							AddOn:NewMasterLooterCheck()
						end
					end
				)


		-- create the tabs itself
		config.tabGroup = UI:New('Tabs', config, unpack(sorted)):Point(0, -36):Size(700, 600):SetTo(1)
		config.tabGroup:SetBackdropBorderColor(0,0,0,0)
		config.tabGroup:SetBackdropColor(0,0,0,0)
		config.tabGroup:First():SetPoint("TOPLEFT",0,20)

		for index, module in pairs(sorted) do
			supplements[module](config.tabGroup.tabs[index])
		end

		self.configUi = config
	end
end