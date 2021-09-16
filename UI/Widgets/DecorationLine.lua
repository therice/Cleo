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

	if self.isGradient then
		dl:SetColorTexture(1, 1, 1, 1)
		dl:SetGradientAlpha("VERTICAL", .24, .25, .30, 1, .27, .28, .33, 1)
	else
		dl:SetColorTexture(.24, .25, .30, 1)
	end

	BaseWidget.Mod(dl)

	return dl
end


NativeUI:RegisterWidget('DecorationLine', DecorationLine)