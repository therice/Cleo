--- @type AddOn
local _, AddOn = ...
local L, C, Logging, Util, ItemUtil, ACD =
	AddOn.Locale, AddOn.Constants, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util"),
	AddOn:GetLibrary("ItemUtil"), AddOn:GetLibrary('AceConfigDialog')
local UI, UIUtil, Dialog =
	AddOn.Require('UI.Native'), AddOn.Require('UI.Util'), AddOn:GetLibrary("Dialog")

--- @type CustomItems
local CustomItems = AddOn:GetModule("CustomItems", true)

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

function CustomItems:OnDeleteItemClick(...)
	Dialog:Spawn(C.Popups.ConfirmDeleteItem, self.selectedItem)
end

function CustomItems.DeleteItemOnShow(frame, item)
	UIUtil.DecoratePopup(frame)
	-- the info should be available, because deleting an already displayed item
	-- therefore, no need to check if link is set
	local _, link = GetItemInfo(item)
	frame.text:SetText(format(L['confirm_delete_item'], link))
end

function CustomItems.DeleteItemOnClickYes(_, item)
	Logging:Debug("DeleteItemOnClickYes(%s)", tostring(item))
	CustomItems:RemoveItem(item)
end