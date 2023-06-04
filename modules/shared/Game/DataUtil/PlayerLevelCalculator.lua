---
-- @classmod PlayerLevelCalculator
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BASE_XP = 100
local MAX_LEVEL = 8000
local EXPONENT_FACTOR = 2

local PlayerLevelCalculator = {}

function PlayerLevelCalculator:GetLevelFromXP(xpValue)
    return math.clamp(math.floor((xpValue / BASE_XP) ^ (1 / EXPONENT_FACTOR)), 1, MAX_LEVEL) -- replace formula later
end

return PlayerLevelCalculator