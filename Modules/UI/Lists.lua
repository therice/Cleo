--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.DropDown
local DropDown = AddOn.Require('UI.DropDown')
--- @type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.List
local List = AddOn.Package('Models.List').List
--- @type Models.Dao
local Dao = AddOn.Package('Models').Dao
--- @type Lists
local Lists = AddOn:GetModule("Lists", true)


local Tabs = {
	[L["list_configs"]]     = L["list_configs_desc"],
	[L["list_lists"]]       = L["list_lists_desc"],
}

function Lists:LayoutInterface(container)
	container:SetWide(1000)

	container.warning =
		UI:New('Text', container, L["warning_persistence_disabled"])
	        :Point("RIGHT", container.banner, "RIGHT", 0, 0)
	        :Color(0.99216, 0.48627, 0.43137, 0.8)
	        :Right()
	        :FontSize(12)
	        :Shadow(true)
	container.ShowPersistenceWarningIfNeeded = function(self)
		if Dao.ShouldPersist() then
			self.warning:Hide()
		else
			self.warning:Show()
		end
	end

	container.tabs = UI:New('Tabs', container, unpack(Util.Tables.Keys(Tabs))):Point(0, -36):Size(1000, 580):SetTo(1)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, description in pairs(Util.Tables.Values(Tabs)) do
		container.tabs.tabs[index]:Tooltip(description)
	end

	self:LayoutConfigurationTab(container.tabs:Get(1))
	self:LayoutListTab(container.tabs:Get(2))
	container:ShowPersistenceWarningIfNeeded()

	self.interfaceFrame = container
end

function Lists:OnModeChange(_, mode)
	if self.interfaceFrame then
		self.interfaceFrame:ShowPersistenceWarningIfNeeded()
	end
end

function Lists:Players(mapFn, ...)
	mapFn = Util.Objects.IsFunction(mapFn) and mapFn or Util.Objects.Noop

	local players = AddOn:Players(true, true, true)
	for _, p in pairs({...}) do
		Logging:Debug("Players() : Evaluating %s", tostring(p))
		local player = Player.Resolve(p)
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

	-- Horizontal line extending from scroll list to right of tab
	UI:New('DecorationLine', tab)
		:Point("TOPLEFT",0,-65)
		:Point("BOTTOMRIGHT",'x',"TOPRIGHT", -2, -66)

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
	-- invoked when a list item is clicked, where index is the numeric id within the list
	tab.configList.SetListValue = function(self, index)
		Logging:Trace("Config(Tab).ConfigList.SetListValue(%d)", index)
		self:GetParent():Update()
	end
	tab.configList:SetList(module:GetService():Configurations())

	-- returns the currently selected configuration
	--- @return Models.List.Configuration
	local function SelectedConfiguration()
		return tab.configList:Selected()
	end

	-- background in which config dropdown and buttons are located
	UI:New('DecorationLine', tab, true,"BACKGROUND",-5)
		:Point("TOPLEFT", tab.configList, 0, 20)
        :Point("BOTTOMRIGHT",tab.configList,"TOPRIGHT",0, 0)

	-- background (colored) which extends beyond the previous one
	tab.banner =
		UI:New('DecorationLine', tab, true, "BACKGROUND",-5)
			:Point("TOPLEFT", tab.configList, "TOPRIGHT", 0, 0)
			:Point("BOTTOMRIGHT", tab, "TOPRIGHT", -2, -46)
			:Color(0.25, 0.78, 0.92, 1, 0.50)

	tab.version =
		UI:New('Text', tab)
	        :Point("LEFT", tab.banner, "LEFT", 5, 0)
	        :Right()
	        :FontSize(11)
	tab.version:Hide()
	tab.version.SetValue = function(self, config)
		if config then
			self:SetText(
				format(
					"%s %s",
				    UIUtil.ColoredDecorator(C.Colors.Aluminum):decorate(config:hash()),
					UIUtil.ColoredDecorator(C.Colors.Aluminum):decorate("(" ..tostring(config.revision) .. ")")
				)
			)
			self:Show()
		else
			self:Hide()
		end
	end
	-- register for callback when configuration is updated (only to update hash and revision)
	self.listsService:RegisterCallbacks(tab, {
	    [Configuration] = {
			[Dao.Events.EntityUpdated] = function(...) tab.version:SetValue(SelectedConfiguration()) end,
        }
    })

	-- delete configuration
	tab.delete =
		UI:New('ButtonMinus', tab)
	        :Point("TOPRIGHT", tab.configList, "TOPRIGHT", -5, 20)
			:Tooltip(L["delete"])
	        :Size(18,18)
			:OnClick(
				function(...)
					module.OnDeleteConfigurationClick(SelectedConfiguration())
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
					local config = module:GetService().Configuration:Create()
					tab.configList:Add(config)
					module:GetService().Configuration:Add(config)
					-- select it in the list
					tab.configList:SetToLast()
					-- update fields to reflect the selected configuration
					tab:Update()
				end
			)

	-- vertical lines on right side of list
	UI:New('DecorationLine', tab)
		:Point("TOPLEFT", tab.configList,"TOPRIGHT",-1,1)
		:Point("BOTTOMLEFT",tab:GetParent(),"BOTTOM",0,-18)
		:Size(1,0)

	tab.name =
		UI:New('EditBox', tab)
	        :Size(425,20)
	        :Point("LEFT", tab.delete, "RIGHT", 15, -35)
	        :Tooltip(L["name"], L["list_config_name_desc"])
			:OnChange(
				Util.Functions.Debounce(
					function(self, userInput)
						Logging:Trace("Configuration[Name].OnChange(%s)", tostring(userInput))
						if userInput then
							local config = SelectedConfiguration()
							config.name = self:GetText()
							module:GetService().Configuration:Update(config, 'name')
							tab.configList:Update()
						end
					end, -- function
					1, -- seconds
					true -- leading
			)
		)

	tab.default =
		UI:New('Checkbox', tab, L["default"])
			:Point("TOPRIGHT", tab.banner, "TOPRIGHT", -45, -2.5)
			:Tooltip(L["list_config_default_desc"])
			:Size(14,14):AddColorState()
			:OnClick(
				function(self)
					local config = SelectedConfiguration()
					if config then
						Logging:Debug("Config.Default.OnClick(%s) : %s", tostring(config.id), tostring(self:GetChecked()))
						-- this will mutate the configurations (only one default)
						-- so set the list to the returned list
						tab.configList:SetList(
							module:GetService():ToggleDefaultConfiguration(config.id, self:GetChecked())
						)
					end
				end
			)

	tab.status =
		UI:New('Dropdown', tab)
	        :Size(175)
			:Point("TOPLEFT", tab.name, "BOTTOMLEFT", 0, -10)
	        :Tooltip(L["status"], L["list_config_status_desc"])
			:MaxLines(3)
			:SetList(Util.Tables.Flip(Configuration.Status))
			:SetClickHandler(
				function(_, _, item)
					local config = SelectedConfiguration()
					Logging:Debug("Config.Status.OnClick(%s) : %s", tostring(config.id), Util.Objects.ToString(item))
					config.status = item.key
					module:GetService().Configuration:Update(config, "status")
					return true
				end
			)

	tab.owner =
		UI:New('Dropdown', tab)
			:SetWidth(175)
			:Point("TOPRIGHT", tab.name, "BOTTOMRIGHT", 0, -10)
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
					module:GetService().Configuration:Update(config, "permissions")
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
			:Point("TOPLEFT", tab.status, "BOTTOMLEFT", 0, -10)
			:Point("TOPRIGHT", tab.name, "BOTTOMRIGHT", 0, -10)
			:Height(210)
			:AvailableTooltip(L["available"], L["list_config_administrators_avail_desc"])
			:SelectedTooltip(L["administrators"], L["list_config_administrators_desc"])
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
					module:GetService().Configuration:Update(config, "permissions")
				end
			)


	tab.SetFieldsEnabled = function(self, enabled)
		-- todo : check that current user is owner
		self.name:SetEnabled(enabled)
		self.default:SetEnabled(enabled)
		self.status:SetEnabled(enabled)
		self.owner:SetEnabled(enabled)
		self.admins:SetEnabled(enabled)
	end

	tab.Update = function(self)
		local config = SelectedConfiguration()
		if config then
			Logging:Trace("Config(Tab).Update(%s)", tostring(config.id))
			self:SetFieldsEnabled(true)
			self.version:SetValue(config)
			self.name:Text(config.name)
			self.default:SetChecked(config.default)
			self.status:SetViaKey(config.status)
			self.owner:Refresh()
			self.admins:Refresh()
		end
	end

	tab:SetFieldsEnabled(false)


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
	-- need to remove the associated lists as well
	local lists = self:GetService().List:GetAll(
			function(list)
				return list.configId == config.id
			end
	)
	if lists then
		for _, list in pairs(lists) do
			self:GetService().List:Remove(list)
		end
	end
	self:GetService().Configuration:Remove(config)
	self.configTab.configList:RemoveSelected()
	self.configTab:Update()
end

local ListTabs = {
	[L["priority"]]     = L["list_list_priority_desc"],
	[L["equipment"]]    = L["list_list_equipment_desc"],
}

function Lists:LayoutListTab(tab)
	local module = self

	tab.lists =
		UI:New('ScrollList', tab)
			:Size(230, 540)
			:Point(1, -46)
			:LinePaddingLeft(2)
			:ScrollWidth(12)
			:LineTexture(15, UIUtil.ColorWithAlpha(C.Colors.White, 0.5), UIUtil.ColorWithAlpha(C.Colors.ItemArtifact, 0.6))
			:LineTextFormatter(function(list) return list.name end)
		    :HideBorders()
	tab.lists.frame.ScrollBar:Size(10,0):Point("TOPRIGHT",0,0):Point("BOTTOMRIGHT",0,0)
	tab.lists.frame.ScrollBar.buttonUp:HideBorders()
	tab.lists.frame.ScrollBar.buttonDown:HideBorders()
	-- invoked when a list item is clicked, where index is the numeric id within the list
	tab.lists.SetListValue = function(self, index)
		Logging:Trace("List(Tab).Lists.SetListValue(%d)", index)
		self:GetParent():Update()
	end

	-- wide bar in which buttons and drop down are located
	UI:New('DecorationLine', tab, true, "BACKGROUND",-5)
	  :Point("TOPLEFT", tab.lists, 0, 30)
	  :Point("BOTTOMRIGHT",tab.lists,"TOPRIGHT",0, 0)

	--- @return Models.List.Configuration
	local function SelectedConfiguration()
		local values = tab.config:Selected()
		local config = #values == 1 and values[1].value or nil
		-- Logging:Debug("SelectedConfiguration() : %s", tostring(config and config.id or nil))
		return config
	end

	--- @return Models.List.List
	local function SelectedList()
		local list = tab.lists:Selected()
		-- Logging:Debug("SelectedList() : %s", tostring(list and list.id or nil))
		return list
	end

	tab.delete =
		UI:New('ButtonMinus', tab)
			:Point("TOPRIGHT", tab.lists, "TOPRIGHT", -5, 25)
			:Tooltip(L["delete"])
			:Size(18,18)
			:OnClick(
				function(...)
					module.OnDeleteListClick(SelectedList())
				end
			)

	tab.add =
		UI:New('ButtonPlus', tab)
			:Point("TOPRIGHT", tab.delete, "TOPRIGHT", -25, 0)
			:Tooltip(L["add"])
			:Size(18,18)
			:OnClick(
				function(...)
					local config = SelectedConfiguration()
					local list = module:GetService().List:Create(config.id)
					tab.lists:Add(list)
					module:GetService().List:Add(list)
					-- select it in the list
					tab.lists:SetToLast()
					-- update fields to reflect the selected list
					tab:Update()
				end
			)

	-- background in which config dropdown and buttons are located
	UI:New('DecorationLine', tab)
	  :Point("TOPLEFT", tab.lists,"TOPRIGHT", -1, 1)
	  :Point("BOTTOMLEFT",tab:GetParent(),"BOTTOM",0,-18)
	  :Size(1,0)

	tab.config =
		UI:New('Dropdown', tab)
			:SetWidth(170)
		    :Point("TOPLEFT", tab.lists, 5, 25)
		    :MaxLines(10)
			:SetTextDecorator(function(item) return item.value.name end)
			:Tooltip(L["configuration"], L["list_config_dd_desc"])
			:OnShow(
				function(self) self:SetList(module:GetService():Configurations()) end, false
			)
			:OnValueChanged(
				function(item)
					local config = item.value
					Logging:Debug("List.Config.OnValueChanged(%s)", tostring(config.id))
					tab.lists:SetList(module:GetService():Lists(config.id))
					tab.lists:ClearSelection()
					tab:Update()
					tab:SetButtonsEnabled(true)
					return true
				end
			)


	tab.name =
		UI:New('EditBox', tab)
		    :Size(425,20)
		    :Point("LEFT", tab.delete, "RIGHT", 15, 2)
		    :Tooltip(L["name"], L["list_list_name_desc"])
			:OnChange(
				Util.Functions.Debounce(
						function(self, userInput)
							Logging:Trace("List[Name].OnChange(%s)", tostring(userInput))
							if userInput then
								local list = SelectedList()
								list.name = self:GetText()
								module:GetService().List:Update(list, 'name')
								tab.lists:Update()
							end
						end, -- function
						1, -- seconds
						true -- leading
				)
			)

	tab.SetButtonsEnabled = function(self, enabled)
		self.add:SetEnabled(enabled)
		self.delete:SetEnabled(enabled)
	end

	tab.SetFieldsEnabled = function(self, enabled)
		self.name:SetEnabled(enabled)
	end

	tab.Update = function(self)
		local config, list = SelectedConfiguration(), SelectedList()
		Logging:Trace("List(Tab).Update() : %s - %s", tostring(config and config.id or nil), tostring(list and list.id or nil))
		self:SetFieldsEnabled(Util.Objects.IsSet(list))
		self:SetButtonsEnabled(Util.Objects.IsSet(config))

		if list then
			self.name:Text(list.name)
		else
			self.name:Text(nil)
		end

		self.version:SetValue(list)

		-- iterate and child tabs and update their fields
		for _, childTab in self.listSettings:IterateTabs() do
			if childTab.Update then
				childTab:Update()
			end
		end
	end

	-- various tabs related to a configuration list
	tab.listSettings = UI:New('Tabs', tab, unpack(Util.Tables.Keys(ListTabs))):Point(230, -65):Size(840, 530):SetTo(1)
	tab.listSettings:SetBackdropBorderColor(0, 0, 0, 0)
	tab.listSettings:SetBackdropColor(0, 0, 0, 0)
	tab.listSettings:First():SetPoint("TOPLEFT", 0, 20)
	tab.listSettings:SetTo(2)

	for index, description in pairs(Util.Tables.Values(ListTabs)) do
		tab.listSettings.tabs[index]:Tooltip(description)
	end

	-- the background for configuration list tabs
	local tabBg =
		UI:New('DecorationLine', tab, true, "BACKGROUND",-5)
			:Point("TOPLEFT", tab.listSettings, 0, 0)
			:Point("BOTTOMRIGHT",tab,"TOPRIGHT", -2, -45)
			:Color(0.25, 0.78, 0.92, 1, 0.50)

	tab.version =
		UI:New('Text', tab)
	        :Point("RIGHT", tabBg, "RIGHT", -5, 0)
	        :Right()
	        :FontSize(11)
	tab.version:Hide()
	tab.version.SetValue = function(self, list)
		if list then
			self:SetText(
				format(
					"%s %s",
					UIUtil.ColoredDecorator(C.Colors.Aluminum):decorate(list:hash()),
					UIUtil.ColoredDecorator(C.Colors.Aluminum):decorate("(" ..tostring(list.revision) .. ")")
				)
			)
			self:Show()
		else
			self:Hide()
		end
	end
	-- register for callback when list is updated (only to update hash and revision)
	self.listsService:RegisterCallbacks(tab, {
		[List] = {
			[Dao.Events.EntityUpdated] = function(...) tab.version:SetValue(SelectedList()) end,
		}
	})

	self:LayoutListEquipmentTab(
		tab.listSettings:GetByName(L["equipment"]),
		SelectedConfiguration,
		SelectedList
	)

	self:LayoutListPriorityTab(
		tab.listSettings:GetByName(L["priority"]),
		SelectedConfiguration,
		SelectedList
	)

	tab:Update()
	self.listTab = tab
end

function Lists.OnDeleteListClick(list)
	Dialog:Spawn(C.Popups.ConfirmDeleteListList, list)
end

function Lists.DeleteListOnShow(frame, list)
	UIUtil.DecoratePopup(frame)
	frame.text:SetText(format(L['confirm_delete_entry'], UIUtil.ColoredDecorator(C.Colors.ItemArtifact):decorate(list.name)))
end

function Lists:DeleteListOnClickYes(_, list)
	self:GetService().List:Remove(list)
	self.listTab.lists:RemoveSelected()
	self.listTab:Update()
end

function Lists:LayoutListEquipmentTab(tab, configSupplier, listSupplier)
	local module = self

	tab.equipment =
		UI:New('DualListbox', tab)
			:Point("TOPLEFT", tab, "TOPLEFT", 20, -35)
			:Point("TOPRIGHT", tab, "TOPRIGHT", -350, 0)
			:Height(210)
			:AvailableTooltip(L["available"], L["equipment_type_avail_desc"])
			:SelectedTooltip(L["equipment_types"], L["equipment_type_desc"])
			:OptionsSorter(
				function(opts)
					local sorted =
						Util(C.EquipmentLocationsSort)
							:CopyFilter(
								function(v)
									return Util.Tables.ContainsKey(opts, v)
								end
							)()
					return sorted
				end
			)
			:OptionsSupplier(
				function()
					local config, list = configSupplier(), listSupplier()
					Logging:Debug("List.Equipment(OptionsSupplier) : %s ", tostring(list and list.id or nil))
					local unassigned = config and module:GetService():UnassignedEquipmentLocations(config.id) or {}
					--[[
					Logging:Debug("%s - %s",
					              Util.Objects.ToString(unassigned),
					              Util.Objects.ToString(Util.Tables.CopySelect(C.EquipmentLocations, unpack(unassigned))))
					--]]
					return
						Util.Tables.CopySelect(C.EquipmentLocations, unpack(unassigned)),
						list and list:GetEquipment(true) or {}
				end
			)
			:OnSelectedChanged(
				function(equipment, added)
					-- translate name into actual type/slot
					local slot = AddOn.GetEquipmentLocation(equipment)
					Logging:Debug("List.Equipment(OnSelectedChanged) : %s/%s, %s", tostring(equipment), tostring(slot), tostring(added))

					local list = listSupplier()
					if list then
						if added then
							list:AddEquipment(slot)
						else
							list:RemoveEquipment(slot)
						end
						module:GetService().List:Update(list, "equipment")
					end
				end
			)

	tab.SetFieldsEnabled = function(self, enabled)
		self.equipment:SetEnabled(enabled)
		if not enabled then self.equipment:Clear() end
	end

	-- will be invoked when a list is selected
	tab.Update = function(self)
		Logging:Debug("List.Equipment(Tab).Update(%s)", tostring(self:IsVisible()))
		if self:IsVisible() then
			local enabled = (configSupplier() and listSupplier())
			self:SetFieldsEnabled(enabled)
			if enabled then
				self.equipment:Refresh()
			end
		end
	end

	tab:SetScript("OnShow", function(self) self:Update() end)
	self.listEquipmentTab = tab
end


local PriorityWidth, PriorityHeight = 150, 18
local EditDragType = {
	Within = 1, -- within existing priorities (reorder)
	Into   = 2, -- new addition to existing priorities (insert)
}
local PriorityActionsMenu, PlayerActionsMenu

function Lists:LayoutListPriorityTab(tab, configSupplier, listSupplier)
	local module = self

	PriorityActionsMenu = MSA_DropDownMenu_Create(C.DropDowns.ListPriorityActions, tab)
	PlayerActionsMenu = MSA_DropDownMenu_Create(C.DropDowns.ListPlayerActions, tab)
	MSA_DropDownMenu_Initialize(PriorityActionsMenu, self.PriorityActionsMenuInitializer, "MENU")
	MSA_DropDownMenu_Initialize(PlayerActionsMenu, self.PlayerActionsMenuInitializer, "MENU")

	local rowsPerColumn, columns = ceil(tab:GetHeight()/(PriorityHeight+6)), min(3, floor(tab:GetWidth()/(PriorityWidth + 25)))
	Logging:Trace("rowsPerColumn=%d, columns=%d", rowsPerColumn, columns)

	local function PriorityCoord(self, xAdjust, yAdjust)
		xAdjust = Util.Objects.IsNumber(xAdjust) and xAdjust or 0
		yAdjust = Util.Objects.IsNumber(yAdjust) and yAdjust or 0

		local column = floor((self.index - 1) / rowsPerColumn)
		local row = ((self.index -1) % rowsPerColumn)
		Logging:Trace(
			"columns=%d, rowsPerColumn=%d, index=%d, column=%d, row=%d",
			columns, rowsPerColumn, self.index, column, row
		)
		return (10 + (column * (PriorityWidth + 15))) + xAdjust, (-20 - (row  * 22)) + yAdjust
	end

	local function EditOnDragStart(self)
		if self:IsMovable() then
			Logging:Debug("EditOnDragStart")
			-- capture the original position
			 _, _, _, self.x, self.y = self:GetPoint()
			self:StartMoving()
		end
	end

	local function EditOnDragStop(self, dragType)
		self:StopMovingOrSizing()

		local function SetText(edit, text)
			edit:Set(text)
		end

		local function SwapText(from, to)
			local textFrom, textTo = from:GetText(), to:GetText()
			SetText(to, textFrom)
			SetText(from, textTo)
		end

		local x, y
		for i = 1, #tab.priorityEdits do
			local target = tab.priorityEdits[i]
			if target:IsMouseOver() and target ~= self then
				if dragType == EditDragType.Within then
					SwapText(self, target)
					x, y = PriorityCoord(self)
				elseif dragType == EditDragType.Into then
					SetText(target, self:GetText())
					x, y = self.x, self.y
				end
				break
			end
		end

		-- not  match, send it back to where it came from
		if not (x and y) then
			x, y = self.x, self.y
		end

		self:NewPoint("TOPLEFT", x, y)
		self:ClearFocus()
	end

	local function EditOnChange(self, isPriority, userInput)
		local playerName, index, priorities = self:GetText(), self.index, self:GetParent().priorities
		Logging:Debug("EditOnChange(%d - %s, %s) : %s", index, tostring(isPriority), tostring(userInput), Util.Objects.Default(playerName, "nil"))
		if Util.Strings.IsSet(playerName) then
			self:SetTextColor(UIUtil.GetPlayerClassColor(playerName):GetRGBA())
		end

		if isPriority then
			Logging:Debug("EditOnChange() : %d => %s", index, tostring(playerName))
			if Util.Strings.IsSet(playerName) then
				priorities[index] = Player:Get(playerName)
			else
				priorities[index] = nil
			end

			if tab:HasPendingChanges() then
				tab.warning:Show()
			else
				tab.warning:Hide()
			end

			tab:UpdateAvailablePlayers()
		end
	end

	-- yuck, yuck, yuck
	local rt = tab:GetParent():GetParent():GetParent():GetParent().banner
	tab.warning =
		UI:New('Text', tab, L["warning_unsaved_changes"])
			:Point("TOPRIGHT", rt, "TOPRIGHT", 0, 17)
			:Color(0.99216, 0.48627, 0.43137, 0.8)
			:Right()
			:FontSize(14)
			:Shadow(true)
	tab.warning:Hide()

	-- this tracks player's priority "edits" which are currently on the list (pure UI element)
	tab.priorityEdits = {}
	-- create individual priority slots (which can be dragged and dropped)
	for index = 1, (columns * rowsPerColumn) do
		local priorityEdit = UI:New('EditBox', tab)
								:Size(PriorityWidth, PriorityHeight)
								:AddXButton()
								:OnChange(function(self, userInput) EditOnChange(self, true, userInput) end)
		tab.priorityEdits[index] = priorityEdit
		priorityEdit.index = index
		priorityEdit:BackgroundText(tostring(index))
		priorityEdit.xButton:Hide()
		priorityEdit.xButton:SetScript(
				"OnClick",
				function(self)
					self:GetParent():Set(nil)
				end
		)
		priorityEdit.Reset = function(self)
			local otcFn = self:GetScript("OnTextChanged")
			self:OnChange(nil)
			self:Set(nil)
			self:OnChange(otcFn)
		end
		priorityEdit.Set = function(self, text)
			self:SetText(text or "")
			if Util.Objects.IsEmpty(text) then
				self:BackgroundText(tostring(self.index))
				self.xButton:Hide()
			else
				self:BackgroundText(nil)
				self.xButton:Show()
			end
			self:SetCursorPosition(1)
		end
		priorityEdit:SetScript("OnMouseDown",
				function(self, button)
					if Util.Strings.Equal(C.Buttons.Right, button) then
						PriorityActionsMenu.module = module
						DropDown.ToggleMenu(1, PriorityActionsMenu, self)
					end
				end
		)
		priorityEdit:SetMovable(true)
		priorityEdit:SetEnabled(false)
		priorityEdit:RegisterForDrag("LeftButton")
		priorityEdit:SetScript("OnDragStart", EditOnDragStart)
		priorityEdit:SetScript("OnDragStop", function(self) EditOnDragStop(self, EditDragType.Within) end)
		priorityEdit:Point("TOPLEFT", PriorityCoord(priorityEdit))
	end

	-- this tracks player "edits" which aren't currently on the list (pure UI element)
	tab.playerEdits = {}
	tab.playersScroll =
		UI:New('ScrollBar', tab)
			:Point("TOP", PriorityCoord(tab.priorityEdits[1], 0, -(PriorityHeight * 1.5)))
			:Point("BOTTOM", 0, (columns * PriorityHeight) - 8)
			:Point("RIGHT", tab, -135, 0)
			:Size(12,558)
			:SetMinMaxValues(0,1)
			:SetValue(0)
			:SetObey(true)
			:OnChange(function() tab:UpdateAvailablePlayers() end)
	tab.playersScroll:SetShown(false)
	tab.playersScroll:SetScript(
			"OnMouseWheel",
			function(self, delta)
				local min, max = self:GetMinMaxValues()
				local val = self:GetValue()
				if (val - delta) < min then
					self:SetValue(min)
				elseif (val - delta) > max then
					self:SetValue(max)
				else
					self:SetValue(val - delta)
				end
			end
	)

	tab.playersInGuild =
		UI:New('Checkbox', tab, L["guild"], false)
			:Point("TOPLEFT", PriorityCoord(tab.priorityEdits[1], (columns + 0.5) * PriorityWidth))
		    :TextSize(10)
		    :OnClick(
				function(self)
					self:GetParent().includeGuild = self:GetChecked()
 					self:GetParent():UpdateAvailablePlayers()
				end
			)
	tab.playersInGuild:SetSize(14, 14)

	tab.playersInRaid =
		UI:New('Checkbox', tab, L["raid"], false)
			:Point("LEFT", tab.playersInGuild, "RIGHT", 40, 0)
			:TextSize(10)
			:OnClick(
				function(self)
					self:GetParent().includeRaid = self:GetChecked()
					self:GetParent():UpdateAvailablePlayers()
				end
			)
	tab.playersInRaid:SetSize(14, 14)

	tab.HasPendingChanges = function(self)
		Logging:Debug("HasPendingChanges() : Orig(%d), Current(%d)", Util.Tables.Count(self.prioritiesOrig), Util.Tables.Count(self.priorities))
		return not Util.Tables.Equals(self.prioritiesOrig, self.priorities, true)
	end

	tab.UpdatePriorities = function(self, reload)
		reload = Util.Objects.IsNil(reload) and true or reload
		local list = listSupplier()

		Logging:Debug("UpdatePriorities(%s) : reload(%s)", list and list.id or 'nil', tostring(reload))

		if reload then
			self.prioritiesOrig, self.priorities = {}, {}
			if list then
				self.prioritiesOrig = list:GetPlayers()
			end
		end

		local priorityCount = reload and #self.prioritiesOrig or table.maxn(self.priorities)
		Logging:Debug("UpdatePriorities(%s) : Count(%d)",  list and list.id or 'nil', priorityCount)

		for priority = 1, priorityCount do
			-- reset it so potential change to previous value still fires the OnTextChanged event
			self.priorityEdits[priority]:Reset()
			local player = reload and self.prioritiesOrig[priority] or self.priorities[priority]
			self.priorityEdits[priority]:Set(player and player:GetShortName() or nil)
		end

		for priority = priorityCount + 1, #self.priorityEdits do
			self.priorityEdits[priority]:Set(nil)
		end
	end

	tab.SavePriorities = function(self)
		local list = listSupplier()
		if list then
			if self:HasPendingChanges() then
				local compacted = Util.Tables.Compact(self.priorities)
				list:SetPlayers(unpack(Util.Tables.Values(compacted)))
				module:GetService().List:Update(list, "players")
				self:UpdatePriorities()
			end
		end
	end

	tab.SetPriority = function(self, player, first)
		local list = listSupplier()
		if list then
			local position
			-- random
			if Util.Objects.IsNil(first) then
				position = math.random(1, table.maxn(self.priorities))
				self.priorities = Util.Tables.Splice2(self.priorities, position, position + 1, {player})
			elseif first then
				Util.Tables.Insert(self.priorities, 1, player)
			else
				Util.Tables.Insert(self.priorities, table.maxn(self.priorities) + 1, player)
			end

			Logging:Debug("SetPriority(%s, %s) : %d", tostring(player), tostring(first), Util.Tables.Count(self.priorities))
			self:UpdatePriorities(false)
		end
	end

	tab.UpdateAvailablePlayers = function(self)
		-- less 3 rows because of headers and footers
		local displayRows = (rowsPerColumn - 3)
		--- @type  table<string, Models.Player>
		local allPlayers = AddOn:Players(self.includeRaid, self.includeGuild, true)
		Logging:Trace("UpdateAvailablePlayers() : all(%d) / list(%d)", Util.Tables.Count(allPlayers), Util.Tables.Count(self.priorities))

		local available =
			Util(allPlayers)
				:CopyFilter(function(player) return not Util.Tables.ContainsValue(self.priorities, player) end)
				:Sort(function(p1, p2) return p1:GetName() < p2:GetName() end)()

		-- update scroll (as needed)
		local overflow = #available - displayRows
		Logging:Trace("UpdateAvailablePlayers() : available(%d), rows(%d), overflow(%d)", Util.Tables.Count(available), displayRows, overflow)
		if overflow > 0 then
			self.playersScroll:SetMinMaxValues(0, overflow)
		else
			self.playersScroll:SetMinMaxValues(0, max(1, #available))
		end

		self.playersScroll:SetShown(overflow > 0 and true or false)

		for index=1, min(displayRows, #available) do
			local playerEdit = self.playerEdits[index]
			-- create individual player slot (which can be dragged and dropped)
			if not playerEdit then
				playerEdit = UI:New('EditBox', tab):Size(PriorityWidth, PriorityHeight):OnChange(function(self, userInput) EditOnChange(self, false, userInput) end)
				self.playerEdits[index] = playerEdit
				playerEdit.index = index
				playerEdit:Point("TOPLEFT", PriorityCoord(playerEdit, (3.5*PriorityWidth), -(PriorityHeight * 1.5)))
				playerEdit:SetFont(playerEdit:GetFont(), 12)
				playerEdit:SetEnabled(false)
				playerEdit:SetMovable(true)
				playerEdit:RegisterForDrag("LeftButton")
				playerEdit:SetScript("OnDragStart", EditOnDragStart)
				playerEdit:SetScript("OnDragStop", function(self) EditOnDragStop(self, EditDragType.Into) end)
			end

			local playerIndex = index + floor(self.playersScroll:GetValue() + 0.5)
			if playerIndex > #available then playerIndex = index end
			
			Logging:Debug("UpdateAvailablePlayers() : index=%d, playerIndex=%d", index, playerIndex)
			playerEdit:SetText(available[playerIndex]:GetShortName())
			playerEdit:SetCursorPosition(1)
			playerEdit:SetScript(
				"OnMouseDown",
				function(self, button)
					if Util.Strings.Equal(C.Buttons.Right, button) then
						PlayerActionsMenu.name = self:GetText()
						PlayerActionsMenu.entry = available[playerIndex]
						PlayerActionsMenu.module = module
						DropDown.ToggleMenu(1, PlayerActionsMenu, self)
					end
				end
			)
			playerEdit:Show()
		end

		for index = #available + 1, #self.playerEdits do
			self.playerEdits[index]:Hide()
		end
	end

	tab.SetFieldsEnabled = function(self, enabled)
		self.playersScroll:Hide()
		self.playersInGuild:SetEnabled(enabled)
		self.playersInRaid:SetEnabled(enabled)
	end

	tab.Update = function(self)
		Logging:Debug("List.Priority(Tab).Update(%s)", tostring(self:IsVisible()))
		if self:IsVisible() then
			-- todo : fix
			local enabled = (configSupplier() and listSupplier())
			self:SetFieldsEnabled(true)
			self:UpdatePriorities()
			--[[
			self:SetFieldsEnabled(enabled)
			if enabled then
				self:LoadPriorities()
			end
			--]]
		end
	end

	tab:SetScript("OnShow", function(self) self:Update() end)
	self.listPriorityTab = tab
end


function Lists:SelectListModuleFn()
	return function(lpad)
		-- select the 'list' module
		lpad:SetModuleIndex(self.interfaceFrame.moduleIndex)
		-- select the 'list' tab
		self.interfaceFrame.tabs:SetTo(2)
		-- select the default configuration

		local configs = self:GetService():Configurations(nil, true)
		if Util.Tables.Count(configs) == 0 then
			configs = self:GetService():Configurations()
		end

		local configId = configs and Util.Tables.Keys(configs)[1] or nil
		if configId then
			self.listTab.config:SetViaKey(configId)
			self.listTab.lists:SetTo(1)
			self.listPriorityTab:Update()
		end
	end
end

do
	local PriorityActionsEntryBuilder =
		DropDown.EntryBuilder()
			:nextlevel()
				:add():text(L["priorities"]):checkable(false):title(true)
				:add():text(L["save"]):checkable(false)
					:disabled(function(_, _, self) return not self.listPriorityTab:HasPendingChanges() end)
					:fn(
						function(_, _, self)
							self.listPriorityTab:SavePriorities()
						end
					)
				:add():text(L["revert"]):checkable(false)
					:disabled(function(_, _, self) return not self.listPriorityTab:HasPendingChanges() end)
					:fn(
						function(_, _, self)
							self.listPriorityTab:UpdatePriorities()
						end
					)

	Lists.PriorityActionsMenuInitializer = DropDown.RightClickMenu(
		Util.Functions.True,
		PriorityActionsEntryBuilder:build()
	)

	local PlayerActionsEntryBuilder =
		DropDown.EntryBuilder()
			:nextlevel()
				:add():text(
					function(name, entry, module)
						return UIUtil.ClassColorDecorator(entry.class):decorate(name)
					end
				):checkable(false):title(true)
				:add():text(L["insert"]):checkable(false):arrow(true)
			:nextlevel()
				:add():text(L["insert_first"]):checkable(false)
					:fn(
						function(_, player, self)
							self.listPriorityTab:SetPriority(player, true)
						end
					)
				:add():text(L["insert_last"]):checkable(false)
					:fn(
						function(_, player, self)
							self.listPriorityTab:SetPriority(player, false)
						end
					)
				:add():text(L["insert_random"]):checkable(false)
					:fn(
						function(_, player, self)
							self.listPriorityTab:SetPriority(player, nil)
						end
					)
	Lists.PlayerActionsMenuInitializer = DropDown.RightClickMenu(
			Util.Functions.True,
			PlayerActionsEntryBuilder:build()
	)
end