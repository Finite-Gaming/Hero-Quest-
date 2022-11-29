--- Various utility functions for tables
-- @classmod TableUtils
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TableUtils = {}

function TableUtils.swapArrange(t)
    local newTable = {}
    for i, v in pairs(t) do
        newTable[v] = i
    end

    return newTable
end

return TableUtils