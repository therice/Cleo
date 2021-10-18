--- @type AddOn
local _, AddOn = ...
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibSHA
local SHA = AddOn:GetLibrary("SHA")
--- @type LibMessagePack
local MessagePack = AddOn:GetLibrary("MessagePack")

--- @class Models.Hasher
local Hasher = AddOn.Class('Models.Hasher')
function Hasher:initialize(hashFn, packFn)
	self.hashFn = hashFn
	self.packFn = packFn
end

function Hasher:hash(data)
	return self.hashFn(self.packFn(data))
end

--- @class Models.Hashable
local Hashable = AddOn.Instance(
		'Models.Hashable',
		function() return { } end
)

function Hashable.IsHashable(obj)
	return Util.Objects.IsSet(obj) and Util.Objects.IsTable(obj) and Util.Objects.IsSet(obj.clazz) and obj.isHashable
end

function Hashable.Includable(algorithm)
	local hasher = Hasher(SHA[algorithm], MessagePack.pack)
	local Adapter = {
		static = {
			excludedHA = {},
			ExcludeAttrsInHash = function(self, ...)
				local excludedAttrs = self.excludedHA
				for _, attr in Util.Objects.Each(...) do
					if not Util.Tables.ContainsValue(excludedAttrs, attr) then
						Util.Tables.Push(excludedAttrs, attr)
					end
				end
			end
		},
		included = function(_, clazz)
			clazz.isHashable = true
		end,
		hash = function(self)
			local asTable = self:toTable()
			for _, attr in pairs(self.clazz.static.excludedHA) do
				Util.Tables.Remove(asTable, attr)
			end
			return hasher:hash(asTable)
		end,
		Verify = function(self, against)
			local ours = self:hash()

			if against and against.hash then
				local theirs = Util.Objects.IsFunction(against.hash) and against:hash() or against.hash
				return Util.Objects.Equals(ours, theirs), ours, theirs
			end

			return false, ours, nil
		end
	}
	return Adapter
end

function Hashable.Include(into, algorithm)
	return into:include(Hashable.Includable(algorithm))
end




