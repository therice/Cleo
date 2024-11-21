-- @type AddOn
local AddOnName, AddOn = ...
-- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.Texture
local Texture = AddOn.Package('UI.Widgets'):Class('Texture', BaseWidget)

function Texture:initialize(parent, name, cR, cG, cB, cA, layer)
	BaseWidget.initialize(self, parent, name)

	if not cB then
		self.texture = cR
		self.layer = cG
	else
		self.color = {cR, cG, cB, cA}
		self.layer = layer
	end
end

function Texture:Create()
	local texture = self.parent:CreateTexture(nil, self.layer or "ARTWORK")
	BaseWidget.Mod(
		texture,
		'Color', Texture.Color,
		'TexCoord', Texture.TexCoord,
		'BlendMode', Texture.BlendMode,
		'Gradient', Texture.Gradient,
		'Texture', Texture.Texture,
		'Atlas', Texture.Atlas,
		'Layer', Texture.Layer
	)

	if self.texture then
		texture:SetTexture(self.texture)
	else
		texture:SetColorTexture(unpack(self.color))
	end

	return texture
end


function Texture.Color(self,arg1,...)
	if Util.Objects.IsString(arg1) then
		local r,g,b,a = arg1:sub(-6,-5),arg1:sub(-4,-3),arg1:sub(-2,-1),arg1:sub(-8,-7)
		r,g,b,a = tonumber(r,16),tonumber(g,16),tonumber(b,16),tonumber(a,16)
		self:SetVertexColor(r and r/255 or 1,g and g/255 or 1,b and b/255 or 1,a and a/255 or 1)
	else
		self:SetVertexColor(arg1,...)
	end
	return self
end

function Texture.TexCoord(self, ...)
	self:SetTexCoord(...)
	return self
end

function Texture.BlendMode(self, ...)
	self:SetBlendMode(...)
	return self
end

function Texture.Gradient(self,...)
	self:SetGradientAlpha(...)
	return self
end

function Texture.Texture(self, cR, cG, cB, cA)
	if cG then
		self:SetColorTexture(cR, cG, cB, cA)
	else
		self:SetTexture(cR)
	end
	return self
end

function Texture.Atlas(self, atlasName, ...)
	self:SetAtlas(atlasName)
	return self
end

function Texture.Layer(self, layer)
	self:SetDrawLayer(layer)
	return self
end

NativeUI:RegisterWidget('Texture', Texture)