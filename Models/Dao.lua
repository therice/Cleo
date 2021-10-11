--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")

--- @class Models.Dao
local Dao = AddOn.Package('Models'):Class('Dao')
function Dao:initialize(module, db, entityClass)
	self.module = module
	self.db = db
	self.entityClass = entityClass
end

function Dao.Create(...)
	if self.entityClass.CreateInstance then
		return self.entityClass.CreateInstance(...)
	end

	return self.entityClass(...)
end

function Dao.Key(entity, attr)
	return entity.id .. '.' .. attr
end

function Dao:Reconstitute(id, attrs)
	local entity = self.entityClass:reconstitute(attrs)
	entity.id = id
	Logging:Trace("Dao.Reconstitute[%s](%s) : %s", tostring(self.entityClass), tostring(id), Util.Objects.ToString(entity:toTable()))
	return entity
end

-- C(reate)
function Dao:Add(entity)
	local asTable = entity:toTable()
	asTable['id'] = nil
	Logging:Trace("Dao.Add[%s](%s) : %s", tostring(self.entityClass), entity.id, Util.Objects.ToString(asTable))
	self.module:SetDbValue(self.db, entity.id, asTable)
end

-- R(ead)
function Dao:Get(id)
	return self:Reconstitute(id, self.db[id])
end

-- YES, you need to copy the backing db elements... otherwise, mutations occur without explicit persistence
function Dao:GetAll(filter, sort)
	Logging:Debug("Dao.GetAll[%s](%s, %s)", tostring(self.entityClass), Util.Objects.ToString(filter), Util.Objects.ToString(sort))

	filter = Util.Objects.IsFunction(filter) and filter or Util.Functions.True
	sort = Util.Objects.IsFunction(sort) and sort or function(a, b) return a.name < b.name end

	return Util(self.db)
			:Copy()
			:Filter(
				function(...) return filter(...) end
			)
			:Map(
				function(value, key)
					return self:Reconstitute(key, value)
				end,
				true
			)
			:Sort(function(a, b) return sort(a, b) end)()
end

-- U(pdate)
function Dao:Update(entity, attr)
	local key = self.Key(entity, attr)
	self.module:SetDbValue(
			self.db,
			key,
			entity:toTable()[attr]
	)
end

-- D(elete)
function Dao:Remove(entity)
	Logging:Trace("Dao.Remove[%s](%s)", tostring(self.entityClass), entity.id)
	self.module:SetDbValue(self.db, entity.id, nil)
end

