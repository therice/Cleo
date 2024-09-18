--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type Models.Versioned
local Versioned = AddOn.Package('Models').Versioned
--- @type Models.Referenceable
local Referenceable = AddOn.Require('Models.Referenceable')
--- @type Models.SemanticVersion
local SemanticVersion = AddOn.Package('Models').SemanticVersion
--- @type CallbackHandler
local Cbh = AddOn:GetLibrary("CallbackHandler")

local Events = {
	EntityCreated   =   "EntityCreated",
	EntityDeleted   =   "EntityDeleted",
	EntityUpdated   =   "EntityUpdated",
}


---@alias EventDetail table<string, any>
local function EventDetail(entity, attr, diff, ref, ...)
	return {
		entity = entity,
		attr   = attr,
		diff   = diff,
		ref    = ref,
		extra = {...},
	}
end

--- @class Models.Dao
local Dao = AddOn.Package('Models'):Class('Dao')
Dao.Events = Events

function Dao:initialize(module, db, entityClass)
	self.module = module
	self.db = db
	self.entityClass = entityClass
	self.callbacks = Cbh:New(self)
end

function Dao.Key(entity, attr)
	return entity.id .. '.' .. attr
end

function Dao:Create(...)
	if self.entityClass.CreateInstance then
		return self.entityClass.CreateInstance(...)
	end
	return self.entityClass(...)
end

function Dao:Reconstitute(id, attrs)
	attrs['id'] = id
	local entity = self.entityClass:reconstitute(attrs)
	--entity.id = id
	Logging:Trace("Dao.Reconstitute[%s](%s) : %s", tostring(self.entityClass), tostring(id), Util.Objects.ToString(entity:toTable()))
	return entity
end

function Dao.ShouldPersist()
	-- testing context OR (test mode is not enabled and persistence mode is enabled)
	return AddOn._IsTestContext() or (not AddOn:TestModeEnabled() and AddOn:PersistenceModeEnabled())
end

--- @param event string the event type
--- @param detail EventDetail the associated detail
function Dao:FireCallbacks(event, detail)
	if event and detail then
		self.callbacks:Fire(event, detail)
	end
end

--- @return table<any>
function Dao:Keys()
	return Util.Tables.Keys(self.db)
end

-- C(reate)
--- @param entity any the entity to add
--- @param fireCallbacks boolean should callbacks be fired
--- @param ... any additional callback arguments
function Dao:Add(entity, fireCallbacks, ...)
	fireCallbacks = Util.Objects.Default(fireCallbacks, true)
	local asTable = entity:toTable()
	asTable['id'] = nil
	Logging:Trace("Dao.Add[%s](%s) : %s", tostring(self.entityClass), tostring(entity.id), Util.Objects.ToString(asTable))
	if self.ShouldPersist() then
		if not entity.id then
			error(format("missing id for entity %s", tostring(self.entityClass)))
		end

		self.module:SetDbValue(self.db, entity.id, asTable)

		if fireCallbacks then
			self:FireCallbacks(Events.EntityCreated, EventDetail(entity, nil, nil, nil, ...))
		end
	end
end

-- R(ead)
function Dao:Get(id)
	Logging:Trace("Dao.Get[%s](%s)", tostring(self.entityClass), tostring(id))
	local attrs = self.db[id]
	if attrs then
		return self:Reconstitute(id, self.db[id])
	else
		Logging:Warn("Dao.Get[%s](%s) : No instance found", tostring(self.entityClass), id)
		return nil
	end
end

-- YES, you need to copy the backing db elements... otherwise, mutations occur without explicit persistence
function Dao:GetAll(filter, sort)
	Logging:Trace("Dao.GetAll[%s](%s, %s)", tostring(self.entityClass), Util.Objects.ToString(filter), Util.Objects.ToString(sort))

	filter = Util.Objects.IsFunction(filter) and filter or Util.Functions.True
	sort = Util.Objects.IsFunction(sort) and sort or function(a, b) return a.name < b.name end

	return Util(self.db)
			:Copy()
			:Filter(function(...) return filter(...) end)
			:Map(
				function(value, key)
					return self:Reconstitute(key, value)
				end,
				true
			)
			:Sort(function(a, b) return sort(a, b) end)()
end

function Dao:UpdateAll(entity, fireCallbacks, ...)
	fireCallbacks = Util.Objects.Default(fireCallbacks, true)
	Logging:Trace("Dao.UpdateAll[%s](%s)", tostring(self.entityClass), tostring(entity.id))

	if self.ShouldPersist() then
		if self.db[entity.id] then
			local asTable = entity:toTable()
			asTable['id'] = nil

			self.module:SetDbValue(self.db, entity.id, asTable)

			if fireCallbacks then
				self:FireCallbacks(Events.EntityUpdated, EventDetail(entity, nil, nil, nil, ...))
			end
		end
	end
end


-- U(pdate)
--- @param entity any the entity to add
--- @param attr string the entity attribute to update
--- @param fireCallbacks boolean should callbacks be fired
--- @param ... any additional callback arguments
function Dao:Update(entity, attr, fireCallbacks, ...)
	fireCallbacks = Util.Objects.Default(fireCallbacks, true)
	Logging:Trace("Dao.Update[%s](%s) : %s=%s", tostring(self.entityClass), tostring(entity.id), attr, Util.Objects.ToString(entity[attr]))

	-- if the entity to update doesn't exist, return
	if not self.db[entity.id] then
		Logging:Warn("Dao.Update[%s](%s) : entity does not exist", tostring(self.entityClass), tostring(entity.id))
		return
	end

	local key = self.Key(entity, attr)
	local asTable, ref = entity:toTable(), nil
	local curVal, diff = asTable[attr], nil
	local shouldPersist = self.ShouldPersist()

	if shouldPersist and fireCallbacks then
		-- if the entity is Referenceable, capture it for any registered callbacks.
		-- this is done based upon current persisted value in order to provide a reference point for update
		if Referenceable.IsReferenceable(entity) then
			local current = self:Get(entity.id)
			ref = current and current:ToRef(false)
			Logging:Trace(
				"Dao.Update(%s)[%s](CURRENT) : hash=%s, revision=%d",
				tostring(self.entityClass), entity.id,
				(ref and ref.hash or '?'), (ref and ref.revision or 0)
			)
		end

		-- generate the diff of the two values
		if Util.Objects.IsTable(curVal) then
			local prevVal = self.module:GetDbValue(self.db, key)
			prevVal = Util.Tables.IsEmpty(prevVal) and {} or prevVal
			diff = Util.Patch.diff(prevVal, curVal)
			Logging:Trace(
				"Dao.Update(%s)[%s] : %s / %s => %s [ %s ]",
				tostring(self.entityClass), entity.id,
				attr, Util.Objects.ToString(prevVal), Util.Objects.ToString(curVal),
				Util.Objects.ToString(diff)
			)
		else
			diff = curVal
		end
	end


	if shouldPersist then
		self.module:SetDbValue(self.db, key, curVal)
	end

	-- for versioned entities, trigger a new revision if attribute is marked as such
	if Util.Objects.IsInstanceOf(entity, Versioned) then
		if entity:TriggersNewRevision(attr) then
			Logging:Trace(
				"Dao.Update(%s)[%s] : '%s' triggering (%s) new revision, current = %d",
				tostring(self.entityClass), entity.id,
				tostring(attr), tostring(shouldPersist),
				entity.revision
			)
			entity:NewRevision()
			if shouldPersist then
				self.module:SetDbValue(
					self.db,
					self.Key(entity, 'revision'),
					entity.revision
				)
			end
		end

		if shouldPersist then
			-- check on stored version vs current version
			local version, storedVersion =
				entity.version, self.module:GetDbValue(self.db, self.Key(entity, 'version'))

			if not Util.Objects.IsNil(storedVersion) then
				_, storedVersion = SemanticVersion.Create(storedVersion)
			end

			-- if the version is not stored or it's less than current version, update it
			if Util.Objects.IsNil(storedVersion) or (storedVersion < version) then
				self.module:SetDbValue(
					self.db,
					self.Key(entity, 'version'),
					version:toTable()
				)
			end
		end
	end

	if shouldPersist and fireCallbacks then
		self:FireCallbacks(Events.EntityUpdated, EventDetail(entity, attr, diff, ref, ...))
	end
end

-- D(elete)
--- @param entity any the entity to delete
--- @param fireCallbacks boolean should callbacks be fired
--- @param ... any additional callback arguments
function Dao:Remove(entity, fireCallbacks, ...)
	fireCallbacks = Util.Objects.Default(fireCallbacks, true)
	Logging:Trace("Dao.Remove[%s](%s)", tostring(self.entityClass), tostring(entity.id))
	if self.ShouldPersist() then
		self.module:SetDbValue(self.db, entity.id, nil)

		if fireCallbacks then
			self:FireCallbacks(Events.EntityDeleted, EventDetail(entity, nil, nil, nil, ...))
		end
	end
end