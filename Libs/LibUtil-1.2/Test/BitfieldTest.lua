--- @type LibUtil
local Util

describe("LibUtil", function()
	setup(function()
		loadfile("Test/TestSetup.lua")(false, 'LibUtil')
		loadfile("Libs/LibUtil-1.2/Test/BaseTest.lua")()
		LoadDependencies()
		ConfigureLogging()
		Util = LibStub:GetLibrary('LibUtil-1.2')
	end)

	teardown(function()
		After()
	end)

	describe('Bitfield', function()
		local bitfield = Util.Bitfield.Bitfield
		local modes = {
			A = 0x01, -- 00001
			B = 0x02, -- 00010
			C = 0x04, -- 00100
			D = 0x08, -- 01000

		}

		it("created with a default flags", function()
			local bf = bitfield(modes.A)
			assert(bf:Enabled(modes.A))
			assert(bf:Disabled(modes.B))
			assert(bf:Disabled(modes.C))
		end)

		it("flags can be enabled", function()
			local bf = bitfield(modes.A)
			bf:Enable(modes.B, modes.D)
			assert(bf:Enabled(modes.A))
			assert(bf:Enabled(modes.B))
			assert(bf:Disabled(modes.C))
			assert(bf:Enabled(modes.D))
		end)

		it("flags can be disabled", function()
			local bf = bitfield(modes.A)
			bf:Enable(modes.C)
			assert(bf:Enabled(modes.A))
			assert(bf:Disabled(modes.B))
			assert(bf:Enabled(modes.C))
			assert(bf:Disabled(modes.D))

			bf:Disable(modes.C, modes.D)
			assert(bf:Enabled(modes.A))
			assert(bf:Disabled(modes.B))
			assert(bf:Disabled(modes.C))
			assert(bf:Disabled(modes.D))

			bf:Disable(modes.C)
			assert(bf:Enabled(modes.A))
			assert(bf:Disabled(modes.B))
			assert(bf:Disabled(modes.C))
			assert(bf:Disabled(modes.D))
		end)
	end)
end)