--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Models.Referenceable
local Referenceable = AddOn.Require('Models.Referenceable')
--- @type Package
local AuditPkg = AddOn.ImportPackage('Models.Audit')
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.Permission
local Permission = AddOn.Package('Models.List').Permission
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")

--- @type Models.Audit.Audit
local Audit = AuditPkg.Audit

local ActionType = {
	Create  =   1,
	Modify  =   2,
	Delete  =   3,
}

local ResourceType = {
	Configuration = 1,
	List          = 2,
}

local DeltaParsers = {
	[ResourceType.Configuration] = {},
	[ResourceType.List]          = {},
}

--- @class Models.Audit.TrafficRecord
local TrafficRecord = AuditPkg:Class('TrafficRecord', Audit)

TrafficRecord.ActionType = ActionType
TrafficRecord.TypeIdToAction = tInvert(ActionType)

TrafficRecord.ResourceType = ResourceType
TrafficRecord.TypeIdToResource = tInvert(ResourceType)

function TrafficRecord:initialize(instant)
	Audit.initialize(self, instant)
	-- the guid of the player which performed the action
	self.actor = nil
	-- the configuration associated with the record
	self.config = nil
	-- the list associated with the record
	self.list = nil
	-- the type of action
	self.action = nil
	-- a reference to previous version of the entity
	-- can be used to say this record was applied on top of this reference
	-- and resulted in either associated configuration or list
	self.ref = nil
	-- if the action is a modify, the actual delta
	self.delta = nil
	-- an optional tuple (player, id) for the loot audit record associated with this traffic record
	-- this will only be set for traffic records generated as the result of loot being allocated
	self.lr = nil
end

function TrafficRecord:GetModifiedAttribute()
	if self.delta then
		return Util.Tables.Keys(self.delta)[1]
	end

	return nil
end

function TrafficRecord:GetModifiedAttributeValue()
	if self.delta then
		return self.delta[self:GetModifiedAttribute()]
	end

	return nil
end

function TrafficRecord:ParseableModification()
	return self:_GetModificationParser() ~= nil
end

function TrafficRecord:ParseModification(callback)
	if self.delta then
		local parser = self:_GetModificationParser()
		if parser then
			parser:Parse(self:GetModifiedAttributeValue(), callback)
		end
	end
end

function TrafficRecord:_GetModificationParser()
	if self.delta then
		local parsers = DeltaParsers[self:GetResourceType()]
		if parsers then
			local attr = self:GetModifiedAttribute()
			local _, parser =
				Util.Tables.FindFn(
					parsers,
					function(p) return Util.Strings.Equal(p.field, attr) end
				)
			return parser
		end
	end

	return nil
end

function TrafficRecord:GetResource()
	if self.list then
		return self.list
	elseif self.config then
		return self.config
	end

	return nil
end

function TrafficRecord:GetResourceType()
	return self.list and ResourceType.List or ResourceType.Configuration
end

function TrafficRecord:SetAction(type)
	if not Util.Tables.ContainsValue(ActionType, type) then
		error("Invalid action specified")
	end

	self.action = type
	if self.action ~= ActionType.Modify then
		self.delta = nil
	end
end

function TrafficRecord:SetModification(attr, diff)
	if self.action == ActionType.Modify then
		self.delta = {[attr] = diff}
	end
end

function TrafficRecord:SetReference(ref)
	if Util.Objects.IsNil(ref) then
		self.ref = nil
		return
	end

	if Referenceable.IsReferenceable(ref) then
		self.ref = ref:ToRef(false)
	elseif Util.Objects.IsTable(ref) then
		self.ref = ref
	end
end

--- @param lootRecord Models.Audit.LootRecord
function TrafficRecord:SetLootRecord(lootRecord)
	if lootRecord then
		local player = Player.Resolve(lootRecord.owner)
		self.lr = {player:ForTransmit(), lootRecord.id}
	end
end

--- @return string, number
function TrafficRecord:GetLootRecord()
	if self.lr then
		return unpack(self.lr)
	end

	return nil, nil
end

--- @param config Models.List.Configuration
--- @param list Models.List.List
function TrafficRecord.For(config, list)
	local record = TrafficRecord()
	record.actor = AddOn.player.guid

	if Referenceable.IsReferenceable(config) then
		record.config = config:ToRef(false)
	elseif Util.Objects.IsTable(config) then
		record.config = config
	end

	if list then
		if Referenceable.IsReferenceable(list) then
			record.list = list:ToRef(false)
		elseif Util.Objects.IsTable(list) then
			record.list = list
		end
	end
	return record
end

local DeltaParser = AddOn.Class('DeltaParser')
function DeltaParser:initialize(resourceType, field)
	self.resourceType = resourceType
	self.field = field
	Util.Tables.Push(DeltaParsers[self.resourceType], self)
end

function DeltaParser:Parse(delta, callback)
	-- delta parser is only applicable to tables
	if Util.Objects.IsTable(delta) then
		Logging:Trace("Parse(%s) : %s", self.field, Util.Objects.ToString(delta))
		for k, v in Util.Tables.Sparse.ipairs(delta) do
			-- an empty value means placeholder for the
			-- delta patch, it assists with re-applying
			-- if self:HandleEmpty() or (not Util.Objects.IsEmpty(v) and not Util.Tables.IsEmpty(v)) then
			if self:HandleEmpty() or not Util.Tables.IsEmpty(v) then
				callback(self:Resolve(k, v))
			end
		end
	end
end

function DeltaParser:HandleEmpty()
	return false
end

local V = 'v'

-- return the 'v' value of the 'from'
-- this is a special key used in generating delta patches
function DeltaParser:V(from)
	-- {v = {key = value}}
	-- {key = {v = value}}

	return Util.Tables.ContainsKey(from, V) and from[V] or Util.Tables.Pluck(Util.Tables.Copy(from), V)
end

function DeltaParser:Resolve(key, value)
	assert(false, 'resolve not implemented')
end

local PermissionsParser = DeltaParser(ResourceType.Configuration, 'permissions')
function PermissionsParser:Resolve(player, permissions)
	player = Player.Resolve(player)
	Logging:Trace("Resolve(FROM) : %s", Util.Objects.ToString(permissions))
	local v = self:V(permissions)
	Logging:Trace("Resolve(TO) : %s", Util.Objects.ToString(v))

	local perm = Permission:reconstitute(v)
	return player, tostring(perm)
end

local EquipmentParser = DeltaParser(ResourceType.List, 'equipment')
function EquipmentParser:Resolve(index, equipment)
	return index, Util.Objects.IsEmpty(equipment) and nil or C.EquipmentLocations[self:V(equipment)]
end
function EquipmentParser:HandleEmpty()
	return true
end

local PriorityParser = DeltaParser(ResourceType.List, 'players')
function PriorityParser:Resolve(priority, player)
	local v = self:V(player)
	return priority, Util.Objects.IsSet(v) and Player.Resolve(v) or nil
end