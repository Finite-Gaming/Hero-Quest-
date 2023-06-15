---
-- @classmod TimeUtils
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TimeUtils = {}

function TimeUtils.formatM_S_MS(seconds)
    local minutes = math.floor(seconds/60)
    seconds %= 60
    local miliseconds = (seconds * 1000) % 1000
    return string.format("%02i:%02i:%02i", minutes, seconds, miliseconds)
end

return TimeUtils