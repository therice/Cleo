local AddOnName, AddOn
--- @type Models.Hashable
local Hashable
--- @type Models.Hashers
local Hashers

describe("Hashable", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Hashable')
		Hashable = AddOn.Require('Models.Hashable')
		Hashers = AddOn.Require('Models.Hashers')
	end)

	teardown(function()
		After()
	end)

	describe("hashes", function()
		it("via SHA256", function ()
			local hasher = Hashers.SHA256()
			assert.equal(hasher:hash("1234"), hasher:hash("1234"))
			assert.equal(hasher:hash({1, "1234"}), hasher:hash({1, "1234"}))
			assert.Not.equal(hasher:hash({"1234", 1}), hasher:hash({1, "1234"}))
		end)

		it("via inclusion", function ()
			local HashableClass = AddOn.Class('Hashable.HashableClass'):include(Hashable.Includable('sha256'))
			function HashableClass:initialize(str, number, table)
				self.str = str
				self.number = number
				self.table = table
				self.a = {true, false, true, {99, 1}}
			end

			assert.equal(
				HashableClass("foo", 99, { a = 1, [100] = true, 99, b = 2, [2] = nil, v = { major = 2025, minor = 1, patch = 22 } }):hash(),
				HashableClass("foo", 99, { [100] = true, a = 1, 99, [2] = nil, b = 2, v = { minor = 1, major = 2025, patch = 22 } }):hash()
			)
		end)

	end)
end)