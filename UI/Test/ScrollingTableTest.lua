local AddOn, ST, STColumnBuilder, STCellBuilder, Util

describe("Scrolling Table", function()
    setup(function()
        _, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_ST')
        ST = AddOn.Require('UI.ScrollingTable')
        STColumnBuilder, STCellBuilder =
            AddOn.Package('UI.ScrollingTable').ColumnBuilder,
            AddOn.Package('UI.ScrollingTable').CellBuilder
        Util = AddOn:GetLibrary('Util')
    end)

    teardown(function()
        After()
    end)

    describe("is", function()
        it("loaded and initialized", function()
            assert(ST)
            assert(STColumnBuilder)
            assert(STCellBuilder)
        end)
    end)

    describe("column builder", function()
        it("builds", function()
            local cols =
                STColumnBuilder()
                    :column(""):width(20)
                    :column("name"):width(120):defaultsort(STColumnBuilder.Ascending)
                    :column("rank"):width(120):defaultsort(STColumnBuilder.Ascending):sortnext(6)
                    :column("ep"):width(60):defaultsort(STColumnBuilder.Descending):sortnext(5)
                    :column("gp"):width(60):defaultsort(STColumnBuilder.Descending):sortnext(2)
                    :column("pr"):width(60):sort(STColumnBuilder.Descending):sortnext(4)
                    :build()
            assert.is.same(
                    cols,
                    {
                        {name = '', width = 20},
                        {defaultsort = 1, name = 'name', width = 120},
                        {name = 'rank', sortnext = 6, defaultsort = 1, width = 120},
                        {sortnext = 5, defaultsort = 2, name = 'ep', width = 60},
                        {sortnext = 2, defaultsort = 2, name = 'gp', width = 60},
                        {sortnext = 4, sort = 2, name = 'pr', width = 60}
                    }
            )
        end)
    end)
    describe("cell builder", function()
        it("builds", function()
            local cells =
                STCellBuilder()
                    :cell(1)
                    :classColoredCell('value', 'rogue')
                    :build()

            assert.is.same(
                    cells,
                    {
                        {value = 1},
                        {value = 'value', color = {a = 1, b = 1, g = 1, r = 1}}
                    }
            )

            local f = CreateFrame('frame')
            cells = STCellBuilder():classIconCell('warlock'):build()
            -- CLASS_ICON_TCOORDS is empty in our test framework
            cells[1].DoCellUpdate(_, f)
            assert.equal(f:GetNormalTexture().texture, 'Interface/ICONS/INV_Misc_QuestionMark.png')
        end)
    end)
end)