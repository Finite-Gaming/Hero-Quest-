---
-- @classmod CameraShakeService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local CameraShakeServiceConstants = require("CameraShakeServiceConstants")

local CameraShakeService = {}

function CameraShakeService:Init()
    self._remoteEvent = Network:GetRemoteEvent(CameraShakeServiceConstants.REMOTE_EVENT_NAME)
end

function CameraShakeService:Shake(player, intensity)
    self._remoteEvent:FireClient(player, intensity)
end

return CameraShakeService