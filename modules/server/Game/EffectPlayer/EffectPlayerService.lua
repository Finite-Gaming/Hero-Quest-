--- Handles effect playing on the server
-- @classmod EffectPlayerService
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local EffectPlayerConstants = require("EffectPlayerConstants")
local Network = require("Network")

local EffectPlayerService = {}

function EffectPlayerService:Init()
    self._remoteEvent = Network:GetRemoteEvent(EffectPlayerConstants.REMOTE_EVENT_NAME)
end

function EffectPlayerService:PlayEffect(effectName, position)
    self._remoteEvent:FireAllClients("PlayEffect", effectName, position)
end

function EffectPlayerService:PlayCustom(...)
    self._remoteEvent:FireAllClients("PlayCustom", ...)
end

return EffectPlayerService