local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibScrollingTable
local ST = AddOn:GetLibrary('ScrollingTable')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
local Package = AddOn.Package('UI.ScrollingTable')
--- @type UI.Util.Attributes
local Attributes = AddOn.Package('UI.Util').Attributes
--- @type UI.Util.Builder
local Builder = AddOn.Package('UI.Util').Builder

--- @class UI.ScrollingTable
local ScrollingTable = AddOn.Instance(
        'UI.ScrollingTable',
        function()
            return {
                Lib = ST
            }
        end
)

--- @class Column
local Column = AddOn.Class('Column', Attributes)
-- ST column entry
function Column:initialize() Attributes.initialize(self, {}) end
function Column:named(name) return self:set('name', name) end
function Column:width(width) return self:set('width', width) end
function Column:sort(sort) return self:set('sort', sort) end
function Column:defaultsort(sort) return self:set('defaultsort', sort) end
function Column:sortnext(next) return self:set('sortnext', next) end
function Column:comparesort(fn) return self:set('comparesort', fn) end
function Column:align(align) return self:set('align', align) end

-- ST column builder, for creating ST columns
--- @class UI.ScrollingTable.ColumnBuilder
local ColumnBuilder = Package:Class('ColumnBuilder', Builder)
ColumnBuilder.Ascending = ST.SORT_ASC
ColumnBuilder.Descending = ST.SORT_DSC
function ColumnBuilder:initialize()
    Builder.initialize(self, {})
    tinsert(self.embeds, 'column')
end
function ColumnBuilder:column(name) return self:entry(Column):named(name) end

---- @class Cell
local Cell = AddOn.Class('Cell', Attributes)
function Cell:initialize(value)
    Attributes.initialize(self, {})
    self:set('value', value)
end

function Cell:color(color) return self:set('color', color) end
function Cell:DoCellUpdate(fn) return self:set('DoCellUpdate', fn) end

--- @class ClassIconCell
local ClassIconCell = AddOn.Class('ClassIconCell', Cell)
function ClassIconCell:initialize(value, class)
    Cell.initialize(self, value)
    self:DoCellUpdate(function(_, frame) UIUtil.ClassIconFn()(frame, class) end)
end

--- @class ClassColoredCell
local ClassColoredCell = AddOn.Class('ClassColoredCell', Cell)
function ClassColoredCell:initialize(value, class)
    Cell.initialize(self, value)
    self:color(UIUtil.GetClassColor(class))
end

--- @class DeleteButtonCell
local DeleteButtonCell = AddOn.Class('DeleteButtonCell', Cell)
function DeleteButtonCell:initialize(fn)
    Cell.initialize(self, nil)
    self:DoCellUpdate(
            function(_, frame, data, _, _, realrow)
                -- todo : prevent repeated textures and OnEnter/OnLeave?
                frame:SetNormalTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Up.png")
                frame:SetScript("OnEnter", function()
                    UIUtil.ShowTooltip(L['double_click_to_delete_this_entry'])
                end)
                frame:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
                frame:SetScript(
                        "OnClick",
                        function()
                            if frame.lastClick and GetTime() - frame.lastClick <= 0.5 then
                                frame.lastClick = nil
                                fn(frame, data, realrow)
                            else
                                frame.lastClick = GetTime()
                            end
                        end
                )
                frame:SetSize(20,20)
            end
    )
end

--- @class ItemIconCell
local ItemIconCell = AddOn.Class('ItemIconCell', Cell)
function ItemIconCell:initialize(link, texture)
    Cell.initialize(self, nil)
    self:DoCellUpdate(function(_, frame) UIUtil.ItemIconFn()(frame, link, texture) end)
end

--- @class TextCell
local TextCell = AddOn.Class('TextCell', Cell)
function TextCell:initialize(fn)
    Cell.initialize(self, nil)
    self:DoCellUpdate(
            function(_, frame, data, _, _, realrow)
                if frame.text:GetFontObject() ~= _G.GameFontNormal then
                    frame.text:SetFontObject("GameFontNormal")
                end

                fn(frame, data, realrow)
            end
    )
end

--- @class UI.ScrollingTable.CellBuilder
local CellBuilder = Package:Class('CellBuilder', Builder)
function CellBuilder:initialize()
    Builder.initialize(self, {})
    tinsert(self.embeds, 'cell')
    tinsert(self.embeds, 'classIconCell')
    tinsert(self.embeds, 'classColoredCell')
    tinsert(self.embeds, 'deleteCell')
    tinsert(self.embeds, 'itemIconCell')
    tinsert(self.embeds, 'textCell')
end

--- @return Cell
function CellBuilder:cell(value)
    return self:entry(Cell, value)
end

--- @return ClassIconCell
function CellBuilder:classIconCell(class)
    return self:entry(ClassIconCell, class, class)
end

--- @return ClassColoredCell
function CellBuilder:classColoredCell(value, class)
    return self:entry(ClassColoredCell, value, class)
end

--- @return DeleteButtonCell
function CellBuilder:deleteCell(fn)
    return self:entry(DeleteButtonCell, fn)
end

--- @return ItemIconCell
function CellBuilder:itemIconCell(link, texture)
    return self:entry(ItemIconCell, link, texture)
end

--- @return TextCell
function CellBuilder:textCell(fn)
    return self:entry(TextCell, fn)
end

local DefaultRowCount, DefaultRowHeight, DefaultHighlight =
    20, 25, { ["r"] = 1.0, ["g"] = 0.9, ["b"] = 0.0, ["a"] = 0.5 }

--- @return UI.ScrollingTable.ColumnBuilder
function ScrollingTable.ColumnBuilder()
    return ColumnBuilder()
end

--- @return UI.ScrollingTable.CellBuilder
function ScrollingTable.CellBuilder()
    return CellBuilder()
end

--- @param attach boolean should the scrolling table be attached to frame at 'st'
--- @return table
function ScrollingTable.New(cols, rows, rowHeight, highlight, frame, attach)
    cols = cols or {}
    rows = rows or DefaultRowCount
    rowHeight = rowHeight or DefaultRowHeight
    highlight = highlight or DefaultHighlight
    attach = Util.Objects.Default(attach, true)

    local parent = (frame and frame.content) and frame.content or frame
    local st = ST:CreateST(cols, rows, rowHeight, highlight, parent)
    if frame and attach then
        st.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
        frame.st = st
        frame:SetWidth(st.frame:GetWidth() + 20)
    end

    return st
end

--- @return function
function ScrollingTable.DoCellUpdateFn(fn)
    local function after(rowFrame, _, _, cols, _, realrow, column, _, table, ...)
        local rowdata = table:GetRow(realrow)
        local celldata = table:GetCell(rowdata, column)

        local highlight
        if type(celldata) == "table" then
            highlight = celldata.highlight
        end

        if table.fSelect then
            if table.selected == realrow then
                table:SetHighLightColor(rowFrame, highlight or cols[column].highlight or rowdata.highlight or table:GetDefaultHighlight())
            else
                table:SetHighLightColor(rowFrame, table:GetDefaultHighlightBlank())
            end
        end
    end

    return function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
        fn(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
        after(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
    end
end

--- @return function
function ScrollingTable.SortFn(valueFn)
    return function(table, rowa, rowb, sortbycol)
        return ScrollingTable.Sort(table, rowa, rowb, sortbycol, valueFn)
    end
end

--- @return boolean
function ScrollingTable.Sort(table, rowa, rowb, sortbycol, valueFn)
    -- Logging:Trace("Sort(%s)", tostring(sortbycol))
    local column = table.cols[sortbycol]
    local row1, row2 = table:GetRow(rowa), table:GetRow(rowb)
    local v1, v2 = valueFn(row1), valueFn(row2)

    if v1 == v2 then
        if column.sortnext then
            local nextcol = table.cols[column.sortnext]
            if nextcol and not(nextcol.sort) then
                if nextcol.comparesort then
                    return nextcol.comparesort(table, rowa, rowb, column.sortnext)
                else
                    return table:CompareSort(rowa, rowb, column.sortnext)
                end
            else
                return false
            end
        else
            return false
        end
    else
        local direction = column.sort or column.defaultsort or ST.SORT_DSC
        if direction == ST.SORT_ASC then
            return v1 < v2
        else
            return v1 > v2
        end
    end
end