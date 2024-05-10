loadfile("Test/WowXmlParser.lua")()

-- basic dependencies required by LibUtil
function LoadDependencies()
    ParseXmlAndLoad('Libs/LibSHA-1.0/LibSHA-1.0.xml')
    ParseXmlAndLoad('Libs/LibDeflate/LibDeflate.xml')
    ParseXmlAndLoad('Libs/LibClass-1.1/LibClass-1.1.xml')
    ParseXmlAndLoad('Libs/LibLogging-1.1/LibLogging-1.1.xml')
    ParseXmlAndLoad('Libs/LibUtil-1.2/LibUtil-1.2.xml')
    ParseXmlAndLoad('Libs/AceTimer-3.0/AceTimer-3.0.xml')
end