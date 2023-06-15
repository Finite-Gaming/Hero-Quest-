---
-- @classmod CharacterOverlapParams
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local CharacterOverlapParams = {}

function CharacterOverlapParams:Init()
    self._overlapParams = OverlapParams.new()
    self._overlapParams.FilterType = Enum.RaycastFilterType.Include

    self._ignoreList = {}

    self._overlapParams.FilterDescendantsInstances = self._ignoreList
end

function CharacterOverlapParams:Add(character)
    table.insert(self._ignoreList, character:WaitForChild("HumanoidRootPart"))
    self._overlapParams.FilterDescendantsInstances = self._ignoreList
end

function CharacterOverlapParams:Get()
    return self._overlapParams
end

return CharacterOverlapParams