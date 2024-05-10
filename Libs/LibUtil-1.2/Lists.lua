local MAJOR_VERSION = "LibUtil-1.2"
local MINOR_VERSION = 40400

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Lists) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
--- @class LibUtil.Lists
local Self = Util.Lists
--- @type LibClass
local Class = LibStub("LibClass-1.1")


--- @class LibUtil.Lists.LinkedList
local LinkedList = Class('LinkedList')
Self.LinkedList = LinkedList

--- @class LibUtil.Lists.LinkedList.Node
local Node = Class('LinkedList.Node')
function Node:initialize(prev, element, next)
	self.prev = prev
	self.item = element
	self.next = next
end

function Node:__tostring()
	return format(
			"LinkedList.Node[prev=%s, item=%s, next=%s]",
			Util.Objects.ToString(self.prev and self.prev.item or nil, 1),
			Util.Objects.ToString(self.item and self.item or {}, 1),
			Util.Objects.ToString(self.next and self.next.item or nil, 1)
	)
end

function LinkedList:initialize()
	self:Clear()
end

function LinkedList:Clear()
	self.size = 0
	self.first = nil
	self.last = nil
end

-- overrides the definition from LibClass
function LinkedList:toTable(serializer)
	serializer = serializer or Util.Functions.Id

	local t = {}
	for x in self:Iterator() do
		Util.Tables.Push(t, serializer(x.item))
	end
	return t
end

function LinkedList.FromTable(t, deserializer)
	deserializer = deserializer or Util.Functions.Id

	local ll = LinkedList()
	for _, e in pairs(t) do
		ll:AddLast(deserializer(e))
	end
	return ll
end

function LinkedList:__tostring()
	return format(
			"LinkedList[first=%s, last=%s, size=%d]",
			Util.Objects.ToString(self.first and self.first.item or nil, 1),
			Util.Objects.ToString(self.last and self.last.item or nil, 1),
			self.size
	)
end

local function OutOfBoundsMessage(index, size)
	return format("index=%d, size=%d", index, size)
end

function LinkedList:_isIndex(index)
	return index >= 1 and index <= self.size
end

function LinkedList:_checkIndex(index)
	if not self:_isIndex(index) then
		error(format("IndexOutOfBounds : %s", OutOfBoundsMessage(index, self.size)))
	end
end

function LinkedList:_node(index)
	local x

	if index < (self.size / 2) then
		x = self.first
		local i = 1
		while (i < index) do
			x = x.next
			i = i + 1
		end
	else
		x = self.last
		local i = self.size
		while(i > index) do
			x = x.prev
			i = i -1
		end
	end

	return x
end

function LinkedList:_next(node)
	if node then
		return node.next
	else
		return self.first
	end
end

function LinkedList:_previous(node)
	if node then
		return node.prev
	else
		return self.last
	end
end

function LinkedList:_linkFirst(e)
	local f = self.first
	local newNode = Node(nil, e, f)
	self.first = newNode
	if f == nil then
		self.last = newNode
	else
		f.prev = newNode
	end
	self.size = self.size + 1
end

function LinkedList:_linkLast(e)
	local l = self.last
	local newNode = Node(l, e, nil)
	self.last = newNode
	if l == nil then
		self.first = newNode
	else
		l.next = newNode
	end
	self.size = self.size + 1
end

function LinkedList:_linkBefore(e, succ)
	local pred = succ.prev
	local newNode = Node(pred, e, succ)
	succ.prev = newNode
	if pred == nil then
		self.first = newNode
	else
		pred.next = newNode
	end
	self.size = self.size + 1
end

function LinkedList:_unlinkFirst(f)
	local element = f.item
	local next = f.next
	f.item = nil
	f.next = nil
	self.first = next
	if next == nil then
		self.last = nil
	else
		next.prev = nil
	end
	self.size = self.size - 1
	return element
end

function LinkedList:_unlinkLast(l)
	local element = l.item
	local prev = l.prev
	l.item = nil
	l.prev = nil
	self.last = prev
	if prev == nil then
		self.first = nil
	else
		prev.next = nil
	end
	self.size = self.size - 1
	return element
end

function LinkedList:_unlink(x)
	local element = x.item
	local next = x.next
	local prev = x.prev

	if prev == nil then
		self.first = next
	else
		prev.next = next
		x.prev = nil
	end

	if next == nil then
		self.last = prev
	else
		next.prev = prev
		x.next = nil
	end

	x.item = nil
	self.size = self.size - 1
	return element
end

---
--- @return  number the index of the first occurrence of the specified element in this list, or -1 if this list does not contain the element.
function LinkedList:IndexOf(o)
	local index = 1
	local x  = self.first
	while (x ~= nil) do
		if (o == nil and x.item == nil) or (o == x.item) then
			return index
		end

		index = index + 1
		x = x.next
	end
	return -1
end

function LinkedList:Add(e)
	assert(e)
	self:_linkLast(e)
end

function LinkedList:AddAt(index, e)
	assert(index)
	assert(e)

	self:_checkIndex(index)
	if index == self.size then
		self:_linkLast(e)
	else
		self:_linkBefore(e, self:_node(index))
	end
end

function LinkedList:AddFirst(e)
	assert(e)
	self:_linkFirst(e)
end

function LinkedList:AddLast(e)
	assert(e)
	self:_linkLast(e)
end

function LinkedList:Set(index, e)
	assert(e)
	self:_checkIndex(index)
	local x = self:_node(index)
	local old = x.item
	x.item = e
	return old
end

function LinkedList:InsertAfter(at, e)
	assert(e)
	local index = self:IndexOf(at)
	if index == -1 then
		error("NoSuchElement")
	else
		if (index + 1 >= self.size) then
			local l = self:RemoveLast()
			self:Add(e)
			self:Add(l)
		else
			self:AddAt(index + 1, e)
		end
	end
end

function LinkedList:Size()
	return self.size
end

function LinkedList:Clear()
	local x = self.first
	while(x ~= nil) do
		local next = x.next
		x.item = nil
		x.next = nil
		x.prev = nil
		x = next
	end
	self.first = nil
	self.last = nil
	self.size = 0
end

function LinkedList:Contains(o)
	return self:IndexOf(o) ~= -1
end

function LinkedList:HasIndex(index)
	return self:_isIndex(index)
end

function LinkedList:Get(index)
	assert(index)
	self:_checkIndex(index)
	return self:_node(index).item
end

function LinkedList:RemoveFirst()
	local f = self.first
	if f == nil then
		error("NoSuchElement")
	end

	return self:_unlinkFirst(f)
end

function LinkedList:RemoveLast()
	local l = self.last
	if l == nil then
		error("NoSuchElement")
	end

	return self:_unlinkLast(l)
end

function LinkedList:Remove(o)
	local x = self.first
	while (x ~= nil) do
		if (o == nil and x.item == nil) or (o == x.item) then
			return self:_unlink(x)
		end

		x = x.next
	end

	return nil
end

function LinkedList:RemoveAt(index)
	assert(index)
	self:_checkIndex(index)
	return self:_unlink(self:_node(index))
end

function LinkedList:Iterator()
	return self._next, self
end

function LinkedList:IteratorAt(index)
	assert(index)
	self:_checkIndex(index)
	local node = self:_node(index)
	return self._next, self, node.prev
end

function LinkedList:ReverseIterator()
	return self._previous, self
end

function LinkedList:ReverseIteratorAt(index)
	assert(index)
	self:_checkIndex(index)
	local node = self:_node(index)
	return self._previous, self, node.next
end

