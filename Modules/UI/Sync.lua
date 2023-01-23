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
--- @type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")

--- @type Sync
local Sync = AddOn:GetModule("Sync", true)

local function AddNameToList(l, name, class)
	l[name] = UIUtil.ClassColorDecorator(class):decorate(name)
end

function Sync:AvailableGuildTargets()
	local name, online, class, targets = nil, nil, nil, {}
	for i = 1, GetNumGuildMembers() do
		name, _, _, _, _, _, _, _, online,_,class = GetGuildRosterInfo(i)
		if online then
			AddNameToList(targets, AddOn:UnitName(name), class)
		end
	end

	return targets
end

function Sync:AvailableGroupTargets()
	local name, online, class, targets, groupCount = nil, nil, nil, {}, GetNumGroupMembers()
	for i = 1, groupCount do
		name, _, _, _, _, class, _, online = GetRaidRosterInfo(i)
		if Util.Objects.IsSet(name) and online then
			AddNameToList(targets, AddOn:UnitName(name), class)
		end
	end

	return targets
end

function Sync:AvailableSyncTargets()
	local targets = {}

	Util.Tables.CopyInto(targets, self:AvailableGuildTargets())
	Util.Tables.CopyInto(targets, self:AvailableGroupTargets())

	local playerName = AddOn:UnitName(AddOn.player.name)

	if not AddOn:DevModeEnabled() then
		targets[playerName] = nil
	else
		targets[playerName] = UIUtil.PlayerClassColorDecorator(playerName):decorate(playerName)
	end

	if Util.Tables.Count(targets) == 0 then
		targets[1] = format("-- %s --", L['no_recipients_avail'])
	else
		-- add guild and group targets, which will processed dynamically if selected
		targets[C.guild] = UIUtil.ColoredDecorator(C.Colors.ItemUncommon):decorate(_G.GUILD)
		targets[C.group] = UIUtil.ColoredDecorator(C.Colors.ItemLegendary):decorate(_G.GROUP)
	end

	-- table.sort(targets, function (a,b) return a > b end)
	Logging:Trace("%s", Util.Objects.ToString(targets))

	return targets
end

function Sync.ConfirmSyncShow(data)
	Dialog:Spawn(C.Popups.ConfirmSync, data)
end

function Sync.ConfirmSyncOnShow(frame, data)
	UIUtil.DecoratePopup(frame)
	local sender, _, text = unpack(data)
	Logging:Trace("ConfirmSyncOnShow() : %s, %s", tostring(sender), tostring(text))
	frame.text:SetText(format(L["incoming_sync_message"], text, sender:GetName()))
end


function Sync:UpdateStatus(value, text)
	if not self:IsEnabled() or not self.frame then
		return
	end

	self.frame.statusBar:Update(value, text)
end

function Sync:OnDataTransmit(num, total)
	if not self:IsEnabled() or not self.frame then
		return
	end

	Logging:Debug("OnDataTransmit(%d, %d)", num, total)
	local pct = (num/total) * 100
	self.frame.statusBar:Update(
		pct,
		Util.Numbers.Round2(pct) .. "% - " ..
		Util.Numbers.Round2(num/1000) .."KB / "..
		Util.Numbers.Round2(total/1000) .. "KB"
	)

	if num == total then
		AddOn:Print(format(L["sync_complete"], AddOn.GetDateTime()))
		Logging:Debug("OnDataTransmit() : Data transmission complete")
	end
end

function Sync:IsVisible()
	return self.frame and self.frame:IsVisible()
end

function Sync:GetFrame()
	if not self.frame then
		local f = UI:Popup(UIParent, 'SyncPopup', self:GetName(), L['frame_sync'], 400, 150)

		local help =
			UI:New('Button', f.content, L["sync_header"])
				:Size(15, 15):Point("TOPLEFT", f.banner, "TOPLEFT", 5, -2.5)
				:Tooltip(L["sync_detailed_description"])
		help:SetText("")
		help:SetNormalTexture("Interface/GossipFrame/ActiveQuestIcon")
		help.PushedTexture:SetTexture("Interface/GossipFrame/ActiveQuestIcon")
		help.HighlightTexture:Hide()
		f.help = help

		local type =
			UI:New('Dropdown', f.content)
				:SetWidth(f.content:GetWidth() * 0.4 - 20):Point("TOPLEFT", f.content, "TOPLEFT", 10, -50)
				:Tooltip(L["sync_type"], L["sync_type_desc"])
				:SetClickHandler(function(_, _, item)  self.type = item.key; return true; end)
		type.Update = function(self)
			local syncTypes, syncTypesSort = Sync:HandlersSelect(), {}
			for i, v in pairs(Util.Tables.ASort(syncTypes, function(a,b) return a[2] < b[2] end)) do
				syncTypesSort[i] = v[1]
			end
			self:SetList(syncTypes, syncTypesSort)
		end
		f.type = type

		local target =
			UI:New('Dropdown', f.content)
				:SetWidth(f.content:GetWidth() * 0.6 - 20):Point("LEFT", f.type, "RIGHT", 20, 0)
				:Tooltip(L['sync_target'], L['sync_target_desc'])
				:SetClickHandler(function(_, _, item)  self.target = item.key; return true; end)
		target.Update = function(self)
			local availTargets, availTargetsSort = Sync:AvailableSyncTargets(), {}
			for i, v in pairs(Util.Tables.Sort(Util.Tables.Keys(availTargets), function(a,b)  return string.lower(a) < string.lower(b) end)) do
				availTargetsSort[i] = v
			end
			self:SetList(availTargets, availTargetsSort)
		end
		f.target = target

		local sync =
			UI:New('Button', f.content, L['sync']):Size(150, 20)
				:Point("CENTER", f.content, "CENTER", 0, 0)
				:Point("BOTTOM", f.content, "BOTTOM", 0, 10)

		sync:SetScript(
			"OnClick",
			function()
				if not self.target then
					return AddOn:Print(L["sync_target_not_specified"])
				end
				if not self.type then
					return AddOn:Print(L["sync_type_not_specified"])
				end

				Logging:Debug("Sync() : %s, %s, %s", tostring(self.target), tostring(self.type), Util.Objects.ToString(self.handlers[self.type]))
				self:SendSyncSYN(self.target, self.type, self.handlers[self.type].send())
			end
		)
		f.sync = sync

		f.close:SetScript("OnClick", function() self:Disable() end)

		local statusBar = CreateFrame("StatusBar", nil, f.content, "TextStatusBar")
		statusBar:SetSize(f.content:GetWidth() - 20, 15)
		statusBar:SetPoint("TOPLEFT", f.type, "BOTTOMLEFT", 0, -10)
		statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		statusBar:SetStatusBarColor(0.1, 0, 0.6, 0.8)
		statusBar:SetMinMaxValues(0, 100)
		statusBar:Hide()

		statusBar.text = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		statusBar.text:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
		statusBar.text:SetTextColor(1,1,1)
		statusBar.text:SetText("")

		statusBar.Reset = function(self)
			self:Hide()
			self.text:Hide()
		end

		statusBar.Update = function(self, value, text)
			self:Show()
			if tonumber(value) then self:SetValue(value) end
			self.text:Show()
			self.text:SetText(text)
		end

		f.statusBar = statusBar

		f.Update = function(self)
			self.type:Update()
			self.target:Update()
			self.statusBar:Reset()
		end

		self.frame = f
	end

	return self.frame
end

function Sync:Show()
	if self.frame then
		self.frame:Update()
		self.frame:Show()
	end
end

function Sync:Hide()
	if self.frame then
		self.frame:Hide()
	end
end