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
            assert(Util.Objects.IsEmpty(nil))
            assert(Util.Objects.IsEmpty(""))
            assert(Util.Objects.IsEmpty({}))
        end)
        it("IsType", function()
            local function noop() end
            
            assert(not Util.Objects.IsString(nil))
            assert(not Util.Objects.IsString({ }))
            assert(Util.Objects.IsString(""))
    
            assert(not Util.Objects.IsTable(nil))
            assert(not Util.Objects.IsTable(""))
            assert(Util.Objects.IsTable({}))
    
            assert(not Util.Objects.IsFunction(nil))
            assert(not Util.Objects.IsFunction(""))
            assert(not Util.Objects.IsFunction({}))
            assert(Util.Objects.IsFunction(noop))
    
            assert(not Util.Objects.IsNil(""))
            assert(not Util.Objects.IsNil({}))
            assert(Util.Objects.IsNil(nil))
    
            assert(not Util.Objects.IsNumber(nil))
            assert(not Util.Objects.IsNumber(""))
            assert(not Util.Objects.IsNumber({}))
            assert(Util.Objects.IsNumber(9))
    
            assert(not Util.Objects.IsBoolean(nil))
            assert(not Util.Objects.IsBoolean(""))
            assert(not Util.Objects.IsBoolean({}))
            assert(Util.Objects.IsBoolean(true))
    
            assert(not Util.Objects.IsCallable(nil))
            assert(not Util.Objects.IsCallable(""))
            assert(not Util.Objects.IsCallable({}))
            assert(Util.Objects.IsCallable(noop))
            assert(Util.Objects.IsCallable(Util))
        end)
        it("ToString", function()
            assert.equal(
                    Util.Objects.ToString({'a', 1, true , function() end}),
                    "{a, 1, true, (fn)}"
            )
        end)
    end)
    
end)