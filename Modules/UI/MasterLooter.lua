--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
local Dialog = AddOn:GetLibrary("Dialog")

--- @type MasterLooter
local ML = AddOn:GetModule("MasterLooter", true)

local Tabs = {
	[L["announcements"]]    = L["todo"],
	[L["auto_awards"]]      = L["todo"],
	[L["general"]]          = L["todo"],
	[L["responses"]]        = L["todo"],
}

function ML:LayoutConfigSettings(container)
	container:Tooltip(L["master_looter_desc"])
	container.tabs = UI:New('Tabs', container, unpack(Util.Tables.Sort(Util.Tables.Keys(Tabs))))
							:Point(0, -36):Size(container:GetWidth(), container:GetHeight()):SetTo(1)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, description in pairs(Tabs) do
		container.tabs:GetByName(index):Tooltip(description)
	end

	UI:New('DecorationLine', container.tabs, true, "BACKGROUND",-5)
	  :Point("TOPLEFT", container.tabs, 0, 20)
	  :Point("BOTTOMRIGHT", container.tabs:GetParent(),"TOPRIGHT", -2, -37)
	  :Color(0.25, 0.78, 0.92, 1, 0.50)

	self:LayoutAnnouncementsTab(container.tabs:GetByName(L["announcements"]))
	self:LayoutAutoAwardsTab(container.tabs:GetByName(L["auto_awards"]))
	self:LayoutGeneralTab(container.tabs:GetByName(L["general"]))
	self:LayoutResponsesTab(container.tabs:GetByName(L["responses"]))
end

local ChannelListSort = {}

do
	local index = 1
	for _, v in Util.Tables.OrderedPairs(Util.Tables.Flip(C.ChannelDescriptions)) do
		ChannelListSort[index] = v
		index = index + 1
	end
end


function ML:LayoutAnnouncementsTab(tab)
	local module = self

	tab.scroll =
		UI:New('ScrollFrame', tab)
			:Point("TOPLEFT", tab, "TOPLEFT", 5, -40)
			:Point("TOPRIGHT", tab, "TOPRIGHT", -10, 0)
			:Size(tab:GetWidth(), tab:GetHeight() - 80)
			:HideScrollOnNoScroll()
			:OnShow(
				function(self)
					self:Height(tab:GetHeight() - 80)
					self:OnShow(function()
						local totalGroupHeight =
							tab.awardsGroup:GetHeight() + tab.itemsGroup:GetHeight() + tab.responsesGroup:GetHeight()
						local height = totalGroupHeight + 25 -- padding
						self:Height(height)
						self:OnShow()
					end)
				end, true
			)
	tab.scroll:LayerBorder(0)

	-- awards (START)
	local content = tab.scroll.content
	tab.awardsGroup =
		UI:New('InlineGroup',content)
			:Point("TOPLEFT", content, "TOPLEFT", 0, -5)
			:Point("TOPRIGHT", content, "TOPRIGHT", -20, 0)
			:SetHeight(260)
			:Title(L["awards"])

	content  = tab.awardsGroup.content
	tab.announceAwards =
		UI:New('Checkbox', content, L["announce_awards"], false)
			:Point("TOPLEFT", content, "TOPLEFT", 5, -5)
			:TextSize(12)
			:Tooltip(L["announce_awards_desc"])
			:Datasource(
				module,
				module.db.profile,
				'announceAwards'
			)
	tab.announceAwards:SetSize(14, 14)
	tab.announceAwardsDesc =
		UI:New('Text', content, L["announce_awards_desc_detail"] .. '\n' ..  Util.Strings.Join('\n', unpack(ML.AwardStringsDesc)))
			:Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
			:Point("TOPLEFT", tab.announceAwards, "BOTTOMLEFT", 0, -2)
			:Point("RIGHT", content, "RIGHT", 0, 0)
	tab.announceAwardsChannelLabel =
		UI:New('Text', content, L["channel"])
			:Point("TOPLEFT", tab.announceAwardsDesc, "BOTTOMLEFT", 0, -7)
	tab.announceAwardsChannel =
		UI:New('Dropdown', content, nil, tab.announceAwardsDesc:GetWidth() / 3, 10)
			:Tooltip(L["channel_desc"])
			:Point("TOPLEFT", tab.announceAwardsChannelLabel, "BOTTOMLEFT", 0, -5)
			:SetList(Util.Tables.Copy(C.ChannelDescriptions), ChannelListSort)
			:Datasource(
				module,
				module.db.profile,
				'announceAwardText.channel'
			)
	tab.announceAwardsMessageLabel =
		UI:New('Text', content, L["message"])
	        :Point("LEFT", tab.announceAwardsChannelLabel, "RIGHT", (tab.announceAwardsDesc:GetWidth() / 3), 0)
	tab.announceAwardsMessage =
		UI:New('EditBox', content)
			:Size(250,20)
			:Point("TOPLEFT", tab.announceAwardsMessageLabel, "BOTTOMLEFT", 0, -5)
			:Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
			:Tooltip(L["message_desc"])
			:Datasource(
				module,
				module.db.profile,
				'announceAwardText.text'
			)

	-- items (START)
	content = tab.scroll.content
	tab.itemsGroup =
		UI:New('InlineGroup',content)
		  :Point("TOPLEFT", tab.awardsGroup, "BOTTOMLEFT", 0, -5)
		  :Point("TOPRIGHT", tab.awardsGroup, "BOTTOMRIGHT", 0, 0)
		  :SetHeight(265)
		  :Title(L["items"])
	content = tab.itemsGroup.content
	tab.announceItems =
		UI:New('Checkbox', content, L["announce_items"], false)
		    :Point("TOPLEFT", content, "TOPLEFT", 5, -5)
		    :TextSize(12)
			:Tooltip(L["announce_items_desc"])
		    :Datasource(
				module,
				module.db.profile,
				'announceItems'
			)
	tab.announceItems:SetSize(14, 14)
	tab.announceItemsDesc =
		UI:New('Text', content, L["announce_items_desc_detail"])
				:Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
				:Point("TOPLEFT", tab.announceItems, "BOTTOMLEFT", 0, -2)
				:Point("RIGHT", content, "RIGHT", 0, 0)
	tab.announceItemsChannelLabel =
		UI:New('Text', content, L["channel"])
		  :Point("TOPLEFT", tab.announceItemsDesc, "BOTTOMLEFT", 0, -7)
	tab.announceItemsChannel =
		UI:New('Dropdown', content, nil, tab.announceItemsDesc:GetWidth() / 2, 10)
	        :Tooltip(L["channel_desc"])
	        :Point("TOPLEFT", tab.announceItemsChannelLabel, "BOTTOMLEFT", 0, -5)
	        :SetList(Util.Tables.Copy(C.ChannelDescriptions), ChannelListSort)
	        :Datasource(
					module,
					module.db.profile,
					'announceItemText.channel'
			)
	tab.announceItemsHeaderLabel =
		UI:New('Text', content, L["message_header"])
	        :Point("LEFT", tab.announceItemsChannelLabel, "RIGHT", (tab.announceItemsDesc:GetWidth() / 2), 0)
	tab.announceItemsHeader =
		UI:New('EditBox', content)
	        :Size(250,20)
	        :Point("TOPLEFT", tab.announceItemsHeaderLabel, "BOTTOMLEFT", 0, -5)
	        :Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
	        :Tooltip(L["message_header_desc"])
	        :Datasource(
				module,
				module.db.profile,
				'announceItemPrefix'
			)
	tab.announceItemsDesc2 =
		UI:New('Text', content, L["announce_items_desc_detail2"] .. '\n' ..  Util.Strings.Join('\n', unpack(ML.AnnounceItemStringsDesc)))
	        :Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
	        :Point("TOPLEFT", tab.announceItemsChannel, "BOTTOMLEFT", 0, -2)
	        :Point("RIGHT", content, "RIGHT", 0, 0)
	tab.announceItemsMessageLabel =
		UI:New('Text', content, L["message"])
			:Point("TOPLEFT", tab.announceItemsDesc2, "BOTTOMLEFT", 0, -5)
	tab.announceItemsMessage =
		UI:New('EditBox', content)
			:Size(250,20)
		    :Point("TOPLEFT", tab.announceItemsMessageLabel, "BOTTOMLEFT", 0, -5)
		    :Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
		    :Tooltip(L["message_desc"])
		    :Datasource(
				module,
				module.db.profile,
				'announceItemText.text'
			)

	UI:New('Text', content, L["message"])
		  :Point("TOPLEFT", tab.announceItemsDesc2, "BOTTOMLEFT", 0, -5)

	-- responses (START)
	content = tab.scroll.content
	tab.responsesGroup =
		UI:New('InlineGroup',content)
		  :Point("TOPLEFT", tab.itemsGroup, "BOTTOMLEFT", 0, -5)
		  :Point("TOPRIGHT", tab.itemsGroup, "BOTTOMRIGHT", 0, 0)
		  :SetHeight(260)
		  :Title(L["responses"])
	content = tab.responsesGroup.content
	tab.announceResponses =
		UI:New('Checkbox', content, L["announce_responses"], false)
			:Point("TOPLEFT", content, "TOPLEFT", 5, -5)
		    :TextSize(12)
			:Tooltip(L["announce_responses_desc"])
		    :Datasource(
				module,
				module.db.profile,
				'announceResponses'
			)
	tab.announceResponses:SetSize(14, 14)
	tab.announceResponsesDesc =
		UI:New('Text', content, L["announce_responses_desc_detail"].. '\n' ..  Util.Strings.Join('\n', unpack(ML.AwardStringsDesc)))
		  :Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
		  :Point("TOPLEFT", tab.announceResponses, "BOTTOMLEFT", 0, -2)
		  :Point("RIGHT", content, "RIGHT", 0, 0)
	tab.announceResponsesChannelLabel =
		UI:New('Text', content, L["channel"])
		  :Point("TOPLEFT", tab.announceResponsesDesc, "BOTTOMLEFT", 0, -7)
	tab.announceResponsesChannel =
		UI:New('Dropdown', content, nil, tab.announceResponsesDesc:GetWidth() / 3, 10)
		  :Tooltip(L["channel_desc"])
		  :Point("TOPLEFT", tab.announceResponsesChannelLabel, "BOTTOMLEFT", 0, -5)
		  :SetList(Util.Tables.Copy(C.ChannelDescriptions), ChannelListSort)
		  :Datasource(
				module,
				module.db.profile,
				'announceResponseText.channel'
		)
	tab.announceResponseMessageLabel =
		UI:New('Text', content, L["message"])
		  :Point("LEFT", tab.announceResponsesChannelLabel, "RIGHT", (tab.announceAwardsDesc:GetWidth() / 3), 0)
	tab.announceAwardsMessage =
		UI:New('EditBox', content)
		  :Size(250,20)
		  :Point("TOPLEFT", tab.announceResponseMessageLabel, "BOTTOMLEFT", 0, -5)
		  :Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
		  :Tooltip(L["message_desc"])
		  :Datasource(
				module,
				module.db.profile,
				'announceResponseText.text'
		)

	self.announcementsTab = tab
end

local AutoAwardTypeList = {
	[ML.AutoAwardType.All]          = L['all'],
	[ML.AutoAwardType.Equipable]    = L['equipable'],
	[ML.AutoAwardType.NotEquipable] = L['equipable_not'],
}

-- mapping from sort index to key
local AutoAwardTypeListSort = {}

do
	local index = 1
	for _, v in Util.Tables.OrderedPairs(Util.Tables.Flip(AutoAwardTypeList)) do
		AutoAwardTypeListSort[index] = v
		index = index + 1
	end
end

function ML:LayoutAutoAwardsTab(tab)
	local module = self

	tab.itemsGroup =
		UI:New('InlineGroup',tab)
		  :Point("TOPLEFT", tab, "TOPLEFT", 5, -30)
		  :Point("TOPRIGHT", tab, "TOPRIGHT", -20, 0)
		  :SetHeight(150)
		  :Title(L["items"])

	local content = tab.itemsGroup.content
	tab.itemsAutoAward =
		UI:New('Checkbox', content, L["auto_awards"], false)
		  :Point("TOPLEFT", content, "TOPLEFT", 5, -5)
		  :TextSize(12)
		  :Tooltip(L["auto_award_desc"])
		  :Datasource(
				module,
				module.db.profile,
				'autoAward'
		)
	tab.itemsAutoAward:SetSize(14, 14)
	tab.itemsAATypeLabel =
		UI:New('Text', content, L["auto_award_type"])
		  :Point("TOPLEFT", tab.itemsAutoAward, "BOTTOMLEFT", 0, -10)
	tab.itemsAAType =
		UI:New('Dropdown', content, nil, tab.itemsGroup:GetWidth() / 4, 3)
		  :Tooltip(L["auto_award_type_desc"])
		  :Point("TOPLEFT", tab.itemsAATypeLabel, "BOTTOMLEFT", 0, -5)
		  :SetList(AutoAwardTypeList, AutoAwardTypeListSort)
		  :Datasource(
				module,
				module.db.profile,
				'autoAwardType'
		)
	tab.itemsAALowerThresholdLabel =
		UI:New('Text', content, L["lower_quality_limit"])
			:Point("LEFT", tab.itemsAATypeLabel, "RIGHT", tab.itemsAAType:GetWidth() - 35, 0)
	tab.itemsAALowerThreshold =
		UI:New('Dropdown', content, nil, tab.itemsGroup:GetWidth() / 4, 6)
		  :Tooltip(L["lower_quality_limit_desc"])
		  :Point("TOPLEFT", tab.itemsAALowerThresholdLabel, "BOTTOMLEFT", 0, -5)
		  :SetList(Util.Tables.Copy(C.ItemQualityColoredDescriptions))
		  :Datasource(
				module,
				module.db.profile,
				'autoAwardLowerThreshold'
		)
	tab.itemsAALowerThresholdLabel =
		UI:New('Text', content, L["upper_quality_limit"])
		  :Point("LEFT", tab.itemsAALowerThresholdLabel, "RIGHT", tab.itemsAALowerThreshold:GetWidth() - 70, 0)
	tab.itemsAALowerThreshold =
		UI:New('Dropdown', content, nil, tab.itemsGroup:GetWidth() / 4, 6)
		  :Tooltip(L["upper_quality_limit_desc"])
		  :Point("TOPLEFT", tab.itemsAALowerThresholdLabel, "BOTTOMLEFT", 0, -5)
		  :SetList(Util.Tables.Copy(C.ItemQualityColoredDescriptions))
		  :Datasource(
				module,
				module.db.profile,
				'autoAwardUpperThreshold'
		)

	tab.itemsAAAwardToLabel =
		UI:New('Text', content, L["award_to"])
		  :Point("TOPLEFT", tab.itemsAAType, "BOTTOMLEFT", 0, -10)
	tab.itemsAAAwardTo =
		UI:New('Dropdown', tab, nil, tab.itemsGroup:GetWidth() / 3, 20)
			:Tooltip(L["auto_award_to_desc"])
			:Point("TOPLEFT", tab.itemsAAAwardToLabel, "BOTTOMLEFT", 0, -5)
			:SetTextDecorator(
				function(item)
					return UIUtil.ClassColorDecorator(item.value.class):decorate(item.value:GetShortName())
				end
			)
			:Datasource(
				module,
				module.db.profile,
				'autoAwardTo'
			)
	tab.itemsAAAwardTo.Refresh = function(self)
		local players = AddOn:Players(true, true, true)
		-- see MasterLooter.defaults.autoAwardTo
		players[L["nobody"]] = Player.Nobody()
		self:SetList(players)
	end

	tab.itemsAAAwardReasonLabel =
		UI:New('Text', content, L["reason"])
			:Point("LEFT", tab.itemsAAAwardToLabel, "RIGHT", tab.itemsAAAwardTo:GetWidth() - 25, 0)
	tab.itemsAAAwardReason =
		UI:New('Dropdown', tab, nil, tab.itemsGroup:GetWidth() / 4, 15)
			:Tooltip(L["auto_award_reason_desc"])
			:Point("TOPLEFT", tab.itemsAAAwardReasonLabel, "BOTTOMLEFT", 0, -5)
			:SetList(module.NonVisibleAwardReasons)
			:Datasource(
				module,
				module.db.profile,
				'autoAwardReason'
			)

	tab:SetScript(
		"OnShow",
		function(self)
			self.itemsAAAwardTo:Refresh()
		end
	)

	self.autoAwardsTab = tab
end

local UsageTypeDesc = {
	[ML.UsageType.Always]  = L["usage_ml"],
	[ML.UsageType.Ask]     = L["usage_ask_ml"],
	[ML.UsageType.Never]   = L["usage_never"],
}

local ListConfigSelectionMethodDesc = {
	[ML.ListConfigSelectionMethod.Ask]      = L["list_config_select_ask"],
	[ML.ListConfigSelectionMethod.Default]  = L["list_config_select_default"],
}

function ML:LayoutGeneralTab(tab)
	local module = self

	tab.usageGroup =
		UI:New('InlineGroup',tab)
		  :Point("TOPLEFT", tab, "TOPLEFT", 5, -30)
		  :Point("TOPRIGHT", tab, "TOPRIGHT", -20, 0)
		  :SetHeight(85)
		  :Title(L["usage"])

	local content = tab.usageGroup.content
	tab.usage =
		UI:New('Dropdown', tab, nil, tab.usageGroup:GetWidth() / 2, 3)
			:Tooltip(L["usage_desc"])
			:Point("TOPLEFT", content, "TOPLEFT", 5, -5)
			:SetList(Util.Tables.Copy(UsageTypeDesc))
			:Datasource(
				module,
				module.db.profile,
				'usage.state',
				nil,
				function(value)
					if value == ML.UsageType.Always then
						tab.leaderUsage:Text(L["usage_leader_always"])
					elseif value == ML.UsageType.Ask then
						tab.leaderUsage:Text(L["usage_leader_ask"])
					end

					if value == ML.UsageType.Never then
						tab.leaderUsage:Disable()
						tab.onlyUseInRaids:Disable()
						tab.outOfRaid:Disable()
					else
						tab.leaderUsage:Enable()
						tab.onlyUseInRaids:Enable()
						tab.outOfRaid:Enable()
					end
				end
			)
	UI:New('DecorationLine', content, true, "BACKGROUND", -5)
			:Point("TOPLEFT", tab.usage, "BOTTOMLEFT", 0, -10)
			:Point("RIGHT", content, "RIGHT", -5, 0)
	        :Color(C.Colors.ItemPoor.r, C.Colors.ItemPoor.g, C.Colors.ItemPoor.g, C.Colors.ItemPoor.a, 0.50)

	tab.leaderUsage =
		UI:New('Checkbox', content, nil, false)
			:Point("TOPLEFT", tab.usage, "BOTTOMLEFT", 0, -20)
		    :TextSize(12)
		    :Tooltip(L["usage_leader_desc"])
			:Datasource(
				module,
				module.db.profile,
				'usage.whenLeader'
			)
	tab.leaderUsage:SetSize(14, 14)
	tab.onlyUseInRaids =
		UI:New('Checkbox', content, L["only_use_in_raids"], false)
			:Point("TOPLEFT", tab.leaderUsage, "TOPRIGHT", 150, 0)
		    :TextSize(12)
		    :Tooltip(L["only_use_in_raids_desc"])
			:Datasource(
				module,
				module.db.profile,
				'onlyUseInRaids'
			)
	tab.onlyUseInRaids:SetSize(14, 14)
	tab.outOfRaid =
		UI:New('Checkbox', content, L["out_of_raid"], false)
			:Point("TOPLEFT", tab.onlyUseInRaids, "TOPRIGHT", 150, 0)
		    :TextSize(12)
		    :Tooltip(L["out_of_raid_desc"])
			:Datasource(
				module,
				module.db.profile,
				'outOfRaid'
			)
	tab.outOfRaid:SetSize(14, 14)

	tab.listConfigGroup =
		UI:New('InlineGroup',tab)
	        :Point("TOPLEFT", tab.usageGroup, "BOTTOMLEFT", 0, -5)
	        :Point("TOPRIGHT", tab.usageGroup, "BOTTOMRIGHT", 0, 0)
	        :SetHeight(87)
	        :Title(L["list_configuration"])

	content = tab.listConfigGroup.content
	tab.lcSelectionDesc =
		UI:New('Text', content, L["list_configuration_desc"])
		    :Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
		    :Point("TOPLEFT", content, "TOPLEFT", 5, -5)
			:Point("RIGHT", content, "RIGHT", 0, 0)

	tab.lcSelectionMethod =
		UI:New('Dropdown', tab, nil, tab.usageGroup:GetWidth() / 2, 3)
			:Tooltip(L["list_configuration_selection_desc"])
			:Point("TOPLEFT", tab.lcSelectionDesc, "BOTTOMLEFT", 0, -7)
			:SetList(Util.Tables.Copy(ListConfigSelectionMethodDesc))
			:Datasource(
				module,
				module.db.profile,
				'lcSelectionMethod'
			)

	tab.lootGroup =
		UI:New('InlineGroup',tab)
			:Point("TOPLEFT", tab.listConfigGroup, "BOTTOMLEFT", 0, -5)
			:Point("TOPRIGHT", tab.listConfigGroup, "BOTTOMRIGHT", 0, 0)
	        :SetHeight(87)
	        :Title(L["loot"])
	content = tab.lootGroup.content

	tab.autoStartSession =
		UI:New('Checkbox', content, L["auto_start"], false)
		  :Point("TOPLEFT", content, "TOPLEFT", 5, -15)
		  :TextSize(12)
		  :Tooltip(L["auto_start_desc"])
		  :Datasource(
				module,
				module.db.profile,
				'autoStart'
		)
	tab.autoStartSession:SetSize(14, 14)

	tab.awardLater =
		UI:New('Checkbox', content, L["award_later"], false)
			:Point("TOPLEFT", tab.autoStartSession, "TOPRIGHT", 150, 0)
		    :TextSize(12)
		    :Tooltip(L["award_later_description"])
		    :Datasource(
				module,
				module.db.profile,
				'awardLater'
			)
	tab.awardLater:SetSize(14, 14)

	UI:New('DecorationLine', content, true, "BACKGROUND", -5)
			:Point("TOPLEFT", tab.autoStartSession, "BOTTOMLEFT", 0, -10)
			:Point("RIGHT", content, "RIGHT", -5, 0)
			:Color(C.Colors.ItemPoor.r, C.Colors.ItemPoor.g, C.Colors.ItemPoor.g, C.Colors.ItemPoor.a, 0.50)
	tab.autoAddItems =
		UI:New('Checkbox', content, L["auto_add_items"], false)
			:Point("TOPLEFT", tab.autoStartSession, "BOTTOMLEFT", 0, -20)
		    :TextSize(12)
		    :Tooltip(L["auto_add_items_desc"])
		    :Datasource(
				module,
				module.db.profile,
				'autoAdd',
				nil,
				function(value)
					if value then
						tab.autoAddNonEquipable:Enable()
						tab.autoAddBOE:Enable()
					else
						tab.autoAddNonEquipable:Disable()
						tab.autoAddBOE:Disable()
					end
				end
			)
	tab.autoAddItems:SetSize(14, 14)
	tab.autoAddNonEquipable =
		UI:New('Checkbox', content, format(L["auto_add_x_items"], L["equipable_not"]), false)
			:Point("TOPLEFT", tab.autoAddItems, "TOPRIGHT", 150, 0)
		    :TextSize(12)
		    :Tooltip(L["auto_add_non_equipable_desc"])
		    :Datasource(
				module,
				module.db.profile,
				'autoAddNonEquipable'
			)
	tab.autoAddNonEquipable:SetSize(14, 14)
	tab.autoAddBOE =
		UI:New('Checkbox', content, format(L["auto_add_x_items"], 'BOE'), false)
			:Point("TOPLEFT", tab.autoAddNonEquipable, "TOPRIGHT", 200, 0)
			:TextSize(12)
			:Tooltip(L["auto_add_boe_desc"])
			:Datasource(
				module,
				module.db.profile,
				'autoAddBoe'
			)
	tab.autoAddBOE:SetSize(14, 14)

	tab:SetScript(
			"OnShow",
			function(_)
				local usage = module:GetDbValue(module.db.profile, 'usage.state')

				if usage == ML.UsageType.Always then
					tab.leaderUsage:Text(L["usage_leader_always"])
				elseif usage == ML.UsageType.Ask then
					tab.leaderUsage:Text(L["usage_leader_ask"])
				end

				if usage == ML.UsageType.Never then
					tab.leaderUsage:Disable()
					tab.onlyUseInRaids:Disable()
					tab.outOfRaid:Disable()
				end

				local autoStart = module:GetDbValue(module.db.profile, 'autoAdd')
				if not autoStart then
					tab.autoAddNonEquipable:Disable()
					tab.autoAddBOE:Disable()
				end
			end
	)

	self.generalTab = tab
end

function ML:LayoutResponsesTab(tab)
	local module = self

	tab.timeoutGroup =
		UI:New('InlineGroup',tab)
		  :Point("TOPLEFT", tab, "TOPLEFT", 5, -30)
		  :Point("TOPRIGHT", tab, "TOPRIGHT", -20, 0)
		  :SetHeight(105)
		  :Title(L["timeout"])

	local content = tab.timeoutGroup.content
	tab.timeoutEnabled =
		UI:New('Checkbox', content, L["timeout_enable"], false)
			:Point("TOPLEFT", content, "TOPLEFT", 5, -5)
		    :TextSize(12)
		    :Tooltip(L["timeout_enable_desc"])
		    :Datasource(
				module,
				module.db.profile,
				'timeout.enabled',
				nil,
				function(_)
					if tab.UpdateFields then
						tab:UpdateFields()
					end
				end
			)
	tab.timeoutEnabled:SetSize(14, 14)
	UI:New('DecorationLine', content, true, "BACKGROUND", -5)
			:Point("TOPLEFT", tab.timeoutEnabled, "BOTTOMLEFT", 0, -10)
	        :Point("RIGHT", content, "RIGHT", -5, 0)
	        :Color(C.Colors.ItemPoor.r, C.Colors.ItemPoor.g, C.Colors.ItemPoor.g, C.Colors.ItemPoor.a, 0.50)
	tab.timeoutDuration =
		UI:New('Slider', content, true)
			:SetText(L["timeout_duration"])
			:Tooltip(L["timeout_duration_desc"])
			:Size(250)
			:EditBox()
			:Point("TOPLEFT", tab.timeoutEnabled, "BOTTOMLEFT", 0, -30)
			:Range(0, 240)
			:Datasource(
				module,
				module.db.profile,
				'timeout.duration'
			)

	tab.visibilityGroup =
		UI:New('InlineGroup',tab)
		  :Point("TOPLEFT", tab.timeoutGroup, "BOTTOMLEFT",  0, -5)
		  :Point("TOPRIGHT", tab.timeoutGroup, "BOTTOMRIGHT",0, 0)
		  :SetHeight(50)
		  :Title(L["visibility"])
	content = tab.visibilityGroup.content
	tab.showLootResponses =
		UI:New('Checkbox', content, L["responses_visible_enable"], false)
			:Point("TOPLEFT", content, "TOPLEFT", 5, -5)
			:TextSize(12)
			:Tooltip(L["responses_visible_desc"])
			:Datasource(
				module,
				module.db.profile,
				'showLootResponses'
			)
	tab.showLootResponses:SetSize(14, 14)

	tab.suicideGroup =
		UI:New('InlineGroup',tab)
		  :Point("TOPLEFT", tab.visibilityGroup, "BOTTOMLEFT",  0, -5)
		  :Point("TOPRIGHT", tab.visibilityGroup, "BOTTOMRIGHT",0, 0)
		  :SetHeight(130)
		  :Title(L["suicide_settings"])
	content = tab.suicideGroup.content
	tab.suicideDesc =
		UI:New('Text', content, L["suicide_settings_desc"])
		  :Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
		  :Point("TOPLEFT", tab.suicideGroup, "TOPLEFT", 15, -15)
		  :Point("RIGHT", content, "RIGHT", 0, 0)

	tab.AddSuicideAmounts = function(self)
		if not self.suicideAmounts then
			self.suicideAmounts = {}
			local buttons, content = module.db.profile.buttons, tab.suicideGroup.content
			for _, index in pairs(buttons.ordering) do
				local button = buttons[index]
				local reason = module.AwardReasons[button.key]
				local count = #self.suicideAmounts

				if reason and Util.Objects.Default(reason.suicide, false) and reason.suicide_amt then
					local anchorPoint = count > 0 and self.suicideAmounts[count] or self.suicideDesc
					self.suicideAmounts[count + 1] =
						UI:New('Slider', content, true)
					        :SetText(L[button.key])
							:Tooltip(L["suicide_amount_desc"])
					        :Size(250)
					        :EditBox()
					        :Range(0, 25)
					        :Datasource(
								module,
								module.db.profile.buttons[index],
								'suicide_amt'
							)

					self.suicideAmounts[count+1].Text:SetTextColor(button.color.r, button.color.g, button.color.b, button.color.a)

					if count > 0 then
						self.suicideAmounts[count + 1]:Point("LEFT", anchorPoint, "RIGHT", 15, 0)
					else
						self.suicideAmounts[count + 1]:Point("TOPLEFT", anchorPoint, "BOTTOMLEFT", 10, -15)
					end

					count = count +1
				end
			end
		end
	end

	tab.whispersGroup =
		UI:New('InlineGroup',tab)
			:Point("TOPLEFT", tab.suicideGroup, "BOTTOMLEFT",  0, -5)
			:Point("TOPRIGHT", tab.suicideGroup, "BOTTOMRIGHT",0, 0)
			:SetHeight(225)
			:Title(L["whispers"])
	content = tab.whispersGroup.content
	tab.acceptWhispers =
		UI:New('Checkbox', content, L["accept_whispers"], false)
		  :Point("TOPLEFT", content, "TOPLEFT", 5, -5)
		  :TextSize(12)
		  :Tooltip(L["accept_whispers_desc"])
		  :Datasource(
				module,
				module.db.profile,
				'acceptWhispers',
				nil,
				function(_)
					if tab.UpdateFields then
						tab:UpdateFields()
					end
				end
		)
	tab.acceptWhispers:SetSize(14, 14)
	tab.whispersDesc =
		UI:New('Text', content, L["responses_from_chat_desc"])
		  :Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
		  :Point("TOPLEFT", tab.acceptWhispers, "BOTTOMLEFT", 0, -5)
		  :Point("RIGHT", content, "RIGHT", 0, 0)

	tab.AddWhisperResponses = function(self)
		if not self.whisperResponses then
			self.whisperResponses = {}

			local buttons, content = module.db.profile.buttons, self.whispersGroup.content
			for i, index in pairs(buttons.ordering) do
				local button = buttons[index]
				--Logging:Warn("Button(%d) = %s", index, Util.Objects.ToString(button))
				local anchorPoint = (i==1) and self.whispersDesc or self.whisperResponses[i - 1]
				self.whisperResponses[i] =
					UI:New('EditBox', content)
						:Size(250, 20)
						:Point("TOPLEFT", anchorPoint, "BOTTOMLEFT", (i==1) and 85 or 0, -10)
						:Color(C.Colors.White.r, C.Colors.White.g, C.Colors.White.b, C.Colors.White.a)
						:LeftText(L[button.text])
				self.whisperResponses[i].leftText:Color(button.color.r, button.color.g, button.color.b, button.color.a)
				self.whisperResponses[i]:Text(button.whisperKey)
				self.whisperResponses[i]:OnChange(
					Util.Functions.Debounce(
							function(self, userInput)
								Logging:Trace("EditBox.OnChange(%s)", tostring(userInput))
								if userInput then
									button.whisperKey = self:GetText()
								end
							end,    -- function
							1,      -- seconds
							true    -- leading
					)
				)
			end
		end
	end

	tab.UpdateFields = function(self)
		local timeoutEnabled = module:GetDbValue(module.db.profile, 'timeout.enabled')
		if timeoutEnabled then
			self.timeoutDuration:SetEnabled(true)
		else
			self.timeoutDuration:SetEnabled(false)
		end

		local acceptWhispers = module:GetDbValue(module.db.profile, 'acceptWhispers')
		for i=1, #self.whisperResponses do
			self.whisperResponses[i]:SetEnabled(acceptWhispers)
		end
	end

	tab:SetScript(
			"OnShow",
			function(self)
				self:AddSuicideAmounts()
				self:AddWhisperResponses()
				self:UpdateFields()
			end
	)

	self.responsesTab = tab
end

function ML:PromptForConfigSelection()
	Dialog:Spawn(C.Popups.SelectConfiguration)
end

function ML:LayoutConfigSelectionPopup(frame, ...)
	UIUtil.DecoratePopup(frame)

	local module = self

	-- a bunch of mumbo jumbo to add widgets to LibDialog popup
	-- and then not have them show up on later reuse
	if not frame.csContainer then
		frame.csContainer = CreateFrame("Frame", "ConfigSelectContainer", frame)
		frame.csContainer:SetSize(30, 250)
		frame.csContainer:SetPoint("CENTER", frame, "CENTER")

		frame.configSelection =
			UI:New('Dropdown', frame.csContainer)
				:Size(250)
			    :Point("CENTER", frame.csContainer, "CENTER")
				:Tooltip(L["configuration"], L['active_configs_desc'])
				:OnShow(
					function(self, ...)
						local configs = AddOn:ListsModule():GetService():Configurations(true)
						Util.Tables.Filter(configs, function(c) return c:IsAdminOrOwner(AddOn.player) end)
						self:SetList(configs)
					end,
					false
				)
				:OnValueChanged(
					function(item)
						frame.data = item.value
					end
				)
	else
		frame.csContainer:Show()
	end
end

-- neuter the dialog we added to previously
function ML:NeuterConfigSelectionPopup(frame)
	if frame.csContainer then
		frame.csContainer:Hide()
	end
end