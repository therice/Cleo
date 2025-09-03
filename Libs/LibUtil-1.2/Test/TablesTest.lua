local Util

describe("LibUtil", function()
    setup(function()
        loadfile("Test/TestSetup.lua")(false, 'LibUtil')
        loadfile("Libs/LibUtil-1.2/Test/BaseTest.lua")()
        LoadDependencies()
        loadfile('Libs/LibUtil-1.2/Test/TablesTestData.lua')()
        ConfigureLogging()
        Util = LibStub:GetLibrary('LibUtil-1.2')
    end)


    teardown(function()
        After()
    end)

    describe("Tables", function()
        it("get(s) table entry via path", function()
            local data = Util.Tables.Get(TestTable, "defaults.profile")
            assert.is.Not.Nil(data.buttons)
            assert.is.Not.Nil(data.responses)
            data = Util.Tables.Get(TestTable, "defaults.profile.buttons.default")
            assert.is.Not.Nil(data)
            assert.equal(4, data.numButtons)
        end)
        it("set(s) table entry via path", function()
            local K1 = "kk"
            local K2 = "ll"

            local T = {
                tp = {

                }
            }

            Util.Tables.Set(T, 'tp', K1, {a='b'})
            Util.Tables.Set(T, 'tp', K2, {})
            Util.Tables.Set(T, 'tp', "a", "big", "path", true)
            assert.equal('b', Util.Tables.Get(T, 'tp', K1, 'a'))
            assert.equal(0, Util.Tables.Count(Util.Tables.Get(T, 'tp', K2)))
            assert.equal(true, Util.Tables.Get(T, 'tp.a.big.path'))
        end)
        it("copies and maps", function()
            local copy =
            Util(TestTable2)
                    :Copy()
                    :Map(
                    function(entry)
                        return entry.test and {} or entry
                    end
            )()

            assert(Util.Tables.Equals(copy['a'], {}))
            assert(Util.Tables.Equals(copy['b'], {test=false}))
            assert(Util.Tables.Equals(copy['c'], {test=false}))
            assert(Util.Tables.Equals(copy['d'], {}))
        end)
        it("provides keys", function()
            local keys = Util(TestTable2):Keys()()
            local copy = {}
            for _, v in pairs(keys) do
                assert(Util.Objects.In(v, 'a', 'b', 'c', 'd'))
                Util.Tables.Push(copy, v)
            end
            assert(Util.Tables.Equals(keys, copy))
        end)
        it("ordered pairs", function()
            local t = {
                [2]  = 'not equippable',
                [99] = 'all',
                [1]  = 'equippable',
            }

            local index = 1
            for key, val in Util.Tables.OrderedPairs(Util.Tables.Flip(t)) do
                if index == 1 then
                    assert.equal(val, 99)
                elseif index == 2 then
                    assert.equal(val, 1)
                elseif index == 3 then
                    assert.equal(val, 2)
                end
                assert.equal(key, t[val])
                index = index + 1
            end
            assert.equal(index, 4)

            index = 1
            for key, val in Util.Tables.OrderedPairs(t) do
                if index == 1 then
                    assert.equal(key, 1)
                elseif index == 2 then
                    assert.equal(key, 2)
                elseif index == 3 then
                    assert.equal(key, 99)
                end
                assert.equal(val, t[key])
                index = index + 1
            end
            assert.equal(index, 4)


            t = { b="xxx", a="xxx", 100, [-5]=100 }
            index = 1
            for key, val in Util.Tables.OrderedPairs(t) do
                if index == 1 then
                    assert.equal(key, -5)
                elseif index == 2 then
                    assert.equal(key, 1)
                elseif index == 3 then
                    assert.equal(key, 'a')
                elseif index == 4 then
                    assert.equal(key, 'b')
                end
                assert.equal(val, t[key])

                index = index + 1
            end
            assert.equal(index, 5)

        end)
        it("sorts (ordered pairs)", function()
            local t = {
                [2]  = 'Not Equippable',
                [1]  = 'Equippable',
                [99] = 'All',
            }

            assert.same({All = 99, Equippable = 1, ['Not Equippable'] = 2}, Util.Tables.Sort2(t, true))
            assert.same({'Equippable', 'Not Equippable', [99] = 'All'}, Util.Tables.Sort2(t, false))

	        t = {
		        b="xxx",
		        a="yyy",
		        100,
		        [-5]=100
	        }
	        assert.same({[-5] = 100, [1] = 100, a = "yyy", b = "xxx"}, Util.Tables.Sort2(t, false))

        end)
        it("sorts associatively", function()
            local t = {
                ['test'] = {a=1,b='Zed'},
                ['foo'] = {a=2, b='Bar'},
                ['aba'] = {a=100, b='Qre'},
            }

            local t2 = Util.Tables.ASort(t, function (a,b) return a[2].b < b[2].b end)
            local idx = 1
            for _, v in pairs(t2) do
                assert(v[1] == (idx == 1 and 'foo' or idx == 2 and 'aba' or idx == 3 and 'test' or nil))
                idx = idx + 1
            end
        end)
        it("copies, maps, and flips", function()
            local t =  {
                Declined    = { 1, 'declined' },
                Unavailable = { 3, 'unavailable' },
                Unsupported = { 2, 'unsupported' },
            }

            local t2 = Util(t):Copy():Map(function (e) return e[1] end):Flip()()
            assert(t2[1] == 'Declined')
            assert(t2[2] == 'Unsupported')
            assert(t2[3] == 'Unavailable')
        end)
        it("copies without mutate", function()
            local o = {
                a = {1, "b", true},
                b = {2, "c", true},
                c = {3, "d", false},
            }
            local c = Util(o):Copy()()
            Util.Tables.Remove(c, "b")
            assert(Util.Tables.ContainsKey(o, 'b'))
            assert(not Util.Tables.ContainsKey(c, 'b'))
        end)
        it("copies (except) where", function()
            local t = {
                "A",
                "B",
                "C",
                "D",
                "Z"
            }

            local c = Util(t):CopyWhere(false, "A", "Z")()
            assert.same({"A", "Z"}, c)

            c = Util(t):CopyExceptWhere(false, "A", "Z")()
            assert.same({"B", "C", "D"}, c)
        end)
        it("merges (uniquely)", function()
            local a = {
                "A",
                "B",
                "Z"
            }

            local b = {
                "A",
                "D",
                "E",
                "Z"
            }

            local c = Util(a):Merge(b, true)()
            assert.same({"A", "B", "Z", "D", "E"}, c)
        end)
        it("yields difference", function()
            local source = {
                a = {true},
                b = {},
                c = false,
                x = {}
            }

            local target = {
                a = {true},
                b = {3},
                d = {},
            }

            local delta1 = Util.Tables.CopyUnselect(source, unpack(Util.Tables.Keys(target)))
            local delta2 = Util.Tables.CopyUnselect(target, unpack(Util.Tables.Keys(source)))

            assert(Util.Tables.Count(delta1) == 2)
            assert.Is.Not.Nil(delta1['c'])
            assert.Is.Not.Nil(delta1['x'])

            assert(Util.Tables.Count(delta2) == 1)
            assert.Is.Not.Nil(delta2['d'])

            local deltac = Util.Tables.CopyUnselect({a=1, b=1, c=1}, 'a', 'b', 'c')
            assert(Util.Tables.Count(deltac) == 0)
        end)
        it("sorts", function()
            local t = {
                ['a'] = {x=1,t=GetServerTime()},
                ['b'] = {x=2,t=GetServerTime() + 100},
                ['c'] = {x=3,t=GetServerTime() - 100},
                ['d'] = {x=4,t=GetServerTime()},
            }

            for k, v in Util.Tables.SortedByValue(t, function(a, b) return a.t < b.t end) do
                print(tostring(k) .. ' -> ' .. Util.Objects.ToString(v))
            end
        end)
        it("sorts table via user specified function", function()
            local t = {
                [1] = {'Zed', 'Aba', 'Noas'},
                [2] = {'aB', 'Zx', 'Ab'},
            }

            for k, v in pairs(t) do
                local sorted =
                    Util.Tables.Sort(
                        Util.Tables.Copy(v),
                        function (a, b) return a < b end
                    )

                if k == 1 then
                    assert(Util.Tables.Equals(sorted, {'Aba', 'Noas', 'Zed'}, true))
                elseif k == 2 then
                    assert(Util.Tables.Equals(sorted, {'Ab', 'Zx', 'aB'}, true))
                end
            end
        end)
        it("handles sparse table compaction ", function()
            local sparse = {1, 3, nil, 5, nil, nil, 6, 99, nil}
            local notsparse = {1, 3, 5, 6, 99}
            local mix = {"a", "b", nil, nil, "z", nil, nil, ["x"] = {["a"] = 99}, "xx", ["zed"] = 3}
            local withkeys = {["a"] = "b", nil, ["b"] = nil, ["x"] = {["a"] = 99}, ["zz"] = {1, 2, 3}}

            local t1 = Util.Tables.Compact(sparse)
            local t2 = Util.Tables.Compact(notsparse)
            local t3 = Util.Tables.Compact(mix)
            local t4 = Util.Tables.Compact(withkeys)

            assert(#t1 == #t2)
            assert(table.maxn(t1) == table.maxn(t2))
            assert(Util.Tables.Equals(t1, t2, true))
            assert(Util.Tables.Equals(t1, notsparse, true))
            assert(Util.Tables.Equals(t2, notsparse, true))
            assert(Util.Tables.Equals(t3, {"a", "b", "z", "xx", ["x"] = {["a"] = 99}, ["zed"] = 3}, true))
            assert(Util.Tables.Equals(t4, {["a"] = "b", ["x"] = {["a"] = 99}, ["zz"] = {1, 2, 3}}, true))
        end)
        it("provides random key", function()
            local k = Util.Tables.RandomKey(TestTable2)
            assert(Util.Objects.In(k, 'a', 'b', 'c', 'd'))
            assert(not Util.Tables.RandomKey())
            assert(not Util.Tables.RandomKey({}))
        end)
        it("provides random entry", function()
            local v = Util.Tables.Random({ [1] = {'a'},  [2] = {'b'}, [3] = {'c'}, [4] = {'d'}, [5] = {'e'}})
            assert(v)
            assert(#v == 1)
            assert(type(v[1]) == 'string')
        end)
        it("shuffles", function()
            local t = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            Util.Tables.Shuffle(t)
            assert(#t == 10)
            assert(t[1] >= 1 and t[1] <= 10)
        end)
        it("values", function()
            local v = Util.Tables.Values({ [1] = {'a'},  [2] = {'b'}, [3] = {'c'}, [4] = {'d'}, [5] = {'e'}})
            assert(#v == 5)
        end)
        it("to list", function()
            local o = {
                a = {1, "b", true},
                b = {2, "c", true},
                c = {3, "d", false},
            }
            Util.Tables.List(o)
            assert.is.same(o, {{1, 'b', true}, {3, 'd', false}, {2, 'c', true}})
        end)
        it("sub", function()
            local s = Util.Tables.Sub({ [1] = {'a'},  [2] = {'b'}, [3] = {'c'}, [4] = {'d'}, [5] = {'e'}}, 2, 3)
            assert.is.same(s, {{'b'}, {'c'}})
        end)
        it("head", function()
            local t = { [1] = {'a'},  [2] = {'b'}, [3] = {'c'}, [4] = {'d'}, [5] = {'e'}}
            local s = Util.Tables.Head(t, 2)
            assert.is.same(s, {{'a'}, {'b'}})
        end)
        --it("nth value", function()
        --    local t = { [1] = {'a'},  [2] = {'b'}, [3] = {'c'}, [4] = {'d'}, [5] = {'e'}}
        --    assert.is.same({'a'}, Util.Tables.NthValue(t, 1))
        --    assert.is.same({'e'}, Util.Tables.NthValue(t, 5))
        --    assert(Util.Tables.NthValue(t, 6) == nil)
        --    t = { [99] = {'aa'},  [2] = {'b'}, [3] = {'c'}, [4] = {'d'}, [5] = {'ee'}}
        --    assert.is.same({'aa'}, Util.Tables.NthValue(t, 1))
        --    assert.is.same({'ee'}, Util.Tables.NthValue(t, 5))
        --    assert(Util.Tables.NthValue(t, 6) == nil)
        --    t = { a = {'zz'},  b = {'bb'}, c = {'ff'}, d = {'dd'}, e = {'ee'}}
        --    assert.is.same({'zz'}, Util.Tables.NthValue(t, 1))
        --    assert.is.same({'ff'}, Util.Tables.NthValue(t, 3))
        --    assert(Util.Tables.NthValue(t, 6) == nil)
        --end)
        it("tail", function()
            local s = Util.Tables.Tail({ [1] = {'a'},  [2] = {'b'}, [3] = {'c'}, [4] = {'d'}, [5] = {'e'}}, 1)
            assert.is.same(s, {{'d'}, {'e'}})
        end)
        it("splice", function()
            local t = {"a", "b", "c", "d", "e", "z"}
            local s = Util.Tables.Splice(t, 2, 3, {"aa"})
            assert.is.same(s,{"a", "b", "aa", "c", "d", "e", "z"})
             s = Util.Tables.Splice(t, 2, 4, {"aa"})
            assert.is.same(s,{"a", "b", "aa", "d", "e", "z"})
        end)
        it("splice2", function()
            local t = {1, nil, 2, 3, nil, nil, 99, nil, 'z'}
            local s = Util.Tables.Splice2(t, 3, 4, {"aa"})
            assert.is.same(s, {1, nil, 2, "aa", 3,nil, nil, 99, nil, 'z'})
            s = Util.Tables.Splice2(t, 3, 5, {"aa"})
            assert.is.same(s, {1, nil, 2, "aa", nil,nil, nil, 99, nil, 'z'})
            t = {"A"}
            s = Util.Tables.Splice2(t, 1, 2, {"B"})
            assert.is.same(s, {"A", "B"})
        end)
        it("inserts", function()
            local t = {"a", "b", "c", "d", "e", "z"}
            Util.Tables.Insert(t, 1, "aa")
            assert.is.same(t, {"aa", "a", "b", "c", "d", "e", "z"})
        end)
        it("flattens", function()
            local t = {
                [1] = {"a", "b"},
                [2] = {"c"},
                [12] = {"d", "e", "f", "z", "x"},
                [14] = {"aa"},
            }

            local v = Util.Tables.Values(t)
            assert.same(
                {{'a', 'b'}, {'c'}, {'d', 'e', 'f', 'z', 'x'}, {'aa'}},
                v
            )
            local f = Util.Tables.Flatten(v)
            assert.same(
                {'a', 'b', 'c', 'd', 'e', 'f', 'z', 'x', 'aa'},
                f
            )
        end)
        it("compares", function()
            local t1 = {
                ['a1'] = { 'b', 'c', 'd' },
                ['b1'] = { 'e', 'f', 'g' },
                ['c1'] = { 'h', 'i', 'j' }
            }

            local t2 = {
                ['a1'] = { 'b', 'c', 'd' },
                ['b1'] = { 'e', 'f', 'g' },
                ['c1'] = { 'h', 'i', 'j' }
            }

            assert(Util.Tables.Equals(t1, t2, true))

            t2 = {
                ['c1'] = { 'h', 'i', 'j' },
                ['a1'] = { 'b', 'c', 'd' },
                ['b1'] = { 'e', 'f', 'g' },
            }
            assert.Not(Util.Tables.Equals(t1, t2, false))
            assert(Util.Tables.Equals(t1, t2, true))

            t2 = {
                ['a1'] = { 'c', 'd', 'b' },
                ['b1'] = { 'f', 'g', 'e' },
                ['c1'] = { 'j', 'i', 'h' },

            }
            assert.Not(Util.Tables.Equals(t1, t2, false))
            assert.Not(Util.Tables.Equals(t1, t2, true))

            local k1, k2 =
                Util.Tables.Sort(Util.Tables.Keys(t1)),
                Util.Tables.Sort(Util.Tables.Keys(t2))

            assert(Util.Tables.Equals(k1, k2, false))

            local v1, v2
            for _, k in pairs(k1) do
                v1 = Util.Tables.Sort(Util.Tables.Copy(t1[k]))
                v2 = Util.Tables.Sort(Util.Tables.Copy(t2[k]))
                assert(Util.Tables.Equals(v1, v2, false))
            end
        end)
    end)
end )

--[[

loadfile("/mnt/c/Users/tedri/src/Cleo/Libs/LibStub/LibStub.lua")()
loadfile("/mnt/c/Users/tedri/src/Cleo/Libs/LibUtil-1.2/LibUtil-1.2.lua")()
loadfile("/mnt/c/Users/tedri/src/Cleo/Libs/LibUtil-1.2/Tables.lua")()
loadfile("/mnt/c/Users/tedri/src/Cleo/Libs/LibUtil-1.2/Objects.lua")()
loadfile("/mnt/c/Users/tedri/src/Cleo/Libs/LibUtil-1.2/Functions.lua")()
Util =  LibStub("LibUtil-1.2")


a = {"a", "b", "c", "d"}
print(a[3]) -- c
table.remove(a, 3)
print(a[3]) -- d

a = {"a", "b", "c", "d"}
print(Util.Tables.Count(a)) -- 4

for i, _ in ipairs(a) do
	print("#" .. Util.Tables.Count(a) .. " before(" .. i .. ") => " .. Util.Objects.ToString(a))
	table.remove(a, i)
	print("#" .. Util.Tables.Count(a) .. " after(" .. i .. ") => " .. Util.Objects.ToString(a))
end

#4 before(1) => {a, b, c, d}
#3 after(1) => {b, c, d}
#3 before(2) => {b, c, d}
#2 after(2) => {b, d}

print(Util.Objects.ToString(a)) -- {b, d}

function tUnorderedRemove(tbl, index)
	if index ~= #tbl then
		tbl[index] = tbl[#tbl];
	end
	table.remove(tbl);
end

a = {"a", "b", "c", "d"}
tUnorderedRemove(a, 2)
print(Util.Objects.ToString(a)) -- {a, d, c}

--]]