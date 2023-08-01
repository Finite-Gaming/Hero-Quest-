---
-- @classmod PlayerAbilityClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local HttpService = game:GetService("HttpService")
local BaseObject = require("BaseObject")
local PlayerAbilityData = require("PlayerAbilityData")
local ClientClassBinders = require("ClientClassBinders")
local PlayerAbilityConstants = require("PlayerAbilityConstants")
local Maid = require("Maid")

local Players = game:GetService("Players")

local PlayerAbilityClient = setmetatable({}, BaseObject)
PlayerAbilityClient.__index = PlayerAbilityClient

function PlayerAbilityClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), PlayerAbilityClient)

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == self._obj.Name then
            self._player = player
            break
        end
    end
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
        self._maid.AbilityMaid = nil
        return
    else
        self._abilityUI = ClientClassBinders.PlayerAbilityUI:GetAsync(self._obj, 5)
        if not self._abilityUI then
            warn("[PlayerAbilityClient] - Failed to get UI!")
            return
        end

        local maid = Maid.new()
        self._abilityName = abilityName

        self._abilityUI:SetEnabled(true)
        maid:AddTask(function()
            if self._abilityData then
                return
            end

            local abilityUI = ClientClassBinders.PlayerAbilityUI:Get(self._obj)
            if not abilityUI then
                return
            end
            abilityUI:SetEnabled(false)
        end)
        self._abilityUI:UpdateThumbnail(self._abilityData.Thumbnail)
        maid:AddTask(self._abilityUI:GetButton().Activated:Connect(function()
            self:_activate()
        end))

        maid:BindAction(
            ("__playerAbility_%s"):format(HttpService:GenerateGUID(false)),
            function(_, inputState)
                if inputState ~= Enum.UserInputState.Begin then
                    return
                end

                self:_activate()
            end,
            false,
            Enum.KeyCode.Q
        )

        self._maid.AbilityMaid = maid
    end
end

function PlayerAbilityClient:_activate()
    local fireTime = os.clock()
    local cooldown = self._cooldownTime or self._abilityData.BaseStats.Cooldown
    if fireTime - (self._lastFire or 0) < cooldown then
        return
    end
    if cooldown ~= self._abilityData.BaseStats.Cooldown then
        cooldown = self._abilityData.BaseStats.Cooldown
    end

    local abilityClass = ClientClassBinders[self._abilityData.Class]:Get(self._obj)
    if not abilityClass then
        warn("[PlayerAbilityClient] - Failed to get ability class!")
        return
    end
    if not abilityClass:CanActivate() then
        return
    end

    self._lastFire = fireTime

    self._abilityUI:Cooldown(cooldown)
    abilityClass:Activate(true)
    self._cooldownTime = self._abilityData.BaseStats.Cooldown
end

return PlayerAbilityClient