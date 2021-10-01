local Util

describe("LibUtil[Lists]", function()
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

	describe('LinkedList', function()
		--- @type LibUtil.Lists.LinkedList
		local LinkedList = Util.Lists.LinkedList

		it("handles add", function()
			local ll = LinkedList()
			ll:Add("TEST1")
			ll:Add("TEST2")
			assert.equal(ll:Size(), 2)
			assert.error(function() ll:Add(nil) end)
			assert.equal(ll.first.item, "TEST1")
			assert.equal(ll.first.next.item, "TEST2")
			assert.equal(ll.last.item, "TEST2")
		end)

		it("handles add at", function()
			local ll = LinkedList()
			ll:Add("TEST1")
			ll:AddAt(1, "TEST2")
			ll:AddAt(2, "TEST3")
			assert.equal(ll:Size(), 3)
			assert.error(function() ll:AddAt(1, nil) end)
			assert.error(function() ll:AddAt(4, "TEST2") end)
			assert.error(function() ll:AddAt(nil, "TEST2") end)
			assert.equal(ll.first.item, "TEST1")
			assert.equal(ll.first.next.item, "TEST2")
			assert.equal(ll.first.next.next.item, "TEST3")
			assert.equal(ll.last.item, "TEST3")
		end)

		it("handles add first", function()
			local ll = LinkedList()
			ll:Add("TEST1")
			ll:AddFirst("TEST2")
			assert.equal(ll:Size(), 2)
			assert.error(function() ll:AddFirst(nil) end)
			assert.equal(ll.first.item, "TEST2")
			assert.equal(ll.first.next.item, "TEST1")
			assert.equal(ll.last.item, "TEST1")
		end)

		it("handles add last", function()
			local ll = LinkedList()
			ll:AddLast("TEST2")
			ll:AddLast("TEST1")
			assert.equal(ll:Size(), 2)
			assert.error(function() ll:AddLast(nil) end)
			assert.equal(ll.first.item, "TEST2")
			assert.equal(ll.first.next.item, "TEST1")
			assert.equal(ll.last.item, "TEST1")
		end)

		it("handles clear", function()
			local ll = LinkedList()
			ll:Add("TEST1")
			ll:Add("TEST2")
			assert.equal(ll:Size(), 2)
			ll:Clear()
			assert.equal(ll:Size(), 0)
			assert.is.Nil(ll.first)
			assert.is.Nil(ll.last)
		end)

		it("handles contains", function()
			local ll = LinkedList()
			ll:Add("TEST1")
			ll:Add("TEST2")
			assert.equal(ll:Contains(nil), false)
			assert.equal(ll:Contains("TEST1"), true)
			assert.equal(ll:Contains("TEST2"), true)
			assert.equal(ll:Contains("TEST3"), false)
		end)

		it("handles index of", function()
			local ll = LinkedList()
			ll:Add("TEST1")
			ll:Add("TEST3")
			ll:Add("TEST2")
			assert.equal(ll:IndexOf(nil), -1)
			assert.equal(ll:IndexOf("TEST1"), 1)
			assert.equal(ll:IndexOf("TEST3"), 2)
			assert.equal(ll:IndexOf("TEST2"), 3)
			assert.equal(ll:IndexOf("TEST4"), -1)
		end)

		it("handles get", function()
			local ll = LinkedList()
			for i = 1, 15 do
				ll:Add("TEST" .. tostring(i))
			end

			assert.equal(ll:Size(), 15)
			assert.equal(ll:Get(1), "TEST1")
			assert.equal(ll:Get(2), "TEST2")
			assert.equal(ll:Get(7), "TEST7")
			assert.equal(ll:Get(8), "TEST8")
			assert.equal(ll:Get(13), "TEST13")
			assert.equal(ll:Get(14), "TEST14")
			assert.equal(ll:Get(15), "TEST15")
		end)

		it("handles iterator", function()
			local ll = LinkedList()
			for i = 1, 15 do
				ll:Add("TEST" .. tostring(i))
			end

			local index = 1
			for item in ll:Iterator() do
				assert.equal(item.item, "TEST" .. tostring(index))
				index = index + 1
			end
		end)

		it("handles iterator (at)", function()
			local ll, size = LinkedList(), 15
			for i = 1, size do
				ll:Add("TEST" .. tostring(i))
			end


			local index = 10
			for item in ll:IteratorAt(index) do
				assert.equal(item.item, "TEST" .. tostring(index))
				index = index + 1
			end
			assert.equal(index - 1, size)

			index = 1
			for item in ll:IteratorAt(index) do
				assert.equal(item.item, "TEST" .. tostring(index))
				index = index + 1
			end
			assert.equal(index - 1, size)

			index = 15
			for item in ll:IteratorAt(index) do
				assert.equal(item.item, "TEST" .. tostring(index))
				index = index + 1
			end
			assert.equal(index - 1, size)
		end)

		it("handles reverse iterator", function()
			local ll = LinkedList()
			for i = 1, 15 do
				ll:Add("TEST" .. tostring(i))
			end

			local index = 15
			for item in ll:ReverseIterator() do
				assert.equal(item.item, "TEST" .. tostring(index))
				index = index -1
			end
			assert.equal(index, 0)
		end)

		it("handles reverse iterator (at)", function()
			local ll, size = LinkedList(), 15
			for i = 1, size do
				ll:Add("TEST" .. tostring(i))
			end

			local index = 10
			for item in ll:ReverseIteratorAt(index) do
				assert.equal(item.item, "TEST" .. tostring(index))
				index = index - 1
			end
			assert.equal(index, 0)

			index = 1
			for item in ll:ReverseIteratorAt(index) do
				assert.equal(item.item, "TEST" .. tostring(index))
				index = index - 1
			end
			assert.equal(index, 0)

			index = 15
			for item in ll:ReverseIteratorAt(index) do
				assert.equal(item.item, "TEST" .. tostring(index))
				index = index - 1
			end
			assert.equal(index, 0)
		end)

		it("handles remove first", function()
			local ll, size = LinkedList(), 5
			for i = 1, size do
				ll:Add("TEST" .. tostring(i))
			end
			local e = ll:RemoveFirst()
			assert.equal(e, "TEST1")
			assert.equal(ll:Get(1), "TEST2")
			e = ll:RemoveFirst()
			assert.equal(e, "TEST2")
			assert.equal(ll:Get(1), "TEST3")
			assert.equal(ll:Size(), 3)
		end)

		it("handles remove last", function()
			local ll, size = LinkedList(), 5
			for i = 1, size do
				ll:Add("TEST" .. tostring(i))
			end
			local e = ll:RemoveLast()
			assert.equal(e, "TEST5")
			assert.equal(ll:Get(1), "TEST1")
			assert.equal(ll:Get(4), "TEST4")
			e = ll:RemoveLast()
			assert.equal(e, "TEST4")
			assert.equal(ll:Get(1), "TEST1")
			assert.equal(ll:Get(3), "TEST3")
			assert.equal(ll:Size(), 3)
		end)

		it("handles remove (specific element)", function()
			local ll, size = LinkedList(), 5
			for i = 1, size do
				ll:Add("TEST" .. tostring(i))
			end
			local e = ll:Remove("TEST2")
			assert.equal(e, "TEST2")
			assert.equal(ll:Get(1), "TEST1")
			assert.equal(ll:Get(2), "TEST3")
			assert.equal(ll:Size(), 4)
			e = ll:Remove(nil)
			assert.is.Nil(e)
			assert.equal(ll:Size(), 4)
		end)

		it("handles remove (specific index)", function()
			local ll, size = LinkedList(), 5
			for i = 1, size do
				ll:Add("TEST" .. tostring(i))
			end
			local e = ll:RemoveAt(3)
			assert.equal(e, "TEST3")
			assert.equal(ll:Get(1), "TEST1")
			assert.equal(ll:Get(2), "TEST2")
			assert.equal(ll:Size(), 4)
			assert.error(function() ll:RemoveAt(nil) end)
			assert.error(function() ll:RemoveAt(6) end)
			e = ll:RemoveAt(1)
			assert.equal(e, "TEST1")
			assert.equal(ll:Size(), 3)
		end)

		it("serializes to table", function()
			local ll, size = LinkedList(), 5
			for i = 1, size do
				ll:Add("TEST" .. tostring(i))
			end
			ll:AddFirst(("TEST99"))
			ll:AddLast(("TESTXX"))
			assert.same(ll:toTable(), {"TEST99", "TEST1", "TEST2", "TEST3", "TEST4", "TEST5", "TESTXX"})
		end)

		it("deserializes from table", function()
			local ll = LinkedList.FromTable({"TEST99", "TEST1", "TEST2", "TEST3", "TEST4", "TEST5", "TESTXX"})
			assert.equal(ll:Size(), 7)
			assert.equal(ll:Get(1), "TEST99")
			assert.equal(ll:Get(7), "TESTXX")
			for i = 2, 6 do
				assert.equal(ll:Get(i), "TEST" .. tostring(i-1))
			end
		end)
	end)
end)