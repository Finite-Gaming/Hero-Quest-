---
-- @classmod PlayerAbilityClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local PlayerAbilityData = require("PlayerAbilityData")
local ClientClassBinders = require("ClientClassBinders")
local PlayerAbilityConstants = require("PlayerAbilityConstants")

local PlayerAbilityClient = setmetatable({}, BaseObject)
PlayerAbilityClient.__index = PlayerAbilityClient

function PlayerAbilityClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), PlayerAbilityClient)

    self._remoteEvent = self._obj:WaitForChild(PlayerAbilityConstants.REMOTE_EVENT_NAME)
    self._maid:AddTask(self._remoteEvent.OnClientEvent:Connect(function(action, ...)
        if action == "UpdateAbility" then
            self:UpdateAbility(...)
        end
    end))

    return self
end

function PlayerAbilityClient:UpdateAbility(abilityName)
    local abilityData = PlayerAbilityData[abilityName]
    if not abilityData then
        warn("[PlayerAbilityClient] - Invalid ability name!")
        return
    end

    self._abilityName = abilityName
    self._abilityClass = ClientClassBinders[abilityData.Class]

    local abilityUI = ClientClassBinders.PlayerAbilityUI:Get(self._obj)
    if not abilityUI then
        warn("[PlayerAbilityClient] - Failed to get UI!")
    else
        abilityUI:UpdateThumbnail(abilityData.Thumbnail)
    end

    self._maid:BindAction(
        "__playerAbility",
        function(_, inputState)
            if inputState ~= Enum.UserInputState.Begin then
                return
            end

            local fireTime = os.clock()
            if fireTime - (self._lastFire or 0) < (self._cooldownTime or abilityData.BaseStats.Cooldown) then
                warn("nuh uh uhhhh")
                return
            end
            self._lastFire = fireTime

            local abilityClass = self._abilityClass:Get(self._obj)
            if not abilityClass then
                warn("[PlayerAbilityClient] - Failed to get ability class!")
                return
            end

            warn("woah beamed")
            abilityClass:Activate(true)
            self._cooldownTime = abilityData.BaseStats.Cooldown
        end,
        false,
        Enum.KeyCode.Q
    )
end

return PlayerAbilityClient