--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type LootSession
local LootSession = AddOn:GetModule('LootSession')

local ScrollColumns =
	ST.ColumnBuilder()
        :column(""):width(30)   -- remove item (1)
        :column(""):width(40)   -- item icon (2)
        :column(""):width(50)   -- item level (3)
        :column(""):width(160)  -- item link (4)
    :build()

function LootSession:GetFrame()
	if not self.frame then
		local f = UI:NewNamed('Frame', UIParent, 'LootSession', 'LootSession', L['frame_loot_session'], 275, 305)

		local st = ST.New(ScrollColumns, 5, 40, nil, f)
		-- disable sorting
		st:RegisterEvents({
			["OnClick"] = function(_, _, _, _, row, realrow)
			  if not (row or realrow) then
			      return true
			  end
			end,
		})
		st.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
		st.frame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 75)

		local start = UI:New('Button', f.content)
		start:SetText(_G.START)
		start:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 20)
		start:SetScript("OnClick", function() self:Start() end)
		f.start = start

		local cancel = UI:NewNamed('Button', f.content)
		cancel:SetText(_G.CANCEL)
		cancel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 20)
		cancel:SetScript("OnClick", function() self:Cancel() end)
		f.cancel = cancel

		-- replaced the close function
		f.close:SetScript("OnClick", function() self:Cancel() end)

		f.Update = function()
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
				-- but rather it will send a query meaning results should be available when needed
				if not item or not item:IsValid() then
					Logging:Warn("AddItems(%s) : referenced item not available, will re-try querying later", tostring(entry.item))
				end
				Util.Tables.Push(
						self.frame.rows,
						{
							session = session,
							item = item,
							cols =
								ST.CellBuilder()
									:deleteCell(function(_, data, row) self:DeleteItem(data[row].session) end)
							        :itemIconCell(item and item.link or nil, item and item.texture or nil)
							        :cell(" " .. (item and item.ilvl or ""))
							        :textCell(
										function(frame, data, row)
											if not data[row].item then
												frame.text:SetText("--".._G.RETRIEVING_ITEM_INFO.."--")
												self.loadingItems = true
												if not self.showPending then
													self.showPending = true
													self:ScheduleTimer("Show", 0, self.ml.lootTable)
												end
											else
												frame.text:SetText(data[row].item.link)
											end
										end
									)
								:build()

						}
				)
			end
		end
	    self.frame.st:SetData(self.frame.rows)
	end
end

function LootSession:DeleteItem(session)
	Logging:Debug("DeleteItem(%s)", tostring(session))
	self.ml:RemoveLootTableEntry(session)
	self:Show(self.ml.lootTable)
end

function LootSession:Show(items)
	local frame = self:GetFrame()
	frame:Show()
	self.showPending = false

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
