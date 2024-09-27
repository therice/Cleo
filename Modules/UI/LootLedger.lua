--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type LibUtil
local Util = AddOn:GetLibrary('Util')
--- @type LibCandyBar
local CandyBar = AddOn:GetLibrary('CandyBar')
--- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type Core.Message
local Message = AddOn.RequireOnUse('Core.Message')
--- @type Models.Item.LootedItem
local LootedItem = AddOn.Package('Models.Item').LootedItem
--- @type LootLedger
local LootLedger = AddOn:GetModule("LootLedger")
--- @type UI.DropDown
local DropDown = AddOn.Require('UI.DropDown')
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local  STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder

local MaxTradeTimeRemaining, ScrollColumns = 7200,
	ST.ColumnBuilder()
		-- 1 (item icon)
		:column(""):width(20):sortnext(3)
		-- 2 (item name)
		:column(_G.NAME):width(125)
			:defaultsort(STColumnBuilder.Ascending)
			:comparesort(ST.SortFn(function(row) return ItemUtil:ItemLinkToItemString(row.entry.item) end))
		-- 3 (added)
		:column(L['added']):width(125):sortnext(2)
			:defaultsort(STColumnBuilder.Descending)
			:comparesort(ST.SortFn(function(row) return row.entry.added end))
		-- 4 (state/status)
		:column(L['status']):width(75)
		-- 5 (encounter/boss)
		:column(L['dropped_by']):width(150)
		-- 6 (recipient/winner)
		:column(L['winner']):width(150)
		-- 7 (time remaining)
		:column(L['trade_time_remaining']):width(250)
	:build()

function LootLedger:LayoutInterface(container)
	Logging:Debug("LayoutInterface(%s)", tostring(container:GetName()))
	local module = self

	container:SetWide(1000)

	local st = ST.New(ScrollColumns, 20, 20, nil, container)
	st.frame:SetPoint("TOPLEFT", container.banner, "BOTTOMLEFT", 10, -30)
	st.frame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -15, 0)
	st:EnableSelection(true)

	container:SetScript("OnShow", function(self) module:Populate(self) end)
	self.interfaceFrame = container
end

--- Refreshes displayed data if module is enabled and interface is shown
function LootLedger:Refresh()
	if self:IsEnabled() and self.interfaceFrame and self.interfaceFrame:IsVisible() then
		self:Populate(self.interfaceFrame)
	end
end

---
--- Populates the scrolling table with data
---
--- @param container Frame
function LootLedger:Populate(container)
	--- @type LibScrollingTable.ScrollingTable
	local st = container.st
	if st then
		local rows, row = {}, 1
		self:GetStorage():ForEach(
			function(_, e)
				-- this is only to declare type for help with completion in IDE
				--- @type LootLedger.Entry
				local entry = e
				if entry then
					rows[row] = {
						num = row,
						entry = entry,
						cols =
							STCellBuilder()
								:itemIconCell(entry.item)
								:cell(entry.item)
								:cell(entry:FormattedTimestampAdded())
								:cell(entry:GetStateDescription())
								:cell(entry:GetEncounter():map(function(encounter) return AddOn.GetEncounterCreatures(encounter.encounterId) end):orElse(L['na']))
								:playerColoredCellOrElse(entry:GetWinner():orElse(nil), L['na'])
								:timerBarCell(250, 20,
									function(cdb, _, data, realRow)
										--- @type LootLedger.Entry
										local rowEntry = data[realRow].entry
										local bag, slot = AddOn:GetBagAndSlotByGUID(rowEntry.guid)
										if bag and slot then
											local ttRemaining = AddOn:GetInventoryItemTradeTimeRemaining(bag, slot)
											cdb:SetDuration(ttRemaining)
											cdb:AddUpdateFunction(
												function(self)
													if self.remaining > MaxTradeTimeRemaining then
														return
													end
													local pctRemaining = (self.remaining / MaxTradeTimeRemaining) * 100;
													if (pctRemaining >= 60) then
														self:SetColor(C.Colors.Peppermint:GetRGBA())
													elseif (pctRemaining >= 30) then
														self:SetColor(C.Colors.YellowLight:GetRGBA())
													else
														self:SetColor(C.Colors.RoseQuartz:GetRGBA())
													end
												end
											)
											cdb:Start(MaxTradeTimeRemaining)
										else
											cdb:SetParent(UIParent)
											cdb:Stop()
											cdb:Hide()
										end
									end
								)
								:build()
					}
					row = row + 1
				end
			end
		)

		st:SetData(rows)
		st:SortData()
	end
end


--[[ LootLedger.TradeTimesWindow START --]]
--- @type LibUtil.Numbers.AtomicNumber
local TTEntryCounter = Util.Numbers.AtomicNumber(1)
local TTHeaderHeight, TTRowHeight, TTMaxRows, TTMaxWidth, TTMaxHeight = 25, 22, 5, 1200, 490

---
--- Widget for display trade time remaining on looted items
---
--- @class LootLedger.TradeTimesWindow
--- @field frame table the window frame
local TradeTimesWindow = AddOn.Package("LootLedger"):Class("TradeTimesWindow")
function TradeTimesWindow:initialize()
	self.frame = nil
	--- @type table<string, table>
	self.rows = {}
	--- @type table<string, boolean>
	self.hidden = {}
	--- @type number
	self.rowsShown = 0
end

function TradeTimesWindow:Get()
	--Logging:Trace("Get(%s) : START", tostring(self.frame ~= nil))
	if not self.frame then
		local f = CreateFrame("Frame", AddOn:Qualify("TradeTimesWindow"), UIParent, Frame)
		f:SetSize(250, 100 + TTHeaderHeight) --.408
		f:SetPoint("CENTER", UIParent, "CENTER");
		f:SetClampedToScreen(true)
		f:SetFrameStrata("FULLSCREEN_DIALOG")
		f:SetToplevel(true)

		UIUtil.EmbedExtras(f, function() return Util.Tables.Get(AddOn.db.profile, "ui.LootLedger_TradeTimes") or {} end)
		UIUtil.EmbedMinimizeSupport(f)

		-- texture that goes behind title, differentiating it from rest of frame
		-- also adds support for double-clicking to minimize/maximize frame and drag-n-drop
		local titleTexture =
			UI:New('Texture', f, 0, 0, 0, 0.6, "BACKGROUND")
			  :AllPoints(f):Point("BOTTOM", f, "TOP", 0, -TTHeaderHeight)
			  :SetMultipleScripts({
	              OnMouseDown = function(self)
	                  local frame = self:GetParent()
	                  frame:StartMoving()
	              end,
	              OnMouseUp = function(self)
	                  local frame = self:GetParent()
	                  frame:StopMovingOrSizing()
	                  frame:SavePosition()
	                  frame:OnMouseUp()
	              end
	          })
		titleTexture:EnableMouse(true)
		f.titleTexture = titleTexture

		-- title of the window
		local title =
			UI:New('Text', f, L["frame_trade_times"], 12)
			  :Point("TOPLEFT", 5, -5):Color(1, 1, 1, 1):Left():Middle():Outline()
		f.title = title

		-- this is where all the "stuff" goes, allowing for easy hiding
		local content = CreateFrame("Frame", AddOn:Qualify("TradeTimesWindow", "Content"), f)
		content:SetSize(250, 100)
		content:SetToplevel(true)
		content:EnableMouse(true)
		-- put it right under the title bar (texture)
		content:SetPoint("TOP", titleTexture, "BOTTOM")
		content:SetPoint("LEFT", titleTexture, "LEFT")
		content:SetPoint("RIGHT", titleTexture, "RIGHT")
		f.content = content

		-- texture that goes into the content, as background
		local contentTexture =
			UI:New('Texture', content, 0, 0, 0, 0.3, "BACKGROUND"):AllPoints(content)
		f.contentTexture = contentTexture

		-- resizing support
		-- minWidth, minHeight [, maxWidth, maxHeight]
		content:SetResizeBounds(250, 100, TTMaxWidth, TTMaxHeight)
		content:SetResizable(true)
		f:SetResizeBounds(250, 100 + TTHeaderHeight, TTMaxWidth, TTMaxHeight)
		f:SetResizable(true)

		UIUtil.AddResizeWidget(content)

		content.resize:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
		content.resize:SetScript("OnMouseUp", function()  f:StopMovingOrSizing() end)
		content:SetScript("OnSizeChanged",
			function(self)
				local width, height = self:GetWidth(), self:GetHeight()
				self:SetWidth(math.min(width, TTMaxWidth))
				self:SetHeight(math.min(height, TTMaxHeight))

				local parent = self:GetParent()
				width, height = parent:GetWidth(), parent:GetHeight()
				parent:SetWidth(math.min(width, TTMaxWidth))
				parent:SetHeight(math.min(height, TTMaxHeight))

				parent:SaveDimensions()
				parent:SavePosition()
			end
		)
		content.resize:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -3, 2)
		content.resize:SetFrameLevel(500)
		content.resize.normalTexture:SetTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up")
		content.resize:SetSize(10, 10)

		-- do this after establishing to foundation elements, otherwise it can create
		-- stack overflows due to creation of widgets calling back into this
		f:HookScript("OnSizeChanged", function(_, _, _) self:SetHeight() end)

		-- various actions on a row by row basis
		local actionButtons = CreateFrame("Frame", AddOn:Qualify("TradeTimesWindow", "ActionButtons"), content)
		actionButtons:SetSize(TTRowHeight, TTRowHeight)
		actionButtons:Hide()

		local hideButton = UI:New('ButtonClose', actionButtons,  AddOn:Qualify("TradeTimesWindow", "ActionButtons", "Hide"))
		hideButton:SetSize(TTRowHeight, TTRowHeight)
		hideButton:SetPoint("TOPLEFT", actionButtons, "TOPLEFT")

		local normalTexture = hideButton:CreateTexture()
		normalTexture:SetTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Up")
		normalTexture:SetAllPoints(hideButton)
		hideButton:SetNormalTexture(normalTexture)

		local highlightTexture = hideButton:CreateTexture()
		highlightTexture:SetTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Up")
		highlightTexture:SetAllPoints(hideButton)
		hideButton:SetHighlightTexture(highlightTexture)

		hideButton:HookScript("OnLeave",
			function()
				actionButtons:Hide()
			end
		)

		actionButtons.hideButton = hideButton
		f.actionButtons = actionButtons

		self.frame = f
	end

	return self.frame
end

local RHLColorDefault, RHLColorMissing, RHLColorAwardLater, RHLColorToTrade =
	C.Colors.ItemPoor, C.Colors.DeathKnightRed, C.Colors.MageBlue, C.Colors.ShamanBlue

local TradeTimeRowAction = {
	Hide = "HIDE"
}

local TradeTimeRowType = {
	AwardLater = "AWARD_LATER",
	Item       = "ITEM",
	Missing    = "MISSING",
	ToTrade    = "TO_TRADE",
}

local TradeTimeRowActionsMenu, TradeTimeRowActionsMenuInitializer = nil, nil

do
	local TradeTimeRowActionsMenuEntryBuilder =
		DropDown.EntryBuilder()
			-- level 1
			:nextlevel()
				-- item section
				:add():text(L['item']):title(true):checkable(false):disabled(true)
					-- the item
					:add():text(
						function(_, entry, _)
							return ItemUtil:ItemLinkToColor(entry.tradeTime.link) .. ItemUtil:ItemLinkToItemName(entry.tradeTime.link) .. "|r"
						end
					):arrow(true):checkable(false):value(TradeTimeRowType.Item)
				-- category section
				:add():text(L['category']):title(true):checkable(false):disabled(true)
					-- missing
					:add():text(UIUtil.ColoredDecorator(RHLColorMissing):decorate(L['missing']))
						:arrow(true):checkable(false):value(TradeTimeRowType.Missing)
					-- award later
					:add():text(UIUtil.ColoredDecorator(RHLColorAwardLater):decorate(L['award_later']))
						:arrow(true):checkable(false):value(TradeTimeRowType.AwardLater)
					-- to trade
					:add():text(UIUtil.ColoredDecorator(RHLColorToTrade):decorate(L['trade']))
						:arrow(true):checkable(false):value(TradeTimeRowType.ToTrade)
			-- level 2
			:nextlevel()
				:add():set('special', TradeTimeRowAction.Hide)

	TradeTimeRowActionsMenuInitializer = DropDown.RightClickMenu(
		Util.Functions.True,
		TradeTimeRowActionsMenuEntryBuilder:build(),
		function(info, menu, level, entry, value)
			--- @type LootLedger.TradeTimesWindow
			local self = menu.module
			if entry.special == TradeTimeRowAction.Hide then
				info.text = L['hide']
				info.icon = "Interface/BUTTONS/UI-GroupLoot-Pass-Up"

				local hideFn = Util.Functions.Noop
				if Util.Strings.Equal(value, TradeTimeRowType.Item) then
					hideFn = function() self:HideItem(menu.entry.tradeTime.guid) end
				elseif Util.Strings.Equal(value, TradeTimeRowType.Missing) then
					hideFn = function() self:HideItems(true) end
				elseif Util.Strings.Equal(value, TradeTimeRowType.AwardLater) then
					hideFn = function() self:HideItems(false, true) end
				elseif Util.Strings.Equal(value, TradeTimeRowType.ToTrade) then
					hideFn = function() self:HideItems(false, false, true) end
				end

				info.func = function()
					hideFn()
					MSA_HideDropDownMenu(1)
				end

				MSA_DropDownMenu_AddButton(info, level)
				DropDown.HideCheckButton(level, 1)
			end
		end
	)
end

--- @param parent Frame
--- @param tradeTime LootLedger.TradeTime
function TradeTimesWindow:CreateRow(parent, tradeTime, actionButtons)
	-- e.g. Cleo_TradeTimesWindow_Row_1
	Logging:Trace("CreateRow() : %s", Util.Objects.ToString(tradeTime))

	if not TradeTimeRowActionsMenu then
		TradeTimeRowActionsMenu = MSA_DropDownMenu_Create(C.DropDowns.TradeTimeActions, parent)
		MSA_DropDownMenu_Initialize(TradeTimeRowActionsMenu, TradeTimeRowActionsMenuInitializer, "MENU")
		TradeTimeRowActionsMenu.module = self
	end

	local frame = CreateFrame(
		"Frame", AddOn:Qualify("TradeTimesWindow", "Row", tostring(TTEntryCounter:GetAndIncrement())), parent
	)
	frame:SetHeight(TTRowHeight);
	frame:SetPoint("LEFT", parent, "LEFT", 0, 0)
	frame:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
	frame.order = 0

	local countDownBar = CandyBar:New(UI.ResolveTexture("Clean"), 240, TTRowHeight)
	countDownBar:Set("type", "TRADE_TIME_REMAINING")
	countDownBar:Set("itemGUID", tradeTime.guid)
	countDownBar:SetParent(frame)
	countDownBar:SetDuration(tradeTime.remaining)
	countDownBar:SetColor(0, 1, 0, 0.3)
	countDownBar:SetFont(_G.GameFontNormalSmall:GetFont(), 12, "OUTLINE")
	countDownBar:SetBackgroundColor(0, 0, 0, 0.3)
	countDownBar:SetLabel(" " .. tradeTime.link)
	countDownBar:SetAllPoints(frame);
	countDownBar:SetTimeVisibility(false)
	frame.countDownBar = countDownBar

	-- this is a colored bar to left of the item icon, which is used to highlight the status of the item
	-- with respect to storage, either missing, award later, or to trade
	UI.LayerBorder(countDownBar.candyBarIconFrame, 4, RHLColorDefault.r, RHLColorDefault.b, RHLColorDefault.g, RHLColorDefault.a)
	countDownBar.candyBarIconFrame:HideBorders()

	frame.UpdateIcon = function(self)
		self.countDownBar:SetIcon(tradeTime.texture)
		countDownBar.candyBarIconFrame:ShowBorder("Left")
	end
	frame:UpdateIcon()

	frame.GetLootLedgerEntry = function()
		return LootLedger:GetStorage():GetByItemGUID(tradeTime.guid)
	end

	-- only show time remaining when hovered
	countDownBar:SetScript("OnEnter",
		function(cdb)
			cdb:SetTimeVisibility(true)
			actionButtons:ClearAllPoints()
			actionButtons:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
			actionButtons:SetFrameLevel(cdb:GetFrameLevel() + 1)
			actionButtons:Show()

			actionButtons.hideButton:SetScript("OnClick",
				function()
					if IsModifierKeyDown() then
						return
					end

					self:HideItem(tradeTime.guid)
					actionButtons:Hide()
				end
	       )
       end
	)

	-- hide time remaining when no longer hovered
	countDownBar:SetScript("OnLeave",
		function(cdb)
			cdb:SetTimeVisibility(false)
			if not UIUtil.IsMouseOnFrame(actionButtons) then
				actionButtons:Hide()
			end
		end
	)

	countDownBar:SetScript("OnMouseDown",
       function(self, button)
           if Util.Strings.Equal(C.Buttons.Right, button) then
	           TradeTimeRowActionsMenu.entry = {
                   tradeTime    = tradeTime,
                   storageEntry = frame:GetLootLedgerEntry()
               }
               DropDown.ToggleMenu(1, TradeTimeRowActionsMenu, self, 100, 10)
           end
       end
	)

	-- create link to item when icon is hovered
	countDownBar.candyBarIconFrame:SetScript("OnEnter",
		function()
			UIUtil.Link(tradeTime.link, frame)
		end
	)

	-- close link to item when icon is no longer hovered
	countDownBar.candyBarIconFrame:SetScript("OnLeave",
         function()
	         UIUtil:HideTooltip()
         end
	)

	countDownBar:AddUpdateFunction(
		function(cdb)
			if cdb.remaining > MaxTradeTimeRemaining then
				self:ReleaseRow(self.rows[tradeTime.guid])
				return
			end

			local pctRemaining = (cdb.remaining / MaxTradeTimeRemaining) * 100;
			if (pctRemaining >= 60) then
				countDownBar:SetColor(C.Colors.Peppermint:GetRGBA())
			elseif (pctRemaining >= 30) then
				countDownBar:SetColor(C.Colors.YellowLight:GetRGBA())
			else
				countDownBar:SetColor(C.Colors.RoseQuartz:GetRGBA())
			end

			local storageEntry = frame:GetLootLedgerEntry()
			if not storageEntry then
				countDownBar.candyBarIconFrame:SetBorderColor(RHLColorMissing:GetRGBA())
			elseif storageEntry.state == LootedItem.State.AwardLater then
				countDownBar.candyBarIconFrame:SetBorderColor(RHLColorAwardLater:GetRGBA())
			elseif storageEntry.state == LootedItem.State.ToTrade then
				countDownBar.candyBarIconFrame:SetBorderColor(RHLColorToTrade:GetRGBA())
			else
				countDownBar.candyBarIconFrame:SetBorderColor(RHLColorDefault:GetRGBA())
			end
		end
	)

	CandyBar.RegisterCallback(self, "LibCandyBar_Stop",
		function(_, cdb)
			if cdb and
				Util.Strings.Equal(cdb:Get("type"), "TRADE_TIME_REMAINING") and
				not cdb:Get("stopping") then

				local itemGUID = cdb:Get("itemGUID")
				if not Util.Strings.IsEmpty(itemGUID) then
					self:HideItem(itemGUID)
				end
			end
		end
	)

	local _Show, _Hide = frame.Show, frame.Hide
	frame.Show = function(self)
		self.countDownBar:Show()
		_Show(self)
	end

	frame.Hide = function(self)
		self.countDownBar:Hide()
		_Hide(self)
	end

	countDownBar:Start(MaxTradeTimeRemaining)

	return frame
end

--- @param row Frame
function TradeTimesWindow:ReleaseRow(row)
	if row  then
		local countDownBar = row.countDownBar
		if countDownBar and
			Util.Strings.Equal(countDownBar:Get("type"), "TRADE_TIME_REMAINING") and
			not countDownBar:Get("stopping") then

			countDownBar:SetParent(UIParent)
			countDownBar:Set("stopping", true)

			if countDownBar.running then
				countDownBar:Stop()
			end

			countDownBar:Hide()
		end

		row:Hide()
	end
end

function TradeTimesWindow:Refresh()
	Logging:Debug("Refresh()")
	local state = AddOn:LootLedgerModule():GetTradeTimes():GetState()
	--if there is now current trade time state, hide the window
	if Util.Tables.IsEmpty(state) then
		self:Hide()
		return
	end

	local frame = self:Get()

	-- hide anything no longer present in state or explicitly hidden
	for itemGUID, row in pairs(self.rows) do
		if not state[itemGUID] or self.hidden[itemGUID] then
			self:ReleaseRow(row)
			self.rows[itemGUID] = nil
		end
	end

	-- add anything which is present in state
	for itemGUID, entry in pairs(state) do
		if not self.rows[itemGUID] and not self.hidden[itemGUID] then
			self.rows[itemGUID] = self:CreateRow(frame.content, entry, frame.actionButtons)
		end
	end

	-- implicitly a copy due to use of Values()
	local entries, index = Util(state):Values()
	                                  :Sort(function (e1, e2) return e1.remaining and e2.remaining and e1.remaining < e2. remaining end)(), 1
	-- assign order based upon time remaining and hide
	for _, entry in pairs(entries) do
		local row = self.rows[entry.guid]
		if row then
			row.order = index
			index = index + 1
			row:Hide()
		end
	end

	local rowsShown, maxRows = 0, TTMaxRows
	for _, row in pairs(self.rows) do
		if row.order ~= 0 and row.order <= maxRows then
			row:SetPoint("TOP", frame.content, "TOP", 0, (row.order - 1) * -TTRowHeight)
			row:UpdateIcon()
			row:Show()
			rowsShown = rowsShown + 1
		end
	end

	self.rowsShown = rowsShown
	if rowsShown <= 0 then
		self:Hide()
		return
	end

	self:Show()
end

function TradeTimesWindow:HideItem(itemGUID)
	self.hidden[itemGUID] = true
	self:Refresh()
end

function TradeTimesWindow:HideItems(missing, awardLater, toTrade)
	missing, awardLater, toTrade = (missing == true), (awardLater == true), (toTrade == true)

	for itemGUID, row in pairs(self.rows) do
		if not self.hidden[itemGUID] then
			--- @type LootLedger.Entry
			local entry = row:GetLootLedgerEntry()
			if not entry and missing then
				self.hidden[itemGUID] = true
			elseif entry and ((awardLater and entry:IsAwardLater()) or (toTrade and entry:IsToTrade())) then
				self.hidden[itemGUID] = true
			end
		end
	end

	self:Refresh()
end

function TradeTimesWindow:SetHeight()
	local frame, height = self:Get(), math.ceil(TTHeaderHeight + (self.rowsShown * TTRowHeight))
	frame:SetHeight(height)
	frame.content:SetHeight(height - TTHeaderHeight)
end

function TradeTimesWindow:Show()
	Logging:Trace("Show()")
	self:SetHeight()
	self:Get():Show()
end

function TradeTimesWindow:Hide()
	Logging:Trace("Hide()")
	for key, row in pairs(self.rows) do
		if row then
			self:ReleaseRow(row)
			self.rows[key] = nil
		end
	end

	self:Get():Hide()
end
--[[ LootLedger.TradeTimesWindow END --]]

--[[ LootLedger.TradeTimesOverview START --]]
--- @class LootLedger.TradeTimesOverview
local TradeTimesOverview = AddOn.Instance(
	'LootLedger.TradeTimesOverview',
	function()
		return {
			--- @type LootLedger.TradeTimesWindow
			private     = TradeTimesWindow(),
			--- @type boolean
			enabled     = false,
			--- @type table
			messageSubs = nil,
		}
	end
)

function TradeTimesOverview:Enable()
	if not self.enabled then
		self.messageSubs = Message():BulkSubscribe({
			[C.Messages.TradeTimeItemsChanged] = function(_, _)
				Logging:Debug("TradeTimesOverview(%s)", C.Messages.TradeTimeItemsChanged)
				self.private:Refresh()
			end
		})

		self.enabled = true
	end
end

function TradeTimesOverview:Disable()
	if self.enabled then
		if self.messageSubs ~= nil then
			AddOn.Unsubscribe(self.messageSubs)
			self.messageSubs = nil
		end
		self.enabled = false
	end
end

function TradeTimesOverview:Open()
	self.private:Show()
end

function TradeTimesOverview:Close()
	self.private:Hide()
end
--[[ LootLedger.TradeTimesOverview END --]]