local params = {...}

--- @type AddOn
local AddOn= params[1]
--- @type LibUtil
local Util = AddOn.Libs.Util

function ModuleWithData(m, data, enable)
	enable = Util.Objects.IsEmpty(enable) and true or enable
	local db = NewAceDb(m.defaults)
	db.profile.lootStorage = Util.Tables.Copy(data)

	m:OnInitialize()
	m:SetDb(db)
	if enable then
		AddOn:CallModule(m:GetName())
		-- by default this is only called upon PLAYER_LOGIN event, which also triggers other stuff
		m:OnEnable()
		-- sketchy to do this, but calling Enable() has other ramifications
		m.enabledState = true
	end
end