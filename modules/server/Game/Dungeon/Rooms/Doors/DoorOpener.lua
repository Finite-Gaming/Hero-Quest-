---
-- @classmod BaseService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local DoorOpenerConstants = require("DoorOpenerConstants")

local BaseService = {}

function BaseService:Init()
    self._remoteEvent = Network:GetRemoteEvent(DoorOpenerConstants.REMOTE_EVENT_NAME)
end

function BaseService:OpenDoor(door)
    self._remoteEvent:FireAllClients(door)
end

return BaseService