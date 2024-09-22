--- @type AddOn
local AddOn
local AddOnName
--- @type Models.Dao
local Dao

--- @type LibUtil
local Util
--- @type LootLedger.Entry
local Entry
--- @type LootLedger.TradeTime
local TradeTime
-- @type Player
local Player
--- @type Core.Message
local Message

local function ModuleWithData(m, data, enable)
	enable = Util.Objects.IsEmpty(enable) and true or enable
	local db = NewAceDb(m.defaults)
	db.profile.lootStorage = Util.Tables.Copy(data)

	m:OnInitialize()
	m:SetDb(db)
	if enable then
		AddOn:CallModule(m:GetName())
		-- by default this is only called upon PLAYER_LOGIN event, which also triggers other stuff
		m:OnEnable()
		-- sketchy to do this, but calling Enable() has other ramifications
		m.enabledState = true
	end
end

insulate("LootLedger (Module)", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootLedger')
		Util = AddOn.Libs.Util
		AddOnLoaded(AddOnName, true)
		SetTime()
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is enabled on startup", function()
			local module = AddOn:LootLedgerModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("LootLedger")
			local module = AddOn:LootLedgerModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("LootLedger")
			local module = AddOn:LootLedgerModule()
			assert(module)
			assert(module:IsEnabled())
		end)
	end)
end)

insulate("LootLedger (Storage)", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootLedger')
		Util, Entry = AddOn.Libs.Util, AddOn.Package('LootLedger').Entry
		Dao = AddOn.Package('Models').Dao
		SetTime()
	end)

	teardown(function()
		After()
	end)

	describe("functionality", function()
		--- @type LootLedger
		local m

		before_each(function()
			m = AddOn:LootLedgerModule()
			assert(not m:IsEnabled())
		end)

		after_each(function()
			AddOn:YieldModule(m:GetName())
			m:OnDisable()
			assert(not m:IsEnabled())
		end)


		it("is empty", function()
			ModuleWithData(m, {})
			local storage = AddOn:LootLedgerModule():GetStorage()
			assert(storage)
			assert(storage.db)
			assert.equal(0, #storage.db)
		end)

		it("is populated", function()
			ModuleWithData(m, {
				['25043e0c46539bdde0df99cd07a156d6a633583919e8c4aedfb831a69775194a'] =
                    {state = 'TT', item = '|cffa335ee|Hitem:16489:::::::::::::::::|h[ItemName16489]|h|r', guid='Item-4372-0-400000033D4D1C16', added = 0},
				['7a041794f0edae6ad54833009470a4d6dae16b0d67959d39d28f6d55f1b632ba'] =
                    {state = 'AL', item = '|cffa335ee|Hitem:16439:::::::::::::::::|h[ItemName16439]|h|r', guid='Item-4372-0-400000033D4D1C17', added = 0},
				['255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61'] =
                    {state = 'TT', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r', guid='Item-4372-0-400000033D4D1C18', added = 0},
			}, false)

			local storage = AddOn:LootLedgerModule():GetStorage()
			assert(storage)
			assert(storage.db)
			assert.equal(3, Util.Tables.Count(storage.db))

			for _, item in pairs(storage:GetAll()) do
				assert(item)
			end
		end)

		it("CRUD operations work", async(function(as)
			ModuleWithData(m, {})
			local EventCount = {
				[Dao.Events.EntityCreated] = 0,
				[Dao.Events.EntityUpdated] = 0,
				[Dao.Events.EntityDeleted] = 0,
			}

			local x = {
				UpdateEventCount = function(_, event, ...)
					EventCount[event] = EventCount[event] + 1
				end
			}

			local storage = AddOn:LootLedgerModule():GetStorage()

			storage:RegisterCallbacks(x, {
				[Dao.Events.EntityCreated] = function(...) x:UpdateEventCount(...) end,
				[Dao.Events.EntityDeleted] = function(...) x:UpdateEventCount(...) end,
				[Dao.Events.EntityUpdated] = function(...) x:UpdateEventCount(...) end,
			})


			local item1 = Entry("|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r", Entry.State.AwardLater, "Item-4372-0-400000033D4D1C15")
			local item2 = Entry("|cffa335ee|Hitem:15918:::::::::::::::::|h[ItemName15918]|h|r", Entry.State.AwardLater, "Item-4372-0-400000033D4D1C16")

			storage:Add(item2)
			storage:Add(item1)

			local item3, item4 = storage:Get(item1.id), storage:Get(item2.id)

			assert.equal(item1, item3)
			assert.equal(item2, item4)

			local items = storage:GetAll()
			assert.equal(2, Util.Tables.Count(items))
			assert.equal(item1, items[item1.id])
			assert.equal(item2, items[item2.id])

			item1.measured = GetServerTime()
			storage:Update(item1, 'measured')

			local item5 = storage:Get(item1.id)
			assert(item5.measured ~= 0)
			assert.equal(item1, item5)

			storage:Remove(item2)
			local item6 = storage:Get(item1.id)
			assert.equal(item5, item6)

			storage:Clear()
			assert.equal(0, Util.Tables.Count(storage.db))
			assert.equal(2, EventCount[Dao.Events.EntityCreated])
			assert.equal(1, EventCount[Dao.Events.EntityUpdated])
			assert.equal(1, EventCount[Dao.Events.EntityDeleted])

			while not as.finished() do
				as.sleep(1)
			end

			finally(function()
				storage:UnregisterCallbacks(x, {Dao.Events.EntityCreated, Dao.Events.EntityDeleted, Dao.Events.EntityUpdated})
			end)
		end))

		it("GUID to ID index is maintained", async(function(as)
			ModuleWithData(m, {
				['25043e0c46539bdde0df99cd07a156d6a633583919e8c4aedfb831a69775194a'] =
					{state = 'TT', item = '|cffa335ee|Hitem:16489:::::::::::::::::|h[ItemName16489]|h|r', guid='Item-4372-0-400000033D4D1C16', added = 0},
				['7a041794f0edae6ad54833009470a4d6dae16b0d67959d39d28f6d55f1b632ba'] =
					{state = 'AL', item = '|cffa335ee|Hitem:16439:::::::::::::::::|h[ItemName16439]|h|r', guid='Item-4372-0-400000033D4D1C17', added = 0},
				['255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61'] =
					{state = 'TT', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r', guid='Item-4372-0-400000033D4D1C18', added = 0},
			}, false)

			local storage = AddOn:LootLedgerModule():GetStorage()
			assert.same({
				['Item-4372-0-400000033D4D1C16'] = '25043e0c46539bdde0df99cd07a156d6a633583919e8c4aedfb831a69775194a',
				['Item-4372-0-400000033D4D1C17'] = '7a041794f0edae6ad54833009470a4d6dae16b0d67959d39d28f6d55f1b632ba',
				['Item-4372-0-400000033D4D1C18'] = '255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61',
			}, storage.guidIndex)


			local item1 = Entry("|cffa335ee|Hitem:12345:::::::::::::::::|h[ItemName12345]|h|r", Entry.State.AwardLater)
			local item2 = Entry("|cffa335ee|Hitem:12346:::::::::::::::::|h[ItemName12346]|h|r", Entry.State.AwardLater, 'Item-4372-0-400000033D4D1C19')
			storage:Add(item1)
			storage:Add(item2)

			while not as.finished() do
				as.sleep(1)
			end

			assert.same({
	            ['Item-4372-0-400000033D4D1C16'] = '25043e0c46539bdde0df99cd07a156d6a633583919e8c4aedfb831a69775194a',
	            ['Item-4372-0-400000033D4D1C17'] = '7a041794f0edae6ad54833009470a4d6dae16b0d67959d39d28f6d55f1b632ba',
	            ['Item-4372-0-400000033D4D1C18'] = '255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61',
				['Item-4372-0-400000033D4D1C19'] = item2.id,
            }, storage.guidIndex)

			item1.guid = 'Item-4372-0-400000033D4D1C20'
			storage:Update(item1, 'guid')

			while not as.finished() do
				as.sleep(1)
			end

			assert.same({
	            ['Item-4372-0-400000033D4D1C16'] = '25043e0c46539bdde0df99cd07a156d6a633583919e8c4aedfb831a69775194a',
	            ['Item-4372-0-400000033D4D1C17'] = '7a041794f0edae6ad54833009470a4d6dae16b0d67959d39d28f6d55f1b632ba',
	            ['Item-4372-0-400000033D4D1C18'] = '255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61',
	            ['Item-4372-0-400000033D4D1C19'] = item2.id,
	            ['Item-4372-0-400000033D4D1C20'] = item1.id,
            }, storage.guidIndex)

			storage:Remove(item1)
			storage:Remove(item2)
			while not as.finished() do
				as.sleep(1)
			end

			assert.same({
	            ['Item-4372-0-400000033D4D1C16'] = '25043e0c46539bdde0df99cd07a156d6a633583919e8c4aedfb831a69775194a',
	            ['Item-4372-0-400000033D4D1C17'] = '7a041794f0edae6ad54833009470a4d6dae16b0d67959d39d28f6d55f1b632ba',
	            ['Item-4372-0-400000033D4D1C18'] = '255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61',
            }, storage.guidIndex)
		end))
	end)
end)

insulate("LootLedger (Watcher)", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootLedger')
		Util, Player = AddOn.Libs.Util, AddOn.Package('Models').Player
		Message = AddOn.RequireOnUse('Core.Message')
		AddOn.player = Player:Get("Player1")
		SetTime()
	end)

	teardown(function()
		After()
	end)

	--- @type LootLedger
	local m

	before_each(function()
		m = AddOn:LootLedgerModule()
		assert(not m:IsEnabled())
	end)

	after_each(function()
		if m:IsEnabled() then
			AddOn:YieldModule(m:GetName())
			m:OnDisable()
			assert(not m:IsEnabled())
		end
	end)

	describe("functionality", function()
		it("parses loot messages", function()
			--- @type LootLedger.Watcher
			local Watcher = AddOn.Package("LootLedger").Watcher
			local itemLink, playerName, itemCount =
				Watcher.GetMessageItemDetails("Fluffy-Bunny receives loot: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|rx2.")
			assert.equal("|cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r", itemLink)
			assert.equal("Fluffy-Bunny", playerName)
			assert.equal(2, itemCount)

			itemLink, playerName, itemCount =
				Watcher.GetMessageItemDetails("Bad-Bunny receives loot: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r.")
			assert.equal("|cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r", itemLink)
			assert.equal("Bad-Bunny", playerName)
			assert.equal(1, itemCount)

			itemLink, playerName, itemCount =
				Watcher.GetMessageItemDetails("You receive loot: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|rx2.")
			assert.equal("|cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r", itemLink)
			assert.equal("Player1-Realm1", playerName)
			assert.equal(2, itemCount)

			itemLink, playerName, itemCount =
				Watcher.GetMessageItemDetails("You receive loot: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r.")
			assert.equal("|cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r", itemLink)
			assert.equal("Player1-Realm1", playerName)
			assert.equal(1, itemCount)

			itemLink, playerName, itemCount =
				Watcher.GetMessageItemDetails("This is not a loot message: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r.")
			assert(not itemLink)
			assert(not playerName)
			assert(not itemCount)
		end)

		it("dispatches loot received messages", function()
			ModuleWithData(m, {}, true)
			local Watcher = AddOn.Package("LootLedger").Watcher

			local watcher = Watcher()
			assert(watcher)
			watcher:Start()

			local _IsHandled = m.IsHandled
			m.IsHandled = function() return true end
			assert(m:IsHandled())

			local itemCount = 0
			local subs = Message():BulkSubscribe({
                 [AddOn.Constants.Messages.LootItemReceived] = function(_, item)
	                 itemCount = itemCount + 1
	                 assert(item.id > 0)
	                 assert(item.link)
	                 assert.equal(AddOn.player:GetName(), item.player)
	                 assert(item.when <= GetServerTime())
                 end,
            })

			SendChatMessage("Fluffy-Bunny receives loot: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|rx2.", "LOOT")
			SendChatMessage("Bad-Bunny receives loot: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r.", "LOOT")
			SendChatMessage("You receive loot: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|rx2.", "LOOT")
			SendChatMessage("You receive loot: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r.", "LOOT")
			SendChatMessage("This is not a loot message: |cffa335ee|Hitem:59117:::::::::::::::::|h[ItemName59117]|h|r.", "LOOT")

			assert.equal(2, itemCount)

			finally(function()
				AddOn.Unsubscribe(subs)
				watcher:Stop()
				m.isHandled = _IsHandled
			end)
		end)
	end)
end)

insulate("LootLedger (TradeTimes)", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootLedger')
		Util, Entry, TradeTime = AddOn.Libs.Util, AddOn.Package('LootLedger').Entry, AddOn.Package('LootLedger').TradeTime
		Message = AddOn.RequireOnUse('Core.Message')
		Dao = AddOn.Package('Models').Dao
		SetTime()
	end)

	teardown(function()
		After()
	end)

	--- @type LootLedger
	local m

	before_each(function()
		m = AddOn:LootLedgerModule()
		assert(not m:IsEnabled())
	end)

	after_each(function()
		AddOn:YieldModule(m:GetName())
		m:OnDisable()
		assert(not m:IsEnabled())
	end)

	describe("functionality", function()
		it("handles trade time processing", async(function(as)
			ModuleWithData(m, {}, true)

			local tt = AddOn:LootLedgerModule():GetTradeTimes()
			-- adjust the functionality of a few instance methods to emulate expected behavior
			local _IsHandled, _TestModeEnabled = m.IsHandled, AddOn.TestModeEnabled
			m.IsHandled = function() return true end
			assert(m:IsHandled())

			AddOn.TestModeEnabled = function(_) return false end
			AddOn.Testing.LootLedger.TradeTimes:SetItems(59117, 65030, 69884, 69885)
			local containerItemInfo = {
				[1] = {
					[4] = {nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:59117:::::::::::::::::|h[Item59117]|h|r", nil, nil, 59117}
				},
				[3] = {
					[9] = {nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:65030:::::::::::::::::|h[Item65030]|h|r", nil, nil, 65030}
				},
				[4] = {
					[2] = {nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:69884:::::::::::::::::|h[Item69884]|h|r", nil, nil, 69884}
				},
			}

			local _GetContainerItemInfo = C_Container.GetContainerItemInfo
			C_Container.GetContainerItemInfo = function(container, slot)
				local c = containerItemInfo[container]
				if c and c[slot] then
					return unpack(c[slot])
				end

				return _GetContainerItemInfo(container, slot)
			end

			local _GetItemGUID, _GetItemID = C_Item.GetItemGUID, C_Item.GetItemID
			C_Item.GetItemGUID = function(location)
				local itemId = C_Item.GetItemID(location)
				if itemId == 59117 then
					return "Item-4372-0-400000033D4D1C16"
				elseif itemId == 65030 then
					return "Item-4372-0-400000033D4D1C17"
				elseif itemId == 69884 then
					return "Item-4372-0-400000033D4D1C18"
				elseif itemId == 69885 then
					return "Item-4372-0-400000033D4D1C19"
				end

				return _GetItemGUID(location)
			end

			C_Item.GetItemID = function(location)
				local container, slot = location.bagID, location.slotIndex
				local itemId = select(10, _G.C_Container.GetContainerItemInfo(container, slot))
				if itemId then
					return tonumber(itemId)
				end

				return _GetItemID(location)
			end

			local messageCount = 0
			local subs = Message():BulkSubscribe({
				[AddOn.Constants.Messages.TradeTimeItemsChanged] = function(_, items)
					assert(not Util.Tables.IsEmpty(items))
					messageCount = messageCount + 1
				end,
			})

			WoWAPI_FireEvent(AddOn.Constants.Events.BagUpdateDelayed)
			while not as.finished() do
				as.sleep(1)
			end

			assert.equal(messageCount, 1)
			assert.equal(Util.Tables.Count(tt.state), 3)
			for _, t in pairs(tt.state) do
				assert(not t:HasExpired())
			end

			messageCount = 0
			WoWAPI_FireEvent(AddOn.Constants.Events.BagUpdateDelayed)
			while not as.finished() do
				as.sleep(1)
			end

			-- no new event should be fired, as the state doesn't change
			assert.equal(messageCount, 0)
			assert.equal(Util.Tables.Count(tt.state), 3)
			for _, t in pairs(tt.state) do
				assert(not t:HasExpired())
			end

			containerItemInfo[1][5] = {nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:69885:::::::::::::::::|h[Item69885]|h|r", nil, nil, 69885}
			messageCount = 0
			WoWAPI_FireEvent(AddOn.Constants.Events.BagUpdateDelayed)
			while not as.finished() do
				as.sleep(1)
			end

			assert.equal(messageCount, 1)
			assert.equal(Util.Tables.Count(tt.state), 4)
			for _, t in pairs(tt.state) do
				assert(not t:HasExpired())
			end

			finally(function()
				AddOn.TestModeEnabled = _TestModeEnabled
				m.IsHandled = _IsHandled
				AddOn.Testing.LootLedger.TradeTimes:ClearItems()
				C_Container.GetContainerItemInfo = _GetContainerItemInfo
				C_Item.GetItemGUID = _GetItemGUID
				C_Item.GetItemID = _GetItemID
				AddOn.Unsubscribe(subs)
				tt.state = {}
			end)
		end))
	end)
end)


insulate("LootLedger (Module)", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootLedger')
		Util = AddOn.Libs.Util
		AddOn.player = Player:Get("Player1")
		SetTime()
	end)

	teardown(function()
		After()
	end)

	--- @type LootLedger
	local m

	before_each(function()
		m = AddOn:LootLedgerModule()
		assert(not m:IsEnabled())
	end)

	after_each(function()
		AddOn:YieldModule(m:GetName())
		m:OnDisable()
		assert(not m:IsEnabled())
	end)

	describe("functionality", function()
		it("validates storage entries", function()
			ModuleWithData(m, {
				-- no guid, added over 3 hours ago
				['deb99e6d9ac4e323b91b161229a720ae75e49c7e9af2bf84a341175afde20dae'] = -- 09/04/24 09:02:32
					{state = 'TT', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r', added = 1725462152},
				-- not located in bags
				['4a154b00055db56f26ed2249bbfdff40710747efb669aaea4527e77648cc44a6'] = -- 09/04/24 08:33:10
					{state = 'AL', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r', added = 1725460390, guid = 'Item-4372-0-400000033D4D1C17'},
				-- in bags, remaining trade time
				['255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61'] = -- 09/04/24 08:32:15
					{state = 'AL', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r', added = 1725460335, guid = 'Item-4372-0-400000033D4D1C16'},
				-- invalid item (state)
				['655e6616e3a818c5568a8bd6d671fef27ba9aaf3c0e64de86569d588203c1bda'] = -- 09/04/24 08:57:28
					{state = 'NA', item = '|cffa335ee|Hitem:15918:::::::::::::::::|h[ItemName15918]|h|r', added = 1725461848, guid = 'Item-4372-0-400000033D4D1C18'},
				-- in bags, trade time expired
				['f4056dea1b4cc1f277d8a1a408e8daed2fdb788d5c0c53946ee0b74dc56a0051'] = -- 09/04/24 08:57:38
					{state = 'TT', item = '|cffa335ee|Hitem:15919:::::::::::::::::|h[ItemName15919]|h|r', added = 1725461858, guid = 'Item-4372-0-400000033D4D1C19'},
			}, true)

			local _IsHandled, _TestModeEnabled = m.IsHandled, AddOn.TestModeEnabled
			m.IsHandled = function() return true end
			assert(m:IsHandled())

			AddOn.TestModeEnabled = function(_) return false end
			local _GetItemGUID = C_Item.GetItemGUID
			C_Item.GetItemGUID = function(location)
				local container, slot = location.bagID, location.slotIndex
				if container == 2 and slot == 1 then
					return 'Item-4372-0-400000033D4D1C16'
				elseif container == 4 and slot == 3 then
					return 'Item-4372-0-400000033D4D1C19'
				end
			end

			local _GetInventoryItemTradeTimeRemaining = AddOn.GetInventoryItemTradeTimeRemaining
			AddOn.GetInventoryItemTradeTimeRemaining = function(_, bag, slot)
				if bag == 2 and slot == 1 then
					return 1200
				elseif bag == 4 and slot == 3 then
					return 0
				end

				return _GetInventoryItemTradeTimeRemaining(AddOn, bag, slot)
			end

			m:ValidateEntries()

			local storage = m:GetStorage()
			assert.equal(1, Util.Tables.Count(storage.db))
			assert(storage:Get('255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61'))

			finally(function()
				AddOn.TestModeEnabled = _TestModeEnabled
				m.IsHandled = _IsHandled
				AddOn.GetInventoryItemTradeTimeRemaining = _GetInventoryItemTradeTimeRemaining
				C_Item.GetItemGUID = _GetItemGUID
			end)
		end)

		it("handles item received", function()
			--local Watcher = AddOn.Package("LootLedger").Watcher

			ModuleWithData(m, {
				['deb99e6d9ac4e323b91b161229a720ae75e49c7e9af2bf84a341175afde20dae'] = -- 09/04/24 09:02:32
					{state = 'TT', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r', added = 1725462152},
				['4a154b00055db56f26ed2249bbfdff40710747efb669aaea4527e77648cc44a6'] = -- 09/04/24 08:33:10
					{state = 'AL', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r', added = 1725460390},
				['255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61'] = -- 09/04/24 08:32:15
					{state = 'AL', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r', added = 1725460335},
				['655e6616e3a818c5568a8bd6d671fef27ba9aaf3c0e64de86569d588203c1bda'] = -- 09/04/24 08:57:28
					{state = 'AL', item = '|cffa335ee|Hitem:15918:::::::::::::::::|h[ItemName15918]|h|r', added = 1725461848},
				['f4056dea1b4cc1f277d8a1a408e8daed2fdb788d5c0c53946ee0b74dc56a0051'] = -- 09/04/24 08:57:38
					{state = 'TT', item = '|cffa335ee|Hitem:15919:::::::::::::::::|h[ItemName15919]|h|r', added = 1725461858},
			}, true)

			local _IsHandled, _TestModeEnabled = m.IsHandled, AddOn.TestModeEnabled
			m.IsHandled = function() return true end
			assert(m:IsHandled())

			--[[
			local watcher = Watcher()
			assert(watcher)
			watcher:Start()
			--]]

			AddOn.TestModeEnabled = function(_) return false end

			local containerItemInfo = {
				[1] = {
					[4] = { nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:159117:::::::::::::::::|h[Item15917]|h|r", nil, nil, 15917 },
					[5] = { nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:159117:::::::::::::::::|h[Item15917]|h|r", nil, nil, 15917 }
				},
				[3] = {
					[9] = { nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:159118:::::::::::::::::|h[Item15918]|h|r", nil, nil, 15918 }
				},
				[4] = {
					[1] = { nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:159117:::::::::::::::::|h[Item15917]|h|r", nil, nil, 15917 },
					[2] = { nil, nil, nil, nil, nil, nil, "|cffa335ee|Hitem:159119:::::::::::::::::|h[Item15919]|h|r", nil, nil, 15919 }
				},
			}

			local _GetContainerItemInfo = C_Container.GetContainerItemInfo
			C_Container.GetContainerItemInfo = function(container, slot)
				local c = containerItemInfo[container]
				if c and c[slot] then
					return unpack(c[slot])
				end

				return _GetContainerItemInfo(container, slot)
			end

			local _GetItemGUID, _GetItemID = C_Item.GetItemGUID, C_Item.GetItemID
			C_Item.GetItemGUID = function(location)
				local itemId = C_Item.GetItemID(location)
				if itemId == 15917 then
					local container, slot = location.bagID, location.slotIndex
					if container == 1 and slot == 4 then
						return "Item-4372-0-400000033D4D1C16"
					elseif container == 1 and slot == 5 then
						return "Item-4372-0-400000033D4D1C17"
					elseif container == 4 and slot == 1 then
						return "Item-4372-0-400000033D4D1C20"
					end
				elseif itemId == 15918 then
					return "Item-4372-0-400000033D4D1C18"
				elseif itemId == 15919 then
					return "Item-4372-0-400000033D4D1C19"
				end

				return _GetItemGUID(location)
			end

			C_Item.GetItemID = function(location)
				local container, slot = location.bagID, location.slotIndex
				local itemId = select(10, _G.C_Container.GetContainerItemInfo(container, slot))

				if itemId then
					return tonumber(itemId)
				end

				return _GetItemID(location)
			end

			local _GetInventoryItemTradeTimeRemaining = AddOn.GetInventoryItemTradeTimeRemaining
			AddOn.GetInventoryItemTradeTimeRemaining = function(_, bag, slot)
				if bag == 1 and slot == 4 then -- 15917
					return 1200 -- 20 mins
				elseif bag == 1 and slot == 5 then -- 15917
					return 2400 -- 40 mins
				elseif bag == 3 and slot == 9 then -- 15918
					return 2460 -- 41 mins
				elseif bag == 4 and slot == 1 then -- 15917
					return 4800 -- 1 hr 20 mins
				elseif bag == 4 and slot == 2 then -- 15919
					return 2520 -- 42 mins
				end

				return _GetInventoryItemTradeTimeRemaining(AddOn, bag, slot)
			end

			local function AssertEntryGuid(id, guid)
				local entry = m:GetStorage():Get(id)
				assert(entry)
				assert.equal(guid, entry.guid)
			end

			--SendChatMessage("You receive loot: |cffa335ee|Hitem:15917:::::::::::::::::|h[Item15917]|h|r.", "LOOT")
			m:OnItemReceived({
				id = 1,
				link = '|cffa335ee|Hitem:15917:::::::::::::::::|h[Item15917]|h|r',
				count = 1,
				player = AddOn.player:GetName(),
				when= GetServerTime()
			})
			AssertEntryGuid("255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61", "Item-4372-0-400000033D4D1C16")
			AssertEntryGuid("4a154b00055db56f26ed2249bbfdff40710747efb669aaea4527e77648cc44a6", nil)
			AssertEntryGuid("deb99e6d9ac4e323b91b161229a720ae75e49c7e9af2bf84a341175afde20dae", nil)

			--SendChatMessage("You receive loot: |cffa335ee|Hitem:15917:::::::::::::::::|h[Item15917]|h|r.", "LOOT")
			m:OnItemReceived({
				id = 1,
				link = '|cffa335ee|Hitem:15917:::::::::::::::::|h[Item15917]|h|r',
				count = 1,
				player = AddOn.player:GetName(),
				when = GetServerTime()
			})
			AssertEntryGuid("255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61", "Item-4372-0-400000033D4D1C16")
			AssertEntryGuid("4a154b00055db56f26ed2249bbfdff40710747efb669aaea4527e77648cc44a6", "Item-4372-0-400000033D4D1C17")
			AssertEntryGuid("deb99e6d9ac4e323b91b161229a720ae75e49c7e9af2bf84a341175afde20dae", nil)

			--SendChatMessage("You receive loot: |cffa335ee|Hitem:15917:::::::::::::::::|h[Item15917]|h|r.", "LOOT")
			m:OnItemReceived({
				id = 1,
				link = '|cffa335ee|Hitem:15917:::::::::::::::::|h[Item15917]|h|r',
				count = 1,
				player = AddOn.player:GetName(),
				when = GetServerTime()
			})
			AssertEntryGuid("255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61", "Item-4372-0-400000033D4D1C16")
			AssertEntryGuid("4a154b00055db56f26ed2249bbfdff40710747efb669aaea4527e77648cc44a6", "Item-4372-0-400000033D4D1C17")
			AssertEntryGuid("deb99e6d9ac4e323b91b161229a720ae75e49c7e9af2bf84a341175afde20dae", "Item-4372-0-400000033D4D1C20")

			--SendChatMessage("You receive loot: |cffa335ee|Hitem:15918:::::::::::::::::|h[Item15918]|h|r.", "LOOT")
			m:OnItemReceived({
				id = 1,
				link = '|cffa335ee|Hitem:15918:::::::::::::::::|h[Item15918]|h|r',
				count=1,
				player = AddOn.player:GetName(),
				when = GetServerTime()
			})
			AssertEntryGuid("655e6616e3a818c5568a8bd6d671fef27ba9aaf3c0e64de86569d588203c1bda", "Item-4372-0-400000033D4D1C18")

			--SendChatMessage("You receive loot: |cffa335ee|Hitem:15919:::::::::::::::::|h[Item15919]|h|r.", "LOOT")
			m:OnItemReceived({
				id = 1,
				link = '|cffa335ee|Hitem:15919:::::::::::::::::|h[Item15919]|h|r',
				count = 1,
				player = AddOn.player:GetName(),
				when = GetServerTime()
			})
			AssertEntryGuid("f4056dea1b4cc1f277d8a1a408e8daed2fdb788d5c0c53946ee0b74dc56a0051", "Item-4372-0-400000033D4D1C19")


			finally(function()
				AddOn.TestModeEnabled = _TestModeEnabled
				m.IsHandled = _IsHandled
				AddOn.GetInventoryItemTradeTimeRemaining = _GetInventoryItemTradeTimeRemaining
				C_Container.GetContainerItemInfo = _GetContainerItemInfo
				C_Item.GetItemGUID = _GetItemGUID
				C_Item.GetItemID = _GetItemID
			end)
		end)
	end)
end)