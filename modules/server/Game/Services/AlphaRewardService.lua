---
-- @classmod AlphaRewardService
-- @author unknown, frick

local cRequire = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local GameModeManager = cRequire("GameModeManager")

local UserData = require(ServerScriptService:WaitForChild("PlayerData"):WaitForChild("UserData"))

local ALPHA_BADGE_ID = 2126509640

local AlphaRewardService = {}

function AlphaRewardService:Init()
    if not GameModeManager:IsAlpha() then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(self._handlePlayerAdded, self, player)
    end

    Players.PlayerAdded:Connect(function(player)
        self:_handlePlayerAdded(player)
    end)
end

function AlphaRewardService:_handlePlayerAdded(player)
    BadgeService:AwardBadge(player.UserId, ALPHA_BADGE_ID)
    UserData:GiveSpecialReward(player.UserId, "ItCameFromTheDeep")
end

return AlphaRewardService