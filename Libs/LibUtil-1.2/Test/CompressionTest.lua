local Util, Compression
local TestValue = "12123123412345123456123456712345678123456789"

describe("LibUtil", function()
    setup(function()
        loadfile("Test/TestSetup.lua")(false, 'LibUtil')
        loadfile("Libs/LibUtil-1.2/Test/BaseTest.lua")()
        LoadDependencies()
        ConfigureLogging()
        Util, _ = LibStub('LibUtil-1.2')
        Compression = Util.Compression
    end)
    teardown(function()
        After()
    end)
    describe("Compression", function()
        it("handles encoding/decoding ", function()
            for _, encoder in pairs(Compression.Encoders()) do
                local encoded = encoder:encode(TestValue)
                assert(encoder:decode(encoded) == TestValue)
            end
        end)
        it("handles compression", function()
            for _, compressor in pairs(Compression.Compressors()) do
                local compressed = compressor:compress(TestValue)
                compressed = compressor:compress(TestValue, true)
            end
        end)
        it("handles decompression", function()
            for _, compressor in pairs(Compression.Compressors()) do
                local compressed = compressor:compress(TestValue)
                local decompressed = compressor:decompress(compressed)
                assert(TestValue == decompressed)
            end
        end)
        it("handles decompression with encoding", function()
            for _, compressor in pairs(Compression.Compressors()) do
                local compressed = compressor:compress(TestValue, false)
                local decompressed = compressor:decompress(compressed, false)
                assert(TestValue == decompressed)
            end
        end)
        it("handles selecting specific encoders", function()
            local C = Compression.Compressors()
            local compressors = Compression.GetCompressors(Compression.CompressorType.LibDeflate)
            assert(#compressors == 1)
            assert(compressors[1] == C[Compression.CompressorType.LibDeflate])
            compressors = Compression.GetCompressors(
                    Compression.CompressorType.NoOp,
                    Compression.CompressorType.LibDeflate
            )
            assert(#compressors == 2)
            assert(compressors[1] == C[Compression.CompressorType.NoOp])
            assert(compressors[2] == C[Compression.CompressorType.LibDeflate])
        end)
    end)
end)