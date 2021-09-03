loadfile("Test/WowXmlParser.lua")()

-- basic dependencies required by LibUtil
function LoadDependencies(AddOnName, AddOn)
    ParseXmlAndLoad('Libs/LibDeflate/LibDeflate.xml')
    ParseXmlAndLoad('Libs/LibClass-1.0/LibClass-1.0.xml')
    ParseXmlAndLoad('Libs/LibLogging-1.0/LibLogging-1.0.xml')
    ParseXmlAndLoad('Libs/LibUtil-1.1/LibUtil-1.1.xml')
    ParseXmlAndLoad('Core/Oak/Oak.xml', AddOnName, AddOn)
end