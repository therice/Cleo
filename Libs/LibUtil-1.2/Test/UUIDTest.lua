local Util, Deflate, sha

describe("LibUtil", function()
	setup(function()
		loadfile("Test/TestSetup.lua")(false, 'LibUtil')
		loadfile("Libs/LibUtil-1.2/Test/BaseTest.lua")()
		LoadDependencies()
		ConfigureLogging()
		Util = LibStub:GetLibrary('LibUtil-1.2')
		Deflate = LibStub:GetLibrary('LibDeflate')
		sha = LibStub:GetLibrary('LibSHA-1.0')
	end)

	teardown(function()
		After()
	end)

	describe('UUID', function()
		local uuid = Util.UUID.UUID
		local md5sum = sha.md5
		-- "[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}"
		local uuid_regex = "[0-9a-fA-F]*%-[0-9a-fA-F]*%-[0-9a-fA-F]*%-[0-9a-fA-F]*%-[0-9a-fA-F]*"

		it("generates uuid", function()
			local uuid = uuid()
			print(uuid)

			assert.matches(uuid_regex, uuid)
			assert.equal(md5sum(uuid), md5sum(uuid))
		end)
	end)
end)