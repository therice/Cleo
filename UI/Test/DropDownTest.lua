local AddOn, Util, DD, DDBuilder

describe("Drop Down", function()
    setup(function()
        _, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_DD')
        DD = AddOn.Require('UI.DropDown')
        DDBuilder = AddOn.Package('UI.DropDown').EntryBuilder
        Util = AddOn:GetLibrary('Util')
    end)

    teardown(function()
        After()
    end)

    describe("is", function()
        it("loaded and initialized", function()
            assert(DD)
            assert(DDBuilder)
        end)
    end)

    describe("entry builder", function()
        it("fails on invalid usage", function()
            assert.has.errors(function() DDBuilder():build() end, "must call 'nextlevel' at least once before adding entries or building")
            assert.has.errors(function() DDBuilder():add():build() end, "must call 'nextlevel' at least once before adding entries or building")
            assert.has.errors(function() DDBuilder():nextlevel():build() end, "no entries were added to level 1")
            assert.has.errors(function() DDBuilder():nextlevel():nextlevel():build() end, "no entries were added to level 1")
            assert.has.errors(function() DDBuilder():nextlevel():add():build() end, "no attributes were added to pending entry at level 1 index 1")
            assert.has.errors(function() DDBuilder():nextlevel():add():text('text'):add():build() end, "no attributes were added to pending entry at level 1 index 2")
        end)
        it("builds", function()
            local entries = DDBuilder():nextlevel():add():text('test'):build()
            assert.is.same(
                    entries,
                    { { { text = 'test' } } }
            )


            entries = DDBuilder()
                        :nextlevel()
                            :add():text('test1')
                            :add():text('test2')
                        :build()
            assert.is.same(
                    entries,
                    { { { text = 'test1' }, { text = 'test2' } } }
            )

            entries = DDBuilder()
                        :nextlevel()
                            :add():text('test1')
                            :add():text('test2')
                        :nextlevel()
                            :add():text('test3')
                            :add():text('test4')
                        :build()
            assert.is.same(
                    entries,
                    { { { text = 'test1' }, { text = 'test2' } }, { { text = 'test3' }, { text = 'test4' } } }
            )

            entries = DDBuilder()
                        :nextlevel()
                            :add():text('Adjust'):checkable(false):arrow(true):value('ADJUST')
                        :nextlevel()
                            :add():text(function () return "text1" end):checkable(false):fn(function () return true end)
                            :add():text(function () return "text2" end):checkable(false):fn(function () return false end)
                        :build()
            --{
            --    {
            --        {
            --            notCheckable = true,
            --            text = Adjust,
            --            value = ADJUST,
            --            hasArrow = true
            --        }
            --    },
            --    {
            --        {
            --            notCheckable = true,
            --            text = (fn),
            --            func = (fn)
            --        },
            --        {
            --            notCheckable = true,
            --            text = (fn),
            --            func = (fn)
            --        }
            --    }
            --}

            assert(entries[2][1].text() == 'text1')
            assert(entries[2][1].func() ==  true)
            assert(entries[2][2].text() == 'text2')
            assert(entries[2][2].func() ==  false)
            -- print(Util.Objects.ToString(entries))
        end)
    end)
end)
