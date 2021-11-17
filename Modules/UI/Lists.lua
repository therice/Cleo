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
			:Point(0, -36):Size(1000, 580):SetTo(1)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, key in ipairs(Util.Tables.Sort(Util.Tables.Keys(Tabs))) do
		container.tabs.tabs[index]:Tooltip(Tabs[key])
	end

	--self:LayoutAltTab(container.tabs:Get(1))
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

function Lists:LayoutConfigurationTab(tab)
	local module = self

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

	tab.version =
		UI:New('Text', tab)
	        :Point("RIGHT", tab.banner, "RIGHT", -5, 0)
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
		local enabled = config and config:IsAdmin()
		self.delete:SetEnabled(enabled)
	end

	tab.Update = function(self)
		local config = SelectedConfiguration()
		self.version:SetValue(config)
		self:SetButtonsEnabled(config)

		for _, childTab in self.configSettings:IterateTabs() do
			if childTab.Update then
				childTab:Update()
			end
		end
	end

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
		ceil(tab:GetHeight()/(PlayerHeight + 6)), min(4, floor(tab:GetWidth()/(PlayerWidth + 25)))

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

		Logging:Debug(
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
					Logging:Debug("EditOnChange()[main] : %s (previous) cleared", tostring(priorValue))
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
			self:RegisterForDrag(active and "LeftButton" or nil)
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
			:Point("BOTTOM", 0, (columns - 1.8) * PlayerHeight)
			:Point("RIGHT", tab, -110, 0)
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
		local config = configSupplier()
		if config then
			return not Util.Tables.Equals(config:GetAlternates(), self:ProcessPlayers(), true)
		end
		return false
	end

	tab.playersCache = {}
	tab.ProcessPlayers = Util.Memoize.Memoize(
		function(self)
			Logging:Debug("ProcessPlayers()")

			local players = {}
			-- iterate through main indexes
			for mainIndex = 1, (columns * rowsPerColumn), (MaxAlts + 1) do
				local mainName = self.altEdits[mainIndex]:GetText()
				if Util.Objects.IsSet(mainName) then
					local main, alts = Player:Get(mainName), {}
					Logging:Debug("ProcessPlayers(%d) : %s", mainIndex, tostring(mainName))
					for altIndex = mainIndex + 1, (mainIndex + MaxAlts) do
						local altName = self.altEdits[altIndex]:GetText()
						if Util.Objects.IsSet(altName) then
							Logging:Debug("ProcessPlayers(%d) : %s", altIndex, tostring(altName))
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
		local config = configSupplier()
		if config then
			if self:HasPendingChanges() then
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
				playerEdit:Point("TOPLEFT", PriorityCoord(playerEdit, (4.5*PlayerWidth), -(PlayerHeight * 1.5)))
				playerEdit:SetFont(playerEdit:GetFont(), 12)
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
		local enabled = config and config:IsAdminOrOwner()
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
	local module, configList = self, tab:GetParent().configList

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
					Logging:Trace("Config.Status.OnClick(%s) : %s", tostring(config.id), Util.Objects.ToString(item))
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
				Logging:Trace("Config.Owner.OnClick(%s) : %s", tostring(config.id), Util.Objects.ToString(item))
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
		return config
	end

	--- @return Models.List.List
	local function SelectedList()
		local list = tab.lists:Selected()
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
				function(self) self:SetList(module:GetService():Configurations()) end, false
			)
			:OnValueChanged(
				function(item)
					local config = item.value
					Logging:Trace("List.Config.OnValueChanged(%s)", tostring(config.id))
					tab.lists:SetList(module:GetService():Lists(config.id))
					tab.lists:ClearSelection()
					tab:Update()
					tab:SetButtonsEnabled(config)
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
					Logging:Trace("List.Equipment(OptionsSupplier) : %s ", tostring(list and list.id or nil))
					local unassigned = config and module:GetService():UnassignedEquipmentLocations(config.id) or {}
					--[[
					Logging:Trace("%s - %s",
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
					Logging:Trace("List.Equipment(OnSelectedChanged) : %s/%s, %s", tostring(equipment), tostring(slot), tostring(added))

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


local PriorityWidth, PriorityHeight = 150, 18
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
		local playerName, index, priorities = self:GetText(), self.index, self:GetParent().priorities
		if Util.Strings.IsSet(playerName) then
			self:SetTextColor(UIUtil.GetPlayerClassColor(playerName):GetRGBA())
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
						DropDown.ToggleMenu(1, PriorityActionsMenu, self)
					end
				end
		)
		priorityEdit:SetEnabled(false)
		priorityEdit:Point("TOPLEFT", PriorityCoord(priorityEdit))

		priorityEdit.SetActive = function(self, active)
			self:SetMovable(active)
			self:RegisterForDrag(active and "LeftButton" or nil)
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
		return not Util.Tables.Equals(self.prioritiesOrig, self.priorities, true)
	end

	tab.UpdatePriorities = function(self, reload)
		reload = Util.Objects.IsNil(reload) and true or reload
		local list = listSupplier()

		Logging:Trace("UpdatePriorities(%s) : reload(%s)", list and list.id or 'nil', tostring(reload))

		if reload then
			self.prioritiesOrig, self.priorities = {}, {}
			if list then
				self.prioritiesOrig = list:GetPlayers()
			end
		end

		local priorityCount = reload and #self.prioritiesOrig or table.maxn(self.priorities)
		Logging:Trace("UpdatePriorities(%s) : Count(%d)",  list and list.id or 'nil', priorityCount)

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

	tab.UpdateAvailablePlayers = function(self)
		-- less 3 rows because of headers and footers
		local displayRows = (rowsPerColumn - 3)
		--- @type  table<string, Models.Player>
		local allPlayers = AddOn:Players(self.includeRaid, self.includeGuild, true)
		local allAlts = Util.Tables.Flatten(Util.Tables.Values(configSupplier():GetAlternates()))

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

	local ConfigAltsMenuInitializer =
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
		ConfigAltsMenuInitializer:build()
	)
end