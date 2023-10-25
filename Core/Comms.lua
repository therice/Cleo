--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Core.Comm
local Comm = AddOn.Require('Core.Comm')

function AddOn:SubscribeToComms()
    Logging:Debug("SubscribeToComms(%s)", self:GetName())
    self.commSubscriptions = Comm:BulkSubscribe(C.CommPrefixes.Main, {
        [C.Commands.PlayerInfoRequest] = function(_, sender)
            Logging:Debug("PlayerInfoRequest from %s", tostring(sender))
            Comm:Send {
                target = Player:Get(sender),
                command = C.Commands.PlayerInfo,
                data = {self:GetPlayerInfo()}
            }
        end,
        [C.Commands.PlayerInfo] = function(data, sender)
            Logging:Debug("PlayerInfo %s from %s", Util.Objects.ToString(data), tostring(sender))
            local guildRank, enchanter, enchanterLvl, ilvl = unpack(data)
            Player:Get(sender):Update({
              guildRank    = guildRank,
              enchanter    = enchanter,
              enchanterLvl = enchanterLvl,
              ilvl         = ilvl
            })
        end,
        [C.Commands.LootTable] = function(data, sender)
            Logging:Debug("LootTable %s from %s", Util.Objects.ToString(data), tostring(sender))
            if not self.UnitIsUnit(sender, self.masterLooter) then
                Logging:Warn("LootTable received from %s (they are not the ML)", tostring(sender))
                return
            end
            self:OnLootTableReceived(unpack(data))
        end,
        [C.Commands.LootTableAdd] = function(data, sender)
            Logging:Debug("LootTableAdd %s from %s", Util.Objects.ToString(data), tostring(sender))
            if not self.UnitIsUnit(sender, self.masterLooter) then
                Logging:Warn("LootTableAdd received from %s (they are not the ML)", tostring(sender))
                return
            end
            self:OnLootTableAddReceived(unpack(data))
        end,
        [C.Commands.MasterLooterDb] = function(data, sender)
            Logging:Debug("MasterLooterDb from %s", tostring(sender))
            if AddOn:IsMasterLooter() then
                return
            end

            if AddOn.UnitIsUnit(sender, self.masterLooter) then
                AddOn:OnMasterLooterDbReceived(unpack(data))
            else
                Logging:Warn("MasterLooterDb received from %s (NOT the master looter)", tostring(sender))
            end
        end,
        [C.Commands.LootSessionEnd] = function(_, sender)
            Logging:Debug("LootSessionEnd from %s", tostring(sender))
            if AddOn:IsMasterLooter(sender) then
                AddOn:OnLootSessionEnd()
            end
        end,
        [C.Commands.ReRoll] = function(data, sender)
            Logging:Debug("ReRoll from %s", tostring(sender))
            if AddOn:IsMasterLooter(sender) and self.enabled then
                self:OnReRollReceived(sender, unpack(data))
            end
        end,
    })
end

function AddOn:UnsubscribeFromComms()
    Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
    AddOn.Unsubscribe(self.commSubscriptions)
    self.commSubscriptions = nil
end


--- target, session, response, extra (k/v pairs)
--- @param target string|Models.Player
--- @param session number
--- @param response string
--- @param extra table
function AddOn:SendResponse(target, session, response, extra)
    assert(Util.Objects.IsSet(target), "target was not provided")
    assert(Util.Objects.IsNumber(session), "session was not provided")
    assert(Util.Objects.IsSet(response), "reason was not provided")

    local args = {
        response = response,
    }

    if extra and Util.Objects.IsTable(extra) then
        Util.Tables.CopyInto(args, extra)
    end

    -- always send the player's name along with response, as other use cases
    -- could potentially require the message is sent by another player (i.e. ML) on
    -- behalf of the actual candidate. therefore, treat them consistently
    -- for reference, see MasterLooter:GetItemsFromMessage()
    self:Send(target, C.Commands.Response, session, self.player:GetName(), args)
end


--- @return string
function AddOn:GetAnnounceChannel(channel)
    return channel == C.group and (IsInRaid() and C.Channels.Raid or C.Channels.Party) or channel
end

function AddOn:SendAnnouncement(msg, channel)
    --Logging:Trace("SendAnnouncement(%s) : %s", channel, msg)
    if channel == C.Channels.None then return end

    if self:TestModeEnabled() then
        msg = "(" .. L["test"] .. ") " .. msg
    end

    if (not IsInGroup() and Util.Objects.In(channel, C.group, C.Channels.Raid, C.Channels.RaidWarning, C.Channels.Party, C.Channels.Instance))
        or channel == C.chat
        or (not IsInGuild() and Util.Objects.In(channel, C.Channels.Guild, C.Channels.Officer)) then
        self:Print(msg)
    elseif (not IsInRaid() and Util.Objects.In(channel, C.Channels.Raid, C.Channels.RaidWarning)) then
        SendChatMessage(msg, C.Channels.Party)
    else
        SendChatMessage(msg, self:GetAnnounceChannel(channel))
    end
end