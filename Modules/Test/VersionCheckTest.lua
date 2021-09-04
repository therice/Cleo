local AddOnName, AddOn, Util, Comm, C, SemanticVersion

describe("VersionCheck", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_VersionCheck')
		AddOnLoaded(AddOnName, true)
		Util, C = AddOn:GetLibrary('Util'), AddOn.Constants
		SemanticVersion = AddOn.ImportPackage('Models').SemanticVersion
		Comm = AddOn.Require('Core.Comm')
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local module = AddOn:VersionCheckModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("VersionCheck")
			local module = AddOn:VersionCheckModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("VersionCheck")
			local module = AddOn:VersionCheckModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
	end)

	describe("functional", function()
		--- @type VersionCheck
		local vc
		setup(function()
			Comm:Register(C.CommPrefixes.Version)
			local db = NewAceDb(
					{
						global = {
							versions = {
								['A'] = {'2020.2', GetServerTime() - 604800},
								['B'] = {'2020.2', GetServerTime() - (86400 - 60)},
								['C'] = {'2020.2', GetServerTime() - (2 * 86400)},
								['D'] = {'2021.1', GetServerTime() - (2 * 86400)}
							}
						}
					}
			)
			vc = AddOn:VersionCheckModule()
			vc.Versions = function()
				return db.global.versions
			end
			AddOn:CallModule("VersionCheck")
		end)

		teardown(function()
			vc = nil
		end)

		it("clears expired versions", function()
			vc:ClearExpiredVersions()
			assert.equal(Util.Tables.Count(vc.Versions()), 3)
			vc:DisplayOutOfDateClients()
		end)

		it("handles version ping/reply", function()
			local version = AddOn.version
			_G.UnitIsUnit = function(unit1, unit2) return false end
			AddOn.version = SemanticVersion('2020.1')
			vc:SendGuildVersionPing()
			WoWAPI_FireUpdate(GetTime() + 10)
			_G.UnitIsUnit = function(unit1, unit2) return true end
			AddOn.version = version
			vc:SendGuildVersionPing()
			WoWAPI_FireUpdate(GetTime() + 10)
		end)

		it("queries", function()
			local s = spy.on(vc, "OnVersionCheckReceived")
			vc:Query(C.guild)
			WoWAPI_FireUpdate(GetTime() + 10)
			assert.spy(s).was.called(1)
			s:clear()
			vc:Query(C.group)
			WoWAPI_FireUpdate(GetTime() + 10)
			assert.spy(s).was.called(1)
		end)
	end)
end)