--- Does cool things
-- @classmod ApplyImpulseClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local ApplyImpulseConstants = require("ApplyImpulseConstants")

local ApplyImpulseClient = {}

function ApplyImpulseClient:Init()
    self._remoteEvent = Network:GetRemoteEvent(ApplyImpulseConstants.REMOTE_EVENT_NAME)

    self._remoteEvent.OnClientEvent:Connect(function(part, force)
        part:ApplyImpulse(force)
    end)
end

return ApplyImpulseClient