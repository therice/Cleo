local _, AddOn = ...
local Logging, Util, Window = AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util'), AddOn:GetLibrary('Window')
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @type UI.Widgets.ButtonIcon
local ButtonIcon = AddOn.ImportPackage('UI.Widgets').ButtonIcon
local Frame = AddOn.Package('UI.Widgets'):Class('Frame', BaseWidget)

--- Creates a standard frame with title, minimizing, positioning and scaling supported
--		Adds Minimize(), Maximize() and IsMinimized() functions on the frame, and registers it for hide on combat
--		SetWidth/SetHeight called on frame will also be called on frame.content
--		Minimizing is done by double clicking the title, but the returned frame and frame.title is NOT hidden
--      Only frame.content is minimized, so put children there for minimize support
--
-- @param name global name of the frame
-- @param module name of the module (used for lib-window-1.1 config in DB).
-- @param title the title text.
-- @param width width of the frame, defaults to 450
-- @param height height of the frame, defaults to 325
-- @param hookConfig should the frame be hooked into respecting configuration frame (hide/show if present). defaults to true
function Frame:initialize(parent, name, module, title, width, height, hookConfig)
    BaseWidget.initialize(self, parent, name)
    self.module = module
    self.title = title
    self.width = width
    self.height = height
    self.hookConfig = hookConfig
end

function Frame:Create()
    local f = CreateFrame("Frame", d, self.parent)
    local hookIt = Util.Objects.IsNil(self.hookConfig) and true or self.hookConfig
    local storage = { }
    if self.module and AddOn.db then
        local path = 'ui.'  .. (self.name and (self.module .. '_' .. self.name) or self.module)
        storage = Util.Tables.Get(AddOn.db.profile, path) or {}
        Logging:Debug('Create() : storage at %s is %s', path, Util.Objects.ToString(storage))
    end

    f:Hide()
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetWidth(self.width or 450)
    f:SetHeight(self.height or 325)
    f:SetScale(storage.scale or 1.1)
    Window:Embed(f)
    f:RegisterConfig(storage)
    f:RestorePosition()
    f:MakeDraggable()
    f:SetScript("OnMouseWheel", function(f,delta) if IsControlKeyDown() then Window.OnMouseWheel(f,delta) end end)
    f:HookScript("OnShow", function() f.restoreConfig = hookIt and AddOn.HideConfig() end)
    f:HookScript("OnHide",
                 function()
                     if f.restoreConfig then
                         AddOn.ShowConfig()
                         f.restoreConfig = false
                     end
                 end
    )

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
                            Logging:Trace("OnKeyDown(): Closing via %s", button:GetName())
                            button:Click()
                            return true
                        else
                            return false
                        end
                    end

                    if not closeOrCancel() then
                        Logging:Trace("OnKeyDown(): Closing via Hide()")
                        self:Hide()
                    end
                else
                    self:SetPropagateKeyboardInput(true)
                end
            end
    )

    self:CreateTitle(f)
    self:CreateContent(f)
    self:CreateButtons(f)
    self.EmbedMinimizeSupport(f)
    NativeUI:TrackFrame(f)
    return f
end

function Frame:CreateTitle(f)
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

function Frame:CreateButtons(f)
    local close = NativeUI:New('ButtonIcon', f.content, ButtonIcon.Type.Close)
    close:SetSize(18,18)
    close:SetPoint("TOPRIGHT",-1,0)
    close:SetScript("OnClick", function() f.content:GetParent():Hide() end)
    f.close = close
end

local _MinimizePrototype = {
    minimized = false,
    IsMinimized = function(f)
        return f.minimized
    end,
    Minimize = function(f)
        if not f.minimized then
            f.content:Hide()
            f.minimized = true
        end
    end,
    Maximize = function(f)
        if f.minimized then
            f.content:Show()
            f.minimized = false
        end
    end
}

function Frame.EmbedMinimizeSupport(f)
    for field, obj in pairs(_MinimizePrototype) do
        f[field] = obj
    end
end

NativeUI:RegisterWidget('Frame', Frame)