--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util = AddOn:GetLibrary('Util')
--- @type LibWindow
local Window = AddOn:GetLibrary('Window')
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
local Frame = AddOn.Package('UI.Widgets'):Class('Frame', BaseWidget)

--- Creates a standard frame with title, minimizing, positioning and scaling supported
--		Adds Minimize(), Maximize() and IsMinimized() functions on the frame, and registers it for hide on combat
--		SetWidth/SetHeight called on frame will also be called on frame.content
--		Minimizing is done by double clicking the title, but the returned frame and frame.title is NOT hidden
--      Only frame.content is minimized, so put children there for minimize support
--
-- @param name global name of the frame
-- @param module name of the module (used for lib-window-1.1 config in DB).
-- @param title the title text. (if nil, not title will be shown)
-- @param width width of the frame, defaults to 450
-- @param height height of the frame, defaults to 325
function Frame:initialize(parent, name, module, title, width, height)
    BaseWidget.initialize(self, parent, name)
    self.module = module
    self.title = title
    self.width = width
    self.height = height
end

function Frame:Create()
    local f = CreateFrame("Frame", AddOn:Qualify(self.name), self.parent, BackdropTemplateMixin and "BackdropTemplate")

    f.GetStorage = function()
        local path = 'ui.'  .. (self.name and (self.module .. '_' .. self.name) or self.module)
        local storage = Util.Tables.Get(AddOn.db.profile, path) or {}
        --Logging:Trace('Create() : storage at %s is %s', path, Util.Objects.ToString(storage))
        return storage
    end

    local storage = f:GetStorage()
    f:Hide()
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetWidth(self.width or 450)
    f:SetHeight(self.height or 325)
    f:SetScale(storage.scale)
    Window:Embed(f)
    f:RegisterConfig(storage)
    f:RestorePosition()
    f:MakeDraggable()
    f:SetScript("OnMouseWheel", function(f,delta) if IsControlKeyDown() then Window.OnMouseWheel(f,delta) end end)
    f:SetScript("OnKeyDown",
            function(self, key)
                -- Logging:Trace("OnKeyDown(%s) : %s", self:GetName(), key)
                if key == "ESCAPE" then
                    self:SetPropagateKeyboardInput(false)

                    -- Attempt to locate the appropriate button and click it, one of
                    --      close
                    --      abort
                    --      cancel
                    local function closeOrCancel()
                        local button
                        if self.close then
                            button = self.close
                        elseif self.abort then
                            button = self.abort
                        elseif self.cancel then
                            button = self.cancel
                        end

                        if button and button:IsShown() then
                            --Logging:Trace("OnKeyDown(): Closing via %s", button:GetName())
                            button:Click()
                            return true
                        else
                            return false
                        end
                    end

                    if not closeOrCancel() then
                        --Logging:Trace("OnKeyDown(): Closing via Hide()")
                        self:Hide()
                    end
                else
                    self:SetPropagateKeyboardInput(true)
                end
            end
    )

    self:CreateTitle(f)
    self:CreateContent(f)
    self:EmbedScalingSupport(f)
    self:CreateButtons(f)
    self:EmbedMinimizeSupport(f)
    NativeUI:TrackFrame(f)

    BaseWidget.Mod(
        f,
        'CreateShadow', function(self, ...) self.border = BaseWidget.Shadow(self, ...) end,
        'ShadowInside', BaseWidget.ShadowInside
    )

    return f
end

function Frame:CreateTitle(f)
    if not Util.Objects.IsEmpty(self.title) then
        local tf = CreateFrame("Frame", AddOn:Qualify(self.name, 'Title'), f, BackdropTemplateMixin and "BackdropTemplate")
        tf:SetToplevel(true)
        tf:SetBackdrop({
            bgFile = BaseWidget.ResolveTexture('white'),
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 8, edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        tf:SetBackdropColor(0, 0, 0, 1)
        tf:SetBackdropBorderColor(0, 0, 0, 1)
        tf:SetHeight(22)
        tf:EnableMouse()
        tf:SetMovable(true)
        tf:SetWidth(f:GetWidth() * 0.75)
        tf:SetPoint("CENTER", f, "TOP", 0, -1)
        tf:SetScript("OnMouseDown", function(self) self:GetParent():StartMoving() end)
        tf:SetScript("OnMouseUp", function(self)
            local frame = self:GetParent()
            frame:StopMovingOrSizing()
            if frame:GetScale() and frame:GetLeft() and frame:GetRight() and frame:GetTop() and frame:GetBottom() then
                frame:SavePosition()
            end
            if self.lastClick and GetTime() - self.lastClick <= 0.5 then
                self.lastClick = nil
                if frame.minimized then frame:Maximize() else frame:Minimize() end
            else
                self.lastClick = GetTime()
            end
        end)

        local text = tf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", tf, "CENTER")
        text:SetText(self.title)
        tf.text = text
        f.title = tf
        f.title:SetPoint("CENTER", f, "TOP", 0, 10)
    end
end

function Frame:CreateContent(f)
    local c = CreateFrame("Frame", AddOn:Qualify(self.name, 'Content'), f, BackdropTemplateMixin and "BackdropTemplate")
    c:SetBackdrop({
        bgFile = BaseWidget.ResolveTexture('white'),
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 8, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    c:SetBackdropColor(0, 0, 0, 1)
    c:SetBackdropBorderColor(0, 0, 0, 1)
    c:EnableMouse(true)
    c:SetWidth(self.width or 450)
    c:SetHeight(self.height or 325)
    c:SetPoint("TOPLEFT")
    c:SetScript("OnMouseDown", function(self) self:GetParent():StartMoving() end)
    c:SetScript("OnMouseUp", function(self)
        local frame = self:GetParent()
        frame:StopMovingOrSizing()
        if frame:GetScale() and frame:GetLeft() and frame:GetRight() and frame:GetTop() and frame:GetBottom() then
            frame:SavePosition()
        end
    end)

    f:HookScript("OnSizeChanged", function(self, w, h)
        self.content:SetWidth(w)
        self.content:SetHeight(h)
    end)
    f.content = c
end

local _ScalingPrototype = {
    GetFrameScale = function(self)
        local storage = self:GetStorage()
        local scale = storage.scale or 1.0
        return max(min(scale, 2.0), 0.5)
    end,
    SetFrameScale = function(self, scale)
        local storage = self:GetStorage()
        storage.scale = scale
    end,

}

local ScaleX, ScaleY = -30, -5

function Frame:EmbedScalingSupport(f)
    for field, obj in pairs(_ScalingPrototype) do
        f[field] = obj
    end

    local parent = f.content or f

    local scaleSlider = NativeUI:New('Slider', parent, true):_Size(70,8):Point("TOPRIGHT", ScaleX, ScaleY):Range(50,200,true):NoValueOnTooltip()
    scaleSlider.RefreshTooltip = function(self, reload)
        self:Tooltip(L["ui_scale"], Util.Numbers.Round(f:GetFrameScale() * 100) .. "%", L["right_click_reset"])
        if reload then
            self:ReloadTooltip()
        end
    end

    scaleSlider:OnShow(
        function(self)
            Logging:Trace("OnShow()")

            local scale = f:GetFrameScale()
            self:SetTo(scale * 100):Scale(1 / scale)
                :OnChange(
                function(self, event)
                    Logging:Trace("OnChange()")

                    if self.disable then
                        self:SetTo(100)
                        self:RefreshTooltip()
                        return
                    end

                    event = Util.Numbers.Round2(event)
                    local newScale = event/100
                    -- Logging:Trace("SetScale(%.2f) : %.2f", event, newScale)
                    f:SetFrameScale(newScale)
                    UIUtil.SetScale(f, newScale, true)
                    self:SetScale(1 / newScale)
                    self:RefreshTooltip(true)
                end
            )

            self:SetScript("OnShow",nil)
            self:RefreshTooltip()
            self:Point("TOPRIGHT", ScaleX * f:GetFrameScale(), ScaleY)
            f:SetScale(f:GetFrameScale())
        end,
        true
    )
    scaleSlider:SetScript(
        "OnMouseDown",
        function(self,button)
            if Util.Strings.Equal(button, C.Buttons.Right) then
                self:SetTo(100)
                self.disable = true
            end
        end
    )
    scaleSlider:SetScript(
        "OnMouseUp",
        function(self,button)
            if Util.Strings.Equal(button, C.Buttons.Right) then
                self.disable = nil
            end
            self:Point("TOPRIGHT",-45 * f:GetFrameScale(), -5)
        end
    )
    f.scale = scaleSlider
end

function Frame:CreateButtons(f)
    local parent = f.content or f
    local target = f.content and f.content:GetParent() or f

    local close = NativeUI:New('ButtonClose', parent)
    close:SetSize(18,18)
    close:SetPoint("TOPRIGHT",-1,0)
    close:SetScript("OnClick", function() target:Hide() end)
    f.close = close
end

local _MinimizePrototype = {
    minimized = false,
    IsMinimized = function(f)
        return f.minimized
    end,
    Minimize = function(f)
        if not f.minimized then
            if f.content then f.content:Hide() else f:Hide() end
            if f.border then f.border:Hide() end
            if f.HideShadow then f:HideShadow() end
            f.minimized = true
        end
    end,
    Maximize = function(f)
        if f.minimized then
            if f.content then f.content:Show() else f:Show() end
            if f.border then f.border:Show() end
            if f.ShowShadow then f:ShowShadow() end
            f.minimized = false
        end
    end
}

function Frame:EmbedMinimizeSupport(f)
    for field, obj in pairs(_MinimizePrototype) do
        f[field] = obj
    end
end

NativeUI:RegisterWidget('Frame', Frame)