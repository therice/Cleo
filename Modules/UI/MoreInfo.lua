--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')

--- @class UI.MoreInfo
local MI = AddOn.Instance(
        'UI.MoreInfo',
        function()
            return {

            }
        end
)

local function Enabled(module)
    local settings = AddOn:ModuleSettings(module)
    return settings and settings.moreInfo or false, settings
end

local function Toggle(module)
    local enabled, settings = Enabled(module)
    enabled = not enabled
    if settings then settings.moreInfo = enabled end
    return enabled
end

local function SetTextures(module, miButton)
    local miEnabled = Enabled(module)
    if miEnabled then
        miButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        miButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    else
        miButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        miButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    end
end

-- fn : function(frame [frame on which widget was embedded], data, row)
function MI.EmbedWidgets(module, frame, fn)
    if not Util.Objects.IsFunction(fn) then error("no function provided for updating more info") end

    local miButton = UI:NewNamed('Button', frame.content, "MoreInfoButton")
    miButton:SetSize(25, 25)
    miButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -20)
    SetTextures(module, miButton)
    miButton:SetScript(
            "OnClick",
            function(button)
                Toggle(module)
                SetTextures(module, button)
                frame.moreInfo.Update()
            end
    )
    miButton:SetScript("OnEnter", function() UIUtil.CreateTooltip(L["click_more_info"]) end)
    miButton:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
    miButton:HideTextures()
    frame.moreInfoBtn = miButton

    local mi = UI:NewNamed('GameTooltip', frame, 'MoreInfo')
    mi.Update = function(...)
        -- no more information widget, cannot update
        if not frame.moreInfo then return end
        local enabled = Enabled(module)
        -- not enabled, just hide and return
        if not enabled then return frame.moreInfo:Hide() end
        fn(frame, ...)
    end

    frame:HookScript("OnHide", function() frame.moreInfo:Hide() end)
    frame.moreInfo = mi
end

function MI.Update(frame, ...)
    if frame and frame.moreInfo then
        frame.moreInfo.Update(...)
    end
end


--- @return boolean, any
function MI.Context(frame, data, row, attr)
    if not frame and frame.moreInfo then
        return false, nil
    end

    local val
    if data and row then
        val = data[row][attr]
        Logging:Trace("Context(%s) : via data[%s] %s", tostring(row), tostring(attr), tostring(val))
    end

    if Util.Objects.IsEmpty(val) and frame.st then
        local selection = frame.st:GetSelection()
        local r = frame.st:GetRow(selection)
        val = r and r[attr] or nil
        Logging:Trace("Context(%s) : via secltion %s", tostring(attr), tostring(val))
    end

    if Util.Objects.IsEmpty(val) then
        frame.moreInfo:Hide()
        return false, nil
    end

    return true, val
end

function MI.UpdateMoreInfoWithLootStats(frame, data, row)
    local proceed, name = MI.Context(frame, data, row, 'name')
    if proceed then
        local class = AddOn:UnitClass(name)
        local c = UIUtil.GetClassColor(class)
        local tip = frame.moreInfo
        tip:SetOwner(frame, "ANCHOR_RIGHT")
        tip:AddLine(AddOn.Ambiguate(name), c.r, c.g, c.b)
        -- todo
        tip:AddLine(L["no_entries_in_loot_history"])
        tip:Show()
        tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
    else
        Logging:Warn("UpdateMoreInfoWithLootStats() : could not get context for update")
    end
end
