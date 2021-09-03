local AddOnName, AddOn

describe("Instance", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(false, 'Instance')
        loadfile("Core/Oak/Test/BaseTest.lua")()
        LoadDependencies(AddOnName, AddOn)
    end)

    teardown(function()
        After()
        AddOn.DiscardInstances()
        AddOn.DiscardPackages()
    end)

    describe("creation", function()
        it("fails with invalid arguments", function()
            assert.has.errors(function () AddOn.Instance(1) end, "Instance name was not provided")
            assert.has.errors(function () AddOn.Instance("I") end, "Instance meta-data not provided for 'I'")
            assert.has.errors(function () AddOn.Instance("I", true) end, "Could not resolve class for 'I' from meta-data")
            assert.has.errors(function () AddOn.Instance("I", function (...) error("E") end) end, "E")
        end)
        it("succeeds with valid arguments", function()
            local p = AddOn.Package('p')
            local c = p:Class('c')
            function c:initialize(foo)
                c.foo = foo
            end
            local t = {
            }
            setmetatable(t, {
                __call = function()
                    return {z=false}
                end
            })

            local i = AddOn.Instance("I", c, 'bar')
            assert(i.clazz)
            assert(i.foo == 'bar')
            AddOn.DiscardInstances()
            i = AddOn.Instance("I", { pkg='p', class='c'}, 'baz')
            assert(i.clazz)
            assert(i.foo == 'baz')
            AddOn.DiscardInstances()
            i = AddOn.Instance("I", function () return {} end)
            assert(not i.clazz)
            assert(type(i) == 'table')
            AddOn.DiscardInstances()
            i = AddOn.Instance("I", t)
            assert(not i.clazz)
            assert(type(i) == 'table')
            assert(i.z == false)
            AddOn.DiscardInstances()
            AddOn.DiscardPackages()
        end)
    end)

    describe("access", function()
        it("fails with instance does not exist", function()
            assert.has.errors(function () AddOn.Require(nil) end, "Instance name was not provided")
            assert.has.errors(function () AddOn.Require("I") end, "Instance 'I' does not exist")
        end)
        it("returns correct instance", function()
            local p = AddOn.Package('p')
            local c = p:Class('c')
            local i1 = AddOn.Instance("I", c)
            local i2 = AddOn.Require("I")
            assert.are.same(i1, i2)

            local i1 = AddOn.Instance("I2", c)
            local I2 = AddOn.RequireOnUse('I2')
            assert.are.same(i1, I2())
            assert.are.same(i1, I2())

            AddOn.DiscardInstances()
            AddOn.DiscardPackages()
        end)
    end)
end)