loadfile("Test/WowXmlParser.lua")()

-- basic dependencies required by LibEncounter
function LoadDependencies()
	ParseXmlAndLoad('Libs/CallbackHandler-1.0/CallbackHandler-1.0.xml')
	ParseXmlAndLoad('Libs/AceEvent-3.0/AceEvent-3.0.xml')
	ParseXmlAndLoad('Libs/LibDeformat-3.0/LibDeformat-3.0.xml')
	ParseXmlAndLoad('Libs/LibDeflate/LibDeflate.xml')
	ParseXmlAndLoad('Libs/LibClass-1.0/LibClass-1.0.xml')
	ParseXmlAndLoad('Libs/LibLogging-1.0/LibLogging-1.0.xml')
	ParseXmlAndLoad('Libs/LibUtil-1.1/LibUtil-1.1.xml')
	ParseXmlAndLoad('Libs/LibBabble-3.0/LibBabble-3.0.xml')
	ParseXmlAndLoad('Libs/LibBabble-SubZone-3.0/LibBabble-SubZone-3.0.xml')
	ParseXmlAndLoad('Libs/LibBabble-Boss-3.0/LibBabble-Boss-3.0.xml')
end