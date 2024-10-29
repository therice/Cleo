local frames, FrameClass = {}, {}
FrameClass.__index = FrameClass

local id = 0

local function nextid()
    id = id + 1
    return id
end

function FrameClass:New(name)
    if name then
        assert(name and type(name) == 'string')
    end

    local self = setmetatable({}, FrameClass)
    self.events = {}
    self.scripts = {}
    self.timer = GetTime()
    self.fname = name
    self.isShow = true
    self.parent = nil
    self.text = nil
    self.type = nil
    self.textures = {}
    self.id = nextid()
    self[0] = "(userdata)"
    return self

end

function FrameClass:IsObjectType(type)
    return self.type == type
end

function FrameClass:SetID(id)
    self.id = id
end

function FrameClass:GetID()
    return self.id
end

function FrameClass:SetToplevel(top)

end


function FrameClass:GetObjectType()
    return "Frame"
end

function FrameClass:SetMovable()

end

function FrameClass:RegisterForDrag()

end

function FrameClass:RegisterForClicks()

end

function FrameClass:SetText(text)
    self.text = text
end

function FrameClass:SetTextColor()

end

function FrameClass:HasScript(script)
    return self.scripts[script] ~= nil
end

function FrameClass:SetScript(script,handler)
    -- print('SetScript -> ' .. tostring(script) .. ',' .. tostring(handler))
    self.scripts[script] = handler
end

function FrameClass:HookScript(scriptType, handler)
    -- print('HookScript -> ' .. tostring(scriptType) .. ',' .. tostring(handler))
end

function FrameClass:GetScript(script)
    return self.scripts[script]
end

function FrameClass:RegisterEvent(event)
    self.events[event] = true
end

function FrameClass:UnregisterEvent(event)
    self.events[event] = nil
end

function FrameClass:UnregisterAllEvents(frame)
    for event in pairs(self.events) do
        self.events[event] = nil
    end
end

function FrameClass:SetPropagateKeyboardInput(val) end

function FrameClass:StopMovingOrSizing() end

function FrameClass:GetLeft() end

function FrameClass:GetRight() end

function FrameClass:GetTop() end

function FrameClass:GetBottom() end

function FrameClass:Show()
    self.isShow = true
end

function FrameClass:Hide()
    self.isShow = false
end

function FrameClass:IsShown()
    return self.isShow
end

function FrameClass:IsVisible()
    return self:IsShown()
end

function FrameClass:ClearAllPoints()

end

function FrameClass:SetParent(parent)
    self.parent = parent
end

function FrameClass:GetParent()
    return self.parent
end

function FrameClass:GetFontString()
    return CreateFrame("FontString")
end

function FrameClass:SetPushedTextOffset()

end

function FrameClass:SetFrameLevel(l)
end

function FrameClass:EnableKeyboard() end

function FrameClass:SetJustifyV()

end

function FrameClass:GetFrameLevel()
    return 0
end

function FrameClass:GetName()
    return self.fname
end

function FrameClass:SetOwner(owner, anchor)

end

function FrameClass:SetHyperlink(link)

end

function FrameClass:NumLines()
    return 0
end

function FrameClass:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy)

end

function FrameClass:SetSize(x, y)

end

function FrameClass:GetHeight()
    return 600
end

function FrameClass:SetFrameStrata(strata)

end

function FrameClass:SetBackdrop(bgFile, edgeFile, tile, tileSize, edgeSize, insets)

end

function FrameClass:CreateFontString(name, layer, inheritsFrom)
    return CreateFrame("FontString", name)
end

function FrameClass:SetWidth(width)

end

function FrameClass:GetWidth()
    return 600
end

function FrameClass:SetHeight(width)

end

function FrameClass:AddLine() end

function FrameClass:GetText()
    return  self.text
end

function FrameClass:SetFormattedText() end

function FrameClass:SetAnchorType() end

function FrameClass:SetNormalFontObject(font)

end

function FrameClass:SetHighlightFontObject(font)

end

function FrameClass:SetFontString(font)

end

function FrameClass:GetFont()
    return nil, nil, nil
end

function FrameClass:SetDisabledFontObject(font)

end

function FrameClass:SetWordWrap(wrap)

end

function FrameClass:SetJustifyH(just)

end

function FrameClass:SetMotionScriptsWhileDisabled(enabled)

end

function FrameClass:SetDisabledTexture(texture)

end

function FrameClass:SetAttribute(k, v)

end

function FrameClass:SetScale(scale)

end

function FrameClass:SetNumeric() end

function FrameClass:GetObjectType()
    return self.type
end

function FrameClass:CreateTexture(name, texture, texturePath)
    return CreateTexture(name, texture, texturePath, self)
end

function FrameClass:SetNormalTexture(texture, texturePath)
    local texture = CreateTexture("normal", texture, texturePath, self)
    self.textures['normal'] = texture
end

function FrameClass:GetNormalTexture()
    return self.textures['normal']
end

function FrameClass:SetPushedTexture(texture, texturePath)
    local texture = CreateTexture("pushed", texture, texturePath, self)
    self.textures['pushed'] = texture
end

function FrameClass:GetPushedTexture()
    return self.textures['pushed']
end

function FrameClass:SetHighlightTexture(texture, texturePath)
    local texture = CreateTexture("highlight", texture, texturePath, self)
    self.textures['highlight'] = texture
end

function FrameClass:GetHighlightTexture()
    return self.textures['highlight']
end

function FrameClass:CreateAnimationGroup(name)
    return CreateAnimationGroup(name)
end

function FrameClass:EnableMouse(on) end

function FrameClass:SetAllPoints() end

function FrameClass:SetBackdropColor(r, g, b)  end

function FrameClass:SetBackdropBorderColor(r, g, b) end

function FrameClass:SetFontObject(font) end

function FrameClass:SetFont(x, y, z) end

function FrameClass:EnableMouseWheel() end

function FrameClass:SetFading() end

function FrameClass:SetMaxLines(l) end

function FrameClass:SetTextInsets(a, b, c, d) end

function FrameClass:GetTextInsets()
    return 0, 0, 0, 0
end


function FrameClass:Enable() end

function FrameClass:Disable() end

function FrameClass:SetClampedToScreen() end

function FrameClass:SetOrientation() end

function FrameClass:SetHitRectInsets() end

function FrameClass:SetThumbTexture() end

function FrameClass:SetScrollChild() end

function FrameClass:SetMinMaxValues() end

function FrameClass:SetValueStep() end

function FrameClass:SetValue() end

function FrameClass:GetChildren() end

function FrameClass:SetAutoFocus() end

function FrameClass:GetStringWidth() return 0 end

function FrameClass:SetMultiLine() end

function FrameClass:SetCountInvisibleLetters() end

function FrameClass:SetMaxLetters()  end

function FrameClass:SetCursorPosition() end

function FrameClass:GetScale() return 1 end

function FrameClass:LockHighlight() end

function FrameClass:UnlockHighlight() end

function FrameClass:SetResizable() end

function FrameClass:SetMinResize() end

function FrameClass:GetFontObject() return "" end

function FrameClass:GetTextWidth() return 10 end

function FrameClass:SetShadowColor(...) end

function FrameClass:SetShadowOffset(...) end

function FrameClass:SetShown(...) end

function FrameClass:SetDontSavePosition(...) end

function FrameClass:SetFixedFrameStrata(isFixed) end

function FrameClass:SetFixedFrameLevel(isFixed) end

function CreateFrame(kind, name, parent, template)
    local frame = FrameClass:New(name)
    frame.type = kind
    frame.parent = parent


    if kind == 'Button' then
        frame.Click = function(self)  end
        frame.SetEnabled = function(self, enabled)  end
        frame.IsEnabled = function(self) return true end
    elseif kind == 'Slider' then
        frame.GetValue = function(self)  return 1 end
        frame.GetMinMaxValues = function(self)  return 0, 1 end
        frame.GetOrientation = function(...) return "HORIZONTAL" end
        frame.SetObeyStepOnDrag = function(...)  end
        frame.SetSize = function(...)  end
        frame.SetEnabled = function(...)  end
    elseif kind == 'CheckButton' then
        frame.CreateTexture = function(...) return CreateTexture(...) end
        frame.SetCheckedTexture = function(...) end
        frame.SetChecked = function(...) end
        frame.GetChecked = function(...) return true end
        frame.IsEnabled = function(...) return true end
        frame.SetEnabled = function(...)  end
    elseif kind == 'ScrollFrame' then
        frame.SetVerticalScroll = function(...)  end
    elseif kind == 'EditBox' then
        frame.SetEnabled = function(self, enabled)  end
        frame.HasFocus = function(self) return true  end
    end

    if template then
        if template == 'UIDropDownMenuTemplate' then
            frame.left = CreateFrame("Frame", name .. "Left", frame)
            frame.middle = CreateFrame("Frame", name .. "Middle", frame)
            frame.right = CreateFrame("Frame", name .. "Right", frame)
            frame.button = CreateFrame("Frame", name .. "Button", frame)
            frame.text = CreateFrame("Frame", name .. "Text", frame)
        elseif template == 'UIPanelScrollFrameTemplate' then
            frame.scrollBar = CreateFrame("Frame", name .. "ScrollBar", frame)
        elseif template == "OptionsFrameTabButtonTemplate" then
            frame.text = CreateFrame("Frame", name .. "Text", frame)
        elseif template == "TextStatusBar" then
            frame.SetStatusBarTexture = function() end
            frame.SetStatusBarColor = function() end
            frame.SetMinMaxValues = function() end
            frame.text = CreateFrame("Frame", (name or "TextStatusBar") .. "Text", frame)
        elseif template == "GameTooltipTemplate" then
            frame.AddDoubleLine = function() end
            frame.AddLine = function() end
        end
    end

    tinsert(frames, frame)
    frame.index = #frames
    if name then _G[name] = frame end
    --print('Created Frame : ' .. tostring(name))
    return frame
end

UIParent = CreateFrame('Frame', 'UIParent', {})
GameTooltip = CreateFrame('Frame', 'GameTooltip', UIParent)
Minimap = CreateFrame('Frame', 'Minimap', UIParent)

_G.UIParent = UIParent
_G.GameTooltip = GameTooltip
_G.Minimap = Minimap

local textures, TextureClass = {}, {}
TextureClass.__index = TextureClass

function TextureClass:New(name)
    local self = setmetatable({}, TextureClass)
    self.tname = name
    self.texture = nil
    self.texturePath = nil
    self.isShow = true
    self.coord = {}
    self.parent = nil
    return self
end

function TextureClass:Show() self.isShow = true end

function TextureClass:Hide() self.isShow = false end

function TextureClass:SetTexCoord(left, right, top, bottom) end

function TextureClass:SetColorTexture() end

function TextureClass:SetAllPoints() end

function TextureClass:Hide() end

function TextureClass:SetTexture(texture) end

function TextureClass:SetBlendMode(mode) end

function TextureClass:SetWidth(width) end

function TextureClass:SetHeight(width) end

function TextureClass:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy)  end

function TextureClass:SetVertexColor(r, g, b) end

function TextureClass:SetDrawLayer(layer) end

function TextureClass:SetDesaturated(saturated) end

function TextureClass:SetGradientAlpha(...) end

function TextureClass:SetGradient(...) end

function TextureClass:SetAlpha() end

function TextureClass:SetSize() end

function TextureClass:GetVertexColor() end

function TextureClass:GetParent() return self.parent end

function TextureClass:ClearAllPoints() end

function TextureClass:GetTexture() end

function TextureClass:SetAtlas() end

function TextureClass:SetEnabled(enabled) end

function TextureClass:SetCheckedTexture(...) end

function TextureClass:GetWidth() return 100 end

function TextureClass:SetShown(...)  end

function CreateTexture(name, texture, texturePath, parent)
    local tex = TextureClass:New(name)
    tex.texture = texture
    tex.texturePath = texturePath
    tex.parent = parent
    tinsert(textures, tex)
    if name then _G[name] = tex end
    return tex
end

local AgClass = {}
AgClass.__index = AgClass

function AgClass:New(name)
    local self = setmetatable({}, AgClass)
    self.agname = name
    self.animations = {}
    return self
end

function AgClass:CreateAnimation(type, name)
    return CreateAnimation(type, name)
end

function AgClass:SetToFinalAlpha() end

function CreateAnimationGroup(name)
    local ag = AgClass:New(name)
    if name then _G[name] = ag end
    return ag
end

local AnimationClass = {}
AnimationClass.__index = AnimationClass

function AnimationClass:New(type, name)
    local self = setmetatable({}, AnimationClass)
    self.type = type
    self.acname = name
    return self
end

function AnimationClass:SetOrder() end
function AnimationClass:SetDuration() end
function AnimationClass:SetFromAlpha() end
function AnimationClass:SetToAlpha() end
function AnimationClass:SetStartDelay() end

function CreateAnimation(type, name)
    local a = AnimationClass:New(type, name)
    if name then _G[name] = a end
    return a
end


function WoWAPI_FireEvent(event,...)
    for _, frame in pairs(frames) do
        if frame.events[event] then
            if frame.scripts["OnEvent"] then
                for i=1,select('#',...) do
                    _G["arg"..i] = select(i,...)
                end
                _G.event=event
                frame.scripts["OnEvent"](frame,event,...)
            end
        end
    end
end

function WoWAPI_FireUpdate(forceNow)
    if forceNow then  _time = forceNow end
    local now = GetTime()
    for _,frame in pairs(frames) do
        --print('WoWAPI_FireUpdate('.. tostring(frame:GetName()) .. ') : isShow (' .. tostring(frame.isShow) .. ') OnUpdate(' .. tostring(frame.scripts.OnUpdate) .. ')')
        if frame.isShow and frame.scripts.OnUpdate then
            -- reset back in case we reset the clock for more testing
            if now == 0 then frame.timer = 0 end
            _G.arg1 = now - frame.timer
            --print('OnUpdate(' .. tostring(frame:GetName()).. ') => ' .. tostring(now - frame.timer))
            frame.scripts.OnUpdate(frame, now - frame.timer)
            frame.timer = now
        end
    end
end


function PanelTemplates_TabResize() end
function PanelTemplates_DeselectTab() end
function PanelTemplates_SelectTab() end
function SetDesaturation() end
function EnumerateFrames(f)
    if not f then return frames[1] end

    local nextIdx = f.index + 1
    if nextIdx > #frames then
        return nil
    else
        return frames[nextIdx]
    end
end

function FauxScrollFrame_OnVerticalScroll(...) end