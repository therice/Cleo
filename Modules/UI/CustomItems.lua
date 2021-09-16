--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")

--- @type CustomItems
local CustomItems = AddOn:GetModule("CustomItems", true)

local ItemLineHeight, ItemListHeight = 32, 589

function CustomItems:CreateItemWidgets(parent)
	if parent then
		parent.quality =
			UI:New('Dropdown', parent.content or parent)
		        :SetList(Util.Tables.Copy(C.ItemQualityColoredDescriptions))
		        :Tooltip(L["quality"])

		parent.type =
			UI:New('Dropdown', parent.content or parent)
		        :SetList(Util.Tables.Copy(self.EquipmentLocations), self.EquipmentLocationsSort)
		        :Tooltip(L["equipment_loc"])

		parent.level =
			UI:New('Slider', parent.content or parent, true)
		        :TooltipTitle(L["item_lvl"])
				:EditBox()
		        :Size(125)
		        :Range(1,250)
	end

end

function CustomItems:LayoutInterface(container)
	Logging:Debug("CustomItems:LayoutInterface(%s)", tostring(container:GetName()))

	-- grab a reference to self for later use
	local module = self

	container.add =
		UI:New('ButtonAdd', container)
	        :Point("TOPRIGHT", container.banner, "TOPRIGHT", -10, 0)
	        :Size(18,18)
			:Tooltip(L["add_item"])
			:OnClick(
				function(...)
					module:GetAddItemFrame():Show()
				end
			)

	container.itemList =
		UI:New('ScrollFrame', container)
			:Point("TOPLEFT", container.banner, "BOTTOMLEFT", 0, 0)
			:Point("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
			:Size(749, ItemListHeight)
			:MouseWheelRange(50)
	container.itemList:LayerBorder(0)
	container.itemList.lines = {}

	-- this only creates the necessary line templates, which can then later be updated with item specific information
	for index=1, ceil(ItemListHeight/ItemLineHeight) + 2 do
		local line = CreateFrame('Frame', nil, container.itemList.content)
		container.itemList.lines[index] = line
		line:SetPoint("TOPLEFT", 0, -(index - 1) * ItemLineHeight)
		line:SetPoint("RIGHT", 0, 0)
		line:SetHeight(ItemLineHeight)

		line.bgColor = line:CreateTexture(nil, "BACKGROUND")
		line.bgColor:SetPoint("LEFT",0,0)
		line.bgColor:SetSize(350, ItemLineHeight)
		line.bgColor:SetColorTexture(1, 1, 1, 1)
		line.bgColorRGB = {0, 0, 0}
		line:SetScript(
				"OnUpdate",
				function(self)
					local cR, cG, cB =  self.bgColorRGB[1], self.bgColorRGB[2], self.bgColorRGB[3]
					if self:IsMouseOver() then
						self.bgColor:SetGradientAlpha("HORIZONTAL", cR, cG, cB, 0.8, cR, cG, cB, 0)
					else
						self.bgColor:SetGradientAlpha("HORIZONTAL", cR, cG, cB, 0.4, cR, cG, cB, 0)
					end
				end
		)

		line.icon = line:CreateTexture(nil, "ARTWORK")
		line.icon:SetSize(28,28)
		line.icon:SetPoint("LEFT", 10, 0)
		line.icon:SetTexCoord(.1,.9,.1,.9)
		UI.LayerBorder(line.icon, 1,.12,.13,.15,1)

		line.itemName =
			UI:New('Text', line)
				:Size(200, ItemLineHeight)
				:Point("LEFT", line.icon, "RIGHT", 5 ,0)
				:Shadow()

		line.tooltipFrame = CreateFrame("Frame",nil,line)
		line.tooltipFrame:SetAllPoints(line.icon)
		line.tooltipFrame:SetScript(
				"OnEnter",
				function(self)
					local item = self:GetParent().item
					if item then
						UIUtil.Link(self, item.link)
					end
				end
		)
		line.tooltipFrame:SetScript("OnLeave", function() UIUtil:HideTooltip() end)

		self:CreateItemWidgets(line)
		line.quality:SetWidth(100):Point("LEFT", line.itemName, "RIGHT", 5, 0)
		line.type:SetWidth(125):Point("LEFT", line.quality, "RIGHT", 15, 0)
		line.level:Point("TOPLEFT", line.type, "TOPRIGHT", 15,-1):Size(125)

		line.delete =
			UI:New('ButtonTrash', line)
				:Point("TOPLEFT", line.level, "TOPRIGHT", 15,-1)
				:Size(18,18)
				:Tooltip(format(L["double_click_to_delete_this_entry"], L["item"]))
				:OnClick(
					function(self)
						if self.lastClick and GetTime() - self.lastClick <= 0.5 then
							self.lastClick = nil
							local item = self:GetParent().item
							if item then CustomItems.OnDeleteItemClick(item) end
						else
							self.lastClick = GetTime()
						end
					end
				)

		line:Hide()
	end

	container.itemList.Update = function(self)
		local scroll = self.ScrollBar:GetValue()
		self:SetVerticalScroll(scroll % ItemLineHeight)
		local start = floor(scroll / ItemLineHeight)  + 1

		local items = module.db.profile.custom_items
		local sorted = Util.Tables.Sort(Util.Tables.Keys(items))
		local lineCount = 1
		for index = start, #sorted do
			local itemId, line = sorted[index], self.lines[lineCount]
			local item = items[itemId]
			lineCount = lineCount + 1
			if not line then break end

			-- todo : handle query failing
			-- https://wowpedia.fandom.com/wiki/ItemMixin#Methods
			local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(itemId)
			line.item = {
				id = tonumber(itemId),
				link = link,
				GetDataSourceKey = function(self, attr)
					return 'custom_items.' .. tostring(self.id) .. '.' .. attr
				end
			}
			for attr, value in pairs(item) do
				line.item[attr] = value
			end

			line.icon:SetTexture(texture)
			line.icon:SetShown(true)
			line.itemName:SetText(name)

			local function UpdateItemQualityColor(quality)
				local itemQualityColor = _G.ITEM_QUALITY_COLORS[quality]
				if itemQualityColor then
					line.bgColorRGB = {itemQualityColor.r, itemQualityColor.g, itemQualityColor.b}
				end
			end

			UpdateItemQualityColor(item.rarity)
			line.quality:Datasource(
				module,
				line.item:GetDataSourceKey("rarity"),
				function(quality) UpdateItemQualityColor(quality) end
			)

			line.type:Datasource(
				module,
				line.item:GetDataSourceKey("equip_location")
			)

			line.level:Datasource(
				module,
				line.item:GetDataSourceKey("item_level")
			)

			line.delete.lastClick = nil

			line:Show()
		end

		for i = lineCount, #self.lines do
			self.lines[i]:Hide()
		end

		self:Height(ItemLineHeight * #sorted)
	end

	container.itemList.ScrollBar.slider:SetScript(
			"OnValueChanged",
			function(self)
				self:GetParent():GetParent():Update()
				self:UpdateButtons()
			end
	)

	container.itemList:Update()

	self.interfaceFrame = container
end

function CustomItems:GetAddItemFrame()
	if not self.addItemFrame then
		local f = UI:Popup(UIParent, 'AddCustomItem', 'CustomItems', L['frame_add_custom_item'], 250, 210, false)
		-- f:SetPoint("TOPLEFT", self.interfaceFrame and self.interfaceFrame:GetParent() or UIParent, "TOPRIGHT")

		local itemIconFn = UIUtil.ItemIconFn()
		f.icon = UI:New("IconBordered", f.content):Point("LEFT", f.banner, "LEFT", 10, 0)
		f.icon.Set   = function(self, quality, ...)
			itemIconFn(self, ...)
			self:SetBorderColor(_G.ITEM_QUALITY_COLORS[quality])
		end
		f.icon.Reset = function(self)
			itemIconFn(self, nil, nil)
			self:SetBorderColor(C.Colors.Grey)
		end

		f.query =
			UI:New('EditBox', f.content, nil, true)
				:Size(100,15)
				:Point("RIGHT", f.banner, "RIGHT", -10, 0)
				:Tooltip(L["item_add_search_desc"])
				:AddSearchIcon()
				:OnChange(function() f:Query() end)
				:LeftText(L["item_id"])
				:Run(
					function(self)
						self.leftText:Color(C.Colors.MageBlue:GetRGB())
					end
				)

		f.name =
			UI:New('EditBox', f.content)
				:Size(200,15)
				:Point("RIGHT", f.banner, "RIGHT", -20, -40)
				:Tooltip(L["name"])
		f.name:SetJustifyH("RIGHT")
		f.name:SetEnabled(false)
		f.name.Reset = function(self) self:Text("") end

		self:CreateItemWidgets(f)

		f.quality:SetWidth(200):Point("TOPRIGHT", f.name, "BOTTOMRIGHT", 0, -10)
			:OnValueChanged(
				function(value)
					f.item.rarity = value
					f.add:EnableDisable()
				end
			)
		f.quality.Reset = function(self) self:ClearValue() end


		f.type:SetWidth(200):Point("TOPRIGHT", f.quality, "BOTTOMRIGHT", 0, -10)
			:OnValueChanged(
				function(value)
					f.item.equip_location = value
					f.add:EnableDisable()
				end
			)
		f.type.Reset = function(self) self:ClearValue() end

		f.level:Size(200):Point("TOPRIGHT", f.type, "BOTTOMRIGHT", 0,-10)
			:OnChange(
				function(self, value)
					value = Util.Numbers.Round2(value)
					self:SetTo(value)
					f.item.item_level = value
					f.add:EnableDisable()
				end
			)
		f.level.Reset = function(self) self:SetTo(1) end

		f.add =
			UI:New("Button", f.content, L['add'])
				:Point("CENTER", f.content, "CENTER", 0, 0)
				:Point("BOTTOM", f.content, "BOTTOM", 0, 10)
				:OnClick(
					function()
						self:AddItem(f.item)
						f:Hide()
						self.interfaceFrame.itemList:Update()
					end
				)
		f.add.EnableDisable = function(self)
			local f = self:GetParent():GetParent()
			local enable =
				Util.Strings.IsSet(f.name:GetText()) and
				f.quality:HasValue() and
				f.type:HasValue() and
				tonumber(f.level:GetValue()) > 0
			self:SetEnabled(enable)
		end

		f.Enable = function(self, enable)
			enable = Util.Objects.IsNil(enable) and true or enable
			self.quality:SetEnabled(enable)
			self.type:SetEnabled(enable)
			self.level:SetEnabled(enable)
		end

		f.Reset = function(self)
			self.item = {}
			self:Enable(false)
			self.icon:Reset()
			self.name:Reset()
			self.quality:Reset()
			self.type:Reset()
			self.level:Reset()
			self.add:EnableDisable()
		end


		-- throttle queries to once every 2 seconds
		f.Query = Util.Functions.Throttle(
				function(self)
					Logging:Debug("Query()")

					local function query(id, success)
						Logging:Debug("query(%d) : result=%s", id, tostring(success))

						-- non-nil success that is false, means callback failed
						if not Util.Objects.IsNil(success) and not success then
							self:Reset()
							return
						end

						local name, link, quality, ilvl, _, _, subType, _, equipLoc, texture = GetItemInfo(id)
						Logging:Trace(
								"%s => %s, %s, %s, %s, %s, %s",
								tostring(id), tostring(link), tostring(quality), tostring(ilvl),
								tostring(subType), tostring(equipLoc),
								tostring(CustomItems.EquipmentLocations[equipLoc])
						)
						if name then
							if Util.Strings.Equal(subType, C.ItemEquipmentLocationNames.Wand) then equipLoc = "INVTYPE_WAND" end
							if not CustomItems.EquipmentLocations[equipLoc] then equipLoc = nil end

							self.item = {
								id             = id,
								default        = false,
							}

							self.name:Text(name)
							self.quality:SetValue(quality)
							if equipLoc then
								self.type:SetValue(equipLoc)
							else
								self.type:ClearValue()
							end
							self.level:SetTo(ilvl)
							--self.level:HideTooltip()
							self.icon:Set(quality, link, texture)
							self:Enable(true)
							self.add:EnableDisable()
						else
							ItemUtil:QueryItemInfo(id, query)
						end
					end

					local itemId = tonumber(self.query:GetText() or "")
					if itemId and itemId > 0 then
						query(itemId)
					else
						f:Reset()
					end
				end, -- function
				2, -- seconds
				1 -- seconds
		)

		f:Reset()
		self.addItemFrame = f
	end

	return self.addItemFrame
end

--[[
function CustomItems:GetAddItemFrame()
	if not self.addItemFrame then
		local f = UI:NewNamed('Frame', UIParent, 'AddCustomItem', 'CustomItems', L['frame_add_custom_item'], 225, 200, false)
		f:SetPoint("TOPRIGHT", ACD.OpenFrames[C.name] and ACD.OpenFrames[C.name].frame or UIParent, "TOPLEFT", 150)
		f.Reset = function()
			f.itemName.Reset()
			f.itemIcon.Reset()
			f.itemLvl.Reset()
			f.itemType.Reset()
			f.item = nil
			f.add:Disable()
		end

		f.Query = function()
			f.Reset()

			local itemId = f.queryInput:GetText()
			Logging:Debug("Query(%s)", tostring(itemId))

			local function query(id)
				local name, link, rarity, ilvl, _, _, subType, _, equipLoc, texture= GetItemInfo(itemId)
				Logging:Trace(
						"%s => %s, %s, %s, %s, %s, %s",
						tostring(itemId), tostring(link), tostring(rarity), tostring(ilvl),
						tostring(subType), tostring(equipLoc), tostring(CustomItems.EquipmentLocations[equipLoc])
				)
				if name then
					if Util.Strings.Equal(subType, C.ItemEquipmentLocationNames.Wand) then equipLoc = "INVTYPE_WAND" end
					if Util.Strings.Equal(equipLoc, "INVTYPE_RANGEDRIGHT") then equipLoc = "INVTYPE_RANGED" end
					if not CustomItems.EquipmentLocations[equipLoc] then equipLoc = "CUSTOM_SCALE" end

					f.item = {
						id = itemId,
						rarity = rarity or 4,
						item_level = ilvl or 0,
						equip_location = equipLoc,
						default = false,
					}

					f.itemName.Set(name, f.item.rarity)
					f.itemIcon.Set(link, texture)
					f.itemLvl.Set(f.item.item_level)
					f.itemType.Set(f.item.equip_location)
					f.add:Enable()
				else
					ItemUtil:QueryItemInfo(id, function() query(id) end)
				end
			end

			if not itemId or not tonumber(itemId) then
				f.itemName:SetText(UIUtil.ColoredDecorator(0.77,0.12,0.23,1):decorate(L['invalid_item_id']))
				f.itemName:Show()
			else
				query(itemId)
			end
		end

		local itemName = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		itemName:SetPoint("CENTER", f.content, "TOP", 0, -25)
		itemName.Reset = function()
			f.itemName:SetText(nil)
			f.itemName:Hide()
		end
		itemName.Set = function (name, rarity)
			f.itemName:SetText(UIUtil.ItemQualityDecorator(rarity):decorate(name))
			f.itemName:Show()
		end
		f.itemName = itemName

		local itemIcon = UI:New("IconBordered", f.content)
		itemIcon.Reset = function()
			f.itemIcon:SetNormalTexture("Interface\\InventoryItems\\WoWUnknownItem01")
			f.itemIcon:SetScript("OnEnter", nil)
			f.itemIcon:SetScript("OnLeave", nil)
		end
		itemIcon.Set = function(link, texture)
			f.itemIcon:SetNormalTexture(texture)
			f.itemIcon:SetScript("OnEnter", function() UIUtil:CreateHypertip(link) end)
			f.itemIcon:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
		end
		itemIcon:SetPoint("TOPLEFT", f.content, "TOPLEFT", 10, -35)
		f.itemIcon = itemIcon

		local queryLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		queryLabel:SetPoint("LEFT", f.itemIcon, "RIGHT", 5, 0)
		queryLabel:SetText(L["item_id"])
		f.queryLabel = queryLabel

		local queryInput = UI:New("EditBox", f.content)
		queryInput:SetHeight(20)
		queryInput:SetWidth(50)
		queryInput:SetPoint("LEFT", f.queryLabel, "RIGHT", 10, 0)
		f.queryInput = queryInput

		local queryExecute = UI:New("Button", f.content)
		queryExecute:SetSize(25, 25)
		queryExecute:SetPoint("LEFT", f.queryInput, "RIGHT", 10, 0)
		queryExecute:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		queryExecute:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
		queryExecute:SetScript("OnClick", function () f.Query() end)
		f.queryExecute = queryExecute

		local itemLvlLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		itemLvlLabel:SetPoint("TOPLEFT", f.itemIcon, "TOPLEFT", 5, -55)
		itemLvlLabel:SetText(L["item_lvl"])
		f.itemLvlLabel = itemLvlLabel

		local itemLvl = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		itemLvl:SetPoint("LEFT", f.itemLvlLabel, "RIGHT", 10, 0)
		itemLvl:SetTextColor(1, 1, 1, 1)
		itemLvl.Reset = function()
			f.itemLvlLabel:Hide()
			f.itemLvl:SetText(nil)
			f.itemLvl:Hide()
		end
		itemLvl.Set = function(lvl)
			f.itemLvlLabel:Show()
			f.itemLvl:SetText(tostring(lvl))
			f.itemLvl:Show()
		end
		f.itemLvl = itemLvl

		local itemTypeLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		itemTypeLabel:SetPoint("TOPLEFT", f.itemLvlLabel, "TOPLEFT", 0, -25)
		itemTypeLabel:SetText(L["equipment_loc"])
		f.itemTypeLabel = itemTypeLabel

		local itemType = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		itemType:SetPoint("LEFT", f.itemTypeLabel, "RIGHT", 10, 0)
		itemType:SetTextColor(1, 1, 1, 1)
		itemType.Reset = function()
			f.itemTypeLabel:Hide()
			f.itemType:SetText(nil)
			f.itemType:Hide()
		end
		itemType.Set = function(equipLoc)
			f.itemTypeLabel:Show()
			f.itemType:SetText(self.EquipmentLocations[equipLoc])
			f.itemType:Show()
		end
		f.itemType = itemType

		local close = UI:New('Button', f.content)
		close:SetText(_G.CANCEL)
		close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 7)
		close:SetScript("OnClick", function() f:Hide() end)
		f.close = close

		local add = UI:New('Button', f.content)
		add:SetText(_G.ADD)
		add:SetPoint("RIGHT", f.close, "LEFT", -10, 0)
		add:SetScript("OnClick", function() self:AddItem(f.item); f:Hide() end)
		f.add = add

		self.addItemFrame = f
	end

	return self.addItemFrame
end

function CustomItems:OnAddItemClick(...)
	local f = self:GetAddItemFrame()
	f.Reset()
	f:Show()
end

--]]

function CustomItems.OnDeleteItemClick(item)
	Dialog:Spawn(C.Popups.ConfirmDeleteItem, item)
end

function CustomItems.DeleteItemOnShow(frame, item)
	UIUtil.DecoratePopup(frame)
	frame.text:SetText(format(L['confirm_delete_entry'], item.link))
end

function CustomItems:DeleteItemOnClickYes(_, item)
	self:RemoveItem(item.id)
	self.interfaceFrame.itemList:Update()
end
