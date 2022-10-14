--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.CompressedDb
local CDB = AddOn.ImportPackage('Models').CompressedDb
--- @type Models.Audit.LootRecord
local LootRecord =  AddOn.ImportPackage('Models.Audit').LootRecord
--- @type Models.Audit.LootStatistics
local LootStatistics =  AddOn.ImportPackage('Models.Audit').LootStatistics
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')

--- @class LootAudit
local LootAudit = AddOn:NewModule("LootAudit")

LootAudit.defaults = {
	profile = {
		enabled = true,
	},
	factionrealm = {

	}
}
LootAudit.StatsIntervalInDays = 90

function LootAudit:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('LootAudit'), LootAudit.defaults)
	self.history = CDB(self.db.factionrealm)
	self.stats = {stale = true, value = nil}
	self.Send = Comm():GetSender(C.CommPrefixes.Audit)
	AddOn:SyncModule():AddHandler(
			self:GetName(),
			L['loot_audit'],
			function() return self:GetDataForSync() end,
			function(data) self:ImportDataFromSync(data) end
	)
end

function LootAudit:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToComms()
end

function LootAudit:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnsubscribeFromComms()
end

--- @return Models.CompressedDb
function LootAudit:GetHistory()
	return self.history
end

function LootAudit:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Audit, {
		[C.Commands.LootAuditAdd] = function(data, sender)
			Logging:Debug("LootAuditAdd from %s", tostring(sender))
			local record = LootRecord:reconstitute(unpack(data))
			self:OnRecordAdd(record)
		end
	})
end

function LootAudit:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

--- @param record Models.Audit.LootRecord
function LootAudit:OnRecordAdd(record)
	Logging:Trace("OnRecordAdd() : %s", Util.Objects.ToString(record and record:toTable() or {}))
	local winner, history = record.owner, self:GetHistory()
	local winnerHistory = history:get(winner)
	if winnerHistory then
		history:insert(record:toTable(), winner)
	else
		history:put(winner, {record:toTable()})
	end
	self.stats.stale = true
end

--- @param record Models.Audit.LootRecord
function LootAudit:Broadcast(record)
	-- if in test mode and not development mode, return
	if (AddOn:TestModeEnabled() and not AddOn:DevModeEnabled()) then return end
	local channel = (IsInRaid() or IsInGroup()) and C.group or (IsInGuild() and C.guild or C.player)
	self:Send(channel, C.Commands.LootAuditAdd, record)
end

local cpairs = CDB.static.pairs
--- @return Models.Audit.LootStatistics
function LootAudit:GetStatistics()
	Logging:Trace("GetStatistics()")

	local check, ret = pcall(
		function()
			if self.stats.stale or Util.Objects.IsNil(self.stats.value) then
				local cutoff = Date()
				cutoff:add{day = -LootAudit.StatsIntervalInDays}
				Logging:Debug("GetStatistics() : Processing History after %s", tostring(cutoff))

				local s = LootStatistics()
				for name, data in cpairs(self:GetHistory()) do
					for i = #data, 1, -1 do
						local entry = LootRecord:reconstitute(data[i])
						local ts = Date(entry.timestamp)
						if ts > cutoff then
							s:ProcessEntry(name, entry, i)
						end
					end
				end

				self.stats.stale = false
				self.stats.value = s
			end

			return self.stats.value
		end
	)

	if not check then
		Logging:Warn("Error processing Loot Audit : %s", tostring(ret))
		AddOn:Print("Error processing Loot Audit")
	else
		return ret
	end
end

function LootAudit:GetDataForSync()
	Logging:Debug("GetDataForSync()")
	if AddOn:DevModeEnabled() then
		Logging:Debug("GetDataForSync() : %d", Util.Tables.Count(self.db.factionrealm))

		local db = self.db.factionrealm
		local rkeys = {}

		while Util.Tables.Count(rkeys) < math.min(4, Util.Tables.Count(db)) do
			local rkey = Util.Tables.RandomKey(db)
			if not Util.Tables.ContainsKey(rkey) then
				rkeys[rkey] = true
			end
		end

		Logging:Debug("GetDataForSync() : randomly selected keys are %s", Util.Objects.ToString(Util.Tables.Keys(rkeys)))
		return Util.Tables.CopySelect(db, unpack(Util.Tables.Keys(rkeys)))
	else
		return self.db.factionrealm
	end
end

function LootAudit:ImportDataFromSync(data)
	Logging:Debug("ImportDataFromSync() : current history player count is %d, import history player count is %d",
	              Util.Tables.Count(self.db.factionrealm),
	              Util.Tables.Count(data)
	)

	local persist = (not AddOn:DevModeEnabled() and AddOn:PersistenceModeEnabled()) or AddOn._IsTestContext()
	if Util.Tables.Count(data) > 0 then
		local cdb = CDB(data)
		local imported, skipped = 0, 0
		for name, history in cpairs(cdb) do
			local charHistory = self.history:get(name)
			Logging:Debug("ImportDataFromSync(%s)", tostring(name))

			if not charHistory then
				Logging:Debug("ImportDataFromSync(%s) : no previous history, creating and populating", name)
				if persist then
					self.history:put(name, history)
				end
				imported = imported + #history
			else
				Logging:Debug("ImportDataFromSync(%s) : pre-existing history (count=%d), examining each entry", name, #charHistory)
				local function FindExistingEntry(importe)
					return Util.Tables.FindFn(
						charHistory,
						function(e)
							-- Logging:Debug("%d == %d, %s == %s", e.timestamp, importe.timestamp, tostring(e.item), tostring(importe.item))
							return e.timestamp == importe.timestamp and Util.Strings.Equal(e.item, importe.item)
						end
					)
				end

				for _, entryTable in pairs(history) do
					Logging:Debug("ImportDataFromSync(%s, %s) : examining import entry", name, entryTable.id)
					local _, existing = FindExistingEntry(entryTable)
					if existing then
						Logging:Debug("ImportDataFromSync(%s, %s) : found existing entry in history, skipping...", name, entryTable.id)
						skipped = skipped + 1
					else
						Logging:Debug("ImportDataFromSync(%s, %s) : entry does not exist in history, adding...", name, entryTable.id)
						if persist then
							self.history:insert(entryTable, name)
						end
						imported = imported + 1
					end
				end
			end
		end

		if imported > 0 then
			self.stats.stale = true
			self:RefreshData()
		end

		Logging:Debug("ImportDataFromSync(%s) : imported %s history entries, skipped %d import history entries, new history player entry count is %d",
		              tostring(persist),
		              imported,
		              skipped,
		              Util.Tables.Count(self.db.factionrealm)
		)
		AddOn:Print(format(L['import_successful_with_count'], AddOn.GetDateTime(), self:GetName(), imported))
	else
		AddOn:Print(format(L['import_successful_with_count'], AddOn.GetDateTime(), self:GetName(), 0))
	end
end

function LootAudit:Delete(ageInDays)
	if ageInDays then
		local cutoff = Date()
		cutoff:add{day = -ageInDays}
		Logging:Debug("Delete(%d) : Deleting history before %s", ageInDays, tostring(cutoff))
		local history = self:GetHistory()
		for name, data in cpairs(history) do
			local retain = {}

			for i = #data, 1, -1 do
				local entry = LootRecord:reconstitute(data[i])
				local ts = Date(entry.timestamp)
				if ts < cutoff then
					Logging:Debug("Delete() : deleting index %d/%d for %s (%s)", i, #data, name, tostring(ts))
				else
					Util.Tables.Push(retain, data[i])
				end
			end

			if #retain == 0 then
				history:del(name)
			else
				history:put(name, retain)
			end
		end
	end
end

function LootAudit:LaunchpadSupplement()
	return L["loot_audit"], function(container) self:LayoutInterface(container) end , true
end