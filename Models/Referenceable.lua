--- @type AddOn
local _, AddOn = ...
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")


--- @class Models.Referenceable
local Referenceable = AddOn.Instance(
		'Models.Referenceable',
		function() return { } end
)

function Referenceable.Includable()
	local Adapter = {
		static = {
			attrs = {
				pkg = function(self) return self.clazz.package end,
				clz = function(self) return self.clazz.name end
			},
			-- supports both strings and functions
			-- if string, then will be attribute name on the instance
			-- if function, should take one argument (self) and return the value
			IncludeAttrsInRef = function(self, ...)
				local attrs = self.attrs
				for _, attr in Util.Objects.Each(...) do
					if Util.Objects.IsTable(attr) then
						for k, v in pairs(attr) do
							attrs[k] = v
						end
					else
						if not Util.Tables.ContainsValue(attrs, attr) then
							Util.Tables.Push(attrs, attr)
						end
					end
				end
			end,
		},
		included = function(_, clazz)
			clazz.isReferenceable = true
		end,
		ToRef = function(self)
			local ref, asTable = {}, self:toTable()
			for attrn, attr in pairs(self.clazz.static.attrs) do
				if Util.Objects.IsFunction(attr) then
					local value = attr(self)
					Util.Tables.Insert(ref, attrn, value)
				else
					Util.Tables.Insert(ref, attr, asTable[attr])
				end
			end
			return ref
		end,
		-- this will not return a fully populated instance from passed ref
		-- only sufficient attributes to load it (as necessary)
		FromRef = function(self, ref)
			local r = self:reconstitute(ref)
			-- assume that any function generated attribute is not part of
			-- the original instance from which ref was generated
			for attrn, attr in pairs(self.static.attrs) do
				if Util.Objects.IsFunction(attr) then
					r[attrn] = nil
				end
			end

			return r
		end
	}

	return Adapter
end

function Referenceable.FromRef(ref)
	if ref then
		local pkg, clz = ref.pkg, ref.clz
		if pkg and clz then
			local clazz = AddOn.ImportPackage(pkg)[clz]
			return clazz:FromRef(ref)
		end
	end
	return nil
end