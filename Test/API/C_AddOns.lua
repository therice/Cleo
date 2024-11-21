-- https://github.com/Gethe/wow-ui-source/blob/703e072b4f993d3242317ee84d6739c80066391b/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua
--
-- partial implementation of https://warcraft.wiki.gg/wiki/World_of_Warcraft_API#C_AddOns
--
C_AddOns = {}

function C_AddOns.IsAddOnLoaded(name)
	-- stupid workaround for MSA-DropDownMenu
	if name == "ElvUI" or name == "Tukui" or name == "Aurora" then
		return false
	end

	return true
end


_G.C_AddOns = C_AddOns