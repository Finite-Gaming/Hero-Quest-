---
-- @classmod DamageFeedback
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local DamageFeedbackConstants = require("DamageFeedbackConstants")
 
local DamageFeedback = {}

function DamageFeedback:Init()
    self._remoteEvent = Network:GetRemoteEvent(DamageFeedbackConstants.REMOTE_EVENT_NAME)
end

function DamageFeedback:SendFeedback(humanoid, damage, position)
    self._remoteEvent:FireAllClients(humanoid, damage, position)
end

return DamageFeedback