local AddOnName, AddOn, Util


describe("LootSession", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootSession')
        Util = AddOn:GetLibrary('Util')
        AddOnLoaded(AddOnName, true)
    end)

    teardown(function()
        After()
    end)

    describe("lifecycle", function()
        teardown(function()
            AddOn:YieldModule("LootSession")
        end)

        it("is disabled on startup", function()
            local standings = AddOn:LootSessionModule()
            assert(standings)
            assert(not standings:IsEnabled())
        end)
        it("can be enabled", function()
            AddOn:ToggleModule("LootSession")
            local standings = AddOn:LootSessionModule()
            assert(standings)
            assert(standings:IsEnabled())
        end)
        it("can be disabled", function()
            AddOn:ToggleModule("LootSession")
            local standings = AddOn:LootSessionModule()
            assert(standings)
            assert(not standings:IsEnabled())
        end)
    end)

    describe("operations", function()
        local module

        before_each(function()
            AddOn:ToggleModule("LootSession")
            module = AddOn:LootSessionModule()
            PlayerEnteredWorld()
            GuildRosterUpdate()
        end)

        teardown(function()
            AddOn:ToggleModule("LootSession")
            module = nil
        end)

        it("fails to start when loading items", function()
            module.loadingItems = true
            module:Start()
        end)
        it("fails to start without loot table", function()
            module.loadingItems = false
            module:Start()
        end)
        it("fails to start in combat lockdown", function()
            module.loadingItems = false
            module.ml.lootTable = {1, 2, 3}
            _G.InCombatLockdown = function() return true end
            module:Start()
        end)
        it("disables after starting", function()
            module.loadingItems = false
            module.ml.lootTable = {1, 2, 3}
            _G.InCombatLockdown = function() return false end
            module.ml.StartSession = function() end
            module:Start()
            assert(not module:IsEnabled())
        end)
        it("disables after cacnel", function()
            module:Enable()
            assert(module:IsEnabled())
            module:Cancel()
            assert(not module:IsEnabled())
        end)
    end)
end)