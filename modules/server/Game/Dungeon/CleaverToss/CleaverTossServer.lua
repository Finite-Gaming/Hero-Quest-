---
-- @classmod CleaverTossServer
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local CleaverTossConstants = require("CleaverTossConstants")
local PlayerDamageService = require("PlayerDamageService")

local DAMAGE = NumberRange.new(36, 60)

local CleaverTossServer = {}

function CleaverTossServer:Init()
    self._remoteEvent = Network:GetRemoteEvent(CleaverTossConstants.REMOTE_EVENT_NAME)

    self._remoteEvent.OnServerEvent:Connect(function(player)
        PlayerDamageService:DamagePlayer(player, math.random(DAMAGE.Min, DAMAGE.Max))
    end)
end

return CleaverTossServer