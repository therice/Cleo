--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
-- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.DualListbox
local DualListbox = AddOn.Package('UI.Widgets'):Class('DualListbox', BaseWidget)

local ColorAvailable, ColorSelected, ColorDisabled = C.Colors.ItemPoor, C.Colors.ItemPoor, C.Colors.ItemPoor

function DualListbox:initialize(parent, name)
	BaseWidget.initialize(self, parent, name)
end

-- {TexCoord, NormalTexture.VertexColor, HighlightTexture.VertexColor, PushedTexture.VertexColor, DisabledTexture.VertexColor}
local ButtonMetadata = {
	{ 1, 1, 1, 1 },
	{ 1, 1, 1, 0.65 }, -- Util.Tables.New(C.Colors.White:GetRGBA()),
	{ 0.25, 0.78, 0.92, 0.65 }, --Util.Tables.New(C.Colors.MageBlue:GetRGBA()),
	{ 0.3, 0.35, 0.5, 1 }, -- Util.Tables.New(C.Colors.AdmiralBlue:GetRGBA()),
	{ .3, .3, .3, .7 }
}

function DualListbox:Create()
	local dlb = CreateFrame("Frame", self.name, self.parent)
	dlb:SetSize(400, 250)

	-- todo : sizing/positioning on these elements are not accounted for in subsequent calls

	-- available options
	dlb.available =
		NativeUI:New('ScrollList', dlb)
	        :Size(175, 200)
	        :Point("TOPLEFT", dlb, "TOPLEFT", 0, 0)
	        :LinePaddingLeft(2)
	        :ScrollWidth(22)
			:LineTexture(15, UIUtil.ColorWithAlpha(C.Colors.White, 0.5), UIUtil.ColorWithAlpha(C.Colors.ItemArtifact, 0.6))
			--:HideBorders()

	-- selected options
	dlb.selected =
		NativeUI:New('ScrollList', dlb)
			:Size(175, 200)
			:Point("TOPRIGHT", dlb, "TOPRIGHT", 0, 0)
			:LinePaddingLeft(2)
			:ScrollWidth(22)
			:LineTexture(15, UIUtil.ColorWithAlpha(C.Colors.White, 0.5), UIUtil.ColorWithAlpha(C.Colors.ItemArtifact, 0.6))
			--:HideBorders()

	dlb.addAll =
		NativeUI:New('ButtonIcon', dlb, ButtonMetadata, BaseWidget.ResolveTexture("Arrow1"))
	        :Size(25,25)
	        :Point("CENTER", dlb, "CENTER", 0, 28)
	        :Rotate(true)
			:Tooltip(L["add_all"])
			:OnClick(
				function(self, button, down)
					Logging:Debug("DualListbox.AllAll(OnClick) : %s, %s", tostring(button), tostring(down))
					if Util.Strings.Equal(C.Buttons.Left, button) then
						local all = dlb.available:RemoveAll()
						if all and #all >0 then
							for _, selected in pairs(all) do
								dlb.selected:Insert(selected, function(item) return selected < item end)
								if dlb.selectedChangeFn then
									dlb.selectedChangeFn(selected, true)
								end
							end
						end
					end
				end
			)

	dlb.add =
		NativeUI:New('ButtonIcon', dlb, ButtonMetadata, BaseWidget.ResolveTexture("Arrow7"))
			:Size(25,25)
			:Point("CENTER", dlb, "CENTER", 0, 10)
			:Rotate(true)
			:Tooltip(L["add"])
			:OnClick(
				function(self, button, down)
					Logging:Debug("DualListbox.Add(OnClick) : %s, %s", tostring(button), tostring(down))
					if Util.Strings.Equal(C.Buttons.Left, button) then
						Logging:Debug("DualListbox.Add(OnClick) : %d", dlb.available.selected)
						local selected = dlb.available:RemoveSelected()
						if selected then
							dlb.selected:Insert(selected, function(item) return selected < item end)
							if dlb.selectedChangeFn then
								dlb.selectedChangeFn(selected, true)
							end
						end
					end
				end
			)

	dlb.remove =
		NativeUI:New('ButtonIcon', dlb, ButtonMetadata, BaseWidget.ResolveTexture("Arrow7"))
			:Size(25,25)
			:Point("CENTER", dlb, "CENTER", 0, -10)
			:Rotate(false)
			:Tooltip(L["remove"])
			:OnClick(
				function(self, button, down)
					Logging:Debug("DualListbox.Remove(OnClick) : %s, %s", tostring(button), tostring(down))
					if Util.Strings.Equal(C.Buttons.Left, button) then
						Logging:Debug("DualListbox.Remove(OnClick) : %d", dlb.selected.selected)
						local selected = dlb.selected:RemoveSelected()
						if selected then
							dlb.available:Insert(selected, function(item) return selected < item end)
							if dlb.selectedChangeFn then
								dlb.selectedChangeFn(selected, false)
							end
						end
					end
				end
			)


	dlb.removeAll =
		NativeUI:New('ButtonIcon', dlb, ButtonMetadata, BaseWidget.ResolveTexture("Arrow1"))
			:Size(25,25)
	        :Point("CENTER", dlb, "CENTER", 0, -28)
	        :Rotate(false)
			:Tooltip(L["remove_all"])
			:OnClick(
				function(self, button, down)
					Logging:Debug("DualListbox.RemoveAll(OnClick) : %s, %s", tostring(button), tostring(down))
					if Util.Strings.Equal(C.Buttons.Left, button) then
						local all = dlb.selected:RemoveAll()
						if all and #all >0 then
							for _, selected in pairs(all) do
								dlb.available:Insert(selected, function(item) return selected < item end)
								if dlb.selectedChangeFn then
									dlb.selectedChangeFn(selected, false)
								end
							end
						end
					end
				end
			)

	dlb.availableOpts, dlb.selectedOpts = {}, {}
	dlb.optionsSupplier, dlb.optionsSorter = nil, nil
	dlb.selectedChangeFn = nil

	BaseWidget.Mod(
		dlb,
		'BoxSize', DualListbox.BoxSize,
		'Height', DualListbox.Height,
		'Options', DualListbox.Options,
		'OptionsSupplier', DualListbox.SetOptionsSupplier,
		'OptionsSorter', DualListbox.SetOptionsSorter,
		'Refresh', DualListbox.Refresh,
		'LineTextFormatter', DualListbox.SetLineTextFormatter,
		'OnSelectedChanged', DualListbox.SetOnSelectedChange,
		'SetEnabled', DualListbox.SetEnabled,
		'Clear', DualListbox.Clear,
		'AvailableTooltip', DualListbox.SetAvailableTooltip,
		'SelectedTooltip', DualListbox.SetSelectedTooltip
	)

	dlb:SetEnabled(true)

	return dlb
end

function DualListbox.Height(self, height)
	self:SetHeight(height)
	return self
end

function DualListbox.BoxSize(self, width, height)
	self.available:Size(width, height)
	self.selected:Size(width, height)
	return self
end

function DualListbox.SetLineTextFormatter(self, formatter)
	self.available:LineTextFormatter(formatter)
	self.selected:LineTextFormatter(formatter)
	return self
end

function DualListbox.SetOptionsSorter(self, sorter)
	self.optionsSorter = sorter
	return self
end

function DualListbox.SetOptionsSupplier(self, supplier)
	self.optionsSupplier = supplier
	return self
end

function DualListbox.SetOnSelectedChange(self, fn)
	self.selectedChangeFn = fn
	return self
end

function DualListbox.Options(self, available, selected)
	self.availableOpts, self.selectedOpts = available, selected
	self.available:SetList(self.availableOpts, self.optionsSorter and self.optionsSorter(self.availableOpts) or nil)
	self.selected:SetList(self.selectedOpts, self.optionsSorter and self.optionsSorter(self.selectedOpts) or nil)
	self.available:Update()
	self.selected:Update()
	return self
end

function DualListbox.Refresh(self)
	if self.optionsSupplier then
		self:Options(self.optionsSupplier())
	end

	return self
end

function DualListbox.SetEnabled(self, enabled)
	local ac = enabled and ColorAvailable or ColorDisabled
	local rc = enabled and ColorSelected or ColorDisabled

	self.add:SetEnabled(enabled)
	self.remove:SetEnabled(enabled)
	self.addAll:SetEnabled(enabled)
	self.removeAll:SetEnabled(enabled)
	--self.available:HideBorders()
	self.available:Border(ac.r, ac.g, ac.b, ac.a, 1, 0, 0)
	--self.selected:HideBorders()
	self.selected:Border(rc.r, rc.g, rc.b, rc.a, 1, 0, 0)
end

function DualListbox.Clear(self)
	self.available:Clear()
	self.selected:Clear()
end

function DualListbox.SetAvailableTooltip(self, title, ...)
	self.available:Tooltip(title, ...)
	return self
end

function DualListbox.SetSelectedTooltip(self, title, ...)
	self.selected:Tooltip(title, ...)
	return self
end

NativeUI:RegisterWidget('DualListbox', DualListbox)