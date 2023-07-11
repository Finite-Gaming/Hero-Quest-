---
-- @classmod QuestUpdater
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local QuestUpdaterConstants = require("QuestUpdaterConstants")
local UserDataService = require("UserDataService")

local QuestUpdater = {}

function QuestUpdater:Init()
    self._remoteEvent = Network:GetRemoteEvent(QuestUpdaterConstants.REMOTE_EVENT_NAME)
end

function QuestUpdater:Update(player)
    local questData = UserDataService:GetQuestData(player)

    self._remoteEvent:FireClient(player, questData)
end

return QuestUpdater