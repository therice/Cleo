--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')

local Width, Height, ListWidth = 865, 650, 165

function AddOn:Launchpad()
	if not self.launchpad then
		local f = UI:NewNamed('Frame', UIParent, 'LaunchpadPlatform', 'Launchpad', nil, Width, Height, false)
		f:SetPoint("CENTER",0,0)
		f:CreateShadow(20)
		f:ShadowInside()

		f.modulesList =
			UI:New('ScrollList', f.content or f)
				:LineHeight(24)
				:Size(ListWidth - 1, Height)
				:Point(0,0 )
				:FontSize(11)
				:HideBorders()
		f.modulesList.borderRight =
			UI:New('Texture', f.modulesList, 0.24, 0.25, 0.30, 1.0, "BORDER")
			  :Point("TOPLEFT", f.modulesList, "TOPRIGHT", 0, 0)
			  :Point("BOTTOMRIGHT",f.modulesList, "BOTTOMRIGHT", 1, 0)

		f.modulesList.frame.ScrollBar:Size(8,0):Point("TOPRIGHT",0,0):Point("BOTTOMRIGHT",0,0)
		f.modulesList.frame.ScrollBar.thumb:SetHeight(100)
		f.modulesList.frame.ScrollBar.buttonUp:Hide()
		f.modulesList.frame.ScrollBar.buttonDown:Hide()
		f.modulesList.frame.ScrollBar.borderRight =
			UI:New('Texture', f.modulesList.frame.ScrollBar, 0.24, 0.25, 0.30, 1.0, "BORDER")
				:Point("TOPLEFT", f.modulesList.frame.ScrollBar, "TOPLEFT", -1, 0)
				:Point("BOTTOMRIGHT", f.modulesList.frame.ScrollBar, "BOTTOMLEFT", 0 ,0)

		f.frames, f.currentFrame = {}, nil

		f:SetScript(
				"OnShow",
				function(self)
					self.modulesList:Update()
					if self.currentFrame and Util.Objects.IsFunction(self.currentFrame.OnShow) then
						self.currentFrame:OnShow()
					end
				end
		)


		-- sets the current displayed frame to passed frame
		f.SetCurrentFrame = function(self, frame)
			if self.currentFrame then
				self.currentFrame:Hide()
			end

			self.currentFrame = frame
			self.currentFrame:Show()

			-- make this "nicer"
			if self.currentFrame.isWide and self.nowWide ~= self.currentFrame.isWide then
				local width = Util.Objects.IsNumber(self.currentFrame.isWide) and self.currentFrame.isWide or 850
				self:SetWidth(width + ListWidth)
				self.nowWide = self.currentFrame.isWide
			elseif not self.currentFrame.isWide and self.nowWide then
				self:SetWidth(Width)
				self.nowWide = nil
			end

			if self.currentFrame.isWide then
				self.currentFrame:SetWidth(Util.Objects.IsNumber(self.currentFrame.isWide) and self.currentFrame.isWide or 850)
			end

			if Util.Objects.IsFunction(self.currentFrame.OnShow) then
				self.currentFrame:OnShow()
			end
		end

		-- sets the current module index, results in that frame being set to current and displayed
		f.SetModuleIndex = function(self, index)
			Logging:Debug("SetModuleIndex(%d)", tonumber(index))
			self:SetCurrentFrame(self.frames[index])
			self.modulesList:SetTo(index)
		end

		f.modulesList.SetListValue = function(_, index)
			Logging:Debug("SetListValue(%d)", tonumber(index))
			f:SetModuleIndex(index)
		end

		-- creates a module frame, adds to list, and returns the created frame
		f.AddModule = function(self, moduleName, displayName, withTitle)
			Logging:Debug("AddModuleFrame(%s, %s)", tostring(moduleName), tostring(displayName))
			local moduleFrame = CreateFrame("Frame", self:GetName() .. "_" .. moduleName, self.content or self)
			moduleFrame.moduleName = moduleName
			moduleFrame.displayName = Util.Objects.Default(displayName, moduleName)
			moduleFrame:SetSize(Width - ListWidth, Height - 16)
			moduleFrame:SetPoint("TOPLEFT", ListWidth, - 16)

			moduleFrame.CreateTitle = function(self)
				self.title = UI:New('Text', self, self.displayName, 20):Point(15,6):Color(C.Colors.MageBlue:GetRGB()):Top()
				return self
			end

			moduleFrame.SetWide = function(self)
				self.isWide = true
				return self
			end

			local position = #self.frames + 1
			self.modulesList.L[position] = moduleFrame.displayName
			self.frames[position] = moduleFrame

			if self:IsShown() then
				self.modulesList:Update()
			end

			if withTitle then moduleFrame:CreateTitle() end
			moduleFrame:Hide()
			return position, moduleFrame
		end


		self.launchpad = f
	end

	return self.launchpad
end

function AddOn:ApplyModules(moduleSuppliers)
	if self.launchpad then
		local sorted = Util.Tables.Sort(Util.Tables.Keys(moduleSuppliers))

		for _, name in pairs(sorted) do
			-- suppliers will be a tuple or {[module], [function], [boolean]}
			local metadata = moduleSuppliers[name]
			Logging:Debug("ApplyModules(%s) : %s, %s, %s", tostring(name), metadata[1]:GetName(), Util.Objects.ToString(metadata[2]), tostring(metadata[3]))

			local _, moduleFrame = self.launchpad:AddModule(metadata[1]:GetName(), name, true)
			moduleFrame:SetWide()
			moduleFrame.module = metadata[1]
			moduleFrame.banner =
				UI:New('DecorationLine', moduleFrame, true,"BACKGROUND",-5)
						:Point("TOPLEFT",moduleFrame,0,-16)
						:Point("BOTTOMRIGHT",moduleFrame,"TOPRIGHT",0,-36)

			-- enableDisableSupport (as button with callbacks through module prototype)
			if metadata[3] then
				moduleFrame.enable =
					UI:New('Checkbox', moduleFrame, L["enable"], metadata[1]:IsEnabled())
				        :Point("TOPRIGHT", moduleFrame.banner, "TOPRIGHT", -75, -1)
				        :Tooltip(format(L["enabled_generic_desc"], name))
						:Size(18,18):AddColorState():OnClick(
							function(self)
								self:GetParent().module:SetEnabled(nil, self:GetChecked())
							end
						)
			end


			metadata[2](moduleFrame)
		end
	end
end

function AddOn:PrepareForLaunch(configSupplements, lpadSupplements)
	-- build the launchpad
	self:Launchpad()
	-- add about information to launchpad
	self:AddAbout()
	-- apply configuration supplements, registering as necessary in appropriate layout
	self:ApplyConfiguration(configSupplements)
	-- apply modules, registering each as an additional layout
	self:ApplyModules(lpadSupplements)
end

function AddOn:ToggleLaunchpad()
	local lpad = self:Launchpad()
	if lpad:IsVisible() then
		lpad:Hide()
	else
		lpad:Show()
	end
end