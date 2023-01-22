---
-- @classmod TeamLocker
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local TeamLocker = {}

function TeamLocker:Init()
    for _, player in ipairs(Players:GetPlayers()) do
        self:_handlePlayerAdded(player)
    end

    Players.PlayerAdded:Connect(function(player)
        self:_handlePlayerAdded(player)
    end)
end

function TeamLocker:_handlePlayerAdded(player)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        for _, teammate in ipairs(Players:GetPlayers()) do
            if teammate == player then
                continue
            end

            teammate.Team = player.Team
        end
    end)
end

return TeamLocker