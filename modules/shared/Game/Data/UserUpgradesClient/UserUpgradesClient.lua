---
-- @classmod UserUpgradesClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserDataClient = require("UserDataClient")

local UserUpgradesClient = {}

function UserUpgradesClient:Init()
    self._upgrades = UserDataClient:GetUpgradeData()
end

function UserUpgradesClient:UpgradeStat(upgradeName)
    local success, code = UserDataClient:UpgradeStat(upgradeName)
    if success then
        self._upgrades[upgradeName] += 1
    end

    return success, code
end

function UserUpgradesClient:GetUpgradeLevel(upgradeName)
    return self._upgrades[upgradeName]
end

function UserUpgradesClient:GetUpgradeData()
    return self._upgrades
end

return UserUpgradesClient