--- @type AddOn
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
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type LibCandyBar
local CandyBar = AddOn:GetLibrary('CandyBar')

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

---- @class Cell : UI.Util.Attributes
local Cell = AddOn.Class('Cell', Attributes)
function Cell:initialize(value)
    Attributes.initialize(self, {})
    self:set('value', value)
end

function Cell:color(color) return self:set('color', color) end
function Cell:DoCellUpdate(fn) return self:set('DoCellUpdate', fn) end

--- @class ClassIconCell : Cell
local ClassIconCell = AddOn.Class('ClassIconCell', Cell)
function ClassIconCell:initialize(value, class)
    Cell.initialize(self, value)
    self:DoCellUpdate(function(_, frame) UIUtil.ClassIconFn()(frame, class) end)
end

--- @class ClassColoredCell : Cell
local ClassColoredCell = AddOn.Class('ClassColoredCell', Cell)
function ClassColoredCell:initialize(value, class)
    Cell.initialize(self, value)
    self:color(UIUtil.GetClassColor(class))
end

--- @class DeleteButtonCell : Cell
local DeleteButtonCell = AddOn.Class('DeleteButtonCell', Cell)
function DeleteButtonCell:initialize(fn)
    Cell.initialize(self, nil)
    self:DoCellUpdate(
            function(_, frame, data, _, _, realrow)
                -- todo : prevent repeated textures and OnEnter/OnLeave?
                frame:SetNormalTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Up.png")
                frame:SetScript("OnEnter", function()
                    UIUtil.ShowTooltip(frame, nil, format(L["double_click_to_delete_this_entry"], L["item"]))
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

--- @class ItemIconCell : Cell
local ItemIconCell = AddOn.Class('ItemIconCell', Cell)
function ItemIconCell:initialize(link, texture)
    Cell.initialize(self, nil)
    self:DoCellUpdate(function(_, frame) UIUtil.ItemIconFn()(frame, link, texture) end)
end

--- @class IconCell : Cell
local IconCell = AddOn.Class('IconCell', Cell)
function IconCell:initialize(texture)
    Cell.initialize(self, nil)
    self:DoCellUpdate(function(_, frame) UIUtil.IconFn()(frame,  texture) end)
end

--- @class TextCell : Cell
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

--- @class TimerBarCell : Cell
local TimerBarCell = AddOn.Class('TimerBarCell', Cell)
function TimerBarCell:initialize(width, height, fn)
    Cell.initialize(self, nil)
    self:DoCellUpdate(
        -- rowFrame, cellFrame, data, cols, row, realRow, column, fShow, st, ...
        function(rowFrame, cellFrame, data, cols, row, realRow, ...)
            if not cellFrame.cdb then
                Logging:Debug("TimerBarCell:DoCellUpdate()")
                local countDownBar = CandyBar:New(UI.ResolveTexture("Clean"), width, height)
                countDownBar:SetParent(cellFrame)
                countDownBar:SetColor(C.Colors.Peppermint:GetRGBA())
                countDownBar:SetFont(_G.GameFontNormalSmall:GetFont(), 12, "OUTLINE")
                countDownBar:SetBackgroundColor(0, 0, 0, 0.3)
                countDownBar:SetAllPoints(cellFrame)
                countDownBar:SetTimeVisibility(true)
                countDownBar:Hide()
                cellFrame.cdb = countDownBar
            end

            fn(rowFrame, cellFrame, data, cols, row, realRow, ...)
        end
    )
end

--- @class UI.ScrollingTable.CellBuilder : UI.Util.Builder
local CellBuilder = Package:Class('CellBuilder', Builder)
function CellBuilder:initialize()
    Builder.initialize(self, {})
    tinsert(self.embeds, 'cell')
    tinsert(self.embeds, 'classIconCell')
    tinsert(self.embeds, 'classColoredCell')
    tinsert(self.embeds, 'classAndPlayerIconColoredNameCell')
    tinsert(self.embeds, 'playerIconAndColoredNameCell')
    tinsert(self.embeds, 'playerColoredCell')
    tinsert(self.embeds, 'playerColoredCellOrElse')
    tinsert(self.embeds, 'deleteCell')
    tinsert(self.embeds, 'itemIconCell')
    tinsert(self.embeds, 'iconCell')
    tinsert(self.embeds, 'textCell')
    tinsert(self.embeds, 'timerBarCell')
end

--- @return Cell
function CellBuilder:cell(value)
    return self:entry(Cell, value)
end

function CellBuilder:classAndPlayerIconColoredNameCell(class, player)
    if Util.Objects.IsNumber(class) then
        class = ItemUtil.ClassIdToFileName[class]
    end

    return self:classIconCell(class):classColoredCell(player, class)
end

function CellBuilder:playerIconAndColoredNameCell(player)
    local p = Player:Get(player) or Player.Unknown(player)
    return self:classIconCell(p.class):classColoredCell(p:GetShortName(), p.class)
end

function CellBuilder:playerColoredCell(player)
    local p = Player:Get(player) or Player.Unknown(player)
    return self:classColoredCell(p:GetShortName(), p.class)
end

function CellBuilder:playerColoredCellOrElse(player, other)
    local p = Util.Strings.IsSet(player) and Player:Get(player) or nil
    return (p and not p:IsUNK()) and self:classColoredCell(p:GetShortName(), p.class) or self:classColoredCell(other, "PRIEST")
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

--- @return IconCell
function CellBuilder:iconCell(texture)
    return self:entry(IconCell, texture)
end

--- @return ItemIconCell
function CellBuilder:itemIconCell(link, texture)
    return self:entry(ItemIconCell, link, texture)
end

--- @return TextCell
function CellBuilder:textCell(fn)
    return self:entry(TextCell, fn)
end

--- @return TimerBarCell
function CellBuilder:timerBarCell(width, height, fn)
    return self:entry(TimerBarCell, width, height, fn)
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
--- @return LibScrollingTable.ScrollingTable
function ScrollingTable.New(cols, rows, rowHeight, highlight, frame, attach, multiSelect)
    cols = cols or {}
    rows = rows or DefaultRowCount
    rowHeight = rowHeight or DefaultRowHeight
    highlight = highlight or DefaultHighlight
    attach = Util.Objects.Default(attach, true)

    local parent = (frame and frame.content) and frame.content or frame
    local st = ST:CreateST(cols, rows, rowHeight, highlight, parent, Util.Objects.Default(multiSelect, false))
    if frame and attach then
        st.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
        frame.st = st
        frame:SetWidth(st.frame:GetWidth() + 20)
    end

    ScrollingTable.Decorate(st)

    return st
end

local STBackdrop = {
    bgFile = BaseWidget.ResolveTexture('white'),
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 8, edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local STBackdropBorderColor = C.Colors.ItemPoor

function ScrollingTable.Decorate(st)
    st.ReSkin = function(self)
        self.frame:SetBackdrop(STBackdrop)
        self.frame:SetBackdropColor(0, 0, 0, 1)
        self.frame:SetBackdropBorderColor(0, 0, 0, 1)
        BaseWidget.Border(self.frame, STBackdropBorderColor.r, STBackdropBorderColor.g, STBackdropBorderColor.b, 1, 1, 2, 5)

        local sf = self.scrollframe
        local sb = sf.ScrollBar

        if sf and sb then
            sf.scrolltrough:Hide()
            sf.scrolltrough.background:Hide()
            sf.scrolltroughborder:Hide()
            sf.scrolltroughborder.background:Hide()
            sb:Hide()
            sf:SetScript("OnVerticalScroll", nil)
        end

        self.scrollframe.ScrollBar =
            UI:New('ScrollBar', st.frame)
                :Size(16, 0)
                :Point("TOPRIGHT",-3,-3)
                :Point("BOTTOMRIGHT",-3,3)

        return self
    end

    st.Hook = function(self)
        self.scrollframe.ScrollBar:OnChange(
                function(_, offset)
                    --print("OnChange : " .. tostring(offset))
                    FauxScrollFrame_OnVerticalScroll(self.scrollframe, offset, st.rowHeight, function() st:Refresh() end)
                end
        )

        self.UpdateScrollBar = function(self, ...)
            -- Logging:Debug("SetData(): %d, %d, %d", #st.filtered, st.displayRows, st.rowHeight)
            -- max =  (total height for all rows) - (total height for displayed rows)
            local max = (#self.filtered * self.rowHeight) - (self.displayRows * self.rowHeight)
            local min, cmax =  self.scrollframe.ScrollBar:GetMinMaxValues()
            -- these next two lines are important to make sure we don't "jump" around for current scroll position
            -- should data be updated. keep current location and rely upon user to reposition
            self.scrollframe.ScrollBar:Range(0, math.max(0, max), st.rowHeight, (math.max(0, max) == cmax and min == 0))
            self.scrollframe.ScrollBar:SetValue(self.scrollframe.ScrollBar:GetValue() or 0)
            self.scrollframe.ScrollBar:UpdateButtons()
            if not self.scrollframe.ScrollBar.buttonUp:IsEnabled() and not self.scrollframe.ScrollBar.buttonDown:IsEnabled() then
                self.scrollframe.ScrollBar:Hide()
            else
                self.scrollframe.ScrollBar:Show()
            end
        end

        self._SetData = self.SetData
        self.SetData = function(self, ...)
            self:_SetData(...)
            self:UpdateScrollBar()
        end

        self._DoFilter = self.DoFilter
        self.DoFilter = function(self, ...)
            local result = self:_DoFilter(...)
            self:UpdateScrollBar()
            return result
        end

        return self
    end


    return st:ReSkin():Hook()
end

--- @return function
function ScrollingTable.DoCellUpdateFn(fn)
    local function after(rowFrame, _, _, cols, _, realRow, column, _, table, ...)
        local rowData = table:GetRow(realRow)
        local cellData = table:GetCell(rowData, column)

        local highlight
        if type(cellData) == "table" then
            highlight = cellData.highlight
        end

        if table.fSelect then
            if table.selected == realRow then
                table:SetHighLightColor(rowFrame, highlight or cols[column].highlight or rowData.highlight or table:GetDefaultHighlight())
            else
                table:SetHighLightColor(rowFrame, table:GetDefaultHighlightBlank())
            end
        end
    end

    -- rowFrame, cellFrame, data, cols, row, realRow, column, fShow, table. ...
    return function(...)
        fn(...)
        after(...)
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