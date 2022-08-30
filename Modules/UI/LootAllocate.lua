--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type UI.MoreInfo
local MI = AddOn.Require('UI.MoreInfo')
--- @type UI.DropDown
local DropDown = AddOn.Require('UI.DropDown')
local Dialog = AddOn:GetLibrary("Dialog")
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player

--- @type LootAllocate
local LA = AddOn:GetModule('LootAllocate')

local GameTooltip = GameTooltip
local RightClickMenu, FilterMenu, Enchanters

local ScrollColumns, ScrollColumnCells =
	ST.ColumnBuilder()
		:column(""):set("col", "class"):sortnext(5):width(20)                                   -- 1
		:column(_G.NAME):set("col", "name"):width(120)                                          -- 2
		:column(_G.RANK):set("col", "rank"):sortnext(4):width(95)                               -- 3
			:comparesort(function(...) return LA.SortByRank(...) end)
		:column(L["response"]):set("col", "response"):width(240)                                -- 4
			:defaultsort(STColumnBuilder.Ascending):sortnext(5)
			:comparesort(function(...) return LA.SortByResponse(...) end)
		:column(L["priority_active"]):set("col", "pa"):width(100)                               -- 5
			:defaultsort(STColumnBuilder.Ascending):sortnext(6)
			:comparesort(function(...) return LA.SortByActivePrio(...) end)
		:column(L["priority_overall"]):set("col", "po"):sortnext(11):width(100)                 -- 6
			:comparesort(function(...) return LA.SortByOverallPrio(...) end)
		:column(_G.ITEM_LEVEL_ABBR):set("col", "ilvl"):sortnext(8):width(45)                    -- 7
		:column(L["diff"]):set("col", "diff"):width(40)                                         -- 8
		:column(L["g1"]):set("col", "gear1"):width(20):align('CENTER')                          -- 9
		:column(L["g2"]):set("col", "gear2"):width(20):align('CENTER')                          -- 10
		:column(_G.ROLL):set("col", "roll"):sortnext(8):width(50):align('CENTER')               -- 11
	:build()


function LA:GetFrame()
	if not self.frame then
		local f = UI:NewNamed('Frame', UIParent, 'LootAllocate', self:GetName(), L['frame_loot_allocate'], 450, 450)
		f.close:Hide()
		-- override default behavior for ESC to not close the loot allocation window
		-- too easy to make mistakes and not get an opportunity to allocate loot
		f:SetScript(
			"OnKeyDown",
			function(self, key)
				if key == "ESCAPE" then
					self:SetPropagateKeyboardInput(false)
				else
					self:SetPropagateKeyboardInput(true)
				end
			end
		)

		RightClickMenu = MSA_DropDownMenu_Create(C.DropDowns.AllocateRightClick, f.content)
		FilterMenu = MSA_DropDownMenu_Create(C.DropDowns.AllocateFilter, f.content)
		Enchanters = MSA_DropDownMenu_Create(C.DropDowns.Enchanters, f.content)
		MSA_DropDownMenu_Initialize(RightClickMenu, self.RightClickMenu, "MENU")
		MSA_DropDownMenu_Initialize(FilterMenu, self.FilterMenu)
		MSA_DropDownMenu_Initialize(Enchanters, function(...) self:EnchantersMenu(...) end)

		local st = ST.New(ScrollColumns, 15, 20, nil, f)
		st:RegisterEvents({
			["OnClick"] = function(_, cellFrame, data, _, row, realrow, _, _, button, ...)
				if button == C.Buttons.Right and row then
					RightClickMenu.name = data[realrow].name
					RightClickMenu.module = self
					MSA_ToggleDropDownMenu(1, nil, RightClickMenu, cellFrame, 0, 0)
				elseif button == C.Buttons.Left and row then
					MI.Update(f, data, realrow)
					f.Update(Util.Objects.Check((data and row), data[row].name, nil), true)
					if IsAltKeyDown() then
						Dialog:Spawn(C.Popups.ConfirmAward, self:GetItemAward(self.session, data[realrow].name))
					end
				end
				return false
			end,
			["OnEnter"] = function(_, _, data, _, row, realrow, _, _, _, ...)
				if row then
					MI.Update(f, data, realrow)
					f.Update(Util.Objects.Check((data and row), data[row].name, nil), true)
				end
				return false
			end,
			["OnLeave"] = function(_, _, data, _, row, _, _, _, _, ...)
				if row then
					MI.Update(f)
					f.Update(Util.Objects.Check((data and row), data[row].name, nil), false)
				end
				return false
			end,
		})
		st:SetFilter(function (...) return self:FilterFunc(...) end)
		st:EnableSelection(true)

		MI.EmbedWidgets(self:GetName(), f, MI.UpdateMoreInfoWithLootStats)

		local item = UI:New('IconBordered', f.content,  "Interface/ICONS/INV_Misc_QuestionMark")
		item:SetMultipleScripts({
            OnEnter = function()
	            if not self:HaveLootTable() then return end
	            UIUtil:CreateHypertip(self:CurrentEntry().link)
	            GameTooltip:AddLine("")
	            GameTooltip:AddLine(L["always_show_tooltip_howto"], nil, nil, nil, true)
	            GameTooltip:Show()
            end,
            OnLeave = function() UIUtil:HideTooltip() end,
            OnClick = function()
	            if not self:HaveLootTable() then return end
	            if IsModifiedClick() then
		            HandleModifiedItemClick(self:CurrentEntry().link);
	            end

	            if item.lastClick and GetTime() - item.lastClick <= 0.5 then
		            local moduleSettings = AddOn:ModuleSettings(self:GetName())
		            moduleSettings.alwaysShowTooltip = not moduleSettings.alwaysShowTooltip
		            self:Update()
				else
		            item.lastClick = GetTime()
	            end
            end
        })
		item:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -20)
		item:SetSize(50,50)
		f.itemIcon = item
		f.itemTooltip = UIUtil.CreateGameTooltip(self:GetName(), f.content)

		local itemText = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		itemText:SetPoint("TOPLEFT", item, "TOPRIGHT", 10, 0)
		itemText:SetText("")
		f.itemText = itemText

		local itemList  = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		itemList:SetPoint("TOPLEFT", itemText, "BOTTOMLEFT", 5, -5)
		itemList:SetTextColor(0.90, 0.80, 0.50, 1)
		itemList:SetText("IT")
		f.itemList = itemList

		local ilvl = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ilvl:SetPoint("TOPLEFT", itemList, "BOTTOMLEFT", 0, -4)
		ilvl:SetTextColor(1, 1, 1)
		ilvl:SetText("")
		f.itemLvl = ilvl

		local state = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		state:SetPoint("LEFT", ilvl, "RIGHT", 5, 0)
		state:SetTextColor(0, 1, 0, 1)
		state:SetText("")
		f.itemState = state

		local type = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		type:SetPoint("TOPLEFT", ilvl, "BOTTOMLEFT", 0, -4)
		type:SetTextColor(0.5, 1, 1)
		type:SetText("")
		f.itemType  = type

		-- abort button
		local abort = UI:New('Button', f.content)
		abort:SetText(_G.CLOSE)
		abort:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -50)
		abort:SetScript("OnClick", function()
			if AddOn:IsMasterLooter() and self.active then
				Dialog:Spawn(C.Popups.ConfirmAbort)
			else
				self:EndSession(true)
			end
		end)
		f.abort = abort

		-- filter
		local filter = UI:New('Button', f.content):Tooltip(L["deselect_responses"])
		filter:SetText(_G.FILTER)
		filter:SetPoint("RIGHT", f.abort, "LEFT", -10, 0)
		filter:SetScript("OnClick", function(self) MSA_ToggleDropDownMenu(1, nil, FilterMenu, self, 0, 0)  end)
		f.filter = filter

		-- disenchant
		local disenchant = UI:New('Button', f.content):Tooltip(L["enchanter_select"])
		disenchant:SetText(_G.ROLL_DISENCHANT)
		disenchant:SetPoint("RIGHT", f.filter, "LEFT", -10, 0)
		disenchant:SetScript("OnClick", function(self) MSA_ToggleDropDownMenu(1, nil, Enchanters, self, 0, 0)  end)
		f.disenchant = disenchant

		local award  = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		award:SetPoint("CENTER", f.content, "TOP", 0, -35)
		award:SetText(L["item_awarded_to"])
		award:SetTextColor(1, 1, 0, 1) -- Yellow
		award:Hide()
		f.awardString = award

		local awardPlayer = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		awardPlayer:SetPoint("TOP", f.awardString, "BOTTOM", 7.5, -3)
		awardPlayer:SetText("PlayerName")
		awardPlayer:SetTextColor(1, 1, 1, 1)
		awardPlayer:Hide()
		f.awardStringPlayer = awardPlayer

		local awardTexture  = f.content:CreateTexture()
		awardTexture:SetTexture("Interface/ICONS/INV_Misc_QuestionMark.png")
		awardTexture.SetNormalTexture = function(self, tex)  self:SetTexture(tex) end
		awardTexture.GetNormalTexture = function(self) return self end
		awardTexture:SetPoint("RIGHT", f.awardStringPlayer , "LEFT")
		awardTexture:SetSize(15, 15)
		awardTexture:Hide()
		f.awardStringPlayer.classIcon = awardTexture

		-- Session toggle
		local sessionToggle = CreateFrame("Frame", "SessionToggleFrame", f.content)
		sessionToggle:SetWidth(40)
		sessionToggle:SetHeight(f:GetHeight())
		sessionToggle:SetPoint("TOPRIGHT", f, "TOPLEFT", -2, 0)
		f.sessionToggleFrame = sessionToggle

		f.Update = function(name, userResponse)
			-- todo : may not need this if we don't alter stuff based upon response
		end

		self.sessionButtons = {}
		self.frame = f
	end

	return self.frame
end

function LA:UpdateSessionButtons()
	for session, entry in pairs(self.lootTable) do
		self.sessionButtons[session] =
			self:UpdateSessionButton(session, entry.texture, entry.link, entry.awarded)
	end
end

-- if button not present for session, then creates one and associates with session
-- any newly created or existing button is then updated to reflect the status
function LA:UpdateSessionButton(session, texture, link, awarded)
	local btn = self.sessionButtons[session]
	if not btn then
		btn = UI:NewNamed('IconBordered', self.frame.sessionToggleFrame, "AllocateButton".. session , texture)
		if session == 1 then
			btn:SetPoint("TOPRIGHT", self.frame.sessionToggleFrame)
		elseif mod(session, 10) == 1 then
			btn:SetPoint("TOPRIGHT", self.sessionButtons[session - 10], "TOPLEFT", -2, 0)
		else
			btn:SetPoint("TOP", self.sessionButtons[session - 1], "BOTTOM", 0, -2)
		end
		btn:SetScript("Onclick", function() self:SwitchSession(session) end)
	end

	-- then update it
	btn:SetNormalTexture(texture or "Interface\\InventoryItems\\WoWUnknownItem01")
	local lines = { format(L["click_to_switch_item"], link) }
	if session == session then
		btn:SetBorderColor("yellow")
	elseif awarded then
		btn:SetBorderColor("green")
		tinsert(lines, L["item_has_been_awarded"])
	else
		btn:SetBorderColor("white")
	end
	btn:SetScript("OnEnter", function(self) UIUtil.ShowTooltip(self, nil, nil, unpack(lines)) end)
	return btn
end

function LA:GetItemStatus(item)
	if not item then return "" end
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetHyperlink(item)
	local text = ""
	if GameTooltip:NumLines() > 1 then
		local line = getglobal('GameTooltipTextLeft2')
		local t = line:GetText()
		-- Logging:Debug("GetItemStatus() : %s", t)
		if t and strfind(t, "cFF 0FF 0") then
			text = t
		end
	end
	GameTooltip:Hide()
	return text
end

function LA:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

function LA:Show()
	Logging:Trace("Show()")
	if self.frame and self.lootTable[self.session] then
		if self:HaveUnawardedItems() then self.active = true end
		self.frame:Show()
		self:SwitchSession(self.session)
	else
		AddOn:Print(L["session_not running"])
	end
end

function LA:SwitchSession(session)
	Logging:Trace("SwitchSession(%d)", session)
	local entry = self:GetEntry(session)
	self.session = session
	self.frame.itemIcon:SetNormalTexture(entry.texture)
	self.frame.itemIcon:SetBorderColor("purple")
	self.frame.itemText:SetText(entry.link)
	self.frame.itemState:SetText(self:GetItemStatus(entry.link))
	local itemList = AddOn:ListsModule():GetActiveListAndPriority(entry:GetEquipmentLocation())
	self.frame.itemList:SetText((itemList and itemList.name or L['unknown']))
	self.frame.itemLvl:SetText(_G.ITEM_LEVEL_ABBR..": " .. entry:GetLevelText())
	self.frame.itemType:SetText(entry:GetTypeText())

	self:UpdateSessionButtons()
	-- sessions have switched, we want to default sort by response
	local j = 1
	for i in ipairs(self.frame.st.cols) do
		self.frame.st.cols[i].sort = nil
		if self.frame.st.cols[i].col == "response" then
			j = i
		end
	end
	self.frame.st.cols[j].sort = 1
	-- Reset scrolling to 0
	FauxScrollFrame_OnVerticalScroll(self.frame.st.scrollframe, 0, self.frame.st.rowHeight, function() self.frame.st:Refresh() end)
	self:Update(true)
end

function LA:GetScrollingTableCells()
	if not ScrollColumnCells then
		--- @type UI.ScrollingTable.CellBuilder
		local CellBuilder = STCellBuilder()
		for _, col in ipairs(ScrollColumns) do
			local cell = CellBuilder:cell(""):set('col', col.col)
			local method = 'SetCell' .. Util.Strings.UcFirst(col.col)
			if self[method] then
				cell:DoCellUpdate(ST.DoCellUpdateFn(function(...) self[method](self, ...) end))
			end
		end
		ScrollColumnCells = CellBuilder:build()
	end

	return ScrollColumnCells
end

function LA:BuildScrollingTable()
	if self.frame then
		Logging:Trace("BuildScrollingTable()")

		local rows, row = {}, 1
		for name in AddOn:GroupIterator() do
			rows[row] = {
				name = name,
				cols = self:GetScrollingTableCells()
			}
			row = row + 1
		end

		self.frame.st:SetData(rows)
	end
end

LA.SortByRank =
	ST.SortFn(
		function(row)
			local cr = LA:CurrentEntry():GetCandidateResponse(row.name)
			return AddOn.GetGuildRanks()[cr.guildRank] or 100
		end
	)

LA.SortByResponse =
	ST.SortFn(
		function(row)
			local cr = LA:CurrentEntry():GetCandidateResponse(row.name)
			return AddOn:GetResponse(cr.response).sort
		end
	)

LA.SortByActivePrio =
	ST.SortFn(
		function(row)
			local name, entry = row.name, LA:CurrentEntry()
			local _, priority = AddOn:ListsModule():GetActiveListAndPriority(entry:GetEquipmentLocation(), name)
			return priority or 9999
		end
	)

LA.SortByOverallPrio =
	ST.SortFn(
       function(row)
	       local name, entry = row.name, LA:CurrentEntry()
	       local _, priority = AddOn:ListsModule():GetOverallListAndPriority(entry:GetEquipmentLocation(), name)
	       return priority or 9999
       end
	)

--
-- SetCellX BEGIN
--
-- these functions will be automatically discovered and injected into ST cell values
-- based up the column definitions (col value)
--
function LA:SetCellClass(_, frame, data, _, _, realrow, column, _, _, ...)
	local name = data[realrow].name
	local class = self:GetCandidateResponse(self.session, name).class
	UIUtil.ClassIconFn()(frame, class)
	data[realrow].cols[column].value = class or ""
end

function LA:SetCellName(_, frame, data, _, _, realrow, column, _, _, ...)
	local name = data[realrow].name
	frame.text:SetText(AddOn.Ambiguate(name))
	local r = self:GetCandidateResponse(self.session, name)
	if r.class then
		local c = UIUtil.GetClassColor(r.class)
		frame.text:SetTextColor(c.r, c.g, c.b, c.a)
	end
	data[realrow].cols[column].value = name or ""
end

function LA:SetCellRank(_, frame, data, _, _, realrow, column, _, _, ...)
	local name = data[realrow].name
	local response = self:GetCandidateResponse(self.session, name)
	frame.text:SetText(response.guildRank)
	frame.text:SetTextColor(AddOn:GetResponseColor(response.response))
	data[realrow].cols[column].value = response.guildRank or ""
end

function LA:SetCellResponse(_, frame, data, _, _, realrow, _, _, _, ...)
	local name = data[realrow].name
	local cresponse = self:GetCandidateResponse(self.session, name)
	local response = AddOn:GetResponse(cresponse.response)
	local text = response.text
	if (IsInInstance() and select(4, UnitPosition("player")) ~= select(4, UnitPosition(Ambiguate(name, "short")))) or
		((not IsInInstance()) and UnitPosition(Ambiguate(name, "short")) ~= nil) then
		text = text.." ("..L["out_of_instance"]..")"
	end
	frame.text:SetText(text)
	frame.text:SetTextColor(response.color:GetRGBA())
end

-- Priority (Active)
function LA:SetCellPa(_, frame, data, _, _, realrow, column, _, _, ...)
	local name, entry = data[realrow].name, self:CurrentEntry()
	local _, priority = AddOn:ListsModule():GetActiveListAndPriority(entry:GetEquipmentLocation(), name)
	frame.text:SetText(tostring(priority and priority or '?'))
	frame.text:SetTextColor(C.Colors.MageBlue:GetRGB())
	data[realrow].cols[column].value = priority
end

-- Priority (Overall)
function LA:SetCellPo(_, frame, data, _, _, realrow, column, _, _, ...)
	local name, entry = data[realrow].name, self:CurrentEntry()
	local _, priority = AddOn:ListsModule():GetOverallListAndPriority(entry:GetEquipmentLocation(), name)
	frame.text:SetText(tostring(priority and priority or '?'))
	frame.text:SetTextColor(C.Colors.ItemArtifact:GetRGB())
	data[realrow].cols[column].value = priority
end

function LA:SetCellIlvl(_, frame, data, _, _, realrow, column, _, _, ...)
	local name = data[realrow].name
	local cresponse = self:GetCandidateResponse(self.session, name)
	frame.text:SetText(Util.Numbers.Round2(cresponse.ilvl, 2) or Util.Numbers.Round2(cresponse.ilvl))
	data[realrow].cols[column].value = cresponse.ilvl or ""
end

function LA:SetCellDiff(_, frame, data, _, _, realrow, column, _, _, ...)
	local name = data[realrow].name
	local cresponse = self:GetCandidateResponse(self.session, name)
	frame.text:SetText(cresponse.diff)
	frame.text:SetTextColor(AddOn.GetDiffColor(cresponse.diff))
	data[realrow].cols[column].value = cresponse.diff or ""
end

function LA:SetCellGear(frame, name, gearSlot)
	local gear = self:GetCandidateResponse(self.session, name)[gearSlot]
	if gear then
		UIUtil.ItemIconFn()(frame, gear)
		frame:Show()
	else
		frame:Hide()
	end
end

function LA:SetCellGear1(_, frame, data, _, _, realrow, column, _, _, ...)
	self:SetCellGear(frame, data[realrow].name, data[realrow].cols[column].col)
end

function LA:SetCellGear2(_, frame, data, _, _, realrow, column, _, _, ...)
	self:SetCellGear(frame, data[realrow].name, data[realrow].cols[column].col)
end

function LA:SetCellRoll(_, frame, data, _, _, realrow, column, _, _, ...)
	local name = data[realrow].name
	local cresponse = self:GetCandidateResponse(self.session, name)
	frame.text:SetText(cresponse.roll or "")
	data[realrow].cols[column].value = cresponse.roll or ""
end
--
-- SetCellX END
--

function LA:Update(forceUpdate)
	forceUpdate = Util.Objects.Default(forceUpdate, false)
	-- Logging:Trace('Update(%s)', tostring(forceUpdate))
	if not forceUpdate then
		return
	end

	if not self.frame then return end
	if not self:CurrentEntry() then
		Logging:Warn("Update() : No Loot Table entry for session %d", self.session)
		return
	end

	self.frame.st:SortData()
	self.frame.st:SortData()
	
	local entry = self:CurrentEntry()
	if entry and entry.awarded then
		local cr = entry:GetCandidateResponse(entry.awarded)
		self.frame.awardString:SetText(L["item_awarded_to"])
		self.frame.awardString:Show()
		self.frame.awardStringPlayer:SetText(AddOn.Ambiguate(entry.awarded))
		local c = UIUtil.GetClassColor(cr.class)
		self.frame.awardStringPlayer:SetTextColor(c.r, c.g, c.b, c.a)
		self.frame.awardStringPlayer:Show()
		UIUtil.ClassIconFn()(self.frame.awardStringPlayer.classIcon, cr.class)
		self.frame.awardStringPlayer.classIcon:Show()
	else
		self.frame.awardString:Hide()
		self.frame.awardStringPlayer:Hide()
		self.frame.awardStringPlayer.classIcon:Hide()
	end

	if AddOn:IsMasterLooter() then
		if self.active then
			self.frame.abort:SetText(L["abort"])
		else
			self.frame.abort:SetText(_G.CLOSE)
		end
	else
		self.frame.abort:SetText(_G.CLOSE)
	end

	if #self.frame.st.filtered < #self.frame.st.data then
		self.frame.filter.Text:SetTextColor(0.86,0.5,0.22)
	else
		self.frame.filter.Text:SetTextColor(_G.NORMAL_FONT_COLOR:GetRGB())
	end

	local alwaysShowTooltip = AddOn:ModuleSettings(self:GetName()).alwaysShowTooltip
	if alwaysShowTooltip then
		self.frame.itemTooltip:SetOwner(self.frame.content, "ANCHOR_NONE")
		self.frame.itemTooltip:SetHyperlink(entry.link)
		self.frame.itemTooltip:Show()
		self.frame.itemTooltip:SetPoint("TOP", self.frame, "TOP", 0, 0)
		self.frame.itemTooltip:SetPoint("RIGHT", self.sessionButtons[#self.lootTable], "LEFT", 0, 0)
	else
		self.frame.itemTooltip:Hide()
	end
end

-- this stuff is stupid and ugly
do
	-- R(esponse)G(roup)
	local RG = {
		AwardFor       = "AWARD_FOR",
		ChangeResponse = "CHANGE_RESPONSE",
		Reannounce     = "REANNOUNCE",
		RequestRoll    = "REQUESTROLL",
	}

	-- R(esponse)C(ategory)
	local RC = {
		Candidate = "CANDIDATE",
		Group     = "GROUP",
		Roll      = "ROLL",
		Response  = "RESPONSE",
	}

	local function EndsWithRegEx(value, find)
		return value:find('_' .. find .. '$')
	end

	local function StartsWithRegEx(value, find)
		return value:find('^' .. find)
	end

	function LA.SolicitResponseText(candidate, category, self)
		if not Util.Objects.IsString(_G.MSA_DROPDOWNMENU_MENU_VALUE) then return end

		local ddMenuValue, text = _G.MSA_DROPDOWNMENU_MENU_VALUE, ""
		if category == RC.Candidate or EndsWithRegEx(ddMenuValue, RC.Candidate) then
			text = UIUtil.PlayerClassColorDecorator(candidate):decorate(AddOn.Ambiguate(candidate))
		elseif category == RC.Group or EndsWithRegEx(ddMenuValue, RC.Group) then
			text = _G.FRIENDS_FRIENDS_CHOICE_EVERYONE
		elseif category == RC.Roll or EndsWithRegEx(ddMenuValue, RC.Roll) then
			text = _G.ROLL .. ": "  .. (self:GetCandidateResponse(self.session, candidate).roll or "")
		elseif category == RC.Response or EndsWithRegEx(ddMenuValue, RC.Response) then
			local entry = self:CurrentEntry()
			local cresponse = entry:GetCandidateResponse(candidate)
			local response = AddOn:GetResponse(cresponse.response)
			text = L["response"] .. " : " ..
					UIUtil.ColoredDecorator(response.color or {1, 1, 1}):decorate(response.text or "")
		else
			Logging:Warn("unexpected category or dropdown menu values - %s, %s",
			             tostring(category), tostring(ddMenuValue))
		end

		return text
	end

	function LA.SolicitResponseRollPrint(target, thisItem, isRoll)
		local itemText = Util.Objects.Check(thisItem, L["this_item"], L["all_unawarded_items"])
		if isRoll then
			AddOn:Print(format(L["requested_rolls_for_i_from_t"], itemText, target))
		else
			AddOn:Print(format(L["reannounced_i_to_t"], itemText, target))
		end
	end

	--- @param self LootAllocate
	function LA.SolicitResponseButton(candidate, thisItem, self)
		if not Util.Objects.IsString(_G.MSA_DROPDOWNMENU_MENU_VALUE) then return end

		local namePred, sesPred
		if thisItem then
			sesPred = function(session)
				local e1 = self:GetEntry(session)
				local e2 = self:GetEntry(self.session)
				return session == self.session or (not e1.awarded and AddOn.ItemIsItem(e1.link, e2.link))
			end
		else
			sesPred = function(session) return not self:GetEntry(session).awarded end
		end

		local ddMenuValue = _G.MSA_DROPDOWNMENU_MENU_VALUE
		local isRoll = StartsWithRegEx(ddMenuValue, RG.RequestRoll) and true or false

		if EndsWithRegEx(ddMenuValue, RC.Candidate) then
			namePred = candidate
		elseif EndsWithRegEx(ddMenuValue, RC.Group) then
			namePred = true
		elseif EndsWithRegEx(ddMenuValue, RC.Roll) then
			namePred = function(name)
				local r1 = self:GetCandidateResponse(self.session, name)
				local r2 = self:GetCandidateResponse(self.session, candidate)
				return r1.roll == r2.roll
			end
		elseif EndsWithRegEx(ddMenuValue, RC.Response) then
			namePred = function(name)
				local r1 = self:GetCandidateResponse(self.session, name)
				local r2 = self:GetCandidateResponse(self.session, candidate)
				return r1.response == r2.response
			end
		else
			Logging:Warn("unexpected dropdown menu value - '%s' ", tostring(ddMenuValue))
		end

		-- No auto-pass on isRoll, which may be wrong but could be useful in case where you just want to distribute
		-- item based upon random rolls
		local noAutopass = thisItem and (EndsWithRegEx(ddMenuValue, RC.Candidate) or isRoll) and true or false
		if thisItem then
			self:SolicitResponse(namePred, sesPred, isRoll, noAutopass)
			LA.SolicitResponseRollPrint(LA.SolicitResponseText(candidate, nil, self), thisItem, isRoll)
		else
			local target = LA.SolicitResponseText(candidate, nil, self)
			Dialog:Spawn(C.Popups.ConfirmReannounceItems, {
				target = target,
				isRoll = isRoll,
				func = function()
					self:SolicitResponse(namePred, sesPred, isRoll, noAutopass)
					LA.SolicitResponseRollPrint(target, thisItem, isRoll)
				end
			})
		end
	end

	function LA.SolicitResponseCategoryEntry(builder, category)
		builder
			:add():checkable(false):arrow(true)
				:set('onValue', function() return Util.Objects.In(_G.MSA_DROPDOWNMENU_MENU_VALUE, RG.Reannounce, RG.RequestRoll) end)
				:set('value', function() return _G.MSA_DROPDOWNMENU_MENU_VALUE .. "_" .. category end)
				:text(function(candidate, _, self) return LA.SolicitResponseText(candidate, category, self) end)
	end

	local RighClickEntriesBuilder  =
		DropDown.EntryBuilder()
				-- level 1
		        :nextlevel()
			        :add():text(function(name) return AddOn.Ambiguate(name) end)
			            :set('isTitle', true):checkable(false):disabled(true)
			        :add():text(""):checkable(false):disabled(true)
			        :add():text(L['award']):checkable(false)
				        :fn(
							function(name, _, self)
								Dialog:Spawn(C.Popups.ConfirmAward, AddOn:LootAllocateModule():GetItemAward(self.session, name))
							end
						)
			        :add():text(L["award_for"]):value(RG.AwardFor):checkable(false):arrow(true)
			        :add():text(""):checkable(false):disabled(true)
			        :add():text(L["change_response"]):value(RG.ChangeResponse):checkable(false):arrow(true)
			        :add():text(L["reannounce"]):value(RG.Reannounce):checkable(false):arrow(true)
			        :add():text(L["add_rolls"]):checkable(false)
				        :fn(
							function(_)
								AddOn:LootAllocateModule():DoRandomRolls()
							end
						)
			        :add():text(_G.REQUEST_ROLL):value(RG.RequestRoll):checkable(false):arrow(true)
			        :add():text(L["remove_from_consideration"]):checkable(false)
				        :fn(
							function(name, _, self)
								AddOn:Send(AddOn.masterLooter, C.Commands.ChangeResponse, self.session, name, C.Responses.Removed)
							end
						)
				-- level2
		        :nextlevel()
			        :add():set('special', RG.AwardFor)
			        :add():set('special', RG.ChangeResponse)

	-- Reannounce/Reroll entries
	-- e.g. Reannounce -> Candidate, Reroll -> Response, etc.
	LA.SolicitResponseCategoryEntry(RighClickEntriesBuilder, RC.Candidate)
	LA.SolicitResponseCategoryEntry(RighClickEntriesBuilder, RC.Group)
	LA.SolicitResponseCategoryEntry(RighClickEntriesBuilder, RC.Roll)
	LA.SolicitResponseCategoryEntry(RighClickEntriesBuilder, RC.Response)

	RighClickEntriesBuilder
		-- level 3
		:nextlevel()
			:add():checkable(false):set('isTitle', true)
				:set('onValue',
	                 function()
		                 local ddMenuValue = _G.MSA_DROPDOWNMENU_MENU_VALUE
		                 return Util.Objects.IsString(ddMenuValue) and
								(StartsWithRegEx(ddMenuValue, RG.RequestRoll) or StartsWithRegEx(ddMenuValue, RG.Reannounce))
					end
				)
				:text(function(candidate, _, self) return LA.SolicitResponseText(candidate, nil, self) end)
				:fn(function(candidate, _, self) return LA.SolicitResponseButton(candidate, true, self) end)
			:add():checkable(false)
				:set('onValue',
		             function()
			             local ddMenuValue = _G.MSA_DROPDOWNMENU_MENU_VALUE
			             return Util.Objects.IsString(ddMenuValue) and
					             (StartsWithRegEx(ddMenuValue, RG.RequestRoll) or StartsWithRegEx(ddMenuValue, RG.Reannounce))
		             end
				)
				:text(
					function()
						local ddMenuValue = _G.MSA_DROPDOWNMENU_MENU_VALUE
						if Util.Objects.IsString(ddMenuValue) and StartsWithRegEx(ddMenuValue, RG.RequestRoll) then
							return L["this_item"] .. " (" .. _G.REQUEST_ROLL .. ")"
						else
							return L["this_item"]
						end
					end
				)
				:fn(function(candidate, _, self) return LA.SolicitResponseButton(candidate, true, self) end)
			:add():checkable(false)
				:set('onValue',
		             function()
			             local ddMenuValue = _G.MSA_DROPDOWNMENU_MENU_VALUE
			             return Util.Objects.IsString(ddMenuValue) and
					             (StartsWithRegEx(ddMenuValue, RG.RequestRoll) or StartsWithRegEx(ddMenuValue, RG.Reannounce)) and
					             (EndsWithRegEx(ddMenuValue, RC.Candidate) or EndsWithRegEx(ddMenuValue, RC.Group))
		             end
				)
				:text(
					function()
						local ddMenuValue = _G.MSA_DROPDOWNMENU_MENU_VALUE
						if Util.Objects.IsString(ddMenuValue) and StartsWithRegEx(ddMenuValue, RG.RequestRoll)  then
							return L["all_unawarded_items"] .. " (" .. _G.REQUEST_ROLL .. ")"
						else
							return L["all_unawarded_items"]
						end
					end
				)
				:fn(function(candidate, _, self) return LA.SolicitResponseButton(candidate, false, self) end)

	LA.RightClickEntries = RighClickEntriesBuilder:build()

	LA.RightClickMenu = DropDown.RightClickMenu(
			function() return AddOn:IsMasterLooter() end,
			LA.RightClickEntries,
			function(info, menu, level, entry, value)
				local candidateName, self = menu.name, menu.module
				if value == RG.AwardFor and entry.special == value then
					local reasonCount = self.db.profile.awardReasons.numAwardReasons
					for k, v in ipairs(self.db.profile.awardReasons) do
						if k > reasonCount then break end
						info.text = v.text
						info.notCheckable = true
						info.colorCode = UIUtil.RGBToHexPrefix(v.color:GetRGBA())
						info.func = function()
							Dialog:Spawn(C.Popups.ConfirmAward, self:GetItemAward(self.session, candidateName, v))
						end
						MSA_DropDownMenu_AddButton(info, level)
					end
				elseif value == RG.ChangeResponse and entry.special == value then
					local v
					for i = 1, AddOn:GetButtonCount() do
						v = AddOn:GetResponse(i)
						info.text = v.text
						info.colorCode = UIUtil.RGBToHexPrefix(v.color:GetRGBA())
						info.notCheckable = true
						info.func = function()
							AddOn:Send(AddOn.masterLooter, C.Commands.ChangeResponse, self.session, candidateName, i)
						end
						MSA_DropDownMenu_AddButton(info, level)
					end

					local passResponse = AddOn:MasterLooterModule().db.profile.responses.PASS
					info.text = passResponse.text
					info.colorCode = UIUtil.RGBToHexPrefix(passResponse.color:GetRGBA())
					info.notCheckable = true
					info.func = function()
						AddOn:Send(AddOn.masterLooter, C.Commands.ChangeResponse, self.session, candidateName, C.Responses.Pass)
					end

					MSA_DropDownMenu_AddButton(info, level)
					MSA_DropDownMenu_CreateInfo()
				end
			end
	)

	function LA.FilterMenu(_, level)
		local settings = AddOn:ModuleSettings(LA:GetName())
		if level == 1 then
			if not settings.filters then
				settings.filters = {}
			end

			local filters = settings.filters
			local data = {
				[C.Responses.AutoPass] = true,
				[C.Responses.Pass]     = true,
				['STATUS']             = true,
				[C.Responses.Default]  = true,
			}

			for i = 1, AddOn:GetButtonCount() do
				data[i] = i
			end

			local info = MSA_DropDownMenu_CreateInfo()
			info.text = _G.GENERAL
			info.isTitle = true
			info.notCheckable = true
			info.disabled = true
			MSA_DropDownMenu_AddButton(info, level)

			info = MSA_DropDownMenu_CreateInfo()
			info.text = L["candidates_cannot_use"]
			info.func = function()
				filters.showPlayersCantUseTheItem = not filters.showPlayersCantUseTheItem
				LA:Update(true)
			end
			info.checked = filters.showPlayersCantUseTheItem
			MSA_DropDownMenu_AddButton(info, level)


			info = MSA_DropDownMenu_CreateInfo()
			info.text = L["responses"]
			info.isTitle = true
			info.notCheckable = true
			info.disabled = true
			MSA_DropDownMenu_AddButton(info, level)

			info = MSA_DropDownMenu_CreateInfo()
			for k in ipairs(data) do
				local r = AddOn:GetResponse(k)
				info.text = r.text
				info.colorCode = UIUtil.RGBToHexPrefix(r.color:GetRGB())
				info.func = function()
					filters[k] = not filters[k]
					LA:Update(true)
				end
				info.checked = filters[k]
				MSA_DropDownMenu_AddButton(info, level)
			end

			for k in pairs(data) do
				if Util.Objects.IsString(k) then
					if k == "STATUS" then
						info.text = L["Status texts"]
						info.colorCode = "|cffde34e2"
					else
						local r = AddOn:GetResponse(k)
						info.text = r.text
						info.colorCode = UIUtil.RGBToHexPrefix(r.color:GetRGB())
					end
					info.func = function()
						filters[k] = not filters[k]
						LA:Update(true)
					end
					info.checked = filters[k]
					MSA_DropDownMenu_AddButton(info, level)
				end
			end
		end
	end
end

function LA:FilterFunc(_, row)
	local settings = AddOn:ModuleSettings(LA:GetName())
	if not settings.filters then
		settings.filters = {}
	end

	local filters, name, entry, include = settings.filters, row.name, self:CurrentEntry(), true

	local cresponse = entry:GetCandidateResponse(name)
	if not filters.showPlayersCantUseTheItem then
		include = not AddOn:AutoPassCheck(cresponse.class, entry.equipLoc, entry.typeId, entry.subTypeId, entry.classes)
	end

	local response = cresponse.response
	if include then
		if Util.Objects.In(response, C.Responses.AutoPass, C.Responses.Pass) or Util.Objects.IsNumber(response) then
			include = filters[response]
		else
			include = filters['STATUS']
		end
	end

	return include
end

function LA:EnchantersMenu(_, level)
	if level == 1 then
		local added = false
		local info = MSA_DropDownMenu_CreateInfo()

		for name in AddOn:GroupIterator() do
			local player = Player:Get(name)
			if player.enchanter then
				info.text =
					UIUtil.ClassColorDecorator(player.class):decorate(AddOn.Ambiguate(player:GetName())) ..
					"(" .. tostring(player.enchanterLvl) .. ")"
				info.notCheckable = true
				info.func = function()
					for _, reason in ipairs(self.db.profile.awardReasons) do
						if Util.Objects.Default(reason.disenchant, false) then
							Dialog:Spawn(C.Popups.ConfirmAward, self:GetItemAward(self.session, name, reason))
							return
						end
					end
				end

				added = true
				MSA_DropDownMenu_AddButton(info, level)
			end
		end

		if not added then
			info.text = L["no_enchanters_found"]
			info.notCheckable = true
			info.isTitle = true
			MSA_DropDownMenu_AddButton(info, level)
		end
	end
end