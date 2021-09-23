local name, _ = ...
local name_lower = name:lower()
local name_colored = "|cFF9DDAE6" .. name .. "|r"

local L = LibStub("AceLocale-3.0"):NewLocale(name, "enUS", true, true)
if not L then return end

L["active"] = "Active"
L["active_desc"] = "Disables " .. name .. " when unchecked. Note: This resets on every logout or UI reload."
L["add"] = "Add"
L["add_item"] = "Add Item"
L["author"] = "Author"
L["change_log"] = "Change Log"
L["chat_commands_config"]  = "Open the configuration interface"
L["chat_commands_dev"]  = "Toggle development mode"
L["chat_commands_pm"]  = "Toggle persistence mode"
L["chat_commands_version"] = "Open the version checker (alternatives 'v' or 'ver') - can specify boolean as argument to show outdated clients"
L["chat_version"] = "|cFF87CEFA" .. name .. "|r |cFFFFFFFFversion|r|cFFFFA500 %s|r"
L["clear"] = "Clear"
L["clear_item_cache"] = "Clear Item Cache"
L["clear_item_cache_desc"] = "Clears the item cache"
L["clear_player_cache"] = "Clear Player Cache"
L["clear_player_cache_desc"] = "Clears the player information cache"
L["configuration"] = "Configuration"
L["confirm_delete_entry"] = "Are you certain you want to delete %s?"
L["custom_items"] = "Custom Items"
L["custom_items_desc"] = "Customization of Item(s)"
L["custom_items_help"] = "Configure custom items and associated attributes(e.g. Magtheridon's Head)"
L["delete"] = "Delete"
L["double_click_to_delete_this_entry"] = "Double click to delete %s"
L["enable"] = "Enable"
L["enabled_desc"] = "Disables " .. name .. " when unchecked.\nNote: This resets on every logout or UI reload."
L["enabled_generic_desc"] = "Disables %s when unchecked."
L["equipment_loc"] = "Equipment Location"
L["equipment_loc_desc"] = "The type of the item, which includes where it can be equipped"
L["frame_add_custom_item"] = "" .. name_colored .. " : Add Custom Item"
L["frame_logging"] = "" .. name_colored .. " : Logging"
L["general"] = "General"
L["general_desc"] = "General configuration settings"
L["invalid_item_id"] = "Item Id must be a number"
L["item"] = "item"
L["item_id"] = "Item Id"
L["item_add_search_desc"] = "Enter the id of the item you wish to add.\nIf found, attributes will automatically be populated."
L["item_lvl"] = "Item Level"
L["item_lvl_desc"] = "A rough indicator of the power and usefulness of an item, designed to reflect the overall benefit of using the item."
L["left_click"] = "Left Click"
L["lists"] = "Lists"
L["list_config_name_desc"] = "The name of the configuration"
L["list_config_owner_desc"] = "The owner of the conifguration (TODO)"
L["list_configs"] = "Configuration(s)"
L["list_configs_desc"] = "A description of a configuration (TODO)"
L["list_config_dd_desc"] = "Select the configuration to display"
L["list_lists"] = "List(s)"
L["list_lists_desc"] = "A description of a list (TODO)"
L["logging"] = "Logging"
L["logging_desc"] = "Logging configuration"
L["logging_help"] = "Configuration settings for logging, such as threshold at which logging is emitted."
L["logging_threshold"] = "Logging threshold"
L["logging_threshold_desc"] = "All logging events with an associated level less than this threshold are ignored"
L["logging_window_toggle"] = "Toggle Logging Window"
L["logging_window_toggle_desc"] = "Toggle the display of the logging output window"
L["minimize_in_combat"] = "Minimize while in combat"
L["minimize_in_combat_desc"] = "Enable to minimize all frames when entering combat"
L["name"] = "Name"
L["open_config"] = "Open/Close Configuration"
L["open_standings"] = "Open/Close Standings"
L["owner"] = "Owner"
L["quality"] = "Quality"
L["quality_desc"] = "The relationship of the item level (which determines the sizes of the stat bonuses on it) to the required level to equip it.\nIt also determines the number of different stat bonuses."
L["right_click"] = "Right Click"
L["shift_left_click"] = "Shift + Left Click"
L["sync"] = "Synchronize"
L["sync_desc"] = "Allows synchronization of settings between guild or group members"
L["test_desc"] = "Click to simulate the master looting of items for yourself and anyone in your group/raid\nEquivalent to /" .. name_lower .. " test #"
L["Test"] = "Test"
L["unguilded"] = "Unguilded"
L["version"] = "Version"
L["version_check"] = "Version Check"
L["version_check_desc"] = "Query what version(s) of " .. name .. " each group or guild member has installed"