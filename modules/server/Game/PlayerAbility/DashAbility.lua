---
-- @classmod DashAbilityClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local AlignPosition = require("AlignPosition")
local AnimationTrack = require("AnimationTrack")
local DashAbilityConstants = require("DashAbilityConstants")

local DashAbilityClient = setmetatable({}, BaseObject)
DashAbilityClient.__index = DashAbilityClient

function DashAbilityClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), DashAbilityClient)

    self._humanoid = self._obj:WaitForChild("Humanoid")
    self._humanoidRootPart = self._obj:WaitForChild("HumanoidRootPart")
    self._rootAttachment = self._humanoidRootPart:WaitForChild("RootAttachment")

    self._remoteEvent = self._maid:AddTask(Instance.new("RemoteEvent"))
    self._remoteEvent.Name = DashAbilityConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj

    self._maid:AddTask(self._remoteEvent.OnServerEvent:Connect(function(player, state)
        if player.Character ~= self._obj then
            return
        end

        if state then
            self._fallback = true
            self._maid.FallbackDelay = task.delay(0.4, function()
                if self._fallback then
                    self._remoteEvent:FireAllClients(player, false)
                end
            end)
            self._remoteEvent:FireAllClients(player, true)
        else
            self._fallback = false
            self._maid.FallbackDelay = nil
            self._remoteEvent:FireAllClients(player, false)
        end
    end))

    return self
end

return DashAbilityClient