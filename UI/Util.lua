--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
local UIPackage, UIUtilPackage = AddOn.Package('UI'), AddOn.Package('UI.Util')
-- @type UI.Native
local UI = AddOn.Require('UI.Native')

----- @type Models.Award
--local Award = AddOn.Package('Models').Award

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
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 8, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
end

-- creates a tooltip anchored to cursor using the standard GameTooltip
function U.CreateTooltip(...)
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    for i = 1, select("#", ...) do
        GameTooltip:AddLine(select(i, ...),1,1,1)
    end
    GameTooltip:Show()
end

-- hides the tooltip created via CreateTooltip
function U:HideTooltip()
    local tip = self.private:GetHypertip()
    if tip then tip.showing = false end
    GameTooltip:Hide()
end

-- creates and displays a hyperlink tooltip
function U:CreateHypertip(link)
    if Util.Strings.IsEmpty(link) then return end
    -- this is to support shift click comparison on all tooltips
    local function hypertip()
        local tip = UI:NewNamed("GameTooltip", UIParent, AddOn:Qualify("TooltipEventHandler"))
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
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(link)
end

function U.CreateGameTooltip(module, parent)
    local itemTooltip = CreateFrame("GameTooltip", AddOn:Qualify(module, "GameTooltip"), parent, "GameTooltipTemplate")
    itemTooltip:SetClampedToScreen(false)
    itemTooltip:SetScale(parent and parent:GetScale()*.95 or 1)
    return itemTooltip
end

function U.GetClassColorRGB(class)
    local c = U.GetClassColor(class)
    return U.RGBToHex(c.r,c.g,c.b)
end

function U.GetClassColor(class)
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
    return string.format("%02x%02x%02x", math.floor(255*r), math.floor(255*g), math.floor(255*b))
end

function U.RGBToHexPrefix(r, g, b)
    return "|cff" .. U.RGBToHex(r, g, b)
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

function U.SubjectTypeDecorator(subjectType)
    return ColoredDecorator(U.GetSubjectTypeColor(subjectType))
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

local GP = Util.Memoize.Memoize(function() return AddOn:GearPointsModule() end)

function U.AwardReasonDecorator(award)
    return ColoredDecorator(GP():GetAwardColor(award))
end

--[[
local Colors = {
    ResourceTypes = {
        [Award.ResourceType.Ep] = C.Colors.ItemArtifact,
        [Award.ResourceType.Gp] = C.Colors.ItemLegendary,
    },
    SubjectTypes  = {
        [Award.SubjectType.Character] = C.Colors.ItemCommon,
        [Award.SubjectType.Guild]     = C.Colors.ItemUncommon,
        [Award.SubjectType.Raid]      = C.Colors.ItemLegendary,
        [Award.SubjectType.Standby]   = C.Colors.ItemRare,
    },
    ActionTypes   = {
        [Award.ActionType.Add]      = C.Colors.Evergreen,
        [Award.ActionType.Subtract] = C.Colors.PaladinPink,
        [Award.ActionType.Reset]    = C.Colors.RogueYellow,
        [Award.ActionType.Decay]    = C.Colors.Purple,
    }
}

function U.GetSubjectTypeColor(subjectType)
    if Util.Objects.IsString(subjectType) then subjectType = Award.SubjectType[subjectType] end
    return Colors.SubjectTypes[subjectType]
end

function U.GetResourceTypeColor(resourceType)
    if Util.Objects.IsString(resourceType) then resourceType = Award.ResourceType[resourceType] end
    return Colors.ResourceTypes[resourceType]
end

function U.GetActionTypeColor(actionTYpe)
    if Util.Objects.IsString(actionTYpe) then actionTYpe = Award.ActionType[actionTYpe] end
    return Colors.ActionTypes[actionTYpe]
end
--]]

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

function U.ItemIconFn()
    return function(frame, link, texture)
        if not texture and link then
            texture = select(5, GetItemInfoInstant(link))
        end
        frame:SetNormalTexture(texture or "Interface/ICONS/INV_Misc_QuestionMark.png")
        frame:SetScript("OnEnter", function() U:CreateHypertip(link) end)
        frame:SetScript("OnLeave", function() U:HideTooltip() end)
        frame:SetScript("OnClick", function()
            if link and IsModifiedClick() then
                HandleModifiedItemClick(link)
            end
        end)
    end
end