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
--- @type UI.MoreInfo
local MI = AddOn.Require('UI.MoreInfo')
--- @type Models.DateFormat
local DateFormat = AddOn.ImportPackage('Models').DateFormat
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
--- @type ListsDataPlane
local ListsDp = AddOn:GetModule("ListsDataPlane", true)
--- @type LibGuildStorage
local GuildStorage = AddOn:GetLibrary("GuildStorage")

local Tabs = {
	[L["list_configs"]]     = L["list_configs_desc"],
	[L["list_lists"]]       = L["list_lists_desc"],
}

local function AlphabeticalOrder(list)
	local order, index = {}, 1
	for v, _ in Util.Tables.OrderedPairs(Util.Tables.Flip(list, function(c) return c.name end)) do
		order[index] = v.id
		index = index + 1
	end
	return order
end

function Lists:LayoutInterface(container)
	container:SetWide(1150)

	container.warning =
		UI:New('Text', container, L["warning_persistence_disabled"])
	        :Point("RIGHT", container.banner, "RIGHT", -5, 0)
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

	container.tabs =
		UI:New('Tabs', container, unpack(Util.Tables.Sort(Util.Tables.Keys(Tabs))))
			:Point(0, -36):Size(1150, 580):SetTo(1)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, key in ipairs(Util.Tables.Sort(Util.Tables.Keys(Tabs))) do
		container.tabs.tabs[index]:Tooltip(Tabs[key])
	end

	self:LayoutConfigurationTab(container.tabs:Get(1))
	self:LayoutListTab(container.tabs:Get(2))
	container:ShowPersistenceWarningIfNeeded()

	self.interfaceFrame = container
end

-- this is invoked as result of a ModeChanged message
function Lists:OnModeChange(_, mode, flag, enabled)
	-- ignore it unless the flag was persistence mode
	if (flag == C.Modes.Persistence) and self.interfaceFrame then
		self.interfaceFrame:ShowPersistenceWarningIfNeeded()
	end
end

-- this is invoked as result of a ResourceRequestCompleted message
function Lists:OnResourceRequestCompleted(_, resource)
	local ok,msg = pcall(
		function()
			if Util.Objects.IsInstanceOf(resource, Configuration) and self.configTab then
				self.configTab:Refresh(resource)
			end

			if Util.Objects.IsInstanceOf(resource, List) and self.listTab then
				self.listTab:Refresh(resource)
			end
		end
	)

	if not ok then
		Logging:Error("OnResourceRequestCompleted() : %s", tostring(msg))
	end
end

-- will refresh any displayed UI element with updated data
function Lists:Refresh()
	local ok, msg = pcall(
		function()
			if self.interfaceFrame then
				if self.configTab:IsVisible() then
					self.configTab:Refresh()
				end
				if self.listTab:IsVisible() then
					self.listTab:Refresh()
				end
			end
		end
	)

	if not ok then
		Logging:Error("Refresh() : %s", tostring(msg))
	end
end

function Lists:Players(mapFn, ...)
	mapFn = Util.Objects.IsFunction(mapFn) and mapFn or Util.Objects.Noop

	local players = AddOn:Players(true, true, true)
	for _, p in pairs({...}) do
		-- Logging:Trace("Players() : Evaluating %s", tostring(p))
		local player = Player.Resolve(p)
		if player and not players[player:GetShortName()] then
			players[player:GetShortName()] = player
		else
			players[player:GetShortName()] = {}
		end
	end

	return mapFn(players)
end

local ConfigTabs = {
	[L["list_alts"]] = L["list_alts_desc"],
	[L["general"]]   = L["general_desc"],
}

local ConfigActionsMenu

function Lists:LayoutConfigurationTab(tab)
	local module = self

	ConfigActionsMenu = MSA_DropDownMenu_Create(C.DropDowns.ConfigActions, tab)
	MSA_DropDownMenu_Initialize(ConfigActionsMenu, self.ConfigActionsMenuInitializer, "MENU")
	ConfigActionsMenu.module = module

	tab.configList =
		UI:New('ScrollList', tab)
			:Size(230, 540)
			:Point(1, -56)
			:LinePaddingLeft(2)
			:ScrollWidth(12)
			:LineTexture(15, UIUtil.ColorWithAlpha(C.Colors.White, 0.5), UIUtil.ColorWithAlpha(C.Colors.ItemArtifact, 0.6))
			:HideBorders()
	tab.configList.frame.ScrollBar:Size(10,0):Point("TOPRIGHT",0,0):Point("BOTTOMRIGHT",0,0)
	tab.configList.frame.ScrollBar.buttonUp:HideBorders()
	tab.configList.frame.ScrollBar.buttonDown:HideBorders()
	-- invoked when a list item is clicked, where index is the numeric id within the list
	tab.configList.SetListValue = function(self, index, button, ...)
		Logging:Trace("Config(Tab).ConfigList.SetListValue(%d)", index)
		self:GetParent():Update()
		self.List[index]:SetScript(
			"OnMouseDown",
			function(self, button)
				if Util.Strings.Equal(C.Buttons.Right, button) then
					Logging:Trace("Config(Tab).ConfigList.OnMouseDown(%s)", tostring(index))
					ConfigActionsMenu.entry = tab.configList:Selected()
					DropDown.ToggleMenu(1, ConfigActionsMenu, self, 100)
				end
			end
		)
	end

	local configs = module:GetService():Configurations()
	tab.configList:SetList(configs, AlphabeticalOrder(configs))

	-- returns the currently selected configuration
	--- @return Models.List.Configuration
	local function SelectedConfiguration()
		Logging:Trace("SelectedConfiguration()")
		return tab.configList:Selected()
	end

	-- background in which config dropdown and buttons are located
	local bg =
		UI:New('DecorationLine', tab, true,"BACKGROUND",-5)
			:Point("TOPLEFT", tab.configList, 0, 20)
            :Point("BOTTOMRIGHT",tab.configList,"TOPRIGHT",0, 0)

	-- background (colored) which extends beyond the previous one
	tab.banner =
		UI:New('DecorationLine', tab, true, "BACKGROUND",-5)
			:Point("TOPLEFT", bg, "TOPRIGHT", 0, 0)
			:Point("BOTTOMRIGHT", tab, "TOPRIGHT", -2, -56)
			:Color(0.25, 0.78, 0.92, 1, 0.50)

	-- vertical lines on right side of list
	UI:New('DecorationLine', tab)
	  :Point("TOPLEFT", tab.configList,"TOPRIGHT", -1, 1)
	  :Point("BOTTOMLEFT",tab:GetParent(),"BOTTOM",0,-18)
	  :Size(1,0)


	MI.EmbedWidgets(self:GetName() .. "_Configuration", tab, function(...) self:UpdateMoreInfo(...) end)
	tab.moreInfoBtn:SetPoint("TOPRIGHT", tab.banner, "TOPRIGHT", -5, 2)

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

	-- various tabs related to a configuration list
	tab.configSettings = UI:New('Tabs', tab, unpack(Util.Tables.Sort(Util.Tables.Keys(ConfigTabs)))):Point(230, -56):Size(840, 530):SetTo(1)
	tab.configSettings:SetBackdropBorderColor(0, 0, 0, 0)
	tab.configSettings:SetBackdropColor(0, 0, 0, 0)
	tab.configSettings:First():SetPoint("TOPLEFT", 0, 20)
	tab.configSettings:SetTo(2)

	for index, key in ipairs(Util.Tables.Sort(Util.Tables.Keys(ConfigTabs))) do
		tab.configSettings.tabs[index]:Tooltip(ConfigTabs[key])
	end

	tab.SetButtonsEnabled = function(self, config)
		local enabled = config and config:IsOwner()
		self.delete:SetEnabled(enabled)
	end

	tab.Update = function(self)
		local config = SelectedConfiguration()
		MI.Update(tab, config)
		self:SetButtonsEnabled(config)

		for _, childTab in self.configSettings:IterateTabs() do
			if childTab.Update then
				childTab:Update()
			end
		end
	end

	tab.Refresh = function(self, config)
		local cs = module:GetService():Configurations()
		self.configList:SetList(cs, AlphabeticalOrder(cs))
		self:ConfigurationUpdated(nil, {entity=config})
	end

	-- handles updates to configuration, both via UI and external sources
	tab.ConfigurationUpdated = function(self, _, detail)
		--Logging:Debug("ConfigurationUpdated() : %s", Util.Objects.ToString(detail))

		local config = detail.entity
		if config then
			--Logging:Debug("ConfigurationUpdated() : Resolving %s [%s]", tostring(config), tostring(config.id))
			self.configList:Set(config, function(item) return Util.Strings.Equal(config.id, item.id) end)
		end

		self:Update()
	end

	-- register for callback when configuration is updated
	self.listsService:RegisterCallbacks(tab, {
		[Configuration] = {
			[Dao.Events.EntityUpdated] = function(...)
				tab:ConfigurationUpdated(...)
			end,
		}
	})

	self:LayoutConfigAltsTab(
		tab.configSettings:GetByName(L["list_alts"]),
		SelectedConfiguration
	)

	self:LayoutConfigGeneralTab(
		tab.configSettings:GetByName(L["general"]),
		SelectedConfiguration
	)

	tab:Update()
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

function Lists:ExportFrame()
	if not self.exportFrame then
		local f = UI:Popup(UIParent, 'ExportConfigurationOrList', self:GetName(), L['frame_export_config_or_list'], 550, 450)
		f.name = UI:New('Text', f.content):Size(200,15):Point("LEFT", f.banner, "LEFT", 20, 0):Color(C.Colors.White:GetRGB())

		local detail =
			UI:NewNamed('MultiLineEditBox', f.content, 'ExportDetail')
				:Point("CENTER", f.content, "CENTER", 0, 0)
				:Point("TOPLEFT", f.banner, "BOTTOMLEFT", 15, -15)
				:Size(f:GetWidth() - 25, f:GetHeight() - 75)
		f.detail = detail

		self.exportFrame = f
	end

	return self.exportFrame
end

--- @param config Models.List.Configuration
function Lists:ExportConfig(config)
	Logging:Debug("ExportList(%s)", tostring(config))
	local exportFrame = self:ExportFrame()
	if not exportFrame:IsVisible() then
		exportFrame.name:SetText(config.name)
		exportFrame.detail:SetText("")

		local csv = self:GetService():ToCsv(config)
		for _, line in pairs(csv) do
			exportFrame.detail:Append(Util.Strings.Join(',', unpack(line)) .. '\n')
		end
		exportFrame:Show()
		exportFrame.detail:SetFocus()
		exportFrame.detail:HighlightText()
	end
end

local PlayerWidth, PlayerHeight, MaxAlts, AltWidthReduction = 125, 15, 3, 15
local EditDragType = {
	Within = 1, -- within existing values (reorder)
	Into   = 2, -- new addition to existing values (insert)
}

local ConfigAltsActionMenu

function Lists:LayoutConfigAltsTab(tab, configSupplier)
	local module = self

	ConfigAltsActionMenu = MSA_DropDownMenu_Create(C.DropDowns.ConfigAltActions, tab)
	MSA_DropDownMenu_Initialize(ConfigAltsActionMenu, self.ConfigAltsMenuInitializer, "MENU")

	-- minor positioning and size tweaks
	tab:SetPoint("TOPLEFT", 15, -10)

	local rowsPerColumn, columns =
		ceil(tab:GetHeight()/(PlayerHeight + 6)), min(5, floor(tab:GetWidth()/(PlayerWidth + 25)))

	-- need main + max alts grouped together, don't overflow into next column
	rowsPerColumn = rowsPerColumn - (rowsPerColumn % (MaxAlts + 1))

	local function PriorityCoord(self, xAdjust, yAdjust)
		xAdjust = Util.Objects.IsNumber(xAdjust) and xAdjust or 0
		yAdjust = Util.Objects.IsNumber(yAdjust) and yAdjust or 0
		local column = floor((self.index - 1) / rowsPerColumn)
		local row = ((self.index -1) % rowsPerColumn)

		-- shift to right
		if not self.isMain then
			xAdjust = xAdjust + AltWidthReduction
		end

		return (10 + (column * (PlayerWidth + 15))) + xAdjust, (-20 - (row  * 22)) + yAdjust
	end

	local function EditOnDragStart(self)
		if self:IsMovable() then
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
		for i = 1, #tab.altEdits do
			local target = tab.altEdits[i]
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


	-- the implementation of this function is garbage
	local function EditOnChange(self, isPlayer, userInput)
		local playerName, priorValue, isMain, index =
			self:GetText(), self.priorValue, self.isMain, self.index

		if Util.Objects.IsEmpty(playerName) then playerName = nil end
		if Util.Objects.IsEmpty(priorValue) then priorValue = nil end

		Logging:Trace(
			"EditOnChange(%s, %d, %s, %s) : %s / %s",
			tostring(isPlayer), index, tostring(isMain), tostring(userInput),
			tostring(playerName), tostring(priorValue)

		)

		if playerName then
			local color = UIUtil.GetPlayerClassColor(playerName)
			if Util.Objects.IsFunction(color.GetRGBA) then
				self:SetTextColor(color:GetRGBA())
			else
				self:SetTextColor(unpack(color))
			end
		end

		if isPlayer then
			-- clear the cache of processed players
			Util.Tables.Wipe(self:GetParent().playersCache)

			if isMain then
				-- if the main was removed, the alts have no meaning - wipe them
				if not playerName and priorValue then
					Logging:Trace("EditOnChange()[main] : %s (previous) cleared", tostring(priorValue))
					for i = index + 1, index + MaxAlts do
						self:GetParent().altEdits[i]:Reset()
					end
				end
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
	        :FontSize(12)
	        :Shadow(true)
	tab.warning:Hide()

	tab.altEdits = {}
	for index = 1, (columns * rowsPerColumn) do
		local isMain = ((index) % (MaxAlts + 1)) == 1

		local altEdit =
			UI:New('EditBox', tab)
				:Size(PlayerWidth - (isMain and 0 or AltWidthReduction), PlayerHeight)
		        :AddXButton()
				:OnChange(function(self, userInput) EditOnChange(self, true, userInput) end)

		tab.altEdits[index] = altEdit
		altEdit.index = index
		altEdit.isMain = isMain
		altEdit:BackgroundText(altEdit.isMain and "Main" or "Alt")
		altEdit.xButton:Hide()
		altEdit.xButton:SetScript(
			"OnClick",
			function(self)
				self:GetParent():Set(nil)
			end
		)
		altEdit.Reset = function(self)
			local otcFn = self:GetScript("OnTextChanged")
			self:OnChange(nil)
			self:Set(nil)
			self:OnChange(otcFn)
			self.priorValue = nil
		end
		altEdit.Set = function(self, text)
			self.priorValue = self:GetText()
			self:SetText(text or "")
			if Util.Objects.IsEmpty(text) then
				self:BackgroundText(self.isMain and "Main" or "Alt")
				self.xButton:Hide()
			else
				self:BackgroundText(nil)
				-- bind this to whether edit is movable
				-- if not movable, then set to inactive due to permissions
				if self:IsMovable() then self.xButton:Show() end
			end
			self:SetCursorPosition(1)
		end
		altEdit.SetActive = function(self, active)
			self:SetMovable(active)
			if active then
				self:RegisterForDrag("LeftButton")
			else
				self:RegisterForDrag()
			end
			self:SetScript("OnDragStart", active and EditOnDragStart or nil)
			self:SetScript("OnDragStop", active and function(e) EditOnDragStop(e, EditDragType.Within) end or nil)
			if active then self.xButton:Show() else self.xButton:Hide() end
		end

		altEdit:SetScript("OnMouseDown",
			function(self, button)
				if Util.Strings.Equal(C.Buttons.Right, button) then
					ConfigAltsActionMenu.module = module
					DropDown.ToggleMenu(1, ConfigAltsActionMenu, self)
				end
			end
		)

		altEdit:SetEnabled(false)
		altEdit:Point("TOPLEFT", PriorityCoord(altEdit))
		altEdit:SetActive(true)
	end


	tab.playersScroll =
		UI:New('ScrollBar', tab)
			:Point("TOP", PriorityCoord(tab.altEdits[1], 0, -(PlayerHeight * 1.5)))
			:Point("BOTTOM", 0, ((columns - 1.8) * PlayerHeight) - PlayerHeight)
			:Point("RIGHT", tab, 20, 0)
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
			:Point("TOPLEFT", PriorityCoord(tab.altEdits[1], (columns + 0.6) * PlayerWidth))
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
		local config, changes = configSupplier(), false
		if config then
			changes = not Util.Tables.Equals(config:GetAlternates(), self:ProcessPlayers(), true)
		end

		Logging:Trace("HasPendingChanges(%s)", tostring(changes))
		return changes
	end

	tab.playersCache = {}
	tab.ProcessPlayers = Util.Memoize.Memoize(
		function(self)
			Logging:Trace("ProcessPlayers()")

			local players = {}
			-- iterate through main indexes
			for mainIndex = 1, (columns * rowsPerColumn), (MaxAlts + 1) do
				local mainName = self.altEdits[mainIndex]:GetText()
				if Util.Objects.IsSet(mainName) then
					local main, alts = Player:Get(mainName), {}
					Logging:Trace("ProcessPlayers(%d) : %s", mainIndex, tostring(mainName))
					for altIndex = mainIndex + 1, (mainIndex + MaxAlts) do
						local altName = self.altEdits[altIndex]:GetText()
						if Util.Objects.IsSet(altName) then
							Logging:Trace("ProcessPlayers(%d) : %s", altIndex, tostring(altName))
							local alt = Player:Get(altName)
							if alt then
								Util.Tables.Push(alts, alt)
							end
						end
					end

					if Util.Tables.Count(alts) > 0 then
						Util.Tables.Sort(alts, function(p1, p2) return p1.guid < p2.guid end)
						players[main.guid] = alts
						players = Util.Tables.Sort2(players, false)
					end
				end
			end

			return players
		end,
		tab.playersCache
	)

	tab.UpdatePlayers = function(self)
		local config = configSupplier()
		Logging:Trace("UpdatePlayers(%s)", config and config.id or 'nil')

		if config then
			local mappings = config:GetAlternates()
			local mains = Util.Tables.Sort(Util.Tables.Keys(mappings), function(m1, m2) return m1 < m2 end)
			local mainCount = Util.Tables.Count(mains)
			Logging:Trace("UpdatePlayers(%s) : Count(%d)", config and config.id or 'nil', mainCount)

			local editIndex = 1
			for _, mainGuid in pairs(mains) do
				-- reset it so potential change to previous value still fires the OnTextChanged event
				self.altEdits[editIndex]:Reset()
				local main = Player.Resolve(mainGuid) or Player.Unknown(mainGuid)
				Logging:Trace("UpdatePlayers(%s)[Main] : %s => %s ", config.id, tostring(mainGuid), tostring(main:GetShortName()))
				self.altEdits[editIndex]:Set(main:GetShortName())

				local altCount = Util.Tables.Count(mappings[mainGuid])
				for _, alt in pairs(mappings[mainGuid]) do
					editIndex = editIndex + 1
					self.altEdits[editIndex]:Reset()
					self.altEdits[editIndex]:Set(alt:GetShortName())
				end

				for _ = altCount, MaxAlts do
					editIndex = editIndex + 1
					self.altEdits[editIndex]:Reset()
				end
			end

			for index = editIndex, #self.altEdits do
				self.altEdits[index]:Set(nil)
			end

			self:ProcessPlayers()
		end
	end

	tab.SavePlayers = function(self)
		Logging:Trace("SavePlayers()")
		--- @type Models.List.Configuration
		local config = configSupplier()
		if config then
			if self:HasPendingChanges() then
				-- clear out any current alt mappings, they will be re-created on save
				-- technically, should be able to determine the delta and only update those
				-- but this is "easier"
				config:ResetAlternates()

				for main, alts in pairs(self:ProcessPlayers()) do
					local compacted = Util.Tables.Compact(alts)
					config:SetAlternates(Player.Resolve(main), unpack(compacted))
				end
				module:GetService().Configuration:Update(config, "alts")
				self:UpdatePlayers()
			end
		end
	end

	-- this tracks player "edits" which aren't currently on the list (pure UI element)
	tab.playerEdits = {}
	tab.UpdateAvailablePlayers = function(self)
		-- less 3 rows because of headers and footers
		local displayRows = (rowsPerColumn - 3)
		--- @type  table<string, Models.Player>
		local allPlayers = AddOn:Players(self.includeRaid, self.includeGuild, true)
		local players = self:ProcessPlayers()
		local allAlts = Util.Tables.Flatten(Util.Tables.Values(players))
		Logging:Trace("UpdateAvailablePlayers() : all(%d) alts(%d)",
		              Util.Tables.Count(allPlayers), Util.Tables.Count(allAlts)
		)

		local available =
			Util(allPlayers)
				:CopyFilter(
					function(player)
						return
							not Util.Tables.ContainsKey(players, player.guid) and
							not Util.Tables.ContainsValue(allAlts, player)
					end)
				:Sort(function(p1, p2) return p1:GetName() < p2:GetName() end)()

		-- update scroll (as needed)
		local overflow = #available - displayRows
		Logging:Trace(
			"UpdateAvailablePlayers() : available(%d), rows(%d), overflow(%d)",
			Util.Tables.Count(available), displayRows, overflow
		)
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
				playerEdit =
					UI:New('EditBox', tab)
						:Size(PlayerWidth, PlayerHeight)
						:OnChange(function(self, userInput) EditOnChange(self, false, userInput) end)
				self.playerEdits[index] = playerEdit
				playerEdit.index = index
				playerEdit:Point("TOPLEFT", PriorityCoord(playerEdit, (5.5*PlayerWidth), -(PlayerHeight * 1.5)))

				local fontName, _, fontFlags = playerEdit:GetFont()
				playerEdit:SetFont(fontName, 12, fontFlags)
				playerEdit:SetEnabled(false)
				playerEdit:SetMovable(true)
				playerEdit:RegisterForDrag("LeftButton")
				playerEdit:SetScript("OnDragStart", EditOnDragStart)
				playerEdit:SetScript("OnDragStop", function(self) EditOnDragStop(self, EditDragType.Into) end)
			end

			local playerIndex = index + floor(self.playersScroll:GetValue() + 0.5)
			if playerIndex > #available then playerIndex = index end
			Logging:Trace("UpdateAvailablePlayers() : index=%d, playerIndex=%d", index, playerIndex)

			playerEdit:SetText(available[playerIndex]:GetShortName())
			playerEdit:SetCursorPosition(1)
			playerEdit:Show()
		end

		for index = #available + 1, #self.playerEdits do
			self.playerEdits[index]:Hide()
		end
	end

	tab.SetFieldsEnabled = function(self, config)
		local enabled = config and config:IsAdminOrOwner() or false
		self.playersScroll:Hide()
		self.playersInGuild:SetEnabled(enabled)
		self.playersInRaid:SetEnabled(enabled)

		for index = 1, #self.altEdits do
			self.altEdits[index]:SetActive(enabled)
		end
	end

	tab.Update = function(self)
		Logging:Trace("Config.Alts(Tab).Update(%s)", tostring(self:IsVisible()))
		if self:IsVisible() then
			self:SetFieldsEnabled(configSupplier())
			self:UpdatePlayers()
		end
	end

	tab:SetScript("OnShow", function(self) self:Update() end)

	self.configAltsTab = tab
end

function Lists:LayoutConfigGeneralTab(tab, configSupplier)
	local module, configList = self, tab:GetParent():GetParent().configList

	tab.name =
		UI:New('EditBox', tab)
		  :Size(425,20)
		  :Point("TOPLEFT", tab, "TOPLEFT", 15, -15)
		  :Tooltip(L["name"], L["list_config_name_desc"])
		  :OnChange(
			Util.Functions.Debounce(
				function(self, userInput)
					Logging:Trace("Configuration[Name].OnChange(%s)", tostring(userInput))
					if userInput then
						local config = configSupplier()
						config.name = self:GetText()
						module:GetService().Configuration:Update(config, 'name')
						configList:Update()
					end
				end, -- function
				1, -- seconds
				true -- leading
			)
		)

	tab.default =
		UI:New('Checkbox', tab, L["default"])
	        :Point("LEFT", tab.name, "RIGHT", 15, 0)
	        :Tooltip(L["list_config_default_desc"])
	        :Size(14,14):AddColorState()
	        :OnClick(
				function(self)
					local config = configSupplier()
					if config then
						Logging:Trace("Config.Default.OnClick(%s) : %s", tostring(config.id), tostring(self:GetChecked()))
						-- this will mutate the configurations (only one default permitted)
						-- so set the list to the returned list
						configList:SetList(
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
					local config = configSupplier()
					--Logging:Trace("Config.Status.OnClick(%s) : %s", tostring(config.id), Util.Objects.ToString(item))
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
				local config = configSupplier()
				--Logging:Trace("Config.Owner.OnClick(%s) : %s", tostring(config.id), Util.Objects.ToString(item))
				config:SetOwner(item.value)
				module:GetService().Configuration:Update(config, "permissions")
				return true
			end
		)

	tab.owner.Refresh = function(self)
		local config = configSupplier()
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
					local config = configSupplier()
					local owner, admins = config:GetOwner(), config:GetAdministrators()
					Logging:Trace("Config.Admins(OptionsSupplier) : id=%s owner=%s", tostring(config.id), tostring(owner))
					local available =
						module:Players(
							function(t)
								if owner then Util.Tables.Remove(t, owner:GetShortName()) end
								t = Util.Tables.Filter(t, function(p) return not Util.Tables.ContainsValue(admins, p) end)
								return t
							end
						)

					-- available = Util.Tables.Filter(available, function(p) return not Util.Tables.ContainsValue(admins, p) end)
					return available, Util.Tables.Sort(admins)
				end
			)
			:OnSelectedChanged(
				function(player, added)
					Logging:Trace("Config.Admins(OnSelectedChanged) : %s, %s", tostring(player), tostring(added))
					local config = configSupplier()
					if added then
						config:GrantPermissions(player, Configuration.Permissions.Admin)
					else
						config:RevokePermissions(player, Configuration.Permissions.Admin)
					end
					module:GetService().Configuration:Update(config, "permissions")
				end
			)

	--- @param self any
	--- @param config Models.List.Configuration
	tab.SetFieldsEnabled = function(self, config)
		-- todo : disable check for development mode
		-- admins can only modify the list associated with the configuration, not the configuration itself
		local enabled = config and config:IsOwner()
		self.name:SetEnabled(enabled)
		self.default:SetEnabled(enabled)
		self.status:SetEnabled(enabled)
		self.owner:SetEnabled(enabled)
		self.admins:SetEnabled(enabled)
	end

	-- will be invoked when a list is selected
	tab.Update = function(self)
		local config = configSupplier()
		self:SetFieldsEnabled(config)

		if config then
			self.name:Text(config.name)
			self.default:SetChecked(config.default)
			self.status:SetViaKey(config.status)
			self.owner:Refresh()
			self.admins:Refresh()
		end
	end

	tab:SetFieldsEnabled()

	self.configGeneralTab = tab
end

local ListTabs = {
	[L["priority"]]        = L["list_list_priority_desc"],
	[L["priority_active"]] = L["list_list_priority_raid_desc"],
	[L["equipment"]]       = L["list_list_equipment_desc"],
}

local ListActionsMenu

function Lists:LayoutListTab(tab)
	local module = self

	ListActionsMenu = MSA_DropDownMenu_Create(C.DropDowns.ListActions, tab)
	MSA_DropDownMenu_Initialize(ListActionsMenu, self.ListActionsMenuInitializer, "MENU")
	ListActionsMenu.module = module

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
	tab.lists.SetListValue = function(self, index,...)
		Logging:Trace("List(Tab).Lists.SetListValue(%d)", index)
		self:GetParent():Update()
		module.bulkManageFrame:Update()
		self.List[index]:SetScript(
			"OnMouseDown",
			function(self, button)
				if Util.Strings.Equal(C.Buttons.Right, button) then
					Logging:Trace("List(Tab).List.OnMouseDown(%s)", tostring(index))
					ListActionsMenu.entry = tab.lists:Selected()
					DropDown.ToggleMenu(1, ListActionsMenu, self, 100)
				end
			end
		)
	end

	-- wide bar in which buttons and drop down are located
	UI:New('DecorationLine', tab, true, "BACKGROUND",-5)
	  :Point("TOPLEFT", tab.lists, 0, 30)
	  :Point("BOTTOMRIGHT",tab.lists,"TOPRIGHT",0, 0)

	--- @return Models.List.Configuration
	local function SelectedConfiguration()
		local values = tab.config:Selected()
		local config = #values == 1 and values[1].value or nil
		return config
	end

	--- @return Models.List.List
	local function SelectedList()
		return tab.lists:Selected()
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

	-- vertical line separating list from tabs
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
				function(self)
					local configs = module:GetService():Configurations()
					self:SetList(configs, AlphabeticalOrder(configs))
				end, false
			)
			:OnValueChanged(
				function(item)
					local config = item.value
					Logging:Trace("List.Config.OnValueChanged(%s)", tostring(config.id))
					local lists = module:GetService():Lists(config.id)
					tab.lists:SetList(lists, AlphabeticalOrder(lists))
					tab.lists:ClearSelection()
					tab:Update()
					tab:SetButtonsEnabled(config)
					return true
				end
			)

	-- todo : fix text to front
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

	--- @param self any
	--- @param config Models.List.Configuration
	tab.SetButtonsEnabled = function(self, config)
		local enabled = config and config:IsAdminOrOwner()
		self.add:SetEnabled(enabled)
		self.delete:SetEnabled(enabled)
	end

	--- @param self any
	--- @param config Models.List.Configuration
	--- @param list Models.List.List
	tab.SetFieldsEnabled = function(self, config, list)
		local enabled = (list and config) and config:IsAdminOrOwner()
		self.name:SetEnabled(enabled)
	end

	tab.Update = function(self)
		local config, list = SelectedConfiguration(), SelectedList()
		Logging:Trace("List(Tab).Update() : %s - %s", tostring(config and config.id or nil), tostring(list and list.id or nil))
		self:SetFieldsEnabled(config, list)
		self:SetButtonsEnabled(config)

		if list then
			self.name:Text(list.name)
		else
			self.name:Text(nil)
		end

		MI.Update(tab, list)

		-- iterate any child tabs and update their fields
		for _, childTab in self.listSettings:IterateTabs() do
			if childTab.Update then
				childTab:Update()
			end
		end
	end

	tab.Refresh = function(self, list)
		local configs = module:GetService():Configurations()
		self.config:SetList(configs, AlphabeticalOrder(configs))
		self:ListUpdated(nil, {entity=list})
	end

	-- various tabs related to a configuration list
	tab.listSettings = UI:New('Tabs', tab, unpack(Util.Tables.Keys(ListTabs))):Point(230, -65):Size(1150, 530):SetTo(1)
	tab.listSettings:SetBackdropBorderColor(0, 0, 0, 0)
	tab.listSettings:SetBackdropColor(0, 0, 0, 0)
	tab.listSettings:First():SetPoint("TOPLEFT", 0, 20)
	tab.listSettings:SetTo(2)

	for index, description in pairs(Util.Tables.Values(ListTabs)) do
		tab.listSettings.tabs[index]:Tooltip(description)
	end

	-- the background for configuration list tabs
	tab.banner =
		UI:New('DecorationLine', tab, true, "BACKGROUND",-5)
			:Point("TOPLEFT", tab.listSettings, 0, 0)
			:Point("BOTTOMRIGHT",tab,"TOPRIGHT", -2, -45)
			:Color(0.25, 0.78, 0.92, 1, 0.50)

	MI.EmbedWidgets(self:GetName() .. "_List", tab, function(...) self:UpdateMoreInfo(...) end)
	tab.moreInfoBtn:SetPoint("TOPRIGHT", tab.banner, "TOPRIGHT", -5, 2)

	-- handles updates to a list, both via UI and external sources
	tab.ListUpdated = function(self, _, detail)
		--Logging:Debug("ListUpdated() : %s", Util.Objects.ToString(detail))
		local list = detail.entity
		if list then
			self.lists:Set(list, function(item) return Util.Strings.Equal(list.id, item.id) end)
		end
		self:Update()
	end

	-- register for callback when list is updated (only to update hash and revision)
	self.listsService:RegisterCallbacks(tab, {
		[List] = {
			[Dao.Events.EntityUpdated] = function(...)
				tab:ListUpdated(...)
			end,
		}
	})

	self:LayoutListPriorityBulkManageFrame(SelectedConfiguration, SelectedList)

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

	self:LayoutListPriorityRaidTab(
		tab.listSettings:GetByName(L["priority_active"]),
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

	---- fuck-fuckery to deal with item equipment locations which may actually be the item itself
	local function UnassignedEquipmentLocations(config, list)
		--Logging:Trace("UnassignedEquipmentLocations : %s ", tostring(list and list.id or nil))
		local all, unassigned = {}, {}
		if config then
			all, unassigned = module:GetService():UnassignedEquipmentLocations(config.id)
		end
		return all, unassigned
	end

	tab.equipment =
		UI:New('DualListbox', tab)
			:Point("TOPLEFT", tab, "TOPLEFT", 20, -35)
			:Point("TOPRIGHT", tab, "TOPRIGHT", -650, 0)
			:Height(210)
			:AvailableTooltip(L["available"], L["equipment_type_avail_desc"])
			:SelectedTooltip(L["equipment_types"], L["equipment_type_desc"])
			:LineTextFormatter(
				function(equipment)
					if Util.Tables.ContainsKey(C.EquipmentNameToLocation, equipment) then
						return UIUtil.ColoredDecorator(C.Colors.ItemHeirloom):decorate(equipment)
					else
						return UIUtil.ColoredDecorator(C.Colors.LuminousYellow):decorate(equipment)
					end
				end
			)
			:OptionsSorter(
				function(opts)
					local sorted = {}
					for i, v in pairs(Util.Tables.ASort(opts, function(a, b) return a[2] < b[2] end)) do
						sorted[i] = v[1]
					end

					--Logging:Trace("%s", Util.Objects.ToString(sorted))
					return sorted
				end
			)
			:OptionsSupplier(
				function()
					local config, list = configSupplier(), listSupplier()
					local all, unassigned = UnassignedEquipmentLocations(config, list)
					--[[
					Logging:Trace("%s // %s // %s",
					              Util.Objects.ToString(all),
					              Util.Objects.ToString(unassigned),
					              Util.Objects.ToString(Util.Tables.CopySelect(all, unpack(unassigned))))
	                --]]
					return Util.Tables.CopySelect(all, unpack(unassigned)), list and list:GetEquipment(true) or {}
				end
			)
			:OnSelectedChanged(
				function(equipment, added)
					-- translate name into actual type/slot
					local config, list = configSupplier(), listSupplier()
					local slot = AddOn.GetEquipmentLocation(equipment, select(1, UnassignedEquipmentLocations(config, list)))
					--Logging:Trace("List.Equipment(OnSelectedChanged) : %s => %s, %s", tostring(equipment), tostring(slot), tostring(added))

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

	--- @param self any
	--- @param config Models.List.Configuration
	--- @param list Models.List.List
	tab.SetFieldsEnabled = function(self, config, list)
		local enabled = (config and list) and config:IsAdminOrOwner()
		self.equipment:SetEnabled(enabled)
	end

	-- will be invoked when a list is selected
	tab.Update = function(self)
		Logging:Trace("List.Equipment(Tab).Update(%s)", tostring(self:IsVisible()))
		if self:IsVisible() then
			self:SetFieldsEnabled(configSupplier(), listSupplier())
			self.equipment:Refresh()
		end
	end

	tab:SetScript("OnShow", function(self) self:Update() end)
	self.listEquipmentTab = tab
end


local PriorityWidth, PriorityHeight, AttendanceInterval, AttendanceIntervalWeeks = 150, 18, 30, 28
local PriorityActionsMenu, PlayerActionsMenu
local PlayerTooltip

function Lists:LayoutListPriorityTab(tab, configSupplier, listSupplier)
	local module = self

	PriorityActionsMenu = MSA_DropDownMenu_Create(C.DropDowns.ListPriorityActions, tab)
	PlayerActionsMenu = MSA_DropDownMenu_Create(C.DropDowns.ListPlayerActions, tab)
	MSA_DropDownMenu_Initialize(PriorityActionsMenu, self.PriorityActionsMenuInitializer, "MENU")
	MSA_DropDownMenu_Initialize(PlayerActionsMenu, self.PlayerActionsMenuInitializer, "MENU")

	PlayerTooltip = UIUtil.CreateGameTooltip(module, tab)

	local rowsPerColumn, columns = ceil(tab:GetHeight()/(PriorityHeight+6)), min(4, floor(tab:GetWidth()/(PriorityWidth + 25)))
	Logging:Trace("rowsPerColumn=%d, columns=%d, total=%d", rowsPerColumn, columns, (columns * rowsPerColumn))

	local function PriorityCoord(self, xAdjust, yAdjust)
		xAdjust = Util.Objects.IsNumber(xAdjust) and xAdjust or 0
		yAdjust = Util.Objects.IsNumber(yAdjust) and yAdjust or 0

		local column = floor((self.index - 1) / rowsPerColumn)
		local row = ((self.index -1) % rowsPerColumn)
		return (10 + (column * (PriorityWidth + 15))) + xAdjust, (-20 - (row  * 22)) + yAdjust
	end

	local function EditOnDragStart(self)
		if self:IsMovable() then
			Logging:Trace("EditOnDragStart")
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

	local function EditOnChange(self, isPriority)
		--Logging:Trace("EditOnChange() : player=%s, index=%d, isPriority=%s", tostring(self:GetText()), self.index, tostring(isPriority))
		local playerName, index, priorities = self:GetText(), self.index, self:GetParent().priorities
		if Util.Strings.IsSet(playerName) then
			local color = UIUtil.GetPlayerClassColor(playerName)
			if Util.Objects.IsFunction(color.GetRGBA) then
				self:SetTextColor(color:GetRGBA())
			else
				self:SetTextColor(C.Colors.ItemPoor:GetRGBA())
			end
		end

		-- reset border and tooltip back to default
		self:ColorBorder()
		self:ClearTooltip()

		if isPriority then
			if Util.Strings.IsSet(playerName) then
				priorities[index] = Player:Get(playerName)
			else
				priorities[index] = nil
			end

			-- if the player has alts, then color the border
			local config = configSupplier()
			if config and Util.Strings.IsSet(playerName) then
				local alts = config:GetAlternates(playerName)
				if Util.Objects.IsSet(alts) then
					self:ColorBorder(C.Colors.LightBlue:GetRGBA())
				end

				local PlayerMappingFn = tab:GetPlayerMappingFn()

				-- handle tooltips inline as extra stuff to add
				self:SetScript(
					'OnEnter',
					function(self)
						PlayerTooltip:SetOwner(self, 'ANCHOR_RIGHT')
						PlayerTooltip:AddLine(L['raid_attendance'])
						PlayerTooltip:AddLine(" ")

						local stats = AddOn:RaidAuditModule():GetAttendanceStatistics(AttendanceInterval, nil, PlayerMappingFn)
						local playerStats = stats.players[AddOn.Ambiguate(playerName)]
						local pct = playerStats and playerStats.pct
						pct = pct and (pct * 100.0) or (0.0)

						local lrd = playerStats and playerStats.lastRaid or nil
						if lrd then
							lrd = DateFormat.Short:format(lrd)
						else
							lrd = L['none']
						end

						PlayerTooltip:AddDoubleLine(
							format("%s %s", L['past'], format(L["n_days"], AttendanceInterval)),
							format("%.2f %%", pct),
							0.90, 0.80, 0.50,
							1, 1, 1
						)

						local sd, ed = AddOn:RaidAuditModule():GetNormalizedInterval(AttendanceIntervalWeeks)
						stats = AddOn:RaidAuditModule():GetAttendanceStatistics(sd, ed, PlayerMappingFn)
						playerStats = stats.players[AddOn.Ambiguate(playerName)]
						pct = playerStats and playerStats.pct
						pct = pct and (pct * 100.0) or (0.0)

						PlayerTooltip:AddDoubleLine(
							format("%s %s", L['past'], format(L["n_raid_weeks"], AttendanceIntervalWeeks / 7)),
							format("%.2f %%", pct),
							0.90, 0.80, 0.50,
							1, 1, 1
						)

						PlayerTooltip:AddDoubleLine(
							L["last_raid_date"],
							lrd,
							0.90, 0.80, 0.50,
							1, 1, 1
						)

						if Util.Tables.Count(alts) > 0 then
							PlayerTooltip:AddLine(" ")
							PlayerTooltip:AddLine(L['list_alts'])
							PlayerTooltip:AddLine(" ")
							for _, alt in pairs(alts) do
								PlayerTooltip:AddLine(UIUtil.PlayerClassColorDecorator(alt:GetName()):decorate(alt:GetShortName()))
							end
						end

						PlayerTooltip:Show()
					end
				)
				self:SetScript("OnLeave", function() PlayerTooltip:Hide() end)
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
			:FontSize(12)
			:Shadow(true)
	tab.warning:Hide()

	-- this tracks player's priority "edits" which are currently on the list (pure UI element)
	tab.priorityEdits = {}
	-- create individual priority slots (which can be dragged and dropped)
	for index = 1, (columns * rowsPerColumn) do
		local priorityEdit = UI:New('EditBox', tab)
								:Size(PriorityWidth, PriorityHeight)
								:AddXButton()
								:TextInsets(25)
								:BackgroundText(tostring(index), true)
								:OnChange(function(self, userInput) EditOnChange(self, true, userInput) end)
		tab.priorityEdits[index] = priorityEdit
		priorityEdit.index = index
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
				self.xButton:Hide()
			else
				-- bind this to whether edit is movable
				-- if not movable, then set to inactive due to permissions
				if self:IsMovable() then self.xButton:Show() end
			end
			self:SetCursorPosition(1)
		end
		priorityEdit:SetScript("OnMouseDown",
				function(self, button)
					if Util.Strings.Equal(C.Buttons.Right, button) then
						PriorityActionsMenu.module = module
						PriorityActionsMenu.name = self:GetText()
						PriorityActionsMenu.entry = tab.priorities[self.index]
						DropDown.ToggleMenu(1, PriorityActionsMenu, self)
					end
				end
		)
		priorityEdit:SetEnabled(false)
		priorityEdit:Point("TOPLEFT", PriorityCoord(priorityEdit))

		priorityEdit.SetActive = function(self, active)
			active = Util.Objects.Default(active, false)
			self:SetMovable(active)
			if active then
				self:RegisterForDrag("LeftButton")
			else
				self:RegisterForDrag()
			end
			self:SetScript("OnDragStart", active and EditOnDragStart or nil)
			self:SetScript("OnDragStop", active and function(e) EditOnDragStop(e, EditDragType.Within) end or nil)
			if active then self.xButton:Show() else self.xButton:Hide() end
		end
		priorityEdit:SetActive(true)
	end

	-- this tracks player "edits" which aren't currently on the list (pure UI element)
	tab.playerEdits = {}
	tab.playersScroll =
		UI:New('ScrollBar', tab)
			:Point("TOP", PriorityCoord(tab.priorityEdits[1], 0, -(PriorityHeight * 1.5)))
			:Point("BOTTOM", 0, (columns * PriorityHeight) - PriorityHeight)
			:Point("RIGHT", tab, -285, 0)
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
		local result = not Util.Tables.Equals(self.prioritiesOrig, self.priorities, true)
		Logging:Trace("HasPendingChanges(%s)", tostring(result))
		return result
	end

	tab.UpdatePriorities = function(self, reload, list)
		reload = Util.Objects.IsNil(reload) and true or reload
		list = list or listSupplier()

		Logging:Debug("UpdatePriorities(%s) : reload(%s)", list and list.id or 'nil', tostring(reload))

		if reload then
			self.prioritiesOrig, self.priorities = {}, {}
			if list then
				self.prioritiesOrig = list:GetPlayers()
			end
		end

		local priorityCount = reload and #self.prioritiesOrig or table.maxn(self.priorities)
		Logging:Debug("UpdatePriorities(%s) : Count(%d)",  list and list.id or 'nil', priorityCount)

		local reschedule = false

		-- todo : if Unknown player then reschedule
		for priority = 1, priorityCount do
			-- reset it so potential change to previous value still fires the OnTextChanged event
			self.priorityEdits[priority]:Reset()
			local player = reload and self.prioritiesOrig[priority] or self.priorities[priority]
			self.priorityEdits[priority]:Set(player and player:GetShortName() or nil)
			Logging:Trace(
				"UpdatePriorities(%s) : %d => %s/%s",
				list and list.id or 'nil', priority,
				tostring(player and player:GetShortName() or nil),
				tostring(player and player.guid or nil)
			)
			reschedule = reschedule or (player and Util.Strings.Equal(player:GetShortName(), "Unknown"))
		end

		for priority = priorityCount + 1, #self.priorityEdits do
			self.priorityEdits[priority]:Set(nil)
		end

		Logging:Trace("UpdatePriorities(%s) : reschedule(%s)", list and list.id or 'nil', tostring(reschedule))
		if reschedule then
			AddOn:ScheduleTimer(function() tab:UpdatePriorities(true, list) end, 6)
		end
	end

	tab.ClearPriorities = function(self)
		self.priorities = {}
		self:UpdatePriorities(false)
	end

	tab.GetPriorities = function(self)
		return self.priorities
	end

	tab.GetPlayerMappingFn = function(self)
		local config = configSupplier()
		return Lists:GetService():PlayerMappingFunction(config and config.id or nil)
	end

	--- @param rank number numeric rank of guild
	--- @param modifier LibUtil.Optional if empty, only the specified rank. if present and true, that rank and any rank "higher", if presentfalse, that rank and any rank "lower"
	tab.ClearAndPopulatePrioritiesViaGuild = function(self, rank, modifier)
		modifier = modifier or Util.Optional.empty()
		local list = listSupplier()
		if list then
			Logging:Debug("ClearAndPopulatePrioritiesViaGuild(%d, %s)", tonumber(rank), tostring(modifier))
			-- guild ranks are inverted, with highest rank having lowest number (e.g. guild mater) and lowest rank having highest number (e.g. noob)
			self.priorities = {}
			local priorities = {}
			for name, _ in AddOn:GuildIterator() do
				local sname = AddOn.Ambiguate(name)
				local player = GuildStorage:GetMember(sname)
				local index = player.rankIndex

				if  (modifier:isEmpty() and index == rank) or
					(modifier:ifPresent(function(v) if v then return index <= rank else return index >= rank end end)) then
					--Logging:Debug("%s", Util.Objects.ToString(AddOn.Ambiguate(name)))
					local resolved = configSupplier():ResolvePlayer(sname)
					-- only add players which resolve to themselves (i.e. not an ALT) and make sure their level is
					-- reasonable for raiding (in this case 71+)
					if resolved and Util.Strings.Equal(resolved:GetShortName(), sname) and player.level >= 71 then
						Util.Tables.Push(priorities, resolved)
					end
				end
			end

			if #priorities > 0 then
				Util.Tables.Shuffle(priorities)
				for _, player in pairs(priorities) do
					Util.Tables.Push(self.priorities, player)
				end

				self:UpdatePriorities(false)
			end
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
				position = math.random(1, math.max(table.maxn(self.priorities), 1))
				self.priorities = Util.Tables.Splice2(self.priorities, position, position + 1, {player})
			elseif first then
				Util.Tables.Insert(self.priorities, 1, player)
			else
				Util.Tables.Insert(self.priorities, table.maxn(self.priorities) + 1, player)
			end

			Logging:Trace("SetPriority(%s, %s) : %d", tostring(player), tostring(first), Util.Tables.Count(self.priorities))
			self:UpdatePriorities(false)
		end
	end

	tab.SetPriorityRelative = function(self, player, other, after)
		-- if after wasn't specified, default to true
		after = Util.Objects.Default(after, true)
		Logging:Debug("SetPriorityRelative(%s) : %s / %s", tostring(after), tostring(player), tostring(other))

		if not player and not other then
			return
		end

		local list = listSupplier()
		if list then
			local priorities, modifier, handled = {}, 0, false
			for priority, p in Util.Tables.Sparse.ipairs(self.priorities) do
				if p ~= player and p ~= other then
					priorities[priority + modifier] = p
				else
					if not handled and p == other then
						priorities[priority + modifier] = after and p or player
						priorities[priority + modifier + 1] = after and player or p
						modifier, handled = (modifier + 1), true
					end

					if p == player then
						modifier = (modifier - 1)
					end
				end
			end

			if handled then
				self.priorities = priorities
				self:UpdatePriorities(false)
			end
		end
	end

	tab.RemovePlayer = function(self, player)
		local list = listSupplier()
		if list and player then
			local priority = Util.Tables.Find(self.priorities, player)
			if priority then
				self.priorities[priority] = nil
				self:UpdatePriorities(false)
			end
		end
	end

	tab.AdjustPriority = function(self, player, amount)
		amount = Util.Objects.Default(tonumber(amount), 0)
		Logging:Debug("AdjustPriority(%s, %d)", tostring(player), amount)

		if amount ~= 0 then
			local compacted = Util.Tables.Compact(self.priorities)
			local priority = Util.Tables.Find(compacted, player)
			if priority then
				local newPriority, other = priority + amount, nil

				Logging:Debug("AdjustPriority(%s, %d) : %d => %d (%d)", tostring(player), amount, priority, newPriority, #compacted)

				if newPriority < 0 then
					other = compacted[1]
				elseif newPriority > #compacted then
					other = compacted[#compacted]
				else
					other = compacted[newPriority]
				end

				Logging:Debug("AdjustPriority(%s, %d) : %s", tostring(player), amount, tostring(other))

				self:SetPriorityRelative(player, other, (amount > 0))
			end
		end
	end

	tab.UpdateAvailablePlayers = function(self)
		-- less 3 rows because of headers and footers
		local displayRows = (rowsPerColumn - 3)
		local config = configSupplier()
		--- @type  table<string, Models.Player>
		local allPlayers = AddOn:Players(self.includeRaid, self.includeGuild, true)
		local allAlts = config and Util.Tables.Flatten(Util.Tables.Values(config:GetAlternates())) or {}

		Logging:Trace("UpdateAvailablePlayers() : all(%d) / list(%d)", Util.Tables.Count(allPlayers), Util.Tables.Count(self.priorities))

		local available =
			Util(allPlayers)
				:CopyFilter(
					function(player)
						return
							not Util.Tables.ContainsValue(self.priorities, player) and
							not Util.Tables.ContainsValue(allAlts, player)
					end
				)
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
				Logging:Trace("UpdateAvailablePlayers() : creating player edit at index(%d)", index)
				playerEdit = UI:New('EditBox', tab):Size(PriorityWidth, PriorityHeight):OnChange(function(self, userInput) EditOnChange(self, false, userInput) end)
				self.playerEdits[index] = playerEdit
				playerEdit.index = index
				playerEdit:Point("TOPLEFT", PriorityCoord(playerEdit, (4.5*PriorityWidth), -(PriorityHeight * 1.5)))
				local fontName, _, fontFlags = playerEdit:GetFont()
				playerEdit:SetFont(fontName, 12, fontFlags)
				playerEdit:SetEnabled(false)
				playerEdit:SetMovable(true)
				playerEdit:RegisterForDrag("LeftButton")
				playerEdit:SetScript("OnDragStart", EditOnDragStart)
				playerEdit:SetScript("OnDragStop", function(self) EditOnDragStop(self, EditDragType.Into) end)
			end

			local playerIndex = index + floor(self.playersScroll:GetValue() + 0.5)
			if playerIndex > #available then playerIndex = index end

			Logging:Trace("UpdateAvailablePlayers() : index=%d, playerIndex=%d", index, playerIndex)
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

	--- @param self any
	--- @param config Models.List.Configuration
	--- @param list Models.List.List
	tab.SetFieldsEnabled = function(self, config, list)
		local enabled = (config and list) and config:IsAdminOrOwner()
		self.playersScroll:Hide()
		self.playersInGuild:SetEnabled(enabled)
		self.playersInRaid:SetEnabled(enabled)

		for index = 1, #self.priorityEdits do
			self.priorityEdits[index]:SetActive(enabled)
		end
	end

	tab.Update = function(self)
		Logging:Trace("List.Priority(Tab).Update(%s)", tostring(self:IsVisible()))
		if self:IsVisible() then
			self:SetFieldsEnabled(configSupplier(), listSupplier())
			self:UpdatePriorities()
		end
	end

	tab:SetScript("OnShow", function(self) self:Update() end)
	self.listPriorityTab = tab
end

function Lists:LayoutListPriorityRaidTab(tab, configSupplier, listSupplier)

	local rowsPerColumn = ceil(tab:GetHeight()/(PriorityHeight+6))

	local function PriorityCoord(self, xAdjust, yAdjust)
		xAdjust = Util.Objects.IsNumber(xAdjust) and xAdjust or 0
		yAdjust = Util.Objects.IsNumber(yAdjust) and yAdjust or 0

		local column = floor((self.index - 1) / rowsPerColumn)
		local row = ((self.index -1) % rowsPerColumn)
		return (10 + (column * (PriorityWidth + 15))) + xAdjust, (-20 - (row  * 22)) + yAdjust
	end

	local function EditOnChange(self)
		local playerName = self:GetText()
		if Util.Strings.IsSet(playerName) then
			local color = UIUtil.GetPlayerClassColor(playerName)
			if Util.Objects.IsFunction(color.GetRGBA) then
				self:SetTextColor(color:GetRGBA())
			else
				self:SetTextColor(C.Colors.ItemPoor:GetRGBA())
			end
		end

		self:ColorBorder()
		self:ClearTooltip()

		-- if the player has alts, then color the border
		local config = configSupplier()
		if config and Util.Strings.IsSet(playerName) then
			local alts = config:GetAlternates(playerName)
			if Util.Objects.IsSet(alts) then
				self:ColorBorder(C.Colors.LightBlue:GetRGBA())

				local altsColored = {}
				for _, alt in pairs(alts) do
					Util.Tables.Push(
						altsColored,
						UIUtil.PlayerClassColorDecorator(alt:GetName()):decorate(alt:GetShortName())
					)
				end
				self:Tooltip(L['list_alts'], unpack(altsColored))
			end
		end
	end

	-- this tracks player's priorities
	tab.priorities = {}
	-- create individual priority slots
	for index = 1, 40 do
		local priorityEdit =
			UI:New('EditBox', tab)
				:Size(PriorityWidth, PriorityHeight)
				:TextInsets(25)
				:BackgroundText(tostring(index), true)
				:OnChange(function(self) EditOnChange(self) end)
		tab.priorities[index] = priorityEdit
		priorityEdit.index = index
		priorityEdit.Reset = function(self)
			local otcFn = self:GetScript("OnTextChanged")
			self:OnChange(nil)
			self:Set(nil)
			self:OnChange(otcFn)
		end
		priorityEdit.Set = function(self, text)
			self:SetText(text or "")
			self:SetCursorPosition(1)
		end
		priorityEdit:SetEnabled(false)
		priorityEdit:Point("TOPLEFT", PriorityCoord(priorityEdit))
		priorityEdit:SetMovable(false)
	end


	tab.UpdatePriorities = function(self)
		local ac, list = Lists:GetActiveConfiguration(), listSupplier()
		local priorityCount = 0

		if ac and list then
			--- @type Models.List.List
			local al = ac:GetActiveList(list.id)
			local players = al:GetPlayers(true, true)
			--Logging:Trace("UpdatePriorities() : %s", Util.Objects.ToString(players))
			priorityCount = #players

			local player
			for priority = 1, priorityCount do
				self.priorities[priority]:Reset()
				player = Player.Resolve(players[priority])
				self.priorities[priority]:Set(player and player:GetShortName() or L['unknown'])
			end
		end

		for priority = priorityCount + 1, #self.priorities do
			self.priorities[priority]:Set(nil)
		end
	end

	tab.Update = function(self)
		Logging:Trace("List.PriorityRaid(Tab).Update(%s)", tostring(self:IsVisible()))

		-- this tab is only visible when in a raid and there is an active configuration
		if (IsInRaid() or AddOn:DevModeEnabled()) and Lists:HasActiveConfiguration() then
			self.button:Show()
		else
			self.button:Hide()
		end


		if self:IsVisible() then
			self:UpdatePriorities()
		end
	end

	tab:SetScript("OnShow", function(self) self:Update() end)
	self.listPriorityRaidTab = tab
end

local FullDf = DateFormat:new("mm/dd/yyyy HH:MM:SS")

function Lists:UpdateMoreInfo(tab, entity)
	Logging:Debug("UpdateMoreInfo(%s)", tab:GetName())
	if entity then
		local tip = tab.moreInfo
		tip:SetOwner(tab.banner, "ANCHOR_RIGHT")
		tip:AddLine(entity.name)
		tip:AddLine(" ")
		tip:AddDoubleLine(L["hash"], entity:hash(), 0.90, 0.80, 0.50, 1,1,1)
		tip:AddDoubleLine(L["revision"], entity.revision, 0.90, 0.80, 0.50, 1,1,1)
		tip:AddDoubleLine(L["modified"], FullDf:format(entity.revision), 0.90, 0.80, 0.50, 1,1,1)

		local leader = ListsDp:GetReplicaLeader(entity)
		local c = leader and UIUtil.GetPlayerClassColor(leader) or C.Colors.Aluminum
		tip:AddDoubleLine(L["authority"], leader and AddOn.Ambiguate(leader) or "N/A", 0.90, 0.80, 0.50, c.r, c.g, c.b)

		tip:Show()
		tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
	end
end

function Lists:SelectListModuleFn()
	return function(lpad)
		-- select the 'list' module
		lpad:SetModuleIndex(self.interfaceFrame.moduleIndex)
		-- select the 'list' tab
		self.interfaceFrame.tabs:SetTo(2)
		-- select the default active configuration
		local configs = self:GetService():Configurations(true, true)
		if Util.Tables.Count(configs) == 0 then
			configs = self:GetService():Configurations()
		end

		local configId = configs and Util.Tables.Keys(configs)[1] or nil
		if configId then
			self.listTab.config:SetViaKey(configId)
			self.listTab.lists:SetTo(1)
			self.listTab:Update()
			self.listPriorityTab:Update()
		end
	end
end

--- @class BulkManageBase
local BulkManageBase = AddOn.Class('BulkManageBase')
function BulkManageBase:initialize(text)
	self.text = text
end

function BulkManageBase:__tostring()
	return self.text
end

--- @class BulkManageMeasure
local BulkManageMeasure = AddOn.Class('BulkManageMeasure', BulkManageBase)
function BulkManageMeasure:initialize(text, criteria)
	BulkManageBase.initialize(self, text)
	self.criteria = Util.Objects.Default(criteria, {})
end

function BulkManageMeasure:HasCriteria()
	return not Util.Objects.IsEmpty(self.criteria)
end

function BulkManageMeasure:GetCriteria()
	return self.criteria
end

function BulkManageMeasure:Evaluate(...) error("Evaluate() not implemented") end

--- @class NoMeasure
local NoMeasure = AddOn.Class('NoMeasure', BulkManageMeasure)
function NoMeasure:initialize()
	BulkManageMeasure.initialize(self, L['none'])
end

function NoMeasure:Evaluate(...)
	return Util.Tables.Copy(Lists.listPriorityTab:GetPriorities())
end

--- @class AttendanceMeasure
local AttendanceMeasure = AddOn.Class('AttendanceMeasure', BulkManageMeasure)
function AttendanceMeasure:initialize(criteria)
	BulkManageMeasure.initialize(self, L['attendance'], criteria)
end

function AttendanceMeasure:Evaluate(...)
	local evaluation, criteria, priorities = {}, select(1, ...), Lists.listPriorityTab:GetPriorities()
	if Util.Objects.IsSet(criteria) and Util.Tables.ContainsValue(self.criteria, criteria) then
		for _, days in pairs(criteria.interval) do
			Logging:Debug("Evaluate(%s) : %d days", tostring(criteria), days)
			local sd, ed = AddOn:RaidAuditModule():GetNormalizedInterval(days)
			Logging:Debug(
				"Evaluate(%s) : %d days => '%s' -> '%s'",
				tostring(criteria), days, tostring(sd), tostring(ed)
			)


			local PlayerMappingFn = Lists.listPriorityTab:GetPlayerMappingFn()
			local stats = AddOn:RaidAuditModule():GetAttendanceStatistics(sd, ed, PlayerMappingFn)
			-- todo : union of multi range
			if stats then
				for _, player in Util.Tables.Sparse.ipairs(priorities) do
					local pstats = stats.players[AddOn.Ambiguate(player:GetShortName())]
					local ppct = pstats and pstats.pct or 0
					if ppct <= 0 and not Util.Tables.ContainsValue(evaluation, player) then
						Util.Tables.Push(evaluation, player)
					end
				end
			end
		end
	end

	return evaluation
end

--- @class BulkManageCriteria
local BulkManageCriteria = AddOn.Class('BulkManageCriteria', BulkManageBase)
function BulkManageCriteria:initialize(text)
	BulkManageBase.initialize(self, text)
end

local AbsentCriteria = AddOn.Class('AbsentCriteria', BulkManageCriteria)
function AbsentCriteria:initialize(text, ...)
	BulkManageCriteria.initialize(self, text)
	self.interval = Util.Tables.New(...)
end

local BulkManageCriterion = {
	Absent2To4  = AbsentCriteria(
		format("%s : %s %s", L['absent'], L['past'], format(L["n_raid_weeks"], "2-4")),
		14, 21
	),
	Absent4Plus = AbsentCriteria(
		format("%s : %s %s", L['absent'], L['past'], format(L["n_raid_weeks"], "4+")),
		28
	)
}

local BulkManageMeasures = {
	Attendance = AttendanceMeasure({BulkManageCriterion.Absent2To4, BulkManageCriterion.Absent4Plus}),
	None       = NoMeasure(),
}

local BulkActions = {
	Drop2  = Util.Tables.New(
		format("%s %s", L["move_down"], format(L['n_positions'], 2)),
		function(self, players)
			Logging:Debug("Drop2(%d)", Util.Tables.Count(players))
			for _, player in pairs(players) do
				self.listPriorityTab:AdjustPriority(player, 2)
			end
		end
	),
	Drop5  = Util.Tables.New(
		format("%s %s", L["move_down"], format(L['n_positions'], 5)),
		function(self, players)
			Logging:Debug("Drop5(%d)", Util.Tables.Count(players))
			for _, player in pairs(players) do
				self.listPriorityTab:AdjustPriority(player, 5)
			end
		end
	),
	Remove = Util.Tables.New(
		L['remove'],
		function(self, players)
			Logging:Debug("Remove(%d)", Util.Tables.Count(players))
			for _, player in pairs(players) do
				self.listPriorityTab:RemovePlayer(player)
			end
		end
	)
}

function Lists:LayoutListPriorityBulkManageFrame(_, listSupplier)
	local module = self
	local f = UI:Popup(UIParent, 'BulkManageListPriorities', self:GetName(), L['frame_bulk_manage_list_priorities'], 450, 520)
	f.list = UI:New('Text', f.content):Size(200,15):Point("LEFT", f.banner, "LEFT", 20, 0):Color(C.Colors.White:GetRGB())

	f.criteriaGroup =
		UI:New('InlineGroup',f.content)
			:Point("CENTER", f.content, "CENTER", 0, 0)
			:Point("TOPLEFT", f.banner, "BOTTOMLEFT", 0, -15)
			:SetWidth(450):SetHeight(350):Title(L['criteria'])

	--- @type UI.Widgets.Dropdown
	f.measure =
		UI:New('Dropdown', f.content)
			:SetList(Util.Tables.Copy(BulkManageMeasures)):SetWidth(200)
			:Point("CENTER", f.criteriaGroup, "CENTER", 0, 0)
			:Point("TOP", f.criteriaGroup, "TOP", 0, -30)
			:OnValueChanged(function() f.criteria:Update() end)

	--- @type UI.Widgets.Dropdown
	f.criteria =
		UI:New('Dropdown', f.content)
			:SetWidth(200):Point("TOPRIGHT", f.measure, "BOTTOMRIGHT", 0, -10)
			-- should only be called when a value has been selected, which infers a list of criteria has been set
			:OnValueChanged(function() f.evaluate:Enable() end)
	f.criteria.Update = function(self)
		-- measure only supports a single value
		local measure = f.measure:Selected()[1]
		if measure then measure = measure.value end

		if Util.Objects.IsNil(measure) then
			self:SetEnabled(false)
			self:SetList({})
			f.evaluate:Disable()
		else
			self:SetEnabled(measure:HasCriteria())
			self:SetList(measure:GetCriteria())
			f.evaluate:SetEnabled(not measure:HasCriteria())
		end


		f.players:SetEnabled(false)
		self:ClearValue()
	end

	f.evaluate =
		UI:New('Button', f.content, L['evaluate'])
	        :Point("CENTER", f.content, "CENTER", 0, 0)
	        :Point("TOP", f.criteria, "BOTTOM", 0, -10)
			:OnClick(function(self) f:Evaluate() end)
			:Disable()

	f.players =
		UI:New('DualListbox', f.content)
			:Point("CENTER", f.content, "CENTER", 0, 0):Point("TOP", f.evaluate, "BOTTOM", 0, -10):Height(210)
			:SetEnabled(false)
			:AvailableTooltip(L["matched"], L["bulk_manage_matched"])
			:SelectedTooltip(L["selected"], L["bulk_manage_selected"])
			:LineTextFormatter(
				function(player)
					return UIUtil.ClassColorDecorator(player.class):decorate(player:GetShortName())
				end
			)
			:OrderingByListOperation()
			:OnSelectedChanged(function() f.action:Update() end)

	f.Evaluate = function(self)
		--- @type BulkManageMeasure
		local measure = self.measure:Selected()[1].value
		--- @type BulkManageCriteria
		local criteria = measure:HasCriteria() and self.criteria:Selected()[1].value or nil
		--[[
		Logging:Trace(
			"BulkManageFrame:Evaluate() : %s, %s",
			Util.Objects.ToString(measure:toTable()),
			Util.Objects.ToString( Util.Tables.IsEmpty({}) and {} or criteria:toTable())
		)
		--]]
		local priorities = measure:Evaluate(criteria)
		f.players:Options(priorities, {}):SetEnabled(true)
	end

	f.actionGroup =
		UI:New('InlineGroup',f.content)
	        :Point("CENTER", f.content, "CENTER", 0, 0)
	        :Point("TOPLEFT", f.criteriaGroup, "BOTTOMLEFT", 0, -15)
	        :SetWidth(450):SetHeight(100):Title('Action')

	--- @type UI.Widgets.Dropdown
	f.action =
		UI:New('Dropdown', f.content)
			:SetList(Util.Tables.Copy(BulkActions)):SetWidth(200)
			:SetTextDecorator(function(i) return i.value[1] end)
			:OnValueChanged(function() f.action:Update() end)
			:Point("CENTER", f.actionGroup, "CENTER", 0, 0)
			:Point("TOP", f.actionGroup, "TOP", 0, -30)
			:SetEnabled(false)

	f.action.Update = function(self)
		local selected = f.players.selected:GetList()
		local playersSelected = (Util.Tables.Count(selected) > 0)

		self:SetEnabled(playersSelected)

		if not playersSelected then
			self:ClearValue()
			f.execute:Disable()
		else
			if self:HasValue() then
				f.execute:Enable()
			else
				f.execute:Disable()
			end
		end
	end

	f.execute =
		UI:New('Button', f.content, L['execute'])
			:Point("CENTER", f.actionGroup, "CENTER", 0, 0)
			:Point("TOP", f.action, "BOTTOM", 0, -10)
			:OnClick(function(self) f:Execute() end)
			:Disable()

	f.Execute = function(self)
		local action, selected = f.action:Selected()[1].value, f.players.selected:GetList()
		--Logging:Debug("Execute() : action=%s, players=%d", Util.Objects.ToString(action), Util.Tables.Count(selected))
		-- index 2 will be the function to execute for action
		action[2](module, selected)
	end

	f.Update = function(self)
		if self:IsVisible() then
			local list = listSupplier()
			if list then
				self.list:SetText(list and tostring(list) or "")
			end

			self.measure:ClearValue()
			self.criteria:ClearValue()
			self.players:Clear()
			self.criteria:Update()
			self.action:Update()
		end
	end

	f:SetScript("OnShow", function(self) self:Update() end)
	self.bulkManageFrame = f
end

function Lists.ConfirmBroadcastDeleteOnShow(frame, params)
	local configName, targetName = params['configName'], params['targetName']
	Logging:Debug("ConfirmBroadcastDeleteOnShow(%s, %s)", tostring(configName), tostring(targetName))
	UIUtil.DecoratePopup(frame)
	frame.text:SetText(format(L['confirm_broadcast_delete_configuration'], configName, targetName))
end

do
	local PriorityAction = {
		All     = "ALL",
		Player  = "PLAYER"
	}

	local PlayerAction = {
		After  = "AFTER",
		Before = "BEFORE",
		Down   = "DOWN"
	}

	local PriorityActionsEntryBuilder =
		DropDown.EntryBuilder()
	        :nextlevel()
	            :add():text(L["all"])
	                :set('colorCode', UIUtil.RGBToHexPrefix(C.Colors.ItemArtifact:GetRGBA()))
	                :value(PriorityAction.All)
	                :checkable(false):arrow(true)
	            :add():text(function(name, entry) return entry and UIUtil.ClassColorDecorator(entry.class):decorate(name) or L["na"] end)
	                :value(PriorityAction.Player)
	                :checkable(false):arrow(true)
            :nextlevel()
	            :add():set('special', PriorityAction.All)
	            :add():set('special', PriorityAction.Player)
	        :nextlevel()
	            :add():set('special', PlayerAction.After)
	            :add():set('special', PlayerAction.Before)
	            :add():set('special', PlayerAction.Down)


	Lists.PriorityActionsMenuInitializer = DropDown.RightClickMenu(
		Util.Functions.True,
		PriorityActionsEntryBuilder:build(),
		function(info, menu, level, entry, value)
			--Logging:Warn("%s / %s / %s", tostring(level), tostring(value) ,Util.Objects.ToString(entry))

			local player, self = menu.entry, menu.module
			if value == PriorityAction.All and entry.special == value then
				info.text = L['revert']
				info.notCheckable = true
				info.disabled = not self.listPriorityTab:HasPendingChanges()
				info.func = function() self.listPriorityTab:UpdatePriorities() end
				MSA_DropDownMenu_AddButton(info, level)

				info.text = L['save']
				info.notCheckable = true
				info.disabled = not self.listPriorityTab:HasPendingChanges()
				info.func = function() self.listPriorityTab:SavePriorities() end
				MSA_DropDownMenu_AddButton(info, level)
			elseif value == PriorityAction.Player and entry.special == value then
				local enabled = not Util.Objects.IsEmpty(player)

				info.text = L['move_after']
				info.notCheckable = true
				info.hasArrow = enabled
				info.disabled = not enabled
				info.value = PlayerAction.After
				MSA_DropDownMenu_AddButton(info, level)

				info.text = L['move_before']
				info.notCheckable = true
				info.hasArrow = enabled
				info.disabled = not enabled
				info.value = PlayerAction.Before
				MSA_DropDownMenu_AddButton(info, level)

				info.text = L['move_down']
				info.notCheckable = true
				info.hasArrow = enabled
				info.disabled = not enabled
				info.value = PlayerAction.Down
				MSA_DropDownMenu_AddButton(info, level)
			elseif Util.Objects.In(value, PlayerAction.After, PlayerAction.Before) and entry.special == value then
				for _, pplayer in pairs(self.listPriorityTab.priorities) do
					if not Util.Objects.Equals(player, pplayer) then
						info = MSA_DropDownMenu_CreateInfo()
						info.text = UIUtil.ClassColorDecorator(pplayer.class):decorate(pplayer.name)
						info.notCheckable = true
						info.func = function()
							Logging:Warn("%s(%s, %s)", entry.special, tostring(player), tostring(pplayer))
							self.listPriorityTab:SetPriorityRelative(player, pplayer, value == PlayerAction.After or false)
						end
						MSA_DropDownMenu_AddButton(info, level)
					end
				end
			elseif value == PlayerAction.Down and entry.special == value then
				info.text = format(L['n_positions'], 2)
				info.notCheckable = true
				info.func = function() self.listPriorityTab:AdjustPriority(player, 2) end
				MSA_DropDownMenu_AddButton(info, level)

				info.text = format(L['n_positions'], 5)
				info.notCheckable = true
				info.func = function() self.listPriorityTab:AdjustPriority(player, 5) end
				MSA_DropDownMenu_AddButton(info, level)
			end
		end
	)
	local PlayerActionsEntryBuilder =
		DropDown.EntryBuilder()
	            :nextlevel()
	                :add():text(function(name, entry) return UIUtil.ClassColorDecorator(entry.class):decorate(name) end)
						:checkable(false):title(true)
	                :add():text(L["insert"]):checkable(false):arrow(true)
	            :nextlevel()
	                :add():text(L["insert_first"]):checkable(false)
	                    :fn(function(_, player, self) self.listPriorityTab:SetPriority(player, true) end)
	                :add():text(L["insert_last"]):checkable(false)
	                    :fn(function(_, player, self) self.listPriorityTab:SetPriority(player, false) end)
	                :add():text(L["insert_random"]):checkable(false)
	                    :fn(function(_, player, self) self.listPriorityTab:SetPriority(player, nil) end)

	Lists.PlayerActionsMenuInitializer = DropDown.RightClickMenu(
		Util.Functions.True,
		PlayerActionsEntryBuilder:build()
	)

	local ConfigAltsMenuEntryBuilder =
		DropDown.EntryBuilder()
	        :nextlevel()
	            :add():text(L["list_alts"]):checkable(false):title(true)
		        :add():text(L["save"]):checkable(false)
		        :disabled(function(_, _, self) return not self.configAltsTab:HasPendingChanges() end)
		        :fn(
					function(_, _, self)
						self.configAltsTab:SavePlayers()
					end
				)
	        :add():text(L["revert"]):checkable(false)
	            :disabled(function(_, _, self) return not self.configAltsTab:HasPendingChanges() end)
	            :fn(
					function(_, _, self)
						self.configAltsTab:UpdatePlayers()
					end
				)

	Lists.ConfigAltsMenuInitializer = DropDown.RightClickMenu(
		Util.Functions.True,
		ConfigAltsMenuEntryBuilder:build()
	)

	local function ConfigActionDisabled(config)
		return not config:IsAdminOrOwner(AddOn.player)
	end

	local ConfigAction = {
		BroadcastAddUpdate  =   "BAU",
		BroadcastRemove     =   "BR",
		Export              =   "EXPORT",
	}

	local ConfigActionsMenuEntryBuilder =
		DropDown.EntryBuilder()
	        :nextlevel()
	            :add():text(function(_, config, _) return config.name end):checkable(false):title(true)
		        :add():text(L["broadcast"]):checkable(false):arrow(true):value(ConfigAction.BroadcastAddUpdate)
		        :add():text(L["broadcast_remove"]):checkable(false):arrow(true):value(ConfigAction.BroadcastRemove)
				:add():text(L["export"]):checkable(false):arrow(true):value(ConfigAction.Export)
	        :nextlevel()
	            :add():set('special', ConfigAction.BroadcastAddUpdate)
	            :add():set('special', ConfigAction.BroadcastRemove)
				:add():set('special', ConfigAction.Export)

	Lists.ConfigActionsMenuInitializer = DropDown.RightClickMenu(
		Util.Functions.True,
		ConfigActionsMenuEntryBuilder:build(),
		function(info, menu, level, entry, value)
			if value == ConfigAction.BroadcastAddUpdate and entry.special == value then
				info.text = L["guild"]
				info.checkable = true
				info.colorCode = UIUtil.RGBToHexPrefix(C.Colors.Green:GetRGBA())
				info.disabled = ConfigActionDisabled(menu.entry)
				info.func = function()
					local config = menu.entry
					ListsDp:Broadcast(config.id, C.guild)
				end
				MSA_DropDownMenu_AddButton(info, level)

				info = MSA_DropDownMenu_CreateInfo()
				info.text = L["raid"]
				info.checkable = true
				info.colorCode = UIUtil.RGBToHexPrefix(C.Colors.ItemLegendary:GetRGBA())
				info.disabled = ConfigActionDisabled(menu.entry)
				info.func = function()
					local config = menu.entry
					ListsDp:Broadcast(config.id, C.group)
				end
				MSA_DropDownMenu_AddButton(info, level)
			elseif value == ConfigAction.BroadcastRemove and entry.special == value then
				info.text = L["guild"]
				info.checkable = true
				info.colorCode = UIUtil.RGBToHexPrefix(C.Colors.Green:GetRGBA())
				info.disabled = ConfigActionDisabled(menu.entry)
				info.func = function()
					local config = menu.entry
					Dialog:Spawn(C.Popups.ConfirmBroadcastDelete,{
						configId = config.id,
						configName = config.name,
						target= C.guild,
						targetName= L['guild'],
					})
				end
				MSA_DropDownMenu_AddButton(info, level)

				info = MSA_DropDownMenu_CreateInfo()
				info.text = L["raid"]
				info.checkable = true
				info.colorCode = UIUtil.RGBToHexPrefix(C.Colors.ItemLegendary:GetRGBA())
				info.disabled = ConfigActionDisabled(menu.entry)
				info.func = function()
					local config = menu.entry
					Dialog:Spawn(C.Popups.ConfirmBroadcastDelete, {
						configId = config.id,
						configName = config.name,
						target = C.group,
						targetName= L['group'],
					})
				end
				MSA_DropDownMenu_AddButton(info, level)
			elseif value == ConfigAction.Export and entry.special == value then
				info.text = L["lists"]
				info.checkable = true
				info.colorCode = UIUtil.RGBToHexPrefix(C.Colors.White:GetRGBA())
				-- info.disabled = ConfigActionDisabled(menu.entry)
				info.func = function() Lists:ExportConfig(menu.entry) end
				MSA_DropDownMenu_AddButton(info, level)
			end
		end
	)

	local ListAction = {
		Populate = "POPULATE",
	}

	local PopulateVia = {
		Guild = "GUILD",
		Rank  = "RANK",
	}
	local GuildActionQualifiers = {
		{ L["this_rank_only"], C.Colors.Blue, Util.Optional.empty() },
		{ L["this_rank_and_higher"], C.Colors.Green, Util.Optional.of(true) },
		{ L["this_rank_and_lower"], C.Colors.ItemLegendary, Util.Optional.of(false) },
	}

	--- @param list Models.List.List
	--- @param module Lists
	local function ListActionDisabled(_, list, module)
		local config = module:GetService().Configuration:Get(list.configId)
		return config and ConfigActionDisabled(config) or false
	end

	local ListActionsMenuEntryBuilder =
		DropDown.EntryBuilder()
	        :nextlevel()
	            :add():text(function(_, list, _) return list.name end)
	                :checkable(false):title(true)
	            :add():text(L["clear"])
	                :checkable(false):arrow(false)
	                :disabled(ListActionDisabled)
	                :fn(function(_, _, module) module.listPriorityTab:ClearPriorities() end)
	            :add():text(format("%s and %s", L["clear"], L["randomize"]))
	                :checkable(false):arrow(true)
	                :disabled(ListActionDisabled)
	                :value(ListAction.Populate)
	            :add():text(L['bulk_manage_priorities'])
	                :checkable(false):arrow(false)
	                :disabled(ListActionDisabled)
	                :fn(function(_, _, module) module.bulkManageFrame:Show() end)
	        :nextlevel()
	            :add():set('special', ListAction.Populate)
	        :nextlevel()
	            :add():set('special', PopulateVia.Guild)
	        :nextlevel()
	            :add():set('special', PopulateVia.Rank)

	Lists.ListActionsMenuInitializer = DropDown.RightClickMenu(
		Util.Functions.True,
		ListActionsMenuEntryBuilder:build(),
		function(info, menu, level, entry, value)
			local self = menu.module
			--Logging:Warn("%s / %s / %s", tostring(level), Util.Objects.ToString(value), tostring(entry.special))
			if value == ListAction.Populate and entry.special == value then
				info.text = format("%s %s", L['via'], UIUtil.ColoredDecorator(C.Colors.Green):decorate(L['guild']))
				info.notCheckable = true
				info.hasArrow = true
				info.value = PopulateVia.Guild
				MSA_DropDownMenu_AddButton(info, level)
			elseif value == PopulateVia.Guild and entry.special == value then
				for rank, name in pairs(Util.Tables.Sort2(AddOn.GetGuildRanks(), true)) do
					info = MSA_DropDownMenu_CreateInfo()
					info.notCheckable = true
					info.text = name
					info.hasArrow = true
					info.value = { PopulateVia.Rank, rank }
					MSA_DropDownMenu_AddButton(info, level)
				end
			elseif Util.Objects.IsTable(value) and value[1] == PopulateVia.Rank and entry.special == value[1] then
				local rank = value[2]
				for _, qualifier in pairs(GuildActionQualifiers) do
					info = MSA_DropDownMenu_CreateInfo()
					info.notCheckable = true
					info.text = UIUtil.ColoredDecorator(qualifier[2]):decorate(qualifier[1])
					info.func = function()
						self.listPriorityTab:ClearAndPopulatePrioritiesViaGuild(rank, qualifier[3])
					end
					MSA_DropDownMenu_AddButton(info, level)
				end
			end
		end
	)
end