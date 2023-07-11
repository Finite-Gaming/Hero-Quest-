
---
-- @classmod AbilityStatMixin
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")

local UserDataService = nil
if RunService:IsClient() then
    UserDataService = require("UserUpgradesClient")
elseif RunService:IsServer() then
    UserDataService = require("UserDataService")
end

local function getMagicLevel(player)
    if RunService:IsClient() then
        return UserDataService:GetUpgradeLevel("MagicDamage")
    elseif RunService:IsServer() then
        return UserDataService:GetUpgradeLevel(player, "MagicDamage")
    end
end

local AbilityStatMixin = {}

function AbilityStatMixin:Add(class)
    class.GetDamage = self.GetDamage
    class.GetCooldown = self.GetCooldown
    class.GetRange = self.GetRange
end

function AbilityStatMixin:GetDamage()
    local upgradeLevel = getMagicLevel(self._player)
    return self._baseStats.Damage * (1.02 ^ upgradeLevel)
end

function AbilityStatMixin:GetCooldown()
    local upgradeLevel = getMagicLevel(self._player)
    local reductionPercentage = 10 -- TODO: change this?
    local reductionAmount = self._baseStats.Cooldown * (reductionPercentage / 100)

    return self._baseStats.Cooldown - (reductionAmount * upgradeLevel)
end

function AbilityStatMixin:GetRange()
    local upgradeLevel = getMagicLevel(self._player)
    local increasePercentage = 15 -- TODO: change this?
    local increaseAmount = self._baseStats.Range * (increasePercentage / 100)

    return self._baseStats.Range + (increaseAmount * upgradeLevel)
end

return AbilityStatMixin