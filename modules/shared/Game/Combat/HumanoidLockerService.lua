---
-- @classmod BaseService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClientClassBinders = require("ClientClassBinders")

local BaseService = {}

function BaseService:LockHumanoid(humanoid)
    if self._humanoidLocker then
        local lockedHumanoid = self._humanoidLocker:GetObject()
        if lockedHumanoid == humanoid then
            return
        end

        ClientClassBinders.HumanoidLocker:Unbind(lockedHumanoid)
        self._humanoidLocker = nil
    end

    if humanoid then
        self._humanoidLocker = ClientClassBinders.HumanoidLocker:BindAsync(humanoid)
        local unlocked; unlocked = self._humanoidLocker.Unlocked:Connect(function()
            self._humanoidLocker = nil
            unlocked:Disconnect()
        end)
    end
end

return BaseService