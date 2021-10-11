local AddOnName, AddOn
--- @type LibUtil
local Util
--- @type Models.List.Configuration
local Configuration
--- @type Models.Player
local Player

describe("Configuration Model", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_List_Configuration')
		Util, Configuration, Player =
			AddOn:GetLibrary('Util'), AddOn.Package('Models.List').Configuration, AddOn.Package('Models').Player

	end)

	teardown(function()
		After()
	end)

	describe("Configuration", function()
		it("creates instance", function()
			assert(Configuration.CreateInstance())
		end)
		it("adds owner to new instance", function()
			local c = Configuration.CreateInstance()
			assert.equal(Player:Get("Player-1-00000001"), c:GetOwner())
		end)
		it("grants permission", function()
			local c = Configuration.CreateInstance()
			c:GrantPermissions("Player-1-00000002", Configuration.Permissions.Admin)
			local admins = c:GetAdministrators()
			assert.equal(1, #admins)
			assert.equal(Player:Get("Player-1-00000002"), admins[1])
		end)
		it("handles reconstituation", function()
			local c = Configuration.CreateInstance()
			c:GrantPermissions("Player-1-00000004", Configuration.Permissions.Admin)
			c:GrantPermissions("Player-1-00000005", Configuration.Permissions.Admin)
			local t = c:toTable()
			local c2 = Configuration:reconstitute(t)
			assert.equal(c.id, c2.id)
			assert.equal(c.name, c2.name)
			assert.equal(c:GetOwner(), c2:GetOwner())
			assert.same(c:GetAdministrators(), c2:GetAdministrators())
			assert.same(c2:toTable(), t)
		end)
	end)
end)