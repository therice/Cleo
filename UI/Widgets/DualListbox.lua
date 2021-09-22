--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
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

function DualListbox:initialize(parent, name)
	BaseWidget.initialize(self, parent, name)
end

function DualListbox:Create()
	local dlb = CreateFrame("Frame", self.name, self.parent)

	-- available options
	dlb.available =
		NativeUI:New('ScrollList', dlb)
	        :Size(175, 200)
	        :Point("TOPLEFT", dlb, "TOPLEFT", 0, 0)
	        :LinePaddingLeft(2)
	        :ScrollWidth(22)
			:LineTexture(15, UIUtil.ColorWithAlpha(C.Colors.White, 0.5), UIUtil.ColorWithAlpha(C.Colors.ItemArtifact, 0.6))
	-- selected options
	dlb.selected =
		NativeUI:New('ScrollList', dlb)
			:Size(175, 200)
			:Point("TOPRIGHT", dlb, "TOPRIGHT", 0, 0)
			:LinePaddingLeft(2)
			:ScrollWidth(22)
			:LineTexture(15, UIUtil.ColorWithAlpha(C.Colors.White, 0.5), UIUtil.ColorWithAlpha(C.Colors.ItemArtifact, 0.6))

	dlb.add =
		NativeUI:New('ButtonRightLarge', dlb)
	        :Size(15,15)
	        :Point("CENTER", dlb, "CENTER", 0, 38)
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
		NativeUI:New('ButtonLeftLarge', dlb)
			:Size(15,15)
			:Point("CENTER", dlb, "CENTER", 0, -38)
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
		'OnSelectedChanged', DualListbox.SetOnSelectedChange
	)

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

NativeUI:RegisterWidget('DualListbox', DualListbox)