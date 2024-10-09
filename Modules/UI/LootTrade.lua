--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type LibUtil
local Util = AddOn:GetLibrary('Util')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LootTrade
local LootTrade = AddOn:GetModule("LootTrade")

local RowHeight = 30
local ScrollColumns =
	ST.ColumnBuilder()
		-- remove item (1)
		:column(""):width(RowHeight)
		-- item icon (2)
		:column(""):width(RowHeight)
		-- item name (3)
		:column(""):width(120)
		-- arrow (4)
		:column(""):width(RowHeight - 5)
		-- recipient/winner (5)
		:column(""):width(100)
		-- trade indicator (6)
		:column(""):width(40)
	:build()

--- @return Frame
function LootTrade:GetFrame()
	if not self.frame then
		local f = UI:NewNamed('Frame', UIParent, 'LootTrade', self:GetName(), L['frame_loot_trade'], 350, 450)
		local st = ST.New(ScrollColumns, 5, RowHeight, nil, f)
		st.head:Hide()
		f:SetWidth(st.frame:GetWidth() + 20)
		st.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
		st.frame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 50)

		local close = UI:NewNamed('Button', f.content)
		close:SetText(_G.CLOSE)
		close:SetPoint("CENTER", f.content, "CENTER", 0, 0)
		close:SetPoint("BOTTOM", f.content, "BOTTOM", 0, 15)
		--close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15)
		close:SetScript("OnClick", function() self:Hide() end)
		f.cancel = close

		local _Show = f.Show
		f.Show = function(frame, forceShow)
			self:Populate()
			if forceShow or #frame.st.data > 0 then
				_Show(frame)
			end
		end

		self.frame = f
	end

	return self.frame
end

--- @param forceShow boolean should UI be displayed even if no data to display
function LootTrade:Show(forceShow)
	forceShow = Util.Objects.Default(forceShow, false)
	self:GetFrame():Show(forceShow)
end

--- Hides the
function LootTrade:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

--- Refreshes displayed data if module is enabled and interface is shown
function LootTrade:Refresh()
	Logging:Debug("Refresh()")
	if self:IsEnabled() and self.frame and self.frame:IsVisible() then
		--self.frame.st:Refresh()
		self:Populate()
	end
end

--- Populates the contents of the trade window
function LootTrade:Populate()
	if self.frame then
		--- @type LibScrollingTable.ScrollingTable
		local st = self.frame.st
		local rows, row = {}, 1
		AddOn:LootLedgerModule():GetStorage():ForEach(
			function(_, e)
				-- this is only to declare type for help with completion in IDE
				--- @type LootLedger.Entry
				local entry = e
				-- only interested in 'to trade' entries
				if entry and entry:IsToTrade() then
					rows[row] = {
						entry = entry,
						cols =
							STCellBuilder()
								:deleteCell(
									function(_, data, realRow)
										AddOn:LootLedgerModule():GetStorage():Remove(data[realRow].entry)
									end
								)
								:itemIconCell(entry.item)
								:cell(entry.item)
								-- https://www.wowhead.com/icon=450908/misc-arrowright#icon:misc_arrowright
								:iconCell(450908)
								:playerColoredCellOrElse(entry:GetItemAward():map(function(a) return a.winner end):orElse(nil), L['unknown'])
								:textCell(
									function(frame, data, realRow)
										frame.text:SetText(_G.TRADE)
										local award = data[realRow].entry:GetItemAward()
										if AddOn.inCombat or award:isEmpty() then
											frame.text:SetTextColor(C.Colors.RogueYellow:GetRGBA())
										else
											-- https://warcraft.wiki.gg/wiki/API_CheckInteractDistance
											local color = CheckInteractDistance(Ambiguate(award:get().winner, 'short'), 2) and
												C.Colors.Green or C.Colors.Red
											frame.text:SetTextColor(color:GetRGBA())
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