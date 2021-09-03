local name, _ = ...
local name_lower = name:lower()

local L = LibStub("AceLocale-3.0"):NewLocale(name, "enUS", true, true)
if not L then return end