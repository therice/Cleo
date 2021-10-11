--- @type AddOn
local _, AddOn = ...
local C  = AddOn.Constants

function AddOn:GetResponseColor(name)
    return self:GetResponse(name).color:GetRGBA()
end

function AddOn.GetDiffColor(num)
    if not num or num == "" then num = 0 end
    if num > 0 then return C.Colors.Green:GetRGBA() end
    if num < 0 then return C.Colors.LuminousOrange:GetRGBA() end
    return C.Colors.Aluminum:GetRGBA()
end