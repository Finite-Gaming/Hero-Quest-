---
-- @classmod GameModeManager
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GameModeManager = {}

function GameModeManager:IsAlpha()
    return true
end

return GameModeManager