--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")

local UIPackage, UIUtilPackage = AddOn.Package('UI'), AddOn.Package('UI.Util')
-- @type UI.Native
local UI = AddOn.Require('UI.Native')
-- @type UI.Native.BaseWidget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget


-- generic build entry attributes
--- @class UI.Util.Attributes
local Attributes = UIUtilPackage:Class('Attributes')
function Attributes:initialize(attrs) self.attrs = attrs end
function Attributes:set(attr, value)
    self.attrs[attr] = value
    return self
end

-- generic builder which handles entries of attributes
--- @class UI.Util.Builder
local Builder = UIUtilPackage:Class('Builder')
function Builder:initialize(entries)
    self.entries = entries
    self.pending = nil
    self.embeds = {
        'build'
    }
end

local function _Embed(builder, entry)
    for _, method in pairs(builder.embeds) do
        entry[method] = function(_, ...)
            return builder[method](builder, ...)
        end
    end
    return entry
end

function Builder:_CheckPending()
    if self.pending then
        self:_InsertPending()
        self.pending = nil
    end
end

function Builder:_InsertPending()
    tinsert(self.entries, self.pending.attrs)
end

function Builder:entry(class, ...)
    self:_CheckPending()
    self.pending = _Embed(self, class(...))
    return self.pending
end

function Builder:build()
    self:_CheckPending()
    return self.entries
end


--- @class UI.Utils
local Private = UIPackage:Class('Utils')
function Private:initialize()
    self.hypertip = nil
end

function Private:GetHypertip(creator)
    if not self.hypertip and creator then
        self.hypertip = creator()
    end
    return self.hypertip
end

--- @class UI.Util
local U = AddOn.Instance(
        'UI.Util',
        function()
            return {
                private = Private()
            }
        end
)

--- @class UI.Decorator
local Decorator = UIPackage:Class('Decorator')
function Decorator:initialize() end
function Decorator:decorate(...) return Util.Strings.Join('', ...) end

--- @class UI.ColoredDecorator
local ColoredDecorator = UIPackage:Class('ColoredDecorator', Decorator)
function ColoredDecorator:initialize(r, g, b)
    Decorator.initialize(self)
    if Util.Objects.IsTable(r) then
        if r.GetRGB then
            self.r, self.g, self.b = r:GetRGB()
        elseif r.r and r.g and r.b then
            self.r, self.g, self.b = r.r, r.g, r.b
        else
            self.r, self.g, self.b = unpack(r)
        end
    else
        self.r, self.g, self.b = r, g, b
    end

    --Logging:Trace("%s, %s, %s", tostring(self.r), tostring(self.g), tostring(self.b))
end

function ColoredDecorator:decorate(...)
    return U.RGBToHexPrefix(self.r, self.g, self.b) .. ColoredDecorator.super:decorate(...) .. "|r"
end

--- Used to decorate LibDialog Popups
function U.DecoratePopup(frame)
    -- basic fixup for the library provided frame
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetDontSavePosition(true)
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- change the border and backdroup
    frame.border = BaseWidget.Shadow(frame, 20)
    frame:SetBackdrop({bgFile=BaseWidget.ResolveTexture('white')})
    frame:SetBackdropColor(0.05,0.05,0.07,0.98)

    -- replace the close button
    frame.close_button:Hide()
    frame.close = UI:New('ButtonClose', frame)
    frame.close:SetSize(18,18)
    frame.close:SetPoint("TOPRIGHT",-1,0)
    frame.close:SetScript("OnClick", function() frame.close_button:Click() end)

    -- replace the other buttons
    for buttonIndex = 1, #frame.buttons do
        local delegate, replacement = frame.buttons[buttonIndex], nil
        if not frame.replacement_buttons then
            frame.replacement_buttons = {}
        end

        if frame.replacement_buttons[buttonIndex] then
            replacement = frame.replacement_buttons[buttonIndex]
        else
            replacement = UI:NewNamed("Button", delegate:GetParent(), delegate:GetName() .. "_replacement")
            frame.replacement_buttons[buttonIndex] = replacement
        end

        replacement:SetText(delegate:GetText())
        replacement:SetSize(delegate:GetSize())
        replacement:SetPoint("TOPLEFT", delegate, "TOPLEFT")
        replacement:SetPoint("BOTTOMRIGHT", delegate, "BOTTOMRIGHT")
        replacement:SetScript("OnClick", function() delegate:Click() end)
        delegate:Hide()
    end
end

local GameTooltip = _G.GameTooltip

function U.ShowTooltip(owner, anchor, title, ...)
    local x, y = 0, 0
    owner = owner or UIParent

    if Util.Objects.IsTable(anchor) then
        x, y = anchor[2], anchor[3]
        anchor = anchor[1] or "ANCHOR_RIGHT"
    elseif not anchor then
        anchor = "ANCHOR_RIGHT"
    end

    GameTooltip:SetOwner(owner, anchor, x, y)
    if Util.Strings.IsSet(title) then
        GameTooltip:SetText(title)
    end

    for i = 1, select("#", ...) do
        local line = select(i, ...)
        if Util.Objects.IsTable(line) then
            GameTooltip:AddLine(unpack(line))
        else
            GameTooltip:AddLine(line,1,1,1)
        end
    end

    GameTooltip:Show()
end

function U.ShowTooltipLines(...)
    U.ShowTooltip(UIParent, "ANCHOR_RIGHT", nil, ...)
end

-- hides the tooltip created via CreateTooltip
function U:HideTooltip()
    local tip = self.private:GetHypertip()
    if tip then tip.showing = false end
    GameTooltip:Hide()
end

function U.Link(at, data, ...)
    if not data then return end
    local x = at:GetRight()
    if x >= (GetScreenWidth() / 2) then
        GameTooltip:SetOwner(at, "ANCHOR_LEFT")
    else
        GameTooltip:SetOwner(at, "ANCHOR_RIGHT")
    end
    GameTooltip:SetHyperlink(data,...)
    GameTooltip:Show()
end

-- creates and displays a hyperlink tooltip
-- todo : change this ala Link()
function U:CreateHypertip(link, owner, anchor)
    if Util.Strings.IsEmpty(link) then return end

    -- this is to support shift click comparison on all tooltips
    local function hypertip()
        local tip = U.CreateGameTooltip("TooltipEventHandler", owner or UIParent)
        tip:RegisterEvent("MODIFIER_STATE_CHANGED")
        tip:SetScript("OnEvent",
                function(_, event, arg)
                    local ht = self.private:GetHypertip()
                    if ht.showing and event == "MODIFIER_STATE_CHANGED" and (arg == "LSHIFT" or arg == "RSHIFT") and ht.link then
                        self:CreateHypertip(ht.link)
                    end
                end
        )
        return tip
    end

    local tooltip = self.private:GetHypertip(hypertip)
    tooltip.showing = true
    tooltip.link = link

    GameTooltip:SetOwner(owner or UIParent, anchor or "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
end

function U.CreateGameTooltip(module, parent)
    return UI:NewNamed('GameTooltip', parent, AddOn:Qualify(module, "GameTooltip"))
end

function U.SetScale(widget, scale, topRight)
    topRight = Util.Objects.Default(topRight, false)

    local l = topRight and widget:GetRight() or widget:GetLeft()
    local t = widget:GetTop()
    local s = widget:GetScale()

    if not l or not t or not s then return end

    s = scale / s

    --Logging:Trace("SetScale() : l=%.2f, t=%.2f, s =%.2f, scale=%.2f", l, t, s, scale)

    widget:SetScale(scale)

    local script = widget:GetScript("OnDragStop")
    widget:ClearAllPoints()
    widget:SetPoint(topRight and "TOPRIGHT" or "TOPLEFT", UIParent, "BOTTOMLEFT", l / s, t / s)
    if script then script(widget) end
end

function U.GetClassColorRGB(class)
    local c = U.GetClassColor(class)
    return U.RGBToHex(c.r,c.g,c.b)
end

function U.GetClassColor(class)
    class = Util.Objects.IsNumber(class) and ItemUtil.ClassIdToFileName[class] or class
    local color = class and RAID_CLASS_COLORS[class:upper()] or nil
    -- if class not found, return epic color.
    if not color then
        return {r=1,g=1,b=1,a=1}
    end
    color.a = 1.0
    return color
end

function U.GetPlayerClassColor(name)
    return U.GetClassColor(AddOn:UnitClass(name))
end

function U.RGBToHex(r,g,b)
    return string.format("%02X%02X%02X", math.floor(255*r), math.floor(255*g), math.floor(255*b))
end

function U.RGBToHexPrefix(r, g, b)
    return "|cFF" .. U.RGBToHex(r, g, b)
end

function U.ColorWithAlpha(color, alpha)
    local rgba = Util.Tables.New(color:GetRGB())
    rgba[4] = alpha
    return rgba
end

function U.ColoredDecorator(...)
    return ColoredDecorator(...)
end

function U.ClassColorDecorator(class)
    return ColoredDecorator(U.GetClassColor(class))
end

function U.PlayerClassColorDecorator(name)
    return ColoredDecorator(U.GetPlayerClassColor(name))
end

function U.ResourceTypeDecorator(resourceType)
    return ColoredDecorator(U.GetResourceTypeColor(resourceType))
end

function U.ActionTypeDecorator(actionType)
    return ColoredDecorator(U.GetActionTypeColor(actionType))
end

function U.ItemQualityDecorator(rarity)
    return ColoredDecorator(GetItemQualityColor(rarity))
end

function U.ClassIconFn()
    return function(frame, class)
        local coords = CLASS_ICON_TCOORDS[Util.Strings.Upper(class)]
        if coords then
            frame:SetNormalTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            frame:GetNormalTexture():SetTexCoord(unpack(coords))
        else
            frame:SetNormalTexture("Interface/ICONS/INV_Misc_QuestionMark.png")
        end
    end
end

function U.IconFn()
    return function(frame, texture)
        if texture then
            frame:SetNormalTexture(texture)
            frame:GetNormalTexture():SetTexCoord(0,1,0,1)
        else
            frame:SetNormalTexture(nil)
        end
    end
end

function U.ItemIconFn()
    return function(frame, link, texture)
        if not texture and link then
            texture = select(5, GetItemInfoInstant(link))
        end
        frame:SetNormalTexture(texture or "Interface/ICONS/INV_Misc_QuestionMark.png")
        if link then
            frame:SetScript("OnEnter", function() U:CreateHypertip(link, frame, "ANCHOR_RIGHT") end)
            frame:SetScript("OnLeave", function() U:HideTooltip() end)
            frame:SetScript("OnClick", function()
                if IsModifiedClick() then
                    HandleModifiedItemClick(link)
                end
            end)
        else
            frame:SetScript("OnEnter", nil)
            frame:SetScript("OnLeave", nil)
            frame:SetScript("OnClick", nil)
        end
    end
end

--- @type Models.Audit.TrafficRecord
local TrafficRecord = AddOn.ImportPackage('Models.Audit').TrafficRecord

local Colors = {
    ResourceTypes = {
        [TrafficRecord.ResourceType.Configuration]  = C.Colors.Salmon,
        [TrafficRecord.ResourceType.List]           = C.Colors.MageBlue,
    },
    ActionTypes   = {
        [TrafficRecord.ActionType.Create]   = C.Colors.Evergreen,
        [TrafficRecord.ActionType.Delete]   = C.Colors.DeathKnightRed,
        [TrafficRecord.ActionType.Modify]   = C.Colors.RogueYellow,
    }
}

function U.GetResourceTypeColor(resourceType)
    if Util.Objects.IsString(resourceType) then resourceType = TrafficRecord.ResourceType[resourceType] end
    return Colors.ResourceTypes[resourceType]
end

function U.GetActionTypeColor(actionTYpe)
    if Util.Objects.IsString(actionTYpe) then actionTYpe = TrafficRecord.ActionType[actionTYpe] end
    return Colors.ActionTypes[actionTYpe]
end

