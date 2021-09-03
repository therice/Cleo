local Class

describe("LibClass", function()
    setup(function()
        loadfile("Test/TestSetup.lua")(false, 'LibClass')
        loadfile("Test/WowXmlParser.lua")()
        ParseXmlAndLoad('Libs/LibClass-1.0/LibClass-1.0.xml')
        Class = LibStub:GetLibrary('LibClass-1.0')
    end)

    teardown(function()
        After()
    end)

    describe("supports", function()
        local Base = Class('Base')
        function Base:initialize(a, b, c)
            self.a = a
            self.b = b
            self.c = c
        end

        local Subclass = Class('Subclass', Base)
        function Subclass:initialize(a, b, c, d)
            Base.initialize(self, a, b, c)
            self.d = d
        end

        it("simple classes", function()
            local b = Base('a', true, 99)
            assert(tostring(b) == 'instance of class Base')
            assert(b:isInstanceOf(Base))
            assert.equal(b.a, 'a')
            assert.equal(b.b, true)
            assert.equal(b.c, 99)
        end)

        it("sub classes", function()
            local s = Subclass('a', true, 99, {z=false})
            assert(tostring(s) == 'instance of class Subclass')
            assert(s:isInstanceOf(Base))
            assert(s:isInstanceOf(Subclass))
            assert(Subclass:isSubclassOf(Base))
            assert.equal(s.a, 'a')
            assert.equal(s.b, true)
            assert.equal(s.c, 99)
            assert.are.same(s.d, {z=false})
        end)

        it("to table", function()
            local s = Subclass('a', true, 99, {z=false})
            local t = s:toTable()
            assert.equal(t['a'], 'a')
            assert.equal(t['b'], true)
            assert.equal(t['c'], 99)
            assert.are.same(t['d'], {z=false})
        end)

        it("clone", function()
            local s = Subclass('a', true, 99, {z=false})
            local t = s:clone()
            assert.equal(s.a, t.a)
            assert.equal(s.b, t.b)
            assert.equal(s.c, t.c)
            assert.are.same(s.d, t.d)
        end)

        it("reconstitution", function()
            local o = Base('a', true, 99)
            local r = Base:reconstitute({a='a', b=true, c=99})
            assert.equal(o.a, r.a)
            assert.equal(o.b, r.b)
            assert.equal(o.c, r.c)
            assert.are_not.equal(o, r)
            assert.are.same(o:toTable(), r:toTable())
        end)
    end)
end)