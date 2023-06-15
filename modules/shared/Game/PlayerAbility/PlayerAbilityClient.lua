---
-- @classmod PlayerAbilityClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local PlayerAbilityData = require("PlayerAbilityData")
local ClientClassBinders = require("ClientClassBinders")
local PlayerAbilityConstants = require("PlayerAbilityConstants")

local Players = game:GetService("Players")

local PlayerAbilityClient = setmetatable({}, BaseObject)
PlayerAbilityClient.__index = PlayerAbilityClient

function PlayerAbilityClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), PlayerAbilityClient)

    self._player = Players:GetPlayerFromCharacter(self._obj)
    if not self._player then
        warn("[PlayerAbilityClient] - No player!")
        return
    end
    if self._player ~= Players.LocalPlayer then
        return
    end

    self._remoteEvent = self._obj:WaitForChild(PlayerAbilityConstants.REMOTE_EVENT_NAME)
    self._maid:AddTask(self._remoteEvent.OnClientEvent:Connect(function(action, ...)
        if action == "UpdateAbility" then
            self:UpdateAbility(...)
        end
    end))

    return self
end

function PlayerAbilityClient:UpdateAbility(abilityName)
    self._abilityData = PlayerAbilityData[abilityName]
    if not self._abilityData then
        warn("[PlayerAbilityClient] - Invalid ability name!")
        return
    end

    self._abilityName = abilityName

    local abilityUI = ClientClassBinders.PlayerAbilityUI:Get(self._obj) or
        ClientClassBinders.PlayerAbilityUI:BindAsync(self._obj)
    if not abilityUI then
        warn("[PlayerAbilityClient] - Failed to get UI!")
    else
        abilityUI:UpdateThumbnail(self._abilityData.Thumbnail)
        self._maid:AddTask(abilityUI:GetButton().Activated:Connect(function()
            self:_activate()
        end))
    end

    self._maid:BindAction(
        "__playerAbility",
        function(_, inputState)
            if inputState ~= Enum.UserInputState.Begin then
                return
            end

            self:_activate()
        end,
        false,
        Enum.KeyCode.Q
    )
end

function PlayerAbilityClient:_activate()
    local fireTime = os.clock()
    if fireTime - (self._lastFire or 0) < (self._cooldownTime or self._abilityData.BaseStats.Cooldown) then
        warn("nuh uh uhhhh")
        return
    end
    self._lastFire = fireTime

    local abilityClass = ClientClassBinders[self._abilityData.Class]:Get(self._obj)
    if not abilityClass then
        warn("[PlayerAbilityClient] - Failed to get ability class!")
        return
    end

    abilityClass:Activate(true)
    self._cooldownTime = self._abilityData.BaseStats.Cooldown
end

return PlayerAbilityClient