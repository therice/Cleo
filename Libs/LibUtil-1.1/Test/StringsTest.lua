local Util

describe("LibUtil", function()
    setup(function()
        loadfile("Test/TestSetup.lua")(false, 'LibUtil')
        loadfile("Libs/LibUtil-1.1/Test/BaseTest.lua")()
        LoadDependencies()
        ConfigureLogging()
        Util = LibStub:GetLibrary('LibUtil-1.1')
    end)
    
    teardown(function()
        After()
    end)
    
    describe("basic operations", function()
        it("IsEmpty", function()
            assert(Util.Strings.IsEmpty(nil))
            assert(Util.Strings.IsEmpty(""))
            assert(not Util.Strings.IsEmpty("ted"))
        end)
        it("StartsWith", function()
            assert(not Util.Strings.StartsWith(nil, nil))
            assert(not Util.Strings.StartsWith("", nil))
            assert(not Util.Strings.StartsWith("abdccc", "zz"))
            assert(Util.Strings.StartsWith("abdccc", "abd"))
        end)
        it("EndsWith", function()
            assert(not Util.Strings.EndsWith(nil, nil))
            assert(not Util.Strings.EndsWith("", nil))
            assert(not Util.Strings.EndsWith("abdccc", "zz"))
            assert(Util.Strings.EndsWith("abdccc", "cc"))
        end)
        it("Equal", function()
            assert(Util.Strings.Equal(nil, nil))
            assert(not Util.Strings.Equal("", nil))
            assert(not Util.Strings.Equal(nil, ""))
            assert(not Util.Strings.Equal("abdccc", "zz"))
            assert(Util.Strings.Equal("aba", "aba"))
        end)
        it("Wrap", function()
            assert(Util.Strings.Wrap(nil, "a", "b") == "")
            assert(Util.Strings.Wrap("", "a", "b") == "")
            assert(Util.Strings.Wrap(" ", "a", "b") == "")
            assert(Util.Strings.Wrap("a", "[", "]") == "[a]")
        end)
        it("Splits", function()
            local s = Util.Strings.Split("2021.2.0 (2021-11-02)", " ")
            assert.equal("2021.2.0", s[1])
            assert.equal("(2021-11-02)", s[2])
            s = Util.Strings.Split("2021.1.1", " ")
            assert.equal("2021.1.1", s[1])
        end)
    end)
    
end)