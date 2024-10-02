--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type LootSession
local LootSession = AddOn:GetModule('LootSession')

local ScrollColumns =
	ST.ColumnBuilder()
		-- remove item (1)
		:column(""):width(30)
		-- item icon (2)
        :column(""):width(40)
		-- item level (3)
        :column(""):width(50)
		-- item link (4)
        :column(""):width(160)
		-- item source (6)
		:column(""):width(40)
    :build()

function LootSession:GetFrame()
	if not self.frame then
		local f = UI:NewNamed('Frame', UIParent, 'LootSession', 'LootSession', L['frame_loot_session'], 275, 325)
		local st = ST.New(ScrollColumns, 5, 40, nil, f)
		-- disable sorting
		st:RegisterEvents({
			["OnClick"] = function(_, _, _, _, row, realRow)
			  if not (row or realRow) then
			      return true
			  end
			end,
		})
		st.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
		st.frame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 75)

		local toggle = UI:New('Checkbox', f.content):AddColorState()
		toggle:SetText(L['award_later'])
		toggle:Tooltip(L['award_later_tooltip'])
		toggle:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 43)
		toggle:SetSize(14, 14)
		toggle:SetChecked(self.awardLater)
		toggle:SetScript("OnClick", function() self.awardLater = not self.awardLater end)
		f.toggle = toggle

		local start = UI:New('Button', f.content)
		start:SetText(_G.START)
		start:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 15) -- 20
		start:SetScript("OnClick", function() self:Start() end)
		f.start = start

		local cancel = UI:NewNamed('Button', f.content)
		cancel:SetText(_G.CANCEL)
		cancel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15)
		cancel:SetScript("OnClick", function() self:Cancel() end)
		f.cancel = cancel

		-- replaced the close function
		f.close:SetScript("OnClick", function() self:Cancel() end)

		f.Update = function()
			self.frame.toggle:SetChecked(self.awardLater)
			if self.ml.running then
				self.frame.start:SetText(_G.ADD)
			else
				self.frame.start:SetText(_G.START)
			end
		end

		-- the scrolling table header is preventing scale slider from being accessed
		-- we don't use it in this context, so hide it
		st.head:Hide()

		self.frame = f
	end

	return self.frame
end

function LootSession:IsRunning()
	return self.frame and self.frame:IsVisible()
end

--- @param items table<number, Models.Item.LootTableEntry>
function LootSession:AddItems(items)
	if self.frame then
		self.frame.rows = {}
		for session, entry in pairs(items) do
			if not entry.sent then
				--- @type Models.Item.Item
				local item = entry:GetItem()
				-- check if item is available and valid, not because it must be at this moment
				-- but rather it will send an item query meaning results should be available when needed
				if not item or not item:IsValid() then
					Logging:Warn("AddItems(%s) : referenced item not available, will re-try querying later", tostring(entry.item))
				end
				Util.Tables.Push(self.frame.rows,{
					session = session,
					entry = entry,
					item = item,
					cols =
						ST.CellBuilder()
							:deleteCell(function(_, data, realRow) self:DeleteItem(data[realRow].session) end)
					        :itemIconCell(item and item.link or nil, item and item.texture or nil)
					        :cell(" " .. (item and item.ilvl or ""))
					        :textCell(
								function(frame, data, realRow)
									if not data[realRow].item then
										frame.text:SetText("--".._G.RETRIEVING_ITEM_INFO.."--")
										self.loadingItems = true
										if not self.showPending then
											self.showPending = true
											self:ScheduleTimer("Show", 0, self.ml:GetLootTable())
										end
									else
										frame.text:SetText(data[realRow].item.link)
									end
								end
							)
							:cell(""):DoCellUpdate(
								function(_, frame, data, _, _, realRow)
									--- @type  Models.Item.LootTableEntry
									local ltEntry = data[realRow].entry
									if ltEntry then
										--- @type Models.Item.LootSource
										local source = ltEntry.source
										local sourceType, sourceName = source:GetType(), source:GetName()
										local sourceIcon, sourceTt = nil, nil
										local ttTemplate =
											UIUtil.ColoredDecorator(C.Colors.White):decorate("%s :") .. ' ' ..
											UIUtil.ColoredDecorator(C.Colors.ItemHeirloom):decorate("%s")


										if Util.Strings.Equal(sourceType, "Creature") then
											sourceIcon = "Interface/ICONS/Achievement_Boss_Illidan"
											sourceTt = format(ttTemplate, L['creature'], sourceName)
										elseif Util.Strings.Equal(sourceType, "Player") then
											local ttExtraTemplate =
												UIUtil.ColoredDecorator(C.Colors.ItemArtifact):decorate(" (%s)")

											local sourceTtExtra
											-- if the item has a ledger entry, show as such
											if ltEntry:GetLootLedgerEntry():isPresent() then
												sourceIcon = "Interface/ICONS/INV_Misc_Note_01"
												sourceTtExtra = format(ttExtraTemplate, L["in_ledger"])
											else
												sourceIcon = "Interface/ICONS/INV_Misc_Bag_08"
												sourceTtExtra = format(ttExtraTemplate, L["in_bags"])
											end
											sourceTt = format(ttTemplate .. sourceTtExtra, L['player'], sourceName)
										elseif Util.Strings.Equal(sourceType, "Test") then
											sourceIcon = "Interface/ICONS/Trade_Engineering"
											sourceTt = format(ttTemplate, L['test'], sourceName)
										else
											sourceIcon = "Interface/ICONS/INV_Misc_QuestionMark"
											sourceTt = format(ttTemplate, L['unknown'], sourceName)
										end

								        frame:SetNormalTexture(sourceIcon)
										frame:SetScript("OnEnter", function() UIUtil.ShowTooltip(frame, {"ANCHOR_RIGHT", 0, 0}, sourceTt) end)
										frame:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
									else
										frame:SetNormalTexture(nil)
									end
							end)
						:build()

				})
			end
		end
	    self.frame.st:SetData(self.frame.rows)
	end
end

function LootSession:DeleteItem(session)
	Logging:Debug("DeleteItem(%s)", tostring(session))
	self.ml:RemoveLootTableEntry(session)
	self:Show(self.ml:GetLootTable())
end

--- @param items table<number, Models.Item.LootTableEntry>
--- @param disableAwardLater boolean should option for awarding later be disabled
function LootSession:Show(items, disableAwardLater)
	disableAwardLater = (disableAwardLater == true)

	if self.pendingEndSession then
		Logging:Trace("Show() : pending end of session, not showing")
		return
	end

	local frame = self:GetFrame()
	frame:Show()
	self.showPending = false

	if disableAwardLater then
		self.awardLater = false
		self.frame.toggle:Disable()
	else
		self.awardLater = self.ml.db.profile.awardLater
		self.frame.toggle:Enable()
	end

	if items then
		self.loadingItems = false
		self:AddItems(items)
		frame:Update()
	end
end

function LootSession:Hide()
	Logging:Debug("Hide()")
	if self.frame then
		self.frame:Hide()
		self.frame.rows = {}
	end
end
