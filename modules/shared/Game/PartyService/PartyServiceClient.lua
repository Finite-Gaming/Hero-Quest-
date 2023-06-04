---
-- @classmod PartyServiceClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local PartyServiceConstants = require("PartyServiceConstants")
local Signal = require("Signal")
local InviteClient = require("InviteClient")
local NotificationService = require("NotificationService")

local Players = game:GetService("Players")

local PartyServiceClient = {}

function PartyServiceClient:Init()
    self._remoteEvent = Network:GetRemoteEvent(PartyServiceConstants.REMOTE_EVENT_NAME)
    self._remoteFunction = Network:GetRemoteFunction(PartyServiceConstants.REMOTE_FUNCTION_NAME)
    self.ListUpdated = Signal.new()

    self._remoteEvent.OnClientEvent:Connect(function(action, data, ...)
        if action == "Invite" then
            InviteClient:DisplayInvite(data)
        elseif action == "UpdateList" then
            self.ListUpdated:Fire(data)
        elseif action == "Notification" then
            NotificationService:Notify(data, ...)
        else
            warn("action: and stuff:", action, data)
        end
    end)
end

function PartyServiceClient:CreateParty()
    self._remoteEvent:FireServer("CreateParty")
end

function PartyServiceClient:LeaveParty()
    self._remoteEvent:FireServer("LeaveParty")
end

function PartyServiceClient:StartGame()
    self._remoteEvent:FireServer("StartGame")
end

function PartyServiceClient:GetPartyMembers()
    return self._remoteFunction:InvokeServer("GetPartyMembers")
end

function PartyServiceClient:IsPartyMember()
    return self._remoteFunction:InvokeServer("IsPartyMember")
end

function PartyServiceClient:IsPartyOwner()
    return self._remoteFunction:InvokeServer("IsPartyOwner")
end

function PartyServiceClient:InvitePlayer(playerName)
    if not playerName or playerName == "" then
        NotificationService:Notify("Please input a player name", "Error")
        return
    end
    local userId = tonumber(playerName)
    local success = nil
    if not userId then
        success, userId = pcall(Players.GetUserIdFromNameAsync, Players, playerName)
        if not success then
            NotificationService:Notify("Invalid player name", "Error")
            return
        end
    else
        warn("[WARNING] - The userid input function should be removed before release")
    end
    self._remoteEvent:FireServer("Invite", {ToPlayer = userId})
end

function PartyServiceClient:KickPlayer(userId)
    self._remoteEvent:FireServer("Kick", {ToPlayer = userId})
end

return PartyServiceClient