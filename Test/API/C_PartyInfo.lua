-- https://github.com/Gethe/wow-ui-source/blob/703e072b4f993d3242317ee84d6739c80066391b/Interface/AddOns/Blizzard_APIDocumentationGenerated/PartyInfoDocumentation.lua
--
-- partial implementation of https://warcraft.wiki.gg/wiki/World_of_Warcraft_API#PartyInfo
--
C_PartyInfo = {}

function C_PartyInfo.GetLootMethod()
	return "master", nil, 1
end

_G.C_PartyInfo = C_PartyInfo