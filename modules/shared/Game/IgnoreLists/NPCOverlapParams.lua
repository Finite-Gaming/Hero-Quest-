---
-- @classmod NPCOverlapParams
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RaycastList = require("RaycastList")

local NPCOverlapParams = {}

function NPCOverlapParams:Init()
    self._overlapParams = OverlapParams.new()
    self._overlapParams.FilterType = Enum.RaycastFilterType.Include

    self._raycastList = RaycastList.new(workspace.Rooms, function(child)
        if child.Name == "HumanoidRootPart" then
            return true
        end
    end, self._overlapParams)
end

function NPCOverlapParams:Get()
    return self._raycastList:Get()
end

return NPCOverlapParams