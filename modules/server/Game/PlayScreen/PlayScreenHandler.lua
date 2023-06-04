---
-- @classmod PlayScreenHandler
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local PlayScreenConstants = require("PlayScreenConstants")
local UserDataService = require("UserDataService")
local DungeonData = require("DungeonData")

local TeleportService = game:GetService("TeleportService")

local PlayScreenHandler = {}

function PlayScreenHandler:Init()
    self._remoteEvent = Network:GetRemoteEvent(PlayScreenConstants.REMOTE_EVENT_NAME)

    self._remoteEvent.OnServerEvent:Connect(function(player)
        local nextDungeon = UserDataService:GetNextDungeon(player)
        local data = DungeonData[nextDungeon]

        if not data then
            warn("chat is this real?")
            return
        end

        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ShouldReserveServer = true
        TeleportService:TeleportAsync(data.PlaceId, {player}, teleportOptions)
    end)
end

return PlayScreenHandler