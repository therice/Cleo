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
--- @class UI.Widgets.DecorationLine
local DecorationLine = AddOn.Package('UI.Widgets'):Class('DecorationLine', BaseWidget)

function DecorationLine:initialize(parent, name, isGradient, layer, layerCounter)
	BaseWidget.initialize(self, parent, name)
	self.isGradient = isGradient
	self.layer = layer or "BORDER"
	self.layerCounter = layerCounter
end

function DecorationLine:Create()
	local dl = self.parent:CreateTexture(nil, self.layer, nil, self.layerCounter)

	dl.isGradient = self.isGradient

	if self.isGradient then
		dl:SetColorTexture(1, 1, 1, 1)
		BaseWidget.Textures.SetGradientAlpha(dl, "VERTICAL", .24, .25, .30, 1, .27, .28, .33, 1)
	else
		dl:SetColorTexture(.24, .25, .30, 1)
	end

	BaseWidget.Mod(
		dl,
		'Color', DecorationLine.SetColorTexture
	)

	return dl
end


function DecorationLine.SetColorTexture(self, r, g, b, a, gradientPct)
	self:SetColorTexture(r, g, b, a)
	-- if this line is a gradient and a percentage was specified (as decimal)
	if self.isGradient and (gradientPct and Util.Objects.IsNumber(gradientPct)) then
		if Util.Numbers.In(gradientPct, 0, 1) then
			BaseWidget.Textures.SetGradientAlpha(self, "VERTICAL",(r * gradientPct), (g * gradientPct), (b * gradientPct), a,  r, g, b, a)
		end
	end
	return self
end

NativeUI:RegisterWidget('DecorationLine', DecorationLine)