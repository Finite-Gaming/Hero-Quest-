---
-- @classmod UpgradePriceUtil
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UpgradePriceUtil = {}

function UpgradePriceUtil:GetPriceFromLevel(level, upgradeName)
    return level * 100 -- remember, we will replace this later
end

return UpgradePriceUtil