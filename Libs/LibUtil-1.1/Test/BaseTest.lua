loadfile("Test/WowXmlParser.lua")()

-- basic dependencies required by LibUtil
function LoadDependencies()
    ParseXmlAndLoad('Libs/LibDeflate/LibDeflate.xml')
    ParseXmlAndLoad('Libs/LibClass-1.0/LibClass-1.0.xml')
    ParseXmlAndLoad('Libs/LibLogging-1.0/LibLogging-1.0.xml')
    ParseXmlAndLoad('Libs/LibUtil-1.1/LibUtil-1.1.xml')
    ParseXmlAndLoad('Libs/AceTimer-3.0/AceTimer-3.0.xml')
end