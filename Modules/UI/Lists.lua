--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Lists
local Lists = AddOn:GetModule("Lists", true)


local Tabs = {
	[L["list_configs"]]     = L["list_configs_desc"],
	[L["list_lists"]]       = L["list_lists_desc"],
}

function Lists:LayoutInterface(container)
	container.tabs = UI:NewNamed('Tabs', container, "Tabs", unpack(Util.Tables.Keys(Tabs))):Point(0, -36):Size(840, 580):SetTo(1)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, description in pairs(Util.Tables.Values(Tabs)) do
		container.tabs.tabs[index]:Tooltip(description)
	end

	self:LayoutConfigurationTab(container.tabs:First())
	self:LayoutListTab(container.tabs:Get(2))
end

function Lists:Players(mapFn, ...)
	mapFn = Util.Objects.IsFunction(mapFn) and mapFn or Util.Objects.Noop

	local players = AddOn:Players(true, true, true)
	for _, p in pairs({...}) do
		Logging:Debug("Players() : Evaluating %s", tostring(p))
		local player = Player:Get((Util.Objects.IsTable(p) and p:isInstanceOf(Player)) and p:GetName() or p)
		if player and not players[player:GetShortName()] then
			players[player:GetShortName()] = player
		else
			players[player:GetShortName()] = {}
		end
	end

	return mapFn(players)
end

function Lists:LayoutConfigurationTab(tab)
	local module = self

	UI:New('DecorationLine', tab)
		:Point("TOPLEFT",0,-65)
		:Point("BOTTOMRIGHT",'x',"TOPRIGHT", 8, -66)

	tab.configList =
		UI:New('ScrollList', tab)
			:Size(230, 540)
			:Point(1, -66)
			:LinePaddingLeft(2)
			:ScrollWidth(12)
			:LineTexture(15, UIUtil.ColorWithAlpha(C.Colors.White, 0.5), UIUtil.ColorWithAlpha(C.Colors.ItemArtifact, 0.6))
			:HideBorders()
	tab.configList.frame.ScrollBar:Size(10,0):Point("TOPRIGHT",0,0):Point("BOTTOMRIGHT",0,0)
	tab.configList.frame.ScrollBar.buttonUp:HideBorders()
	tab.configList.frame.ScrollBar.buttonDown:HideBorders()
	-- invoked when a lis item is clicked, where index is the numeric id within the list
	tab.configList.SetListValue = function(self, index)
		Logging:Trace("Config(Tab).ConfigList.SetListValue(%d)", index)
		self:GetParent():UpdateFields()
	end
	tab.configList:SetList(module:Configurations())

	-- returns the currently selected configuration
	--- @return Models.List.Configuration
	local function SelectedConfiguration()
		return tab.configList:Selected()
	end

	UI:New('DecorationLine', tab, true,"BACKGROUND",-5)
	  :Point("TOPLEFT", tab.configList, 0, 20)
	  :Point("BOTTOMRIGHT",tab.configList,"TOPRIGHT",0, 0)

	-- delete configuration
	tab.delete =
		UI:New('ButtonMinus', tab)
	        :Point("TOPRIGHT", tab.configList, "TOPRIGHT", -5, 20)
			:Tooltip(L["delete"])
	        :Size(18,18)
			:OnClick(
				function(...)
					Lists.OnDeleteConfigurationClick(SelectedConfiguration())
				end
			)
	-- add configuration
	tab.add =
		UI:New('ButtonPlus', tab)
			:Point("TOPRIGHT", tab.delete, "TOPRIGHT", -25, 0)
			:Tooltip(L["add"])
		    :Size(18,18)
			:OnClick(
				function(...)
					-- create and persist new configuration
					local config = module.Configuration.Create()
					tab.configList:Add(config)
					-- todo : can insert alphabetically instead of blindly adding
					module.Configuration:Add(config)
					-- select it in the list
					tab.configList:SetToLast()
					-- update fields to reflect the selected configuration
					tab:UpdateFields()
				end
			)

	UI:New('DecorationLine', tab.configList.frame.ScrollBar)
		:Point("TOPLEFT",-1,1)
		:Point("BOTTOMRIGHT",'x',"BOTTOMLEFT",0,0)

	UI:New('DecorationLine', tab)
		:Point("TOPLEFT", tab.configList,"TOPRIGHT",0,1)
		:Point("BOTTOMLEFT",tab:GetParent(),"BOTTOM",0,-18)
		:Size(1,0)

	tab.name =
		UI:New('EditBox', tab)
	        :Size(425,20)
	        :Point("LEFT", tab.delete, "RIGHT", 15, -25)
	        :Tooltip(L["name"], L["list_config_name_desc"])

	tab.owner =
		UI:New('Dropdown', tab)
			:SetWidth(150)
			:Point("TOPLEFT", tab.name, "BOTTOMLEFT", 0, -10)
			:Tooltip(L["owner"], L["list_config_owner_desc"])
			:MaxLines(10)
			:SetTextDecorator(
				function(item)
					return UIUtil.PlayerClassColorDecorator(item.value):decorate(item.value)
				end
			)
			:SetClickHandler(
				function(_, _, item)
					local config = SelectedConfiguration()
					Logging:Debug("Config.Owner.OnClick(%s) : %s", tostring(config.id), Util.Objects.ToString(item))
					config:SetOwner(item.value)
					module.Configuration:Update(config, "permissions")
					return true
				end
			)
	tab.owner.Refresh = function(self)
		local config = SelectedConfiguration()
		local owner = config:GetOwner()

		local players =
			module:Players(
				function(t) return Util.Tables.Sort(Util.Tables.Keys(t)) end,
				owner
			)
		self:SetList(players)
		if owner then
			self:SetViaValue(owner:GetShortName())
		end
	end

	-- admin selection start
	tab.admins =
		UI:New('DualListbox', tab)
			:Point("TOPLEFT", tab.owner, "BOTTOMLEFT", 0, -10)
			:Point("TOPRIGHT", tab.name, "BOTTOMRIGHT", 0, -10)
			:Height(210)
			:LineTextFormatter(
				function(player)
					return UIUtil.ClassColorDecorator(player.class):decorate(player:GetShortName())
				end
			)
			:OptionsSupplier(
				function()
					local config = SelectedConfiguration()
					local owner = config:GetOwner()
					Logging:Debug("Config.Admins(OptionsSupplier) : id=%s owner=%s", tostring(config.id), tostring(owner))
					local admins = config:GetAdministrators()
					local available =
						module:Players(
							function(t)
								if owner then
									Util.Tables.Remove(t, owner:GetShortName())
								end
								return t
							end
						)

					-- todo : remove from available list those who are in admins as well (in case it was us)
					return available, Util.Tables.Sort(admins)
				end
			)
			:OnSelectedChanged(
				function(player, added)
					Logging:Debug("Config.Admins(OnSelectedChanged) : %s, %s", tostring(player), tostring(added))
					local config = SelectedConfiguration()
					if added then
						config:GrantPermissions(player, Configuration.Permissions.Admin)
					else
						config:RevokePermissions(player, Configuration.Permissions.Admin)
					end
					module.Configuration:Update(config, "permissions")
				end
			)


	tab.UpdateFields = function(self)
		local config = SelectedConfiguration()
		Logging:Trace("Config(Tab).UpdateFields(%s)", tostring(config.id))

		self.name:Datasource(
			module,
			module.db.factionrealm.configurations,
			module.Configuration.Key(config, "name"),
			function(value)
				config.name = value
				return value
			end,
			function(...)
				tab.configList:Update()
			end
		)

		self.owner:Refresh()
		self.admins:Refresh()
	end

	self.configTab = tab
end

function Lists.OnDeleteConfigurationClick(config)
	Dialog:Spawn(C.Popups.ConfirmDeleteListConfig, config)
end

function Lists.DeleteConfigurationOnShow(frame, config)
	UIUtil.DecoratePopup(frame)
	frame.text:SetText(format(L['confirm_delete_entry'], UIUtil.ColoredDecorator(C.Colors.ItemArtifact):decorate(config.name)))
end

function Lists:DeleteConfigurationOnClickYes(_, config)
	self.Configuration:Remove(config)
	self.configTab.configList:RemoveSelected()
	self.configTab:UpdateFields()
end

function Lists:LayoutListTab(tab)
	local module = self

	UI:New('DecorationLine', tab)
	  :Point("TOPLEFT",0, -45)
	  :Point("BOTTOMRIGHT",'x',"TOPRIGHT", 8, -46)

	tab.lists =
		UI:New('ScrollList', tab)
		  :Size(230, 540)
		  :Point(1, -46)
		  :LinePaddingLeft(2)
		  :ScrollWidth(12)
		  :LineTexture(15, UIUtil.ColorWithAlpha(C.Colors.White, 0.5), UIUtil.ColorWithAlpha(C.Colors.ItemArtifact, 0.6))
		  :HideBorders()
	tab.lists.frame.ScrollBar:Size(10,0):Point("TOPRIGHT",0,0):Point("BOTTOMRIGHT",0,0)
	tab.lists.frame.ScrollBar.buttonUp:HideBorders()
	tab.lists.frame.ScrollBar.buttonDown:HideBorders()

	-- wide bar in which buttons and drop down are located
	UI:New('DecorationLine', tab, true, "BACKGROUND",-5)
	  :Point("TOPLEFT", tab.lists, 0, 30)
	  :Point("BOTTOMRIGHT",tab.lists,"TOPRIGHT",0, 0)

	tab.delete =
		UI:New('ButtonMinus', tab)
		  :Point("TOPRIGHT", tab.lists, "TOPRIGHT", -5, 25)
		  :Tooltip(L["delete"])
		  :Size(18,18)

	tab.add =
		UI:New('ButtonPlus', tab)
		  :Point("TOPRIGHT", tab.delete, "TOPRIGHT", -25, 0)
		  :Tooltip(L["add"])
		  :Size(18,18)

	UI:New('DecorationLine', tab.lists.frame.ScrollBar)
	  :Point("TOPLEFT",-1,1)
	  :Point("BOTTOMRIGHT",'x',"BOTTOMLEFT",0,0)

	UI:New('DecorationLine', tab)
	  :Point("TOPLEFT", tab.lists,"TOPRIGHT",0,1)
	  :Point("BOTTOMLEFT",tab:GetParent(),"BOTTOM",0,-18)
	  :Size(1,0)

	local function SelectedConfiguration()
		local value = tab.config:GetValue()
		return #value == 1 and value[1] or nil
	end

	tab.config =
		UI:New('Dropdown', tab)
			:SetWidth(170)
		    :Point("TOPLEFT", tab.lists, 5, 25)
		    :MaxLines(10)
			:SetTextDecorator(function(item) return item.value.name end)
			:Tooltip(L["configuration"], L["list_config_dd_desc"])
			:SetList(module:Configurations())



	self.listTab = tab
end