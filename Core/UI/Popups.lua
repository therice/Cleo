--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')

local MachuPicchu = "hey, ho, let's go!"

Dialog:Register(C.Popups.ConfirmUsage, {
    text = L["confirm_usage_text"],
    on_show = function(self) UIUtil.DecoratePopup(self) end,
    buttons = {
        {
            text = _G.YES,
            on_click = function() AddOn:StartHandleLoot() end,
        },
        {
            text = _G.NO,
            on_click = function() AddOn:Print(L["is_not_active_in_this_raid"]) end,
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmAbort, {
    text = L["confirm_abort"],
    on_show = function(self) UIUtil.DecoratePopup(self) end,
    buttons = {
        {
            text = _G.YES,
            on_click = function()
                AddOn:MasterLooterModule():EndSession()
                CloseLoot()
                AddOn:LootAllocateModule():EndSession(true)
            end,
        },
        {
            text = _G.NO,
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmAward, {
    text = MachuPicchu,
    icon = "",
    on_show = AddOn:MasterLooterModule().AwardOnShow,
    buttons = {
        {
            text = _G.YES,
            on_click = AddOn:MasterLooterModule().AwardOnClickYes
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmBroadcastDelete, {
    text = MachuPicchu,
    on_show = AddOn:ListsModule().ConfirmBroadcastDeleteOnShow,
    width = 400,
    buttons = {
        {
            text = _G.YES,
            on_click = function(_, params, _)
                local configId, target = params['configId'], params['target']
                AddOn:ListsDataPlaneModule():BroadcastRemove(configId, target)
            end,
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmDeleteItem, {
    text = MachuPicchu,
    on_show = AddOn:CustomItemsModule().DeleteItemOnShow,
    width = 400,
    buttons = {
        {
            text = _G.YES,
            on_click = function(...) AddOn:CustomItemsModule():DeleteItemOnClickYes(...) end,
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})


Dialog:Register(C.Popups.ConfirmDeleteListConfig, {
    text = MachuPicchu,
    on_show = AddOn:ListsModule().DeleteConfigurationOnShow,
    width = 400,
    buttons = {
        {
            text = _G.YES,
            on_click = function(...) AddOn:ListsModule():DeleteConfigurationOnClickYes(...) end,
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmDeleteListList, {
    text = MachuPicchu,
    on_show = AddOn:ListsModule().DeleteListOnShow,
    width = 400,
    buttons = {
        {
            text = _G.YES,
            on_click = function(...) AddOn:ListsModule():DeleteListOnClickYes(...) end,
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})


Dialog:Register(C.Popups.ConfirmReannounceItems, {
    text = MachuPicchu,
    on_show = function(self, data)
        UIUtil.DecoratePopup(self)
        if data.isRoll then
            self.text:SetText(format(L["confirm_rolls"], data.target))
        else
            self.text:SetText(format(L["confirm_unawarded"], data.target))
        end
    end,
    buttons = {
        {
            text = _G.YES,
            on_click = function(_, data)
                data.func()
            end,
        },
        {
            text = _G.NO,
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmSync, {
    text = format("%s : |cfffcd400%s|r", L['addon_name_colored'], L['incoming_sync_request']),
    on_show = AddOn:SyncModule().ConfirmSyncOnShow,
    buttons = {
        {
            text = _G.YES,
            on_click = function(_, data, ...) AddOn:SyncModule():OnSyncAccept(data) end,
        },
        {
            text = _G.NO,
            on_click = function(_, data, ...) AddOn:SyncModule():OnSyncDeclined(data) end,
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.SelectConfiguration, {
    text = format("%s : |cfffcd400%s|r", L['addon_name_colored'], L['select_configuration']),
    height = 60,
    on_show = function(...) AddOn:MasterLooterModule():LayoutConfigSelectionPopup(...) end,
    buttons = {
        {
            text = L["select"],
            on_click = function(frame, ...)
                --Logging:Debug("SelectConfiguration() : %s", Util.Objects.ToString({...}))
                AddOn:MasterLooterModule():NeuterConfigSelectionPopup(frame)
                -- see on_show function
                AddOn:MasterLooterModule():ActivateConfiguration(frame.data --[[ will be Configuration instance --]])
            end,
        },
        {
            text = _G.CANCEL,
            on_click = function(frame, ...)
                AddOn:MasterLooterModule():NeuterConfigSelectionPopup(frame)
            end
        },
    },
    hide_on_escape = false,
    show_while_dead = true,
})