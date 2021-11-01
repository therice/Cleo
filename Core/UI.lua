--- @type AddOn
local _, AddOn = ...
local C  = AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")

function AddOn:GetResponseColor(name)
    local r, g, b, a = 1, 1, 1, 1

    local response

    if Util.Objects.IsString(name) then
        response = self:GetResponse(name)
    elseif Util.Objects.IsNumber(name) then
        response = name < 10 and self:GetResponse(name) or AddOn.NonUserVisibleResponse(name)
    end

    if response and response.color then
        r, g, b, a = response.color:GetRGBA()
    end

    return r, g, b, a
end


function AddOn.GetDiffColor(num)
    if not num or num == "" then num = 0 end
    if num > 0 then return C.Colors.Green:GetRGBA() end
    if num < 0 then return C.Colors.LuminousOrange:GetRGBA() end
    return C.Colors.Aluminum:GetRGBA()
end