--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibClass
local Class = LibStub("LibClass-1.0")
--- @type LibUtil.Lists.LinkedList
local LinkedList =  Util.Lists.LinkedList
--- @type Models.Player
local Player = AddOn.Package('Models').Player

-- dumb, doing this for a workaround to get native LibClass toTable() functionality
local B = Class("B")
--- @class Models.List.List
local List = AddOn.Package('Models.List'):Class('List', B)
function List:initialize(configId, id, name)
	B.initialize(self)
	self.configId = configId
	self.id = id
	self.name = name
	--- @type table<number, string> equipment types/locations to which list applies (e.g. INVTYPE_HEAD)
	self.equipment = {}
	--- @type LibUtil.Lists.LinkedList<Models.Player>
	self.players = LinkedList()
end

--- we only want to serialize the player's stripped guid which is enough
function List:toTable(playerFn)
	local t =  List.super.toTable(self)
	t['players'] = self.players:toTable(playerFn or function(p) return p:ForTransmit() end)
	return t
end

-- player's will be a table with stripped guids
function List:afterReconstitute(instance)
	instance.players = LinkedList.FromTable(
			Util(instance.players):Copy()(),
			function(p) return Player:Get(p) end
	)
	return instance
end

function List:AddEquipment(...)
	self.equipment = Util(self.equipment):Merge({...}, true)()
end

function List:RemoveEquipment(...)
	self.equipment = Util(self.equipment):CopyExceptWhere(false, ...)()
end

function List:GetEquipment(withNames)
	withNames = withNames or false
	if withNames then
		return Util.Tables.Flip(self.equipment, function(slot) return C.EquipmentLocations[slot] end)
	else
		return self.equipment
	end
end

function List:GetPlayers()
	return self.players
end

function List:SetPlayers(...)
	local count = select("#", ...)
	Logging:Trace("SetPlayers(%d)", count)

	if count > 0 then
		local first = select(1, ...)
		if count == 1 and (Util.Objects.IsTable(first) and first:isInstanceOf(LinkedList)) then
			self.players = first
		else
			self.players = LinkedList()
			for i=1, count do
				local player = select(i, ...)
				Logging:Debug("SetPlayers(%d) : %s", i, player:GetShortName())
				if (Util.Objects.IsTable(player) and player:isInstanceOf(Player)) then
					self.players:Add(player)
				else
					self.players:Add(Player:Get(player))
				end
			end
		end
	end
end