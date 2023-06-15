---
-- @classmod TotalEnemiesKilled
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local FunctionUtils = require("FunctionUtils")
local Network = require("Network")
local TotalEnemiesKilledConstants = require("TotalEnemiesKilledConstants")

local DataStoreService = game:GetService("DataStoreService")

local TotalEnemiesKilled = {}

function TotalEnemiesKilled:Init()
    self._playerCache = {}

    task.spawn(function()
        self._killCountStore = FunctionUtils.rCallAPIAsync(DataStoreService, "GetDataStore", "KillCount")

        local totalEnemiesKilled = FunctionUtils.rCallAPIAsync(self._killCountStore, "GetAsync", "TotalEnemiesKilled")
        if not totalEnemiesKilled then
            FunctionUtils.rCallAPI(self._killCountStore, "SetAsync", "TotalEnemiesKilled", 0)
        end

        Network:GetRemoteFunction(TotalEnemiesKilledConstants.REMOTE_FUNCTION_NAME).OnServerInvoke = function(player)
            local invokeTime = os.clock()
            local requestData = self._playerCache[player]
            if requestData then
                if invokeTime - requestData.InvokeTime < 60 then
                    return requestData.Data
                end
            end

            local data = FunctionUtils.rCallAPIAsync(self._killCountStore, "GetAsync", "TotalEnemiesKilled")
            self._playerCache[player] = {InvokeTime = invokeTime, Data = data}

            return data
        end
    end)
end

function TotalEnemiesKilled:AddEnemies(amount)
    assert(typeof(amount) == "number" and amount % 1 == 0)
    FunctionUtils.rCallAPI(self._killCountStore, "IncrementAsync", "TotalEnemiesKilled", amount)
end

return TotalEnemiesKilled