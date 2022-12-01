--- Methods for determining game type
-- @classmod GameModeManager
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GameModeManager = {}

-- Meant to be edited after game is no longer in alpha, various scripts will use this function
function GameModeManager:IsAlpha()
    return true
end

return GameModeManager