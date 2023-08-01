---
-- @classmod HitscanPart
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local HitscanPartConstants = require("HitscanPartConstants")
local PlayerDamageService = require("PlayerDamageService")

local HitscanPart = setmetatable({}, BaseObject)
HitscanPart.__index = HitscanPart

function HitscanPart.new(obj)
    local self = setmetatable(BaseObject.new(obj), HitscanPart)

    self._remoteEvent = Instance.new("RemoteEvent")
    self._remoteEvent.Name = HitscanPartConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj
    self._maid:AddTask(self._remoteEvent.OnServerEvent:Connect(function(player)
        local damage = self._obj:GetAttribute("Damage")
        PlayerDamageService:DamagePlayer(player, math.random(damage.Min, damage.Max))
    end))

    return self
end

return HitscanPart