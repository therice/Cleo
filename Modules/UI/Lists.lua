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
--- @type LibUtil.Lists.LinkedList
local LinkedList = Util.Lists.LinkedList
--- @type Lists
local Lists = AddOn:GetModule("Lists", true)


local Tabs = {
	[L["list_configs"]]     = L["list_configs_desc"],
	[L["list_lists"]]       = L["list_lists_desc"],
}

function Lists:LayoutInterface(container)
	container:SetWide(1000)

	container.tabs = UI:New('Tabs', container, unpack(Util.Tables.Keys(Tabs))):Point(0, -36):Size(1000, 580):SetTo(1)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, description in pairs(Util.Tables.Values(Tabs)) do
		container.tabs.tabs[index]:Tooltip(description)
	end

	self:LayoutConfigurationTab(container.tabs:Get(1))
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
	tab.configList:SetList(module:Configurations())

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
	UI:New('DecorationLine', tab, true, "BACKGROUND",-5)
		:Point("TOPLEFT", tab.configList, "TOPRIGHT", 0, 0)
		:Point("BOTTOMRIGHT", tab, "TOPRIGHT", -2, -46)
		:Color(0.25, 0.78, 0.92, 1, 0.50)

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
					local config = module.Configuration.Create()
					tab.configList:Add(config)
					module.Configuration:Add(config)
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
			:AvailableTooltip(L["available"], L["administrators_avail_desc"])
			:SelectedTooltip(L["administrators"], L["administrators_desc"])
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


	tab.SetFieldsEnabled = function(self, enabled)
		self.name:SetEnabled(enabled)
		self.owner:SetEnabled(enabled)
		self.admins:SetEnabled(enabled)
	end

	tab.Update = function(self)
		local config = SelectedConfiguration()
		Logging:Trace("Config(Tab).Update(%s)", tostring(config.id))

		self:SetFieldsEnabled(true)

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
	self.Configuration:Remove(config)
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
		Logging:Debug("SelectedConfiguration() : %s", tostring(config and config.id or nil))
		return config
	end

	--- @return Models.List.List
	local function SelectedList()
		local list = tab.lists:Selected()
		Logging:Debug("SelectedList() : %s", tostring(list and list.id or nil))
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
					local list = module.List.Create(config.id)
					tab.lists:Add(list)
					module.List:Add(list)
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
				function(self) self:SetList(module:Configurations()) end, false
			)
			:OnValueChanged(
				function(item)
					local config = item.value
					Logging:Debug("List.Config.OnValueChanged(%s)", tostring(config.id))
					tab.lists:SetList(module:Lists(config.id))
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
			self.name:Datasource(
					module,
					module.db.factionrealm.lists,
					module.List.Key(list, "name"),
					function(value)
						list.name = value
						return value
					end,
					function(...)
						tab.lists:Update()
					end
			)
		else
			self.name:ClearDatasource()
		end

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
	UI:New('DecorationLine', tab.listSettings, true, "BACKGROUND",-5)
		:Point("TOPLEFT", tab.listSettings, 0, 0)
		:Point("BOTTOMRIGHT",tab,"TOPRIGHT", -2, -45)
		:Color(0.25, 0.78, 0.92, 1, 0.50)

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
	self.List:Remove(list)
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
					local unassigned = config and module:UnassignedEquipmentLocations(config.id) or {}
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
						module.List:Update(list, "equipment")
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
end


local PriorityWidth, PriorityHeight = 150, 18
local EditDragType = {
	Within = 1, -- within existing priorities (reorder)
	Into   = 2, -- new addition to existing priorities (insert)
	Out    = 3, -- removal from existing priorities (delete)
}

function Lists:LayoutListPriorityTab(tab, configSupplier, listSupplier)
	local module = self
	local rowsPerColumn, columns = ceil(tab:GetHeight()/(PriorityHeight+6)), min(3, floor(tab:GetWidth()/(PriorityWidth + 25)))

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
			-- capture the original posisiton
			 _, _, _, self.x, self.y = self:GetPoint()
			self:StartMoving()
		end
	end

	local function EditOnDragStop(self, dragType)
		self:StopMovingOrSizing()

		local function SetText(edit, text, bgText)
			edit:SetText(text)
			if Util.Objects.IsEmpty(text) then
				edit:BackgroundText(bgText)
				edit.xButton:Hide()
			else
				edit:BackgroundText(nil)
				edit.xButton:Show()
			end
			edit:SetCursorPosition(1)
		end

		local function SwapText(from, to)
			local textFrom, textTo = from:GetText(), to:GetText()
			SetText(to, textFrom, tostring(to.index))
			SetText(from, textTo, tostring(from.index))
		end

		local x, y
		for i = 1, #tab.priorityEdits do
			local target = tab.priorityEdits[i]
			if target:IsMouseOver() and target ~= self then
				if dragType == EditDragType.Within then
					SwapText(self, target)
					x, y = PriorityCoord(self)
				elseif dragType == EditDragType.Into then
					SetText(target, self:GetText(), nil)
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

	local function EditOnChange(self, isPriority)
		local playerName, index, priorities = self:GetText(), self.index, self:GetParent().priorities
		Logging:Debug("EditOnChange(%d) : %s", index, Util.Objects.Default(playerName, "nil"))
		if Util.Strings.IsSet(playerName) then
			self:SetTextColor(UIUtil.GetPlayerClassColor(playerName):GetRGBA())
		end

		if isPriority then
			if Util.Strings.IsSet(playerName) then
				priorities[index] = Player:Get(playerName)
			else
				priorities[index] = nil
			end

			Logging:Debug("Priorities => %s", Util.Objects.ToString(Util.Tables.Keys(priorities)))
			self:GetParent():UpdateAvailablePlayers()
		end
	end

	-- this tracks player's priority "edits" which are currently on the list (pure UI element)
	tab.priorityEdits = {}
	-- create individual priority slots (which can be dragged and dropped)
	for index = 1, (columns * rowsPerColumn) do
		local priorityEdit = UI:New('EditBox', tab):Size(PriorityWidth, PriorityHeight)
								:AddXButton()
								:OnChange(function(self) EditOnChange(self, true) end)
		tab.priorityEdits[index] = priorityEdit
		priorityEdit.index = index
		priorityEdit:BackgroundText(tostring(index))
		priorityEdit.xButton:Hide()
		priorityEdit.xButton:SetScript(
				"OnClick",
				function(self)
					local edit = self:GetParent()
					edit:Text(nil)
					edit:BackgroundText(tostring(edit.index))
					edit.xButton:Hide()
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
	tab.playersInGuild:SetSize(12, 12)


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
	tab.playersInRaid:SetSize(12, 12)


	tab.LoadPriorities = function(self)
		local list = listSupplier()
		-- capture current priority list, allows for in-memory manipulation and reverts
		if list then
			self.priorities = list:GetPlayers():toTable()
		else
			self.priorities = {}
		end
	end

	-- todo : memoize this shit
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
				playerEdit = UI:New('EditBox', tab):Size(PriorityWidth, PriorityHeight):OnChange(function(self) EditOnChange(self, false) end)
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
			local enabled = (configSupplier() and listSupplier())

			self:SetFieldsEnabled(true)
			self:LoadPriorities()

			--[[
			self:SetFieldsEnabled(enabled)
			if enabled then
				self:LoadPriorities()
			end
			--]]
		end
	end

	tab:SetScript("OnShow", function(self) self:Update() end)
end
