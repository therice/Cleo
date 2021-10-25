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
--- @type UI.Widgets.ButtonIcon
local ButtonIcon = AddOn.ImportPackage('UI.Widgets').ButtonIcon

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


local TextureRef, TextureMd =
    ButtonIcon.DefaultTexture, ButtonIcon.TypeMetadata[ButtonIcon.Type.DotDotDot]
local ShowColor, ShowColorHL =
    UIUtil.ColorWithAlpha(C.Colors.MageBlue, 0.9), UIUtil.ColorWithAlpha(C.Colors.MageBlue, 1.0)
local HideColor, HideolorHL =
    UIUtil.ColorWithAlpha(C.Colors.Salmon, 0.9), UIUtil.ColorWithAlpha(C.Colors.Salmon, 1.0)

local function SetTextures(module, miButton)
    if not miButton.showTexture then
        miButton.showTexture = miButton:CreateTexture(nil,"ARTWORK")
        miButton.showTexture:SetTexture(TextureRef)
        miButton.showTexture:SetPoint("TOPLEFT")
        miButton.showTexture:SetPoint("BOTTOMRIGHT")
        miButton.showTexture:SetVertexColor(unpack(ShowColor))
        miButton.showTexture:SetTexCoord(unpack(TextureMd[1]))

        miButton.showTextureHL = miButton:CreateTexture(nil,"ARTWORK")
        miButton.showTextureHL:SetTexture(TextureRef)
        miButton.showTextureHL:SetPoint("TOPLEFT")
        miButton.showTextureHL:SetPoint("BOTTOMRIGHT")
        miButton.showTextureHL:SetVertexColor(unpack(ShowColorHL))
        miButton.showTextureHL:SetTexCoord(unpack(TextureMd[1]))
    end

    if not miButton.hideTexture then
        miButton.hideTexture = miButton:CreateTexture(nil,"ARTWORK")
        miButton.hideTexture:SetTexture(TextureRef)
        miButton.hideTexture:SetPoint("TOPLEFT")
        miButton.hideTexture:SetPoint("BOTTOMRIGHT")
        miButton.hideTexture:SetVertexColor(unpack(HideColor))
        miButton.hideTexture:SetTexCoord(unpack(TextureMd[1]))

        miButton.hideTextureHL = miButton:CreateTexture(nil,"ARTWORK")
        miButton.hideTextureHL:SetTexture(TextureRef)
        miButton.hideTextureHL:SetPoint("TOPLEFT")
        miButton.hideTextureHL:SetPoint("BOTTOMRIGHT")
        miButton.hideTextureHL:SetVertexColor(unpack(HideolorHL))
        miButton.hideTextureHL:SetTexCoord(unpack(TextureMd[1]))
    end

    local miEnabled = Enabled(module)
    if miEnabled then
        miButton:SetNormalTexture(miButton.hideTexture)
        miButton:SetHighlightTexture(miButton.hideTextureHL)
        miButton:SetPushedTexture(miButton.showTexture)
    else
        miButton:SetNormalTexture(miButton.showTexture)
        miButton:SetHighlightTexture(miButton.showTextureHL)
        miButton:SetPushedTexture(miButton.hideTexture)
    end
end

-- fn : function(frame [frame on which widget was embedded], data, row)
function MI.EmbedWidgets(module, frame, fn)
    if not Util.Objects.IsFunction(fn) then error("no function provided for updating more info") end

    -- todo : skin this button
    local miButton = UI:New('Button', frame.content or frame)
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
    miButton:SetScript("OnEnter", function(self) UIUtil.ShowTooltip(self, nil, L["click_more_info"]) end)
    miButton:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
    miButton:HideTextures()
    frame.moreInfoBtn = miButton

    local mi = UI:New('GameTooltip', frame.content or frame)
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
        Logging:Trace("Context(%s) : via selection %s", tostring(attr), tostring(val))
    end

    if Util.Objects.IsNil(val) then
        Logging:Trace("Context() : hiding")
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

        local stats = AddOn:LootAuditModule():GetStatistics()
        if stats and stats:Get(name) then
            local playerEntry = stats:Get(name)
            local playerStats = playerEntry:GetTotals()

            tip:AddLine(" ")
            tip:AddLine(L["latest_items_won"])
            for _, v in pairs(playerEntry.awards) do
                -- Logging:Trace("%s", Util.Objects.ToString(v))
                local item, text = v[1], v[2]
                tip:AddDoubleLine(item, text, 0, 0, 0, 1, 1, 1)
            end
            tip:AddLine(" ")
            tip:AddLine(_G.TOTAL)
            for _, v in pairs(playerStats.responses) do
                local text, count, id = v[1], v[2], v[3]
                local r, g, b = AddOn:GetResponseColor(id)
                tip:AddDoubleLine(text, count, r, g, b, 1, 1, 1)
            end
        else
            tip:AddLine(L["no_entries_in_loot_history"])
        end

        tip:Show()
        tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
    else
        Logging:Warn("UpdateMoreInfoWithLootStats() : could not get context for update")
    end
end
