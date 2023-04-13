--- Does cool things
-- @classmod ApplyImpulse
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local ApplyImpulseConstants = require("ApplyImpulseConstants")

local ApplyImpulse = {}

function ApplyImpulse:Init()
    self._remoteEvent = Network:GetRemoteEvent(ApplyImpulseConstants.REMOTE_EVENT_NAME)
end

function ApplyImpulse:ApplyImpulse(player, part, force)
    self._remoteEvent:FireClient(player, part, force)
end

return ApplyImpulse