---
-- @classmod TotalEnemiesKilledClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local TotalEnemiesKilledConstants = require("TotalEnemiesKilledConstants")

local TotalEnemiesKilledClient = {}

function TotalEnemiesKilledClient:Init()
    self._remoteFunction = Network:GetRemoteFunction(TotalEnemiesKilledConstants.REMOTE_FUNCTION_NAME)
end

function TotalEnemiesKilledClient:GetTotal()
    return self._remoteFunction:InvokeServer()
end

return TotalEnemiesKilledClient