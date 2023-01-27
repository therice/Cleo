--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.SemanticVersion
local SemanticVersion = AddOn.ImportPackage('Models').SemanticVersion
--- @type Core.Mode
local Mode = Util.Memoize.Memoize(function() return AddOn.ImportPackage('Core').Mode end)
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
-- handles to globals
local SendChatMessage = _G.SendChatMessage

--- @class VersionCheck
local VersionCheck = AddOn:NewModule("VersionCheck", "AceTimer-3.0")
VersionCheck.VersionZero = SemanticVersion(0,0,0,0)

function VersionCheck:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.mostRecentVersion = VersionCheck.VersionZero
	self.versionCheckComplete = false
	self:SubscribeToComms()
	self.transientCommSubscriptions = {}
	self.Send = Comm():GetSender(C.CommPrefixes.Version)

	AddOn.Timer.Schedule(function() AddOn:ScheduleTimer(function() if IsInGuild() then self:SendGuildVersionPing() end end, 10) end)
end

function VersionCheck:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:GetFrame()
	self:Show()
	self:SubscribeToTransientComms()
end

function VersionCheck:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:Hide()
	AddOn.Unsubscribe(self.transientCommSubscriptions)
	self.transientCommSubscriptions = {}
end


function VersionCheck:EnableOnStartup()
	return false
end

function VersionCheck:Query(target)
	self:ClearEntries()

	if Util.Strings.Equal(C.guild, target) then
		GuildRoster()
		for i = 1, GetNumGuildMembers() do
			local name, _, _,_,_,_,_,_, online,_, class = GetGuildRosterInfo(i)
			if Util.Objects.IsSet(name) and online then
				self:AddEntry(name, class)
			end
		end
	elseif Util.Strings.Equal(C.group, target) then
		local groupCount =  GetNumGroupMembers()
		for i = 1, groupCount do
			local name, _, _, _, _, class, _, online = GetRaidRosterInfo(i)
			if Util.Objects.IsSet(name) and online then
				self:AddEntry(name, class)
			end
		end
	end

	self:Send(target, C.Commands.VersionCheck)

	self:AddEntry(
		AddOn.player:GetName(),
		AddOn.player.class,
		AddOn.version,
		AddOn.mode
	)

	self:ScheduleTimer("QueryTimer", 5)
end

-- cannot capture this in initializer as the modules are initialized prior to the core addon
-- dubious...
function VersionCheck.Versions()
	return AddOn.db.global.versions
end

local RETENTION_TIME = 604800 -- 1 week

function VersionCheck:ClearExpiredVersions()
	local versions = VersionCheck.Versions()
	if versions then
		for name, data in pairs(versions) do
			if data and data[2] and (GetServerTime() - data[2]) >= RETENTION_TIME then
				Util.Tables.Remove(versions, name)
			end
		end
	end
end

function VersionCheck:TrackVersion(sender, version)
	Logging:Trace("TrackVersion(%s, %s)", tostring(sender), tostring(version))
	if not Util.Strings.IsEmpty(sender) then
		VersionCheck.Versions()[sender] = {version:toTable(), GetServerTime()}
	end
end

function VersionCheck.Check(base, new)
	base = base or AddOn.version
	if base < new then
		return C.VersionStatus.OutOfDate
	else
		return C.VersionStatus.Current
	end
end

function VersionCheck.IsCurrent(version)
	return Util.Strings.Equal(
		VersionCheck.Check(AddOn.version, version),
		C.VersionStatus.Current
	)
end

function VersionCheck:CheckAndDisplay(version)
	if not self.versionCheckComplete then
		if not VersionCheck.IsCurrent(version) then
			AddOn:Print(format(L["version_out_of_date_msg"], tostring(AddOn.version), tostring(version)))
			self.versionCheckComplete = true
		end
	end
end

local function ResolveCommTarget(dist, player)
	local resolved
	if Util.Strings.Equal(Util.Strings.Upper(dist), C.Channels.Guild) then
		resolved = C.guild
	elseif Util.Objects.In(Util.Strings.Upper(dist), C.Channels.Raid, C.Channels.Party, C.Channels.Instance) then
		resolved = C.group
	else
		local p = Player.Resolve(player)
		if Util.Objects.IsSet(p) and (p:IsValid() and not p:IsUNK()) then
			resolved = p
		end
	end

	if Util.Objects.IsEmpty(resolved) then
		Logging:Warn("ResolveCommTarget(%s) : invalid target", tostring(dist))
	end

	return resolved
end

function VersionCheck:OnVersionPingReplyReceived(sender, version)
	Logging:Trace("OnVersionPingReplyReceived(%s, %s)", tostring(sender), tostring(version))
	if not AddOn.UnitIsUnit(sender, C.player) then
		self:TrackVersion(AddOn:UnitName(sender), version)
		self:CheckAndDisplay(version)
	end
end

--- @param sender string
--- @param dist string
--- @param version Models.SemanticVersion
function VersionCheck:OnVersionPingReceived(sender, dist, version)
	Logging:Trace("OnVersionPingReceived(%s, %s)", tostring(sender), tostring(version))
	if not AddOn.UnitIsUnit(sender, C.player) then
		self:TrackVersion(AddOn:UnitName(sender), version)
		-- previously, only sent a reply when version was not current. however, that falls apart when ping is targeted
		-- to a player who is not in guild (for keeping accurate records of versions)
		local target = ResolveCommTarget(dist, sender)
		if target then
			self:Send(target, C.Commands.VersionPingReply, AddOn.version)
		end
		self:CheckAndDisplay(version)
	end
end

function VersionCheck:OnVersionCheckReceived(sender, dist)
	Logging:Trace("OnVersionCheckReceived(%s, %s)", tostring(sender), tostring(dist))
	local target = ResolveCommTarget(dist, sender)

	if Util.Objects.IsSet(target) then
		self:Send(target, C.Commands.VersionCheckReply, AddOn.player.class, AddOn.version, AddOn.mode)
	else
		Logging:Warn("OnVersionCheckReceived(%s, %s) : invalid target", tostring(sender), tostring(dist))
	end
end

function VersionCheck:SendGuildVersionPing()
	self:SendVersionPing(C.guild)
end

function VersionCheck:SendVersionPing(target)
	target = ResolveCommTarget(target, target)

	if Util.Objects.IsSet(target) then
		self:Send(target, C.Commands.VersionPing, AddOn.version)
	else
		Logging:Warn("SendVersionPing(%s) : invalid target", tostring(target))
	end
end


function VersionCheck:DisplayOutOfDateClients()
	local versions, outOfDate, isGrouped, tt = VersionCheck.Versions(), {}, IsInGroup(), GetServerTime() - 86400 --[[ 1 day ]]--
	local sortedVersions = Util.Tables.Sort(
		Util(versions):Copy():Map(function(e) return SemanticVersion(e[1]) end):Values()(),
		function (a, b) return a > b end
	)

	local mostRecent = sortedVersions and sortedVersions[1] or VersionCheck.VersionZero
	Logging:Trace("DisplayOutOfDateClients() : most recent version is '%s', all versions '%s'", tostring(mostRecent), Util.Objects.ToString(versions))

	for name, data in pairs(versions) do
		if (isGrouped and AddOn.group[name]) or not isGrouped then
			Logging:Trace("DisplayOutOfDateClients(%s) : %d, %s", tostring(name), tt, Util.Objects.ToString(data))
			local version, ts = SemanticVersion(data[1]), data[2]
			if version < mostRecent and ts > tt then
				Util.Tables.Push(
					outOfDate,
					format(
						'%s [ %s ]',
						UIUtil.PlayerClassColorDecorator(name):decorate(AddOn.Ambiguate(name)),
						UIUtil.ColoredDecorator(C.Colors.ItemPoor):decorate(tostring(version))
					)
				)
			end
		end
	end

	if  Util.Tables.Count(outOfDate) > 0 then
		AddOn:Print(L["the_following_versions_are_out_of_date"])
		for _, v in pairs(outOfDate) do
			AddOn:Print(v)
		end
	else
		AddOn:Print(L["everyone_up_to_date"])
	end

	local notInstalled = {}
	-- show who doesn't have the add-on installed, either in group or guild
	if isGrouped then
		local groupCount =  GetNumGroupMembers()
		for i = 1, groupCount do
			local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
			if Util.Objects.IsSet(name) and online and not AddOn.UnitIsUnit(name, C.player) and not versions[name] then
				Util.Tables.Push(notInstalled, UIUtil.PlayerClassColorDecorator(name):decorate(AddOn.Ambiguate(name)))
			end
		end
	elseif IsInGuild() then
		GuildRoster()
		for i = 1, GetNumGuildMembers() do
			local name, _, _,_,_,_,_,_, online = GetGuildRosterInfo(i)
			if Util.Objects.IsSet(name) and online and not AddOn.UnitIsUnit(name, C.player) and not versions[name] then
				Util.Tables.Push(notInstalled, UIUtil.PlayerClassColorDecorator(name):decorate(AddOn.Ambiguate(name)))
			end
		end
	end

	if Util.Tables.Count(notInstalled) > 0 then
		AddOn:Print(L["the_following_are_not_installed"])
		for _, v in pairs(notInstalled) do
			AddOn:Print(v)
		end
	end
end

function VersionCheck:NotifyIfNotInstalled(player)
	Logging:Trace("NotifyIfNotInstalled(%s)", tostring(player))
	if Util.Strings.IsSet(player) and not AddOn.UnitIsUnit(player, C.player) then
		player = AddOn:UnitName(player)
		local versions = VersionCheck.Versions()
		if Util.Objects.IsSet(versions) and not versions[player] then
			SendChatMessage(L["whisper_not_installed"], C.Channels.Whisper, nil, player)
		end
	end
end


function VersionCheck:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	Comm():BulkSubscribe(C.CommPrefixes.Version, {
		[C.Commands.VersionPing] = function(data, sender, _, dist)
			Logging:Debug("VersionPing from %s to %s (%s)", tostring(sender), tostring(dist), Util.Objects.ToString(unpack(data)))
			self:OnVersionPingReceived(sender, dist, SemanticVersion(unpack(data)))
		end,
		[C.Commands.VersionPingReply] = function(data, sender)
			Logging:Debug("VersionPingReply from %s ", tostring(sender))
			self:OnVersionPingReplyReceived(sender, SemanticVersion(unpack(data)))
		end,
		[C.Commands.VersionCheck] = function(_, sender, _, dist)
			Logging:Debug("VersionCheck from %s to %s ", tostring(sender), tostring(dist))
			self:OnVersionCheckReceived(sender, dist)
		end
	})
end

function VersionCheck:SubscribeToTransientComms()
	Util.Tables.Push(self.transientCommSubscriptions,
	     Comm():Subscribe(C.CommPrefixes.Version,
			C.Commands.VersionCheckReply,
			function(data, sender)
				local class, v, m = unpack(data)
				local version, mode = SemanticVersion(v), Mode():reconstitute(m)
				self:AddEntry(sender, class, version, mode)
			end
		)
	)
end