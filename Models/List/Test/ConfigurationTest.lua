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
		it("handles reconstitution", function()
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
		it("handles alt(s)", function()
			local c1 = Configuration.CreateInstance()
			c1:SetAlternates("Player-1-00000004", "Player-1-00000022", "Player-1-00000033")
			c1:SetAlternates("Player-1-00000001", "Player-1-00000002")
			c1:SetAlternates("Player-1-00000001", "Player-1-00000003", "Player-1-00000002")

			local t1 = c1:toTable()
			local c2 = Configuration:reconstitute(t1)
			local t2 = c2:toTable()

			assert.same(Util.Tables.Keys(c1.alts), Util.Tables.Keys(c2.alts))
			for k, _ in pairs(c1.alts) do
				assert.same(c1.alts[k], c2.alts[k])
			end

			assert.same(t1, t2)
			assert.same(t1, c2:toTable())
		end)
		--it("is hashable", function()
		--	local c = Configuration.CreateInstance()
		--	c:GrantPermissions("Player-1-00000004", Configuration.Permissions.Admin)
		--	c:GrantPermissions("Player-1-00000005", Configuration.Permissions.Admin)
		--	c.status = Configuration.Status.Active
		--	c.default = false
		--	local h1, h2 = c:hash(), nil
		--	assert(h1)
		--	-- print(Util.Objects.ToString(c:toTable()))
		--	-- print(c:hash())
		--	c.default = true
		--	c.status = Configuration.Status.Inactive
		--	h2 = c:hash()
		--	assert.Not.equal(h1, h2)
		--	c.default = false
		--	c.status = Configuration.Status.Active
		--	h2 = c:hash()
		--	assert.equal(h1, h2)
		--	c:NewRevision(GetServerTime() + 10)
		--	h2 = c:hash()
		--	assert.equal(h1, h2)
		--end)
		--it("is referenceable", function()
		--	local c = Configuration.CreateInstance()
		--	c:GrantPermissions("Player-1-00000004", Configuration.Permissions.Admin)
		--	c:GrantPermissions("Player-1-00000005", Configuration.Permissions.Admin)
		--	c.status = Configuration.Status.Active
		--	c.default = false
		--	local ref = c:ToRef()
		--	assert(ref)
		--	assert(ref.id)
		--	assert(ref.hash)
		--	assert(ref.revision)
		--	assert(ref.version)
		--	assert.equal('Configuration', ref.clz)
		--end)
	end)
end)