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
--- @type Loot
local Loot = AddOn:GetModule('Loot')

local ENTRY_HEIGHT, MAX_ENTRIES, MIN_BUTTON_WIDTH = 90, 6, 40
local GameTooltip = GameTooltip

---@class Loot.Entry
local Entry = AddOn.Class('Loot.Entry')
function Entry:initialize(type)
	self.type = Util.Objects.Default(type, 'default')
end

function Entry:Create(id, parent)
	self.width = parent:GetWidth()
	self.frame = CreateFrame("Frame", AddOn:Qualify('LootEntryFrame', tostring(id)), parent)
	self.frame:SetWidth(self.width)
	self.frame:SetHeight(ENTRY_HEIGHT)
	self.frame:SetPoint("TOPLEFT", parent, "TOPLEFT")

	-- icon for the item
	self.icon = UI:New('IconBordered', self.frame)
	self.icon:SetBorderColor()
	self.icon:SetSize(ENTRY_HEIGHT * 0.78, ENTRY_HEIGHT * 0.78)
	self.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 9, -5)
	self.icon:SetMultipleScripts({
         OnEnter = function()
             if not self.item.link then return end
             UIUtil:CreateHypertip(self.item.link)
             GameTooltip:AddLine("")
             GameTooltip:AddLine(L["always_show_tooltip_howto"], nil, nil, nil, true)
             GameTooltip:Show()
         end,
         OnClick = function()
             if not self.item.link then return end
             if IsModifiedClick() then
                 HandleModifiedItemClick(self.item.link)
             end
             if self.icon.lastClick and GetTime() - self.icon.lastClick <= 0.5 then
	             local moduleSettings = AddOn:ModuleSettings(Loot:GetName())
	             moduleSettings.alwaysShowTooltip = not moduleSettings.alwaysShowTooltip
                 Loot:Update()
             else
                 self.icon.lastClick = GetTime()
             end
         end,
     })

	-- for overlay when there are multiple of same item
	self.itemCount = self.icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
	local fileName, _, flags = self.itemCount:GetFont()
	self.itemCount:SetFont(fileName, 20, flags)
	self.itemCount:SetJustifyH("RIGHT")
	self.itemCount:SetPoint("BOTTOMRIGHT", self.icon, "BOTTOMRIGHT", -2, 2)
	self.itemCount:SetText("error")

	-- buttons
	self.buttons = {}

	-- item text
	self.itemText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	self.itemText:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 6, -1)
	self.itemText:SetText("")

	-- the associated list for equipment and player's priority
	self.listWithPrio = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.listWithPrio:SetPoint("TOPLEFT", self.itemText, "BOTTOMLEFT", 1, -4)
	self.listWithPrio:SetTextColor(1, 1, 1)
	self.listWithPrio:SetText("")

	-- item level
	self.itemLvl = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.itemLvl:SetPoint("TOPLEFT", self.listWithPrio, "BOTTOMLEFT", 1, -2)
	self.itemLvl:SetTextColor(1, 1, 1)
	self.itemLvl:SetText("")

	-- timeoutBar
	self.timeoutBar = CreateFrame("StatusBar", nil, self.frame, "TextStatusBar")
	self.timeoutBar:SetSize(self.frame:GetWidth(), 6)
	self.timeoutBar:SetPoint("BOTTOMLEFT", 9,3)
	self.timeoutBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	self.timeoutBar:SetStatusBarColor(0.00, 1.00, 0.59, 1)
	self.timeoutBar:SetMinMaxValues(0, 60)
	self.timeoutBar:SetScript(
		"OnUpdate",
		function(this, elapsed)
			--Timeout!
			if self.item.timeLeft <= 0 then
				this.text:SetText(L["timeout"])
				this:SetValue(0)
				return Loot:OnRoll(self, C.Responses.Timeout)
			end
			self.item.timeLeft = self.item.timeLeft - elapsed
			this.text:SetText(_G.CLOSES_IN .. ": " .. ceil(self.item.timeLeft))
			this:SetValue(self.item.timeLeft)
		end
	)

	self.timeoutBar.text = self.timeoutBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	self.timeoutBar.text:SetPoint("CENTER", self.timeoutBar)
	self.timeoutBar.text:SetTextColor(1,1,1)
	self.timeoutBar.text:SetText("")
end

function Entry:SetWidth(width)
	local delegate = self.frame.SetWidth
	self.timeoutBar:SetWidth(width - 18)
	delegate(self.frame, width)
	self.width = width
end

function Entry:Show()
	self.frame:Show()
end

function Entry:Hide()
	self.frame:Hide()
end

function Entry:Update(item)
	if not item then
		Logging:Warn("Update() : no item provided")
		return
	end

	self.item = item
	self.itemText:SetText(
		item.isRoll and (_G.ROLL .. ": ") or "" ..
		AddOn.GetItemTextWithCount(self.item.link or "error", #self.item.sessions)
	)
	self.icon:SetNormalTexture(self.item.texture or "Interface\\InventoryItems\\WoWUnknownItem01")
	self.itemCount:SetText(#self.item.sessions > 1 and tostring(#self.item.sessions) or "")
	Loot.UpdateItemText(self)
	Loot.UpdateListAndPriority(self)

	if AddOn:MasterLooterDbValue('timeout.enabled') then
		self.timeoutBar:SetMinMaxValues(
			0,
			AddOn:MasterLooterDbValue('timeout.duration') or AddOn:MasterLooterModule():GetDbValue('timeout.duration')
		)
		self.timeoutBar:Show()
	else
		self.timeoutBar:Hide()
	end

	self:UpdateButtons()
	self:Show()
end

function Entry:UpdateButtons()
	local b = self.buttons
	local numButtons = AddOn:GetButtonCount()
	local buttons = AddOn:GetButtons()
	-- (IconWidth (63) + indent(9)) + pass button (5) +  + numButton * space(5)
	local width = 95 + numButtons * 5
	-- +1 is for the numButtons entry, which we map to the pass button
	for i = 1, numButtons + 1 do
		-- todo : color them buttons
		if i > numButtons then
			b[i] = b[i] or UI:New('Button', self.frame)
			-- b[i]:SetText(_G.PASS)
			b[i]:SetText(UIUtil.ColoredDecorator(C.Colors.Salmon):decorate(_G.PASS))
			b[i]:SetMultipleScripts({
                OnEnter = function() Loot.UpdateItemResponders(self, C.Responses.Pass) end,
                OnLeave = function() UIUtil:HideTooltip() end,
                OnClick = function() Loot:OnRoll(self, C.Responses.Pass) end,
            })
		else
			b[i] = b[i] or UI:New('Button', self.frame)
			-- b[i]:SetText(buttons[i].text)
			-- this is kind of ugly, but ...
			b[i]:SetText(UIUtil.ColoredDecorator(buttons[i].color):decorate(buttons[i].text))
			b[i]:SetMultipleScripts({
                OnEnter = function()
                    Loot.UpdateItemResponders(self, i)
                    Loot.UpdateItemText(self)
                end,
                OnLeave = function()
                    UIUtil:HideTooltip()
                    Loot.UpdateItemText(self)
                end,
                OnClick = function() Loot:OnRoll(self, i) end,
            })
		end
		b[i]:SetWidth(b[i]:GetTextWidth() + 10)
		if b[i]:GetWidth() < MIN_BUTTON_WIDTH then b[i]:SetWidth(MIN_BUTTON_WIDTH) end
		width = width + b[i]:GetWidth()
		if i == 1 then
			b[i]:SetPoint("BOTTOMLEFT", self.icon, "BOTTOMRIGHT", 5, 0)
		else
			b[i]:SetPoint("LEFT", b[i-1], "RIGHT", 5, 0)
		end
		b[i]:Show()
	end
	-- Check if we've more buttons than we should
	if #b > numButtons + 1 then
		for i = numButtons + 2, #b do b[i]:Hide() end
	end
	self.width = width
	self.width = math.max(self.width, 90 + self.itemText:GetStringWidth())
	self.width = math.max(self.width, 89 + self.itemLvl:GetStringWidth())
end

---@class Loot.EntryManager
local EntryManager = AddOn.Class('Loot.EntryManger')
function EntryManager:initialize()
	self.numEntries = 0
	self.entries    = {}
	self.pool       = {}
end

local function GetFromPool(self, type)
	if not self.pool[type] then return nil end
	local t = next(self.pool[type])
	if t then
		Util.Tables.Set(self.pool, type, t, nil)
		return t
	end
	return nil
end

function EntryManager:GetEntry(item)
	if not item then
		Logging:Warn("GetEntry(%s) : No such item", Util.Objects.ToString(item))
		return
	end
	if self.entries[item] then return self.entries[item] end

	--- @type Loot.Entry
	local entry
	if item.isRoll then
		entry = GetFromPool(self, 'roll')
	else
		entry = GetFromPool(self, 'default')
	end

	if entry then
		entry:Update(item)
	else
		if item.isRoll then
			entry = self:CreateRollEntry(item)
		else
			entry = self:CreateEntry(item)
		end
	end

	entry:SetWidth(entry.width)
	entry:Show()
	self.numEntries = self.numEntries + 1
	entry.position = self.numEntries
	self.entries[self.numEntries] = entry
	self.entries[item] = entry
	return entry
end

function EntryManager:CreateEntry(item)
	local entry = Entry()
	entry:Create(self.numEntries + 1, Loot.frame.content)
	entry:Update(item)
	return entry
end

function EntryManager:CreateRollEntry(item)
	local entry = Entry('roll')
	entry:Create(self.numEntries + 1, Loot.frame.content)
	entry.UpdateButtons = function(entry)
		local b = entry.buttons
		-- intentionally don't use the Native widgets
		b[1] = b[1] or CreateFrame("Button", nil, entry.frame)
		b[2] = b[2] or CreateFrame("Button", nil, entry.frame)
		local roll, pass = b[1], b[2]

		roll:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
		roll:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Highlight")
		roll:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Down")
		roll:SetScript("OnClick", function() Loot:OnRoll(entry, C.Responses.Roll) end)
		roll:SetSize(32, 32)
		roll:SetPoint("BOTTOMLEFT", entry.icon, "BOTTOMRIGHT", 5, -7)
		roll:Enable()
		roll:Show()

		pass:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		pass:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
		pass:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
		pass:SetScript("OnClick", function() Loot:OnRoll(entry, C.Responses.Pass) end)
		pass:SetSize(32, 32)
		pass:SetPoint("LEFT", roll, "RIGHT", 5, 3)
		pass:Show()

		entry.rollResult = entry.rollResult or entry.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		entry.rollResult:SetPoint("LEFT", roll, "RIGHT", 5, 3)
		entry.rollResult:SetText("")
		entry.rollResult:Hide()

		entry.width = 250 -- 182
		entry.width = math.max(entry.width, 90 + entry.itemText:GetStringWidth())
		entry.width = math.max(entry.width, 89 + entry.itemLvl:GetStringWidth())
	end
	entry.DisableButtons = function(entry)
		-- disable roll button
		entry.buttons[1]:Disable()
		-- disable pass button
		entry.buttons[2]:Hide()
	end
	entry.SetResult = function(entry, roll)
		entry.rollResult:SetText(roll)
		entry.rollResult:Show()
	end
	entry:Update(item)
	return entry
end

function EntryManager:Update()
	local max = 0
	for i, entry in ipairs(self.entries) do
		if entry.width > max then max = entry.width end
		if i == 1 then
			entry.frame:SetPoint("TOPLEFT", Loot.frame.content, "TOPLEFT",0,-5)
		else
			entry.frame:SetPoint("TOPLEFT", self.entries[i-1].frame, "BOTTOMLEFT")
		end
		entry.position = i
	end
	Loot.frame:SetWidth(max)
	Loot.frame.title:SetWidth(max * 0.90)
	for _, entry in ipairs(self.entries) do
		entry:SetWidth(max)
	end
end

function EntryManager:Recycle(entry)
	Logging:Trace("Recycle() : recycling %s", tostring(entry.type))
	if entry then
		entry:Hide()
	end

	if not Util.Tables.ContainsKey(self.pool, entry.type) then
		Util.Tables.Set(self.pool, entry.type, {})
	end
	Util.Tables.Set(self.pool, entry.type, entry, true)
	tDeleteItem(self.entries, entry)
	Util.Tables.Remove(self.entries, entry.item)
	self.numEntries = self.numEntries - 1
end

function EntryManager:RecycleAll()
	Logging:Trace("RecycleAll(BEGIN) : %d", Util.Tables.Count(self.entries))

	-- make a copy so we're not dealing with a mutating entry list
	-- as a result of removals
	--
	-- we add two entries to table on creation, one for index and one for the item
	-- they both point to same entry, so only go after the numeric index
	local copy = Util.Tables.CopyFilter(
		self.entries,
		function(_, k)
			return Util.Objects.IsNumber(k)
		end,
		true
	)

	for _, entry in pairs(copy) do
		self:Recycle(entry)
	end

	Logging:Trace("RecycleAll(COMPLETE) : %d", Util.Tables.Count(self.entries))
end

-- singleton, capture it now
Loot.EntryManager = EntryManager()

function Loot:GetFrame()
	if not self.frame then
		Logging:Trace("GetFrame() : building loot frame")
		local f = UI:NewNamed('Frame', UIParent, 'Loot', self:GetName(),  L["frame_loot"], 550, 400)
		-- override default behavior for ESC to not close the loot window
		-- too easy to make mistakes and not get an opportunity to specify a response
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
		f.itemTooltip = UIUtil.CreateGameTooltip(self:GetName(), f.content)
		f.close:Hide()
		f.scale:Hide()

		self.frame = f
	end
	return self.frame
end

function Loot:Show()
	if self.frame then
		self.frame:Show()
		self:Update()
	end
end

function Loot:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

function Loot:Update()
	Logging:Trace("Update()")

	local numEntries = 0
	for _, item in pairs(self.items) do
		if numEntries >= MAX_ENTRIES then break end
		if not item.rolled then
			numEntries = numEntries + 1
			self.EntryManager:GetEntry(item)
		end
	end

	if numEntries == 0 then return self:Disable() end

	self.EntryManager:Update()
	self.frame:SetHeight(numEntries * ENTRY_HEIGHT + 7)

	-- this pins an item tooltip to the left of the 1st item with a link to the 1st item
	local first, alwaysShowTooltip = self.EntryManager.entries[1], AddOn:ModuleSettings(self:GetName()).alwaysShowTooltip
	if first and alwaysShowTooltip then
		self.frame.itemTooltip:SetOwner(self.frame.content, "ANCHOR_NONE")
		self.frame.itemTooltip:SetHyperlink(first.item.link)
		self.frame.itemTooltip:Show()
		self.frame.itemTooltip:SetPoint("TOPRIGHT", first.frame, "TOPLEFT", 0, 0)
	else
		self.frame.itemTooltip:Hide()
	end
end

---@param entry Loot.Entry
function Loot.UpdateItemText(entry)
	local item = entry.item
	entry.itemLvl:SetText(
		"Level " .. item:GetLevelText() .." |cff7fffff".. item:GetTypeText() .. "|r"
	)
end

function Loot.UpdateListAndPriority(entry)
	local list, prio =
		AddOn:ListsModule():GetActiveListAndPriority(
			entry.item:GetEquipmentLocation()
		)

	entry.listWithPrio:SetText(
		format("|cFFE6CC80%s|r (|cFFE6CC80%s|r)", (list and list.name or L['unknown']), prio and tostring(prio) or "?")
	)
end

function Loot.UpdateItemResponders(entry, response)
	if entry and entry.item and response then
		local responders = entry.item.responders and entry.item.responders[response] or nil
		if responders and Util.Tables.Count(responders) > 0 then
			local text = {}
			for _, responder in pairs(Util.Tables.Sort(Util.Tables.Copy(responders), function (a, b) return a < b end ))
			do
				Util.Tables.Push(
					text,
					UIUtil.PlayerClassColorDecorator(responder):decorate(AddOn.Ambiguate(responder))
				)
			end

			if #text > 0 then
				UIUtil.ShowTooltipLines(unpack(text))
			end
		end
	end
end