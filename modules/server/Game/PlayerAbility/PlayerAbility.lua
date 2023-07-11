---
-- @classmod PlayerAbility
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local PlayerAbilityConstants = require("PlayerAbilityConstants")
local PlayerAbilityData = require("PlayerAbilityData")
local ServerClassBinders = require("ServerClassBinders")
local UserDataService = require("UserDataService")

local Players = game:GetService("Players")

local PlayerAbility = setmetatable({}, BaseObject)
PlayerAbility.__index = PlayerAbility

function PlayerAbility.new(obj)
    local self = setmetatable(BaseObject.new(obj), PlayerAbility)

    self._player = Players[self._obj.Name]

    self._remoteEvent = self._maid:AddTask(Instance.new("RemoteEvent"))
    self._remoteEvent.Name = PlayerAbilityConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj
    self._maid:AddTask(self._remoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if player.Character ~= self._obj then
            return
        end
    end))

    local equippedAbility = UserDataService:GetEquipped(self._player, "Ability")
    if equippedAbility then
        self:UpdateAbility(equippedAbility)
    end

    return self
end

function PlayerAbility:_fireOtherClients(...)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == self._obj.Name then
            continue
        end

        self._remoteEvent:FireClient(player, ...)
    end
end

function PlayerAbility:UpdateAbility(abilityName)
    local abilityData = PlayerAbilityData[abilityName]
    if not abilityData then
        self._currentAbility = nil
        self._abilityClass:Unbind(self._obj)
        self._remoteEvent:FireClient(self._player, "UpdateAbility", nil)
        return
    end

    if self._currentAbility == abilityName then
        return
    end
    self._currentAbility = abilityName

    if self._abilityClass then
        self._abilityClass:Unbind(self._obj)
    end
    self._abilityClass = ServerClassBinders[abilityData.Class]
    self._abilityClass:Bind(self._obj)

    self._remoteEvent:FireClient(self._player, "UpdateAbility", abilityName)
end

return PlayerAbility