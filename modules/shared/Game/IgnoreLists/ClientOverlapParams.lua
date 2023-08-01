---
-- @classmod ClientOverlapParams
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClientOverlapParams = {}

function ClientOverlapParams:Init()
    self._overlapParams = OverlapParams.new()
    self._overlapParams.FilterType = Enum.RaycastFilterType.Include

    self._ignoreList = {}

    self._overlapParams.FilterDescendantsInstances = self._ignoreList
end

function ClientOverlapParams:Add(character)
    table.insert(self._ignoreList, character)
    self._overlapParams.FilterDescendantsInstances = self._ignoreList
end

function ClientOverlapParams:Get()
    return self._overlapParams
end

return ClientOverlapParams