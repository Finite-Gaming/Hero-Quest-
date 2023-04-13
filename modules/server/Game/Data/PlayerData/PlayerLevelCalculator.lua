---
-- @classmod PlayerLevelCalculator
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserData = require("UserData")

local MAX_LEVEL = 8000

local PlayerLevelCalculator = {}

function PlayerLevelCalculator:GetLevelFromXP(xpValue)
    return math.clamp((100 + xpValue)/100, 1, MAX_LEVEL) -- replace formula later
end

function PlayerLevelCalculator:GetPlayerLevel(player)
    local profile = UserData:GetProfile(player.UserId)

    return self:GetLevelFromXP(profile.XP)
end

return PlayerLevelCalculator