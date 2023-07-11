---
-- @classmod PhaseInAnimator
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local EffectPlayerService = require("EffectPlayerService")
local Maid = require("Maid")

local Players = game:GetService("Players")

local PhaseInAnimator = {}

function PhaseInAnimator:Init()
    self._maid = Maid.new()
    Players.PlayerAdded:Connect(function(player)
        self:_handlePlayerAdded(player)
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        self:_handlePlayerAdded(player)
    end
end

function PhaseInAnimator:_handlePlayerAdded(player)
    local character = player.Character
    if character then
        task.spawn(self._handleCharacterAdded, self, player)
    end
    self._maid[player.Name] = player.CharacterAdded:Connect(function()
        self:_handleCharacterAdded(player)
    end)
end

function PhaseInAnimator:_handleCharacterAdded(player)
    self._maid[player.Name] = nil
    task.wait()
    EffectPlayerService:PlayCustom("PlayerTeleportAnimation", "enter", player)
end

return PhaseInAnimator