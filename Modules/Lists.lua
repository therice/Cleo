--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.List.Service
local ListsService = AddOn.Package('Models.List').Service
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.List
local List = AddOn.Package('Models.List').List
--- @type Models.Player
local Player = AddOn.Package('Models').Player

--- @class Lists
local Lists = AddOn:NewModule('Lists', "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0", "AceHook-3.0")

Lists.defaults = {
	profile = {

	},
	factionrealm = {
		configurations = {

		},
		lists = {

		},
	}
}

function Lists:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('Lists'), self.defaults)
	self:InitializeService()
	self.Send = Comm():GetSender(C.CommPrefixes.Lists)
end

function Lists:InitializeService()
	--- @type Models.List.Service
	self.listsService = ListsService(
			{self, self.db.factionrealm.configurations},
			{self, self.db.factionrealm.lists}
	)
	--- @type Models.List.ActiveConfiguration
	self.activeConfig = nil
end

function Lists:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToComms()
end

function Lists:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnsubscribeFromComms()
end

function Lists:EnableOnStartup()
	return true
end

function Lists:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptionsMain = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.ActivateConfig] = function(data, sender)
			Logging:Debug("ActivateConfig from %s", tostring(sender))
			self:OnActivateConfigReceived(sender, unpack(data))
		end,
	})
	self.commSubscriptionsLists = Comm():BulkSubscribe(C.CommPrefixes.Lists, {
		[C.Commands.ActivateConfig] = function(data, sender)

		end,
	})
end

function Lists:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptionsLists)
	AddOn.Unsubscribe(self.commSubscriptionsMain)
	self.commSubscriptionsMain = nil
end

function Lists:GetService()
	return self.listsService
end

function Lists:HasActiveConfiguration()
	return not Util.Objects.IsNil(self.activeConfig)
end

function Lists:GetActiveConfiguration()
	return self.activeConfig
end


--- @param self Lists
local function GetListAndPriority(self, equipment, player, active, relative)
	player = player and Player.Resolve(player) or AddOn.player
	active = Util.Objects.Default(active, true)
	relative = Util.Objects.Default(relative, false)

	local list, prio = nil, nil
	if equipment and self:HasActiveConfiguration() then
		if active then
			_, list =
				self:GetActiveConfiguration():GetActiveListByEquipment(equipment)
		else
			_, list =
				self:GetActiveConfiguration():GetOverallListByEquipment(equipment)
		end

		if list then
			prio, _ = list:GetPlayerPriority(player, relative)
		end
	end

	return list, prio
end

-- for passed equipment location, this returns the active list for the item
-- along with the specified player's priority
function Lists:GetActiveListAndPriority(equipment, player)
	return GetListAndPriority(self, equipment, player, true, true)
end

-- for passed equipment location, this returns the overall list for the item
-- along with the specified player's priority
function Lists:GetOverallListAndPriority(equipment, player)
	return GetListAndPriority(self, equipment, player, false)
end

--- @param sender string
--- @param activation table
function Lists:OnActivateConfigReceived(sender, activation)
	Logging:Trace("OnActivateConfigReceived(%s)", tostring(sender))

	if not AddOn:IsMasterLooter(sender) then
		Logging:Warn("OnActivateConfigReceived() : Sender is not the master looter, ignoring")
		return
	end

	local function EnqueueRequest(to, id, type)
		Logging:Trace("EnqueueRequest(%s, %s)",tostring(id), tostring(type))
		Util.Tables.Push(to, {id = id, type = type})
	end

	-- see MasterLooter:ActivateConfiguration() for 'activation' message contents
	-- only load reference for configuration, as activation is going to load lists
	if activation and Util.Tables.Count(activation) >= 1 then
		-- a valid request to activate a new configuration means any current one must be discarded
		self.activeConfig = nil

		local configForActivation, toRequest = activation['config'], {}
		local resolved = self.listsService:LoadRefs({configForActivation})

		-- could not resolve the configuration for activation
		-- will need to request it
		--
		-- in practice, we should never be missing (or requesting) information
		-- if we're the master looter we the activation message originated from us
		-- if that were to occur, that's a regression
		if not resolved or #resolved ~= 1 then
			EnqueueRequest(toRequest, configForActivation.id, Configuration.name)
		else
			local activate = resolved[1]
			local result, activated = pcall(
					function()
						return self.listsService:Activate(activate)
					end
			)

			--Logging:Trace("OnActivateConfigReceived(%s) => %s/%s", tostring(activate.id), tostring(result), Util.Objects.ToString(activated))
			if not result then
				EnqueueRequest(toRequest, activate.id, Configuration.name)
				Logging:Warn("OnActivateConfigReceived() : Could not activate configuration '%s' => %s", activate.id, tostring(activated))
			else
				self.activeConfig = activated
				Logging:Debug("OnActivateConfigReceived() : Activated '%s'", activate.id)

				-- we aren't the ML, do some checks to see if we have the correct data
				-- this is entirely for requesting up to date data in case we are behind
				if not AddOn:IsMasterLooter() or AddOn:DevModeEnabled() then
					-- no need to check version and revision here
					-- just compare hashes of data
					local verification = self.activeConfig:Verify(activate, activation['lists'])
					-- index 1 is always the configuration verification
					local v = verification[1]
					if not v.verified then
						Logging:Warn(
								"OnActivateConfigReceived(%s)[Configuration] : Failed hash verification %s / %s",
								self.activeConfig.config.id,
								v.ah,
								v.ch
						)
						EnqueueRequest(toRequest, activate.id, Configuration.name)
					-- only handle potential list requests in face of a verified configuration
					-- otherwise, could result in ordering issues with responses
					-- this means it will take multiple passes to reconcile (send a request, receive a response)
					else
						-- index 1 is always the list verifications
						local listResults = verification[2]
						local verifications, missing, extra = listResults[1], listResults[2], listResults[3]

						for id, vfn in pairs(verifications) do
							if not vfn.verified then
								Logging:Warn(
										"OnActivateConfigReceived(%s)[List] : failed hash verification %s / %s",
										id,
										vfn.ah,
										vfn.ch
								)
								EnqueueRequest(toRequest, id, List.name)
							end
						end

						for _, id in pairs(missing) do
							Logging:Warn("OnActivateConfigReceived(%s)[List] : Missing", id)
							EnqueueRequest(toRequest, id, List.name)
						end

						for _, id in pairs(extra) do
							Logging:Warn("OnActivateConfigReceived(%s)[List] : Extra (this should not occur unless admin/owner which is not current master looter)", id)
							-- no request for an extra one, the sender won't have it
							-- signifies an issue with owners/admins not having synchronized config/list data
						end
					end
				end
			end

			-- todo : request configuration from sender
			-- self:Send(...)
		end
	end

	if self.activeConfig then
		Logging:Debug("OnActivateConfigReceived() : Activated configuration %s", tostring(self.activeConfig.config.name))
		AddOn:Print(format(L["activated_configuration"], tostring(self.activeConfig.config.name)))
	else
		Logging:Warn("OnActivateConfigReceived() : No active configuration")
		AddOn:Print(L["invalid_configuration"])
	end
end

function Lists:LaunchpadSupplement()
	return L["lists"], function(container) self:LayoutInterface(container) end , false
end
