-- @type AddOn
local AddOnName, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.InlineGroup
local InlineGroup = AddOn.Package('UI.Widgets'):Class('InlineGroup', BaseWidget)

local BorderColor = C.Colors.ItemPoor

function InlineGroup:initialize(parent, name, font)
	BaseWidget.initialize(self, parent, name)
	self.font = font or BaseWidget.FontNormalName
end

function InlineGroup:Create()
	local ig = CreateFrame("Frame", self.name, self.parent)
	ig:SetFrameStrata("FULLSCREEN_DIALOG")

	ig.titleText = ig:CreateFontString(nil, "OVERLAY", self.font)
	ig.titleText:SetPoint("TOPLEFT", 12, 10)
	ig.titleText:SetPoint("TOPRIGHT", -12, 10)
	ig.titleText:SetJustifyH("LEFT")
	ig.titleText:SetHeight(18)

	--ig.border = CreateFrame("Frame", nil, ig, BackdropTemplateMixin and "BackdropTemplate")
	--ig.border:SetPoint("TOPLEFT", 0, -17)
	--ig.border:SetPoint("BOTTOMRIGHT", -1, 3)
	--ig.border:SetBackdrop(
	--	{
	--		bgFile = BaseWidget.ResolveTexture('white'), -- "Interface\\ChatFrame\\ChatFrameBackground"
	--		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	--		tile     = true, tileSize = 8, edgeSize = 4,
	--		insets   = { left = 2, right = 2, top = 2, bottom = 2 }
	--
	--		--tile = true, tileSize = 16, edgeSize = 16,
	--		--insets = { left = 3, right = 3, top = 5, bottom = 3 },
	--	}
	--)
	--ig.border:SetBackdropColor(0, 0, 0, 1)
	--ig.border:SetBackdropBorderColor(0, 0, 0, 1)
	--ig.border:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
	--ig.border:SetBackdropBorderColor(0.4, 0.4, 0.4)

	ig.content = CreateFrame("Frame", nil, ig)
	ig.content:SetPoint("TOPLEFT", 10, -10)
	ig.content:SetPoint("BOTTOMRIGHT", -10, 10)

	-- BaseWidget.LayerBorder(ig.content, 2, 0.24, 0.25, 0.30, 1, 2)
	BaseWidget.Border(ig.content, BorderColor.r, BorderColor.g, BorderColor.b, BorderColor.a, 1, 1)

	BaseWidget.Mod(
		ig,
		'Title', InlineGroup.SetTitle
	)

	ig._SetSize = ig.Size
	ig.SetSize = InlineGroup.SetSize
	ig._SetWidth = ig.SetWidth
	ig.SetWidth = InlineGroup.SetWidth
	ig._SetHeight = ig.SetHeight
	ig.SetHeight = InlineGroup.SetHeight

	ig:SetSize(300, 100)
	ig:Title("")

	return ig
end

function InlineGroup:SetSize(width, height)
	self:SetWidth(width)
	self:SetHeight(height)
	return self
end

function InlineGroup:SetWidth(width)
	self:_SetWidth(width)
	local content = self.content
	local contentwidth = width - 20
	if contentwidth < 0 then
		contentwidth = 0
	end
	content:SetWidth(contentwidth)
	content.width = contentwidth
	return self
end

function InlineGroup:SetHeight(height)
	self:_SetHeight(height)
	local content = self.content
	local contentheight = height - 20
	if contentheight < 0 then
		contentheight = 0
	end
	content:SetHeight(contentheight)
	content.height = contentheight
	return self
end

function InlineGroup:SetTitle(title)
	self.titleText:SetText(title or "")
	return self
end

NativeUI:RegisterWidget('InlineGroup', InlineGroup)